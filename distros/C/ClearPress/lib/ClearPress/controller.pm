# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
# Created: 2007-03-28
#
# method id action  aspect  result CRUD
# =====================================
# POST   n  create  -       create    *
# POST   y  create  update  update    *
# POST   y  create  delete  delete    *
# GET    n  read    -       list
# GET    n  read    add     add/new
# GET    y  read    -       read      *
# GET    y  read    edit    edit

package ClearPress::controller;
use strict;
use warnings;
use English qw(-no_match_vars);
use Carp;
use ClearPress::decorator;
use ClearPress::view::error;
use CGI;
use HTTP::Status qw(:constants :is);
use HTTP::Headers;

our $VERSION = q[477.1.2];

our $CRUD    = { # these map HTTP verbs to $action
		POST    => 'create',
		GET     => 'read',
		PUT     => 'update',
		DELETE  => 'delete',
                OPTIONS => 'options',
                HEAD    => 'null',
                TRACE   => 'null',
	       };
our $REST   = { # these assist sanitising $aspect
	       create  => 'POST',
	       read    => 'GET',
	       update  => 'PUT|POST',
	       delete  => 'DELETE|POST',
	       add     => 'GET',
	       edit    => 'GET',
	       list    => 'GET',
               options => 'OPTIONS',
               null    => 'HEAD|TRACE'
	      };

sub accept_extensions {
  return [
	  {'.html' => q[]},
	  {'.xml'  => q[_xml]},
	  {'.png'  => q[_png]},
	  {'.svg'  => q[_svg]},
	  {'.svgz' => q[_svgz]},
	  {'.jpg'  => q[_jpg]},
	  {'.rss'  => q[_rss]},
	  {'.atom' => q[_atom]},
	  {'.js'   => q[_json]},
	  {'.json' => q[_json]},
	  {'.ical' => q[_ical]},
	  {'.txt'  => q[_txt]},
	  {'.xls'  => q[_xls]},
	  {'.csv'  => q[_csv]},
	  {'.ajax' => q[_ajax]},
	 ];
}

sub accept_headers {
  return [
#	  {'text/html'        => q[]},
	  {'application/json' => q[_json]},
	  {'text/xml'         => q[_xml]},
	 ];
}

sub new {
  my ($class, $self) = @_;
  $self ||= {};
  bless $self, $class;
  $self->init();

  eval {
    #########
    # We may be given a database handle from the cache with an open
    # transaction (e.g. from running a few selects), so on controller
    # construction (effectively per-page-view), we rollback any open
    # transaction on the database handle we've been given.
    #
    $self->util->dbh->rollback();
    1;

  } or do {
    #########
    # ignore any error
    #
    carp qq[Failed per-request rollback on fresh database handle: $EVAL_ERROR];
  };

  return $self;
}

sub init {
  return 1;
}

sub util {
  my ($self, $util) = @_;
  if(defined $util) {
    $self->{util} = $util;
  }
  return $self->{util};
}

sub packagespace {
  my ($self, $type, $entity, $util) = @_;

  if($type ne 'view' &&
     $type ne 'model') {
    return;
  }

  $util         ||= $self->util();
  my $entity_name = $entity;

  if($util->config->SectionExists('packagemap')) {
    #########
    # if there are uri-to-package maps, process here
    #
    my $map = $util->config->val('packagemap', $entity);
    if($map) {
      $entity = $map;
    }
  }

  my $namespace = $self->namespace($util);
  return "${namespace}::${type}::$entity";
}

