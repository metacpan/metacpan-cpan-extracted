# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
# Created: 2007-03-28
#
package ClearPress::view;
use strict;
use warnings;
use base qw(Class::Accessor);
use Template;
use Template::Filters;
use ClearPress::util;
use Carp;
use English qw(-no_match_vars);
use POSIX qw(strftime);
use HTML::Entities qw(encode_entities_numeric);
use HTTP::Headers;
use HTTP::Status qw(:constants);
use XML::Simple qw(XMLin);
use utf8;
use ClearPress::Localize;
use MIME::Base64 qw(encode_base64);
use JSON;
use Readonly;

our $VERSION = q[476.4.2];

our $DEBUG_OUTPUT        = 0;
our $DEBUG_L10N          = 0;
our $TEMPLATE_CACHE      = {};
our $LEXICON_CACHE       = {};
our $TRAP_REDIR_OVERFLOW = 0;

__PACKAGE__->mk_accessors(qw(util model action aspect content_type entity_name autoescape charset decorator headers));

sub new { ## no critic (Complexity)
  my ($class, $self)    = @_;
  $self               ||= {};
  bless $self, $class;

  my $util                    = $self->util;
  my $username                = $util ? $util->username : q[];
  $self->{requestor_username} = $username;
  $self->{logged_in}          = $username?1:0;
  $self->{warnings}           = [];
  $self->{output_buffer}      = [];
  $self->{output_finished}    = 0;
  $self->{autoescape}         = 1;

  my $aspect = $self->aspect || q[];

  $self->{content_type} ||= ($aspect =~ /(?:rss|atom|ajax|xml)$/smx)?'text/xml':q[];
  $self->{content_type} ||= ($aspect =~ /(?:js|json)$/smx)?'application/json':q[];
  $self->{content_type} ||= ($aspect =~ /_svg$/smx)?'image/svg+xml':q[];
  $self->{content_type} ||= ($aspect =~ /_svgz$/smx)?'image/svg+xml':q[];
  $self->{content_type} ||= ($aspect =~ /_png$/smx)?'image/png':q[];
  $self->{content_type} ||= ($aspect =~ /_jpg$/smx)?'image/jpeg':q[];
  $self->{content_type} ||= ($aspect =~ /_txt$/smx)?'text/plain':q[];
  $self->{content_type} ||= ($aspect =~ /_csv$/smx)?'text/csv':q[];
  $self->{content_type} ||= ($aspect =~ /_xls$/smx)?'application/vnd.ms-excel':q[];

  $self->setup_filters;

  $self->init;

  ClearPress::Localize->init($self->locales);

  $self->{content_type} ||= 'text/html';

  $self->{charset}      ||= 'UTF-8';
  $self->{headers}      ||= HTTP::Headers->new;

  return $self;
}

sub setup_filters {
  my $self = shift;
  $self->add_tt_filter('js_string', sub {
                         my $string = shift;
                         if(!defined $string) {
                           $string = q[];
                         }
                         $string    =~ s/\r/\\r/smxg;
                         $string    =~ s/\n/\\n/smxg;
                         $string    =~ s/"/\\"/smxg;
#                         $string    =~ s/'/\\'/smxg;
                         return $string;
                       });

  $self->add_tt_filter('xml_entity', sub {
                         my $string = shift;
                         if(!defined $string) {
                           $string = q[];
                         }
                         return encode_entities_numeric($string),
                       });

  $self->add_tt_filter('base64', sub {
                         my $string = shift;
                         if(!defined $string) {
                           $string = q[];
                         }
                         return encode_base64($string),
                       });

  my $util = $self->util;

  $self->add_tt_filter('loc', [sub {

                                 return sub {
                                   my ($string) = shift;

                                   #########
                                   # Cache lexicons for
                                   # speed. However, loading on-demand
                                   # won't generally use shared memory
                                   #
                                   my $lang = ClearPress::Localize->lang;
                                   if($lang && !$LEXICON_CACHE->{$lang}) {
                                     $LEXICON_CACHE->{$lang} = ClearPress::Localize->localizer;
                                   }

                                   my $loc = $string;
                                   eval {
                                     $loc = $util->{localizers}->{$lang}->maketext($string);
                                     1;
                                   } or do {
                                     $DEBUG_L10N && carp qq[Could not localize $string to $lang];
                                     1;
                                   };

                                   return $loc || $string;
                                 };
                               }, 1]);

  return 1;
}