sub process_request { ## no critic (Subroutines::ProhibitExcessComplexity)
  my ($self, $headers) = @_;
  my $util          = $self->util;
  my $method        = $ENV{REQUEST_METHOD} || 'GET';
  my $action        = $CRUD->{uc $method};
  my $pi            = $ENV{PATH_INFO}      || q[];
  my $accept        = $ENV{HTTP_ACCEPT}    || q[];
  my $qs            = $ENV{QUERY_STRING}   || q[];
  my $hxrw          = $ENV{HTTP_X_REQUESTED_WITH} || q[];
  my $xhr           = ($hxrw =~ /XMLHttpRequest/smix);

  my $accept_extensions = join q[|],
                          grep { defined }
                          map  { m{[.](\S+)$}smx; $1 || undef; } ## no critic (ProhibitCaptureWithoutTest, ProhibitComplexMappings)
                          map  { join q[,], keys %{$_} }
                          @{$self->accept_extensions()};

  if($xhr && $pi !~ m{(?:$accept_extensions)(?:/[^/]*?)?$}smx) {
    if($pi =~ /[;]/smx) {
      $pi .= q[_ajax];
    } else {
      $pi .= q[.ajax];
    }
  }

  my ($entity)      = $pi =~ m{^/([^/;.]+)}smx;
  $entity         ||= q[];
  my ($dummy, $aspect_extra, $id) = $pi =~ m{^/$entity(/(.*))?/([[:lower:][:digit:]:,\-_%@.+\s]+)}smix;

  my ($aspect)      = $pi =~ m{;(\S+)}smx;

  if($action eq 'read' && !$id && !$aspect) {
    $aspect = 'list';
  }

  if($action eq 'create' && $id) {
    if(!$aspect || $aspect =~ /^update/smx) {
      $action = 'update';

    } elsif($aspect =~ /^delete/smx) {
      $action = 'delete';
    }
  }

  $aspect ||= q[];
  $aspect_extra ||= q[];

  #########
  # process request extensions
  #
  my $uriaspect = $self->_process_request_extensions(\$pi, $aspect, $action) || q[];
  if($uriaspect ne $aspect) {
    $aspect = $uriaspect;
    ($id)   = $pi =~ m{^/$entity/?$aspect_extra/([[:lower:][:digit:]:,\-_%@.+\s]+)}smix;
  }

  #########
  # process HTTP 'Accept' header
  #
  $aspect   = $self->_process_request_headers(\$accept, $aspect, $action);
  $entity ||= $util->config->val('application', 'default_view');
  $aspect ||= q[];
  $id       = CGI->unescape($id||'0');

  #########
  # no view determined and no configured default_view
  # pull the first one off the list
  #
  if(!$entity) {
    my $views = $util->config->val('application', 'views') || q[];
    $entity   = (split /[\s,]+/smx, $views)[0];
  }

  #########
  # no view determined, no default_view and none in the list
  #
  if(!$entity) {
    croak q[No available views];
  }

  my $viewclass = $self->packagespace('view', $entity, $util);

  if($aspect_extra) {
    $aspect_extra =~ s{/}{_}smxg;
  }

  if($id eq '0') {
    #########
    # no primary key:
    # /thing;method
    # /thing;method_xml
    # /thing.xml;method
    #
    my $tmp = $aspect || $action;
    if($aspect_extra) {
      $tmp =~ s/_/_${aspect_extra}_/smx;

      if($viewclass->can($tmp)) {
	$aspect = $tmp;
      }
    }

  } elsif($id !~ /^\d+$/smx) {
    #########
    # mangled primary key - attempt to match method in view object
    # /thing/method          => list_thing_method (if exists), or read(pk=method)
    # /thing/part1/part2     => list_thing_part1_part2 if exists, or read_thing_part1(pk=part2)
    # /thing/method.xml      => list_thing_method_xml (if exists), or read_thing_xml (pk=method)
    # /thing/part1/part2.xml => list_thing_part1_part2_xml (if exists), or read_thing_part1_xml (pk=part2)
    #

    my $tmp = $aspect;

    if($tmp =~ /_/smx) {
      $tmp =~ s/_/_${id}_/smx;

    } else {
      $tmp = "${action}_$id";

    }

    $tmp =~ s/^read/list/smx;
    $tmp =~ s/^update/create/smx;

    if($aspect_extra) {
      $tmp =~ s/_/_${aspect_extra}_/smx;
    }

    if($viewclass->can($tmp)) {
      $id     = 0;
      $aspect = $tmp;

      #########
      # id has been modified, so reset action
      #
      if($aspect =~ /^create/smx) {
	$action = 'create';
      }

    } else {
      if($aspect_extra) {
	if($aspect =~ /_/smx) {
	  $aspect =~ s/_/_${aspect_extra}_/smx;
	} else {
	  $aspect .= "_$aspect_extra";
	}
      }
    }

  } elsif($aspect_extra) {
    #########
    # /thing/method/50       => read_thing_method(pk=50)
    #
    if($aspect =~ /_/smx) {
      $aspect =~ s/_/_${aspect_extra}_/smx;
    } else {
      $aspect .= "${action}_$aspect_extra";
    }
  }

  #########
  # fix up aspect
  #
  my ($firstpart) = $aspect =~ /^${action}_([^_]+)_?/smx;
  if($firstpart) {
    my $restpart = $REST->{$firstpart};
    if($restpart) {
      ($restpart) = $restpart =~ /^([^|]+)/smx;
      if($restpart) {
	my ($crudpart) = $CRUD->{$restpart};
	if($crudpart) {
	  $aspect =~ s/^${crudpart}_//smx;
	}
      }
    }
  }

  if($aspect !~ /^(?:create|read|update|delete|add|list|edit|options)/smx) {
    my $action_extended = $action;
    if(!$id) {
      $action_extended = {
			  read => 'list',
			 }->{$action} || $action_extended;
    }

    $aspect = $action_extended . ($aspect?"_$aspect":q[]);
  }

#  if($method eq 'OPTIONS') {
#    $action = 'options';
#    $aspect = 'options';
#  }

  #########
  # sanity checks
  #
  my ($type) = $aspect =~ /^([^_]+)/smx; # read|list|add|edit|create|update|delete
  if($method !~ /^$REST->{$type}$/smx) {
    $headers->header('Status', HTTP_BAD_REQUEST);
    croak qq[Bad request. $aspect ($type) is not a $CRUD->{$method} method];
  }

  if(!$id &&
     $aspect =~ /^(?:delete|update|edit|read)/smx) {
    $headers->header('Status', HTTP_BAD_REQUEST);
    croak qq[Bad request. Cannot $aspect without an id];
  }

  if($id &&
     $aspect =~ /^(?:create|add|list)/smx) {
    $headers->header('Status', HTTP_BAD_REQUEST);
    croak qq[Bad request. Cannot $aspect with an id];
  }

  $aspect =~ s/__/_/smxg;
  return ($action, $entity, $aspect, $id);
}

sub _process_request_extensions {
  my ($self, $pi, $aspect, $action) = @_;

  my $extensions = join q[], reverse ${$pi} =~ m{([.][^;.]+)}smxg;

  for my $pair (@{$self->accept_extensions}) {
    my ($ext, $meth) = %{$pair};
    $ext =~ s/[.]/\\./smxg;

    if($extensions =~ s{$ext$}{}smx) {
      ${$pi}    =~ s{$ext}{}smx;
      $aspect ||= $action;
      $aspect   =~ s/$meth$//smx;
      $aspect  .= $meth;
    }
  }

  return $aspect;
}

sub _process_request_headers {
  my ($self, $accept, $aspect, $action) = @_;

  for my $pair (@{$self->accept_headers()}) {
    my ($header, $meth) = %{$pair};
    if(${$accept} =~ /$header$/smx) {
      $aspect ||= $action;
      $aspect  =~ s/$meth$//smx;
      $aspect .= $meth;
      last;
    }
  }

  return $aspect;
}

sub decorator {
  my ($self, $util, $headers) = @_;

  if(!$self->{decorator}) {
    my $appname   = $util->config->val('application', 'name') || 'Application';
    my $namespace = $self->namespace;
    my $decorpkg  = "${namespace}::decorator";
    my $config    = $util->config;
    my $decor;

    my $ref = {
               headers => $headers,
              };
    eval {
      $decor = $decorpkg->new($ref);
      1;
    } or do {
      $decor = ClearPress::decorator->new($ref);
    };

    for my $field ($decor->fields) {
      $decor->$field($config->val('application', $field));
    }

    if(!$decor->title) {
      $decor->title($config->val('application', 'name') || 'ClearPress Application');
    }

    #########
    # only cache decorator when $headers is passed
    #
    if($headers) {
      $self->{decorator} = $decor;
    }
  }

  return $self->{decorator};
}