sub init {
  return 1;
}

sub locales {
  my $self = shift;
  my $util = $self->util;
  return {
          $util ? (q[*]  => [Gettext => sprintf q[%s/po/*.po], $util->data_path] ) : (),
          q[en] => ['Auto'],
         };
}

sub add_warning {
  my ($self, $warning) = @_;
  push @{$self->{warnings}}, $warning;
  return 1;
}

sub warnings {
  my $self = shift;
  return $self->{warnings};
}

sub _accessor { ## no critic (ProhibitUnusedPrivateSubroutines)
  my ($self, $field, $val) = @_;
  carp q[_accessor is deprecated. Use __PACKAGE__->mk_accessors(...) instead];
  if(defined $val) {
    $self->{$field} = $val;
  }
  return $self->{$field};
}

sub authorised {
  my $self      = shift;
  my $action    = $self->action || q[];
  my $aspect    = $self->aspect || q[];
  my $util      = $self->util;
  my $requestor = $util->requestor;

  if(!$requestor) {
    #########
    # If there's no requestor user object then authorisation isn't supported
    #
    return 1;
  }

  if($action =~ /^list/smx ||
     ($action eq 'read' &&
      $aspect !~ /^(?:add|edit|delete|update|create)/smx)) {
    #########
    # by default assume public read access for 'read' actions
    #
    return 1;

  } else {
    #########
    # by default allow only 'admin' group for non-read aspects (add, edit, create, update, delete)
    #
    if($requestor->can('is_member_of') &&
       $requestor->is_member_of('admin')) {
      return 1;
    }
  }

  return;
}

sub template_name {
  my ($self, @args) = @_;

  if(scalar @args) {
    $self->{template_override} = $args[0];
  }

  if(exists $self->{template_override}) {
    return $self->{template_override};
  }

  my $name = $self->entity_name;
  if(!$name) {
    ($name) = (ref $self) =~ /view::(.*)$/smx;
  }
  $name    ||= 'view';
  my $method = $self->method_name;

  $name =~ s/:+/_/smxg;
  if(!$method) {
    return $name;
  }

  my $util = $self->util;
  my $tmp  = "${name}/$method";
  my $path = sprintf q[%s/templates], $util->data_path;

  #########
  # I do not like this stat. I'd prefer a global mode switch in config.
  #
  if(-e "$path/$tmp.tt2") {
    return $tmp;
  }

  return "${name}_$method";
}

sub method_name {
  my $self   = shift;
  my $aspect = $self->aspect;
  my $action = $self->action;
  my $method = $aspect || $action;
  my $model  = $self->model;
  my $pk     = $model->primary_key;

  if(!$method) {
    return q[];
  }

  if($pk               &&
     $method eq 'read' &&
     !$model->$pk()) {
    $method = 'list';
  }

  $method =~ s/__/_/smxg;

  return $method;
}

sub streamed_aspects {
  return [qw(options)];
}

sub streamed {
  my $self = shift;
  my $aspect = $self->aspect;

  for my $str_aspect (@{$self->streamed_aspects}) {
    if($aspect eq $str_aspect) {
      return 1;
    }
  }
  return;
}

sub render {
  my $self   = shift;
  my $util   = $self->util;
  my $aspect = $self->aspect || q[];
  my $action = $self->action;

  if(!$util) {
    croak q[No util object available];
  }

  my $requestor = $util->requestor;

  if(!$self->authorised) {
    #########
    # set http forbidden response code
    #
    $self->headers->header('Status', HTTP_FORBIDDEN);

    if(!$requestor) {
      croak q[Authorisation unavailable for this view.];
    }

    my $username = $requestor->username;
    if(!$username) {
      croak q[You are not authorised for this view. You need to log in.];
    }
    croak qq[You ($username) are not authorised for this view];
  }

  #########
  # Figure out and call the appropriate action if available
  #
  my $method = $self->method_name;
  if($method !~ /^(?:add|edit|create|read|update|delete|list|options)/smx) {
    croak qq[Illegal method: $method];
  }

  if($self->can($method)) {
    if($aspect eq 'options' ||
       $aspect =~ /_(?:jpg|png|gif|svg|svgz)/smx) {
      return $self->$method();
    }

    #########
    # handle streamed methods
    #
    my $streamed = $self->streamed;

    if($streamed) {
      $self->output_flush;
    }

    $self->$method();

    if($streamed) {
      $self->output_end;
      return q[];
    }

  } else {
    croak qq[Unsupported method: $method];
  }

  my $model   = $self->model;
  my $actions = my $warnings = q[];

  if($self->decor) {
    $actions  = $self->actions;
    eval {
      $self->process_template('warnings.tt2', {
					       warnings => $self->warnings,
					      }, \$warnings);

    } or do {
      #########
      # non-fatal warning - usually warnings.tt2 missing
      #
      carp "Warning: $EVAL_ERROR";
    };
  }

  #########
  # handle block (non-streamed) methods
  #
  my $tmpl    = $self->template_name;
  my $cfg     = $util->config;
  my $content = q[];

  $self->process_template("$tmpl.tt2", {}, \$content);

  return $warnings . $actions . $content || q[No data];
}

sub process_template { ## no critic (Complexity)
  my ($self, $template, $extra_params, $where_to_ref) = @_;
  my $util        = $self->util;
  my $cfg         = $util->config;
  my ($entity)    = (ref $self) =~ /([^:]+)$/smx;
  $entity       ||= q[];
  my $script_name = $ENV{SCRIPT_NAME} || q[];
  my ($xfh, $xfp) = ($ENV{HTTP_X_FORWARDED_HOST}, $ENV{HTTP_X_FORWARDED_PORT});
  my $http_host   = ($xfh ? $xfh : $ENV{HTTP_HOST}) || q[localhost];
  my $http_port   = ($xfh ? $xfp : $ENV{HTTP_PORT}) || q[];
  my $http_proto  = $ENV{HTTP_X_FORWARDED_PROTO}    || $ENV{HTTPS}?q[https]:q[http];
  my $href        = sprintf q[%s://%s%s%s%s],
			    $http_proto,
			    $http_host,
			    $http_port?":$http_port":q[],
			    $script_name,
			    ($script_name eq q[/])?q[]:q[/];

  my $cfg_globals = {
		     (map {
		       $_ => $cfg->val('globals',$_)
		     } $cfg->Parameters('globals'))
		    };

  my $params   = {
		  requestor   => $util->requestor,
		  model       => $self->model,
		  view        => $self,
		  entity      => $entity,
		  SCRIPT_NAME => $script_name,
		  HTTP_HOST   => $http_host,
		  HTTP_PORT   => $http_port,
		  HTTPS       => $http_proto,
		  SCRIPT_HREF => $href,
		  ENTITY_HREF => "$href$entity",
		  now         => (strftime '%Y-%m-%dT%H:%M:%S', localtime),
		  %{$cfg_globals},
		  %{$extra_params||{}},
		 };


  my $appname = $util->config->val('application', 'name') ||
                $util->config->val('application', 'namespace') ||
                $ENV{SCRIPT_NAME};

  $TEMPLATE_CACHE->{$appname} ||= {};
  my $template_cache = $TEMPLATE_CACHE->{$appname};

  if(!$template_cache->{$template}) {
    my $path = sprintf q[%s/templates], $util->data_path;
    open my $fh, q[<], "$path/$template" or croak qq[Error opening $template];
    local $RS = undef;
    $template_cache->{$template} = <$fh>;
    close $fh or croak qq[Error closing $template];
  }

  $template = \$template_cache->{$template};

  if($where_to_ref) {
    $self->tt->process($template, $params, $where_to_ref) or croak $self->tt->error;

  } else {
    $self->tt->process($template, $params, $where_to_ref) or croak $self->tt->error;
  }

  return 1;
}

sub _populate_from_cgi {
  my $self  = shift;
  my $util  = $self->util;
  my $model = $self->model;
  my $cgi   = $util->cgi;

  #########
  # Populate model object with parameters posted into CGI
  # by default (in controller.pm) model will only have util & its primary_key.
  #
  $model->read;

  my $pk = $model->primary_key;

  my @fields = $model->fields;
  if($pk) {
    #########
    # don't leave primary key in field list
    #
    @fields = grep { $_ ne $pk } @fields;
  }

  my $params = {
		map { ## no critic (ProhibitComplexMappings)
		      my $p = $cgi->param($_);
		      utf8::decode($p);
		      $_ => $p;
		    } $cgi->param
	       };

  #########
  # parse new-style POST payload
  # todo: look at PUTDATA as well
  #
  my $postdata = $cgi->param('POSTDATA');
  if($postdata) {
    utf8::decode($postdata);
    eval {
      my $json = JSON->new->utf8;
      eval {
        $params = $json->decode($postdata);
        1;

      } or do {
        $params = XMLin($postdata);
      };

      for my $k (%{$params}) {
        if(ref $params->{$k} &&
           ref $params->{$k} eq 'HASH' &&
           !scalar keys %{$params->{$k}}) {
          delete $params->{$k};
        }
      }
      1;

    } or do {
      #########
      # Not an XML-formatted POST body. Ignore for now.
      #
      carp q[Got error while parsing POSTDATA: ].$EVAL_ERROR;
    };
  }

  #########
  # parse old-style XML POST payload
  #
  my $xml = $cgi->param('XForms:Model');
  if($xml) {
    utf8::decode($xml);
    $params = XMLin($xml);
    for my $k (%{$params}) {
      if(ref $params->{$k} &&
	 ref $params->{$k} eq 'HASH' &&
	 !scalar keys %{$params->{$k}}) {
	delete $params->{$k};
      }
    }
  }

  for my $field (@fields) {
    if(!exists $params->{$field}) {
      next;
    }
    my $v = $params->{$field};

    #########
    # $v here will always be defined
    # but may be false, e.g. $v=q[] or $v=q[0]
    #
    if($self->autoescape) {
      $v = $cgi->escapeHTML($v);
    }

    $model->$field($v);
  }

  return 1;
}

sub add {
  my $self = shift;
  return $self->_populate_from_cgi;
}

sub edit {
  my $self = shift;
  return $self->_populate_from_cgi;
}

sub options {
  return 1;
}

sub list {
  return 1;
}

sub read { ## no critic (homonym)
  return 1;
}

sub delete { ## no critic (homonym)
  my $self  = shift;
  my $model = $self->model;

  $model->delete or croak qq[Failed to delete entity: $EVAL_ERROR];

  return 1;
}

sub update {
  my $self  = shift;
  my $model = $self->model;

  #########
  # Populate model object with parameters posted into CGI
  # by default (in controller.pm) model will only have util & its primary_key.
  #
  $self->_populate_from_cgi;

  $model->update or croak qq[Failed to update entity: $EVAL_ERROR];
  return 1;
}

sub create {
  my $self  = shift;
  my $model = $self->model;

  #########
  # Populate model object with parameters posted into CGI
  # by default (in controller.pm) model will only have util & its primary_key.
  #
  $self->_populate_from_cgi;

  $model->create or croak qq[Failed to create entity: $EVAL_ERROR];

  return 1;
}

sub add_tt_filter {
  my ($self, $name, $code) = @_;

  if(!$name || !$code) {
    return;
  }

  $self->tt_filters->{$name} = $code;

  return 1;
}

sub tt_filters {
  my $self = shift;

  if(!$self->{tt_filters}) {
    $self->{tt_filters} = {};
  }

  return $self->{tt_filters};
}

sub tt_opts {
  return {};
}

sub tt {
  my ($self, $tt) = @_;
  my $util = $self->util;

  if($tt) {
    $util->{tt} = $tt;
  }

  if(!$util->{tt}) {
    my $filters = Template::Filters->new({
					  FILTERS => $self->tt_filters,
					 });
    my $opts        = $self->tt_opts;
    my $ns          = $util->config->val('application', 'namespace') ||
                        $util->config->val('application', 'name');
    my $plugin_base = $ns ? q[ClearPress::Template::Plugin] : sprintf q[%s::plugin], $ns;
    my $defaults    = {
                       PLUGIN_BASE  => $plugin_base,
                       RECURSION    => 1,
                       INCLUDE_PATH => (sprintf q[%s/templates], $util->data_path),
                       EVAL_PERL    => 1,
                       ENCODING     => 'utf8',
                       LOAD_FILTERS => [ $filters ],
                      };

    while (my ($k, $v) = each %{$defaults}) {
      if(!exists $opts->{$k}) {
        $opts->{$k} = $v;
      }
    }

    $util->{tt} = Template->new($opts) or croak $Template::ERROR;
  }
  return $util->{tt};
}

sub decor {
  my $self = shift;
  my $aspect = $self->aspect || q[];

  for my $ending (qw(rss atom ajax xml
                     json js _png _jpg _svg _svgz
                     _txt _csv _xls)) {
    if((substr $aspect, -length $ending, length $ending) eq $ending) {
      return 0;
    }
  }
  return 1;
}

sub output_flush {
  my ($self) = @_;
  $DEBUG_OUTPUT and carp "output_flush: @{[scalar @{$self->{output_buffer}}]} blobs in queue";

  eval {
    print grep { $_ } @{$self->{output_buffer}} or croak $ERRNO;
    1;

  } or do {
    #########
    # client stopped receiving (e.g. disconnect from lengthy streamed response)
    #
    carp qq[Error flushing output_buffer: $EVAL_ERROR];
  };

  $self->output_reset;
  return 1;
}

sub output_prepend {
  my ($self, @args) = @_;
  if(!$self->output_finished) {
    if(scalar @args == 2 && $args[1] eq "\n" && !$args[0]) {
      return;
    }
    unshift @{$self->{output_buffer}}, grep { $_ } @args; # don't push undef or ""
    $DEBUG_OUTPUT and carp "output_prepend prepended (@{[scalar @args]} blobs)";
  }
  return 1;
}

sub output_buffer {
  my ($self, @args) = @_;
  if(!$self->output_finished) {
    if(scalar @args == 2 && $args[1] eq "\n" && !$args[0]) {
      return;
    }

    push @{$self->{output_buffer}}, grep { $_ } @args; # don't push undef or ""
    $DEBUG_OUTPUT and carp "output_buffer added (@{[scalar @args]} blobs)";
  }
  return 1;
}

sub output_finished {
  my ($self, $val) = @_;
  if(defined $val) {
    $self->{output_finished} = $val;
    $DEBUG_OUTPUT and carp "output_finished = $val";
  }
  return $self->{output_finished};
}

sub output_end {
  my $self = shift;
  $DEBUG_OUTPUT and carp "output_end: $self";
  $self->output_finished(1);
  return $self->output_flush;
}

sub output_reset {
  my $self = shift;
  $self->{output_buffer} = [];
  $DEBUG_OUTPUT and carp 'output_reset';
  return;
}

sub actions {
  my $self    = shift;
  my $content = q[];

  $self->process_template('actions.tt2', {}, \$content);
  return $content;
}

sub redirect {
  my ($self, $url, $status) = @_;

  $self->headers->header('Status', HTTP_FOUND);
  $self->headers->header('Location', $url);

  #########
  # - reset all previously output but unflushed content
  # - push headers down the pipe, and html redirects
  # - finish up
  #
  $self->output_reset();

  if($TRAP_REDIR_OVERFLOW) {
    Readonly::Scalar my $OVERFLOW => 1024;
    if(length $self->headers->as_string > $OVERFLOW) { # fudge for apparent buffer overflow with apache+mod_perl (ParseHeaders related?)
      carp q[warning: header block looks long];
      $self->headers->remove_header('Location');
      $self->headers->header('Status', HTTP_OK);
    }
  }

  $self->output_buffer($self->headers->as_string, "\n");
  $self->decorator->meta_refresh(qq[0;URL='$url']);

  #########
  # clean everything up and terminate
  #
  $self->output_flush();
  $self->headers->clear();

  ########
  # Note: This ought to correspond to content-type, but doesn't!
  #
  return <<"EOT"
   <p>This document has moved <a href="$url">here</a>.</p>
   <script>document.location.href="$url";</script>
EOT
}

#########
# automated method generation for core CRUD+ view methods
#
BEGIN {
  no strict 'refs'; ## no critic (ProhibitNoStrict)
  for my $ext (qw(xml ajax json csv)) {
    for my $method (qw(create list read update delete)) {
      my $ns = sprintf q[%s_%s], $method, $ext;
      *{$ns} = sub { my $self = shift; return $self->$method; };
    }
  }
}

1;
__END__

=head1 NAME

ClearPress::view - MVC view superclass

=head1 VERSION

$Revision: 470 $

=head1 SYNOPSIS

  my $oView = ClearPress::view::<subclass>->new({util => $oUtil});
  $oView->model($oModel);

  print $oView->decor?
    $oDecorator->header
    :
    q[Content-type: ].$oView->content_type."\n\n";

  print $oView->render;

  print $oView->decor?$oDecorator->footer:q[];

=head1 DESCRIPTION

View superclass for the ClearPress framework

=head1 SUBROUTINES/METHODS

=head2 new - constructor

  my $oView = ClearPress::view::<subclass>->new({util => $oUtil, ...});

=head2 init - additional post-constructor hook

=head2 setup_filters - adds default tt_filters, called by ->new()

=head2 locales - hashref of locale lexicons to feed Locale::Maketext::Lexicon

 Defaults are:

 {
   '*' => [Gettext => sprintf q[%s/po/*.po], $util->data_path],
   'en' => ['Auto'],
 }

=head2 determine_aspect - URI processing

 sets the aspect based on the HTTP Accept: header

 - useful for API access setting Accept: text/xml

=head2 template_name - the name of the template to load, based on view class and method_name. Can be overridden

  my $sTemplateName = $oView->template_name;

  $oView->template_name($sOverriddenName);

=head2 method_name - the name of the method to invoke on the model, based on action and aspect

  my $sMethodName = $oView->method_name;

=head2 add_warning

  $oView->add_warning($sWarningMessage);

=head2 warnings - an arrayref of warning strings set for this view

  my $arWarningStrings = $oView->warnings;

=head2 authorised - Verify authorisation for this view

  This should usually take into account $self->action which suggests
  read or write access.

  my $bIsAuthorised = $oView->authorised;

=head2 render - generates and returns content for this view

  my $sViewOutput = $oView->render;

=head2 streamed_aspects - an arrayref of aspects which perform streamed output.

  Implemented in subclass:

  sub streamed_aspects {
    return [qw(list list_xml list_json)];
  }

  sub list { ... }
  sub list_xml { ... }
  sub list_json { ... }

=head2 list - stub for entity list actions

=head2 create - A default model creation/save method

  $oView->create;

  Populates $oSelf->model with its expected parameters from the CGI
  block, then calls $oModel->create;

=head2 add - stub for single-entity-creation actions

=head2 edit - stub for single-entity editing

=head2 read - stub for single-entity-view actions

=head2 update - stub for entity update actions

=head2 delete - stub for entity delete actions

=head2 tt - a configured Template (TT2) object

  my $tt = $oView->tt;

=head2 tt_opts - a hashref of options for Template::Toolkit construction

e.g.

 sub tt_opts {
   return {
           COMPILE_EXT => '.ttc',
           COMPILE_DIR => '/ramdisk',
          };
 }

=head2 add_tt_filter - add a named template toolkit content filter, usually performed in init

  sub init {
    my $self = shift;
    $self->add_tt_filter('foo_filter',
                         sub {
                              my $string = shift;
                              $string =~ s/foo/bar/smxg;
                              return $string;
                             });
    return;
  }

=head2 tt_filters - hashref of configured template toolkit filters

  my $hrFilters = $oView->tt_filters;

=head2 util - get/set accessor for utility object

  $oView->util($oUtil);
  my $oUtil = $oView->util;

=head2 model - get/set accessor for data model object

  $oView->model($oModel);
  my $oModel = $oView->model;

=head2 action - get/set accessor for the action being performed on this view

  $oView->action($sAction);
  my $sAction = $oView->action;

=head2 aspect - get/set accessor for the aspect being performed on this view

  $oView->aspect($sAction);
  my $sAction = $oView->aspect;

=head2 content_type - get/set accessor for content mime-type (Content-Type HTTP header)

  $oView->content_type($sContentType);
  my $sContentType = $oView->content_type;

=head2 charset - get/set accessor for content charset (Content-Type header charset) - default UTF-8

  $oView->charset($sCharSet);
  my $sCharSet = $oView->charset;

=head2 decor - get/set accessor for page decoration toggle

  $oView->decor($bDecorToggle);
  my $bDecorToggle = $oView->decor;

=head2 streamed - current aspect is streamed, based on @{streamed_aspects}

  my $bStreamedResponse = $oView->streamed;

=head2 entity_name - get/set accessor for the entity_name

 Usually set by the controller, after processing the request. Used for
 remapping requests to classes (specifically things of the form
 application::(model|view)::something::somethingelse .

  $oView->entity_name($sEntityName);
  my $sEntityName = $oView->entity_name;

=head2 actions - templated output for available actions

  my $sActionOutput = $oView->actions;

=head2 redirect - Apache internal redirect via mod-perl subrequest

  $oView->redirect($sURL);

  $oView->redirect($sURL, $sStatus); # optional status

=head2 list_xml - default passthrough to list for xml service

=head2 read_xml - default passthrough to read for xml service

=head2 create_xml - default passthrough to create for xml service

=head2 update_xml - default passthrough to update for xml service

=head2 delete_xml - default passthrough to delete for xml service

=head2 list_ajax - default passthrough to list for ajax service

=head2 read_ajax - default passthrough to read for ajax service

=head2 create_ajax - default passthrough to create for ajax service

=head2 update_ajax - default passthrough to update for ajax service

=head2 delete_ajax - default passthrough to delete for ajax service

=head2 list_json - default passthrough to list for json service

=head2 read_json - default passthrough to read for json service

=head2 create_json - default passthrough to create for json service

=head2 update_json - default passthrough to update for json service

=head2 delete_json - default passthrough to delete for json service

=head2 list_csv - default passthrough to list for csv service

=head2 read_csv - default passthrough to read for csv service

=head2 create_csv - default passthrough to create for csv service

=head2 update_csv - default passthrough to update for csv service

=head2 delete_csv - default passthrough to delete for csv service

=head2 init - post-constructor initialisation hook for subclasses

=head2 headers - an HTTP::Headers object for responses

  my $oHeaders = $oView->headers;

  $oView->headers->header('Status', 500); # usually symbolic named values from HTTP::Status

=head2 process_template - process a template with standard parameters

  Process template.tt2 with standard parameters, output to stdout.

  $oView->process_template('template.tt2');


  Process template.tt2 with standard parameters plus extras, output to
  stdout.

  $oView->process_template('template.tt2', {extra=>'params'});


  Process template.tt2 with standard plus extra parameters and output
  into $to_scalar.

  $oView->process_template('template.tt2', {extra=>'params'}, $to_scalar);

=head2 output_buffer - For streamed output: queue a string for output

  $oView->output_buffer(q[my string]);
  $oView->output_buffer(@aStrings);

=head2 output_prepend - prepend something for output - usually headers

  $oView->output_prepend(q[my string]);
  $oView->output_prepend(@aStrings);

=head2 output_end - For streamed output: flag no more output and flush buffer

  $oView->output_end;

=head2 output_finished - For streamed output: flag there's no more output

  $oView->output_finished(1);
  $oViwe->output_finished(0);

=head2 output_flush - For streamed output: flush output buffer to STDOUT

  $oView->output_flush;

=head2 output_reset - clear data pending output

  $oView->output_reset;

=head2 autoescape - turn auto-escaping of input on/off, usually in a subclass

 If you're producing applications of moderate complexity, you almost
 certainly want to disable autoescaping and handle it more cleverly
 yourself. Subclass ClearPress::view and set self->autoescape to zero
 or override the subroutine:

 sub autoescape { return 0; }

=head2 decorator - get/set accessor for decorator object for cases where a view needs to reset & resend the decorated header. Set by the controller during $view->render()

 $oView->decorator($oDecorator);
 my $oDecorator = $oView->decorator();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

 Set $ClearPress::view::DEBUG_L10N = 1 to report missing locali[zs]ation strings.

 Set $ClearPress::view::DEBUG_OUTPUT = 1 to report output buffer operations.

 Set $ClearPress::view::TRAP_REDIR_OVERFLOW = 1 to enable experimental redirect header overflow handling

=head1 DEPENDENCIES

=over

=item base

=item strict

=item warnings

=item Class::Accessor

=item Template

=item Template::Filters

=item HTML::Entities

=item XML::Simple

=item ClearPress::util

=item Carp

=item English

=item POSIX

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