sub session {
  my ($self, $util) = @_;
  return $self->decorator($util || $self->util())->session() || {};
}

sub handler {
  my ($self, $util) = @_;
  if(!ref $self) {
    $self = $self->new({util => $util});
  }

  my $headers   = HTTP::Headers->new();
  my $cgi       = $util->cgi();
  my $decorator = $self->decorator($util, $headers);
  my $namespace = $self->namespace($util);

  $headers->header('Status', HTTP_OK);
  $headers->header('X-Generator', 'ClearPress');

  #########
  # no obvious right place for this
  #
  my $lang = $decorator->lang;
  if($lang && scalar @{$lang}) {
    $headers->header('Content-Language', join q[,], @{$lang});
  }

  my ($action, $entity, $aspect, $id, $process_request_error);
  eval {
    ($action, $entity, $aspect, $id) = $self->process_request($headers);
    1;
  } or do {
    carp qq[CAUGHT $EVAL_ERROR];
    $process_request_error = $EVAL_ERROR;
  };

  my $params = {
                util    => $util,
                entity  => $entity,
                aspect  => $aspect,
                action  => $action,
                id      => $id,
                headers => $headers,
               };
  #########
  # initial header block
  #
  $headers->header('Content-Type', ClearPress::view->new($params)->content_type || 'text/html'); # don't forget to add charset

  for my $cookie ($decorator->cookie) {
    $self->{headers}->push_header('Set-Cookie', $_);
  }

  if($process_request_error) {
    #########
    # deferred error handling
    #
    return $self->handle_error($process_request_error, $headers);
  }

  $util->username($decorator->username());
  $util->session($self->session($util));

  my $viewobject;
  eval {
    $viewobject = $self->dispatch($params);
    1;
  } or do {
    return $self->handle_error($EVAL_ERROR, $headers);
  };

  my $decor = $viewobject->decor(); # boolean

  #########
  # let the view have the decorator in case it wants to modify headers
  #
  $viewobject->decorator($decorator);

  my $charset      = $viewobject->charset();
  $charset         = ($charset && !exists $ENV{REDIRECT_STATUS}) ? qq[;charset=$charset] : q[];
  my $content_type = sprintf q[%s%s], $viewobject->content_type(), $charset;

  #########
  # update the content-type/charset with whatever the view determined was right for the response
  #
  $headers->header('Content-Type', $content_type);

  if($decor) {
#    if($content_type =~ /text/smx && $charset =~ /utf-?8/smix) {
#      binmode STDOUT, q[:encoding(UTF-8)]; # is this useful? If so, should it be less conditional?
#    }

    #########
    # decorated header
    #
    $viewobject->output_buffer($decorator->header());
  }

  my $errstr;
  eval {
    #########
    # view->render() may be streamed
    #
    if($viewobject->streamed) {
      #########
      # ->render is responsible for all (decorated/undecorated) output
      #
      $viewobject->render();

    } else {
      #########
      # output returned content
      #
      $viewobject->output_buffer($viewobject->render());
    }

    1;
  } or do {
    #########
    # 1. reset pending output_buffer (different view object)
    # 2. set up error response w/headers
    # 3. emit headers
    # 4. hand off to error response handler
    #
    carp qq[controller::handler: view->render failed: $EVAL_ERROR];
    $viewobject->output_reset(); # reset headers on the original view
    $self->errstr($EVAL_ERROR);

    my $code = $headers->header('Status');

    if(!$code || $code == HTTP_OK) {
      $headers->header('Status', HTTP_INTERNAL_SERVER_ERROR);
    }

#    my $content_type = $headers->header('Content-Type');
    $content_type =~ s{;.*$}{}smx;
    $headers->header('Content-Type', $content_type); # ErrorDocuments seem to have a bit of trouble with content-encoding errors so strip the charset

    return $self->handle_error(undef, $headers); # hand off
  };

  #########
  # prepend all response headers (and header block termination)
  #
  $viewobject->output_prepend($headers->as_string, "\n");

  #########
  # re-test decor in case it's changed by render()
  #
  if($viewobject->decor()) {
    $viewobject->output_buffer($decorator->footer());
  }

  #########
  # flush everything left to client socket (via stdout)
  #
  $viewobject->output_end();

  #########
  # save the session after the request has processed
  #
  $decorator->save_session();

  #########
  # clean up any shared state so it's not carried over (e.g. incomplete transactions)
  #
  $util->cleanup();

  return 1;
}

sub handle_error {
  my ($self, $errstr, $headers) = @_;
  my $util      = $self->util;
  my $decorator = $self->decorator();
  my $namespace = $self->namespace();
  my ($action, $entity, $aspect, $id) = $self->process_request($headers);

  # if running in mod_perl, main request serves a bad status header and errordocument is handled by a subrequest
  # if running in CGI, main request serves a bad status header and follows with errordocument content

  #########
  # force reconstruction of CGI object from subrequest QUERY_STRING
  #
  delete $util->{cgi};

  #########
  # but pass-through the errstr
  #
  $util->cgi->param('errstr', CGI::escape($errstr || $self->errstr));

  #########
  # non-mod-perl errordocument handled by application internals
  #
  my $error_ns = sprintf q[%s::view::error], $namespace;
  my $params   = {
                  util      => $util,
                  action    => $action,
                  aspect    => $aspect,
                  headers   => $headers, # same header block as original response? hmm.
                  decorator => $decorator,
                 };

  my $viewobject;
  eval {
    $viewobject = $error_ns->new($params);
    1;
  } or do {
    $viewobject = ClearPress::view::error->new($params);
  };

  my $decor  = $viewobject->decor();
  my $header = q[];
  my $footer = q[];

  $viewobject->output_reset();

  my $body = $viewobject->render;

  if($viewobject->decor) {
    $header = $decorator->header;
    $footer = $decorator->footer;
  }

  my $str = $header . $body . $footer;

  $viewobject->output_prepend($headers->as_string, "\n");
  $viewobject->output_buffer($str);
  $viewobject->output_end();
  $decorator->save_session();
  $util->cleanup();

  return;
}

sub namespace {
  my ($self, $util) = @_;
  my $ns   = q[];

  if((ref $self && !$self->{namespace}) || !ref $self) {
    $util ||= $self->util();
    $ns = $util->config->val('application', 'namespace') ||
          $util->config->val('application', 'name') ||
	  'ClearPress';
    if(ref $self) {
      $self->{namespace} = $ns;
    }
  } else {
    $ns = $self->{namespace};
  }

  return $ns;
}

sub is_valid_view {
  my ($self, $ref, $viewname) = @_;
  my $util     = $ref->{util};
  my @entities = split /[,\s]+/smx, $util->config->val('application','views');

  for my $ent (@entities) {
    if($ent eq $viewname) {
      return 1;
    }
  }

  return;
}

sub errstr {
  my ($self, $str) = @_;

  if($str) {
    $self->{errstr} = $str;
  }

  return $self->{errstr};
}

sub dispatch {
  my ($self, $ref) = @_;
  my $util      = $ref->{util};
  my $entity    = $ref->{entity};
  my $aspect    = $ref->{aspect};
  my $action    = $ref->{action};
  my $id        = $ref->{id};
  my $headers   = $ref->{headers};
  my $viewobject;

  my $state = $self->is_valid_view($ref, $entity);
  if(!$state) {
    $headers->header('Status', HTTP_NOT_FOUND);
    croak qq[No such view ($entity). Is it in your config.ini?];
  }

  my $entity_name = $entity;
  my $viewclass   = $self->packagespace('view',  $entity, $util);

  my $modelobject;
  if($entity ne 'error') {
    my $modelclass = $self->packagespace('model', $entity, $util);
    eval {
      my $modelpk  = $modelclass->primary_key();
      $modelobject = $modelclass->new({
                                       util => $util,
                                       $modelpk?($modelpk => $id):(),
                                      });
      1;
    } or do {
      # bail out

      my $code = $headers->header('Status');

      if(!$code || $code == HTTP_OK) {
        $headers->header('Status', HTTP_INTERNAL_SERVER_ERROR);
        croak qq[Failed to instantiate $entity model: $EVAL_ERROR];
      }

      croak $EVAL_ERROR;
    };
  }

  eval {
    $viewobject = $viewclass->new({
                                   util        => $util,
                                   model       => $modelobject,
                                   action      => $action,
                                   aspect      => $aspect,
                                   entity_name => $entity_name,
                                   decorator   => $self->decorator,
                                   headers     => $headers,
                                  });
    1;
  } or do {
    my $code = $headers->header('Status');

    if(!$code || $code == HTTP_OK) {
      $headers->header('Status', HTTP_INTERNAL_SERVER_ERROR);
      croak qq[Failed to instantiate $entity view: $EVAL_ERROR];
    }

    croak $EVAL_ERROR;
  };

  return $viewobject;
}

1;
__END__

=head1 NAME

ClearPress::controller - Application controller

=head1 VERSION

$Revision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - constructor, usually no specific arguments

 my $oController = application::controller->new();

=head2 init - post-constructor initialisation, called after new()

 $oController->init();

=head2 session

=head2 util

=head2 decorator - get/set accessor for a page decorator implementing the ClearPress::decorator interface

  $oController->decorator($oDecorator);

  my $oDecorator = $oController->decorator();

=head2 accept_extensions - data structure of file-extensions-to-aspect mappings  (e.g. '.xml', '.js') in precedence order

 my $arAcceptedExtensions = $oController->accept_extensions();

 [
  {'.ext' => '_aspect'},
  {'.js'  => '_json'},
 ]

=head2 accept_headers - data structure of accept_header-to-aspect mappings  (e.g. 'text/xml', 'application/javascript') in precedence order

 my $arAcceptedHeaders = $oController->accept_headers();

 [
  {'text/mytype'            => '_aspect'},
  {'application/javascript' => '_json'},
 ]

=head2 process_uri - deprecated. use process_request()

=head2 process_request - extract useful things from %ENV relating to our URI

  my ($sAction, $sEntity, $sAspect, $sId) = $oCtrl->process_request($oHTTPResponseHeaders;

=head2 handler - run the controller

=head2 namespace - top-level package namespace from config.ini

  my $sNS = $oCtrl->namespace();
  my $sNS = app::controller->namespace();

=head2 packagespace - mangled namespace given a package- and entity-type

  my $pNS = $oCtrl->packagespace('model', 'entity_type');
  my $pNS = $oCtrl->packagespace('view',  'entity_type');
  my $pNS = app::controller->packagespace('model', 'entity_type', $oUtil);
  my $pNS = app::controller->packagespace('view',  'entity_type', $oUtil);

=head2 dispatch - view generation

=head2 is_valid_view - view-name validation

#=head2 build_error_object - builds an error view object

=head2 handle_error - main request error response

=head2 errstr - temporary storage for error string to pass through to error handler

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item English

=item Carp

=item ClearPress::decorator

=item ClearPress::view::error

=item CGI

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
