package Apache2::PageKit::Model;

# $Id: Model.pm,v 1.91 2004/01/06 16:31:47 borisz Exp $

use integer;
use strict;
use Data::FormValidator;

use Apache2::Const qw(REDIRECT OK DONE DECLINED NOT_FOUND);
use APR::Const    -compile => 'SUCCESS';
use Apache2::PageKit::Param;

sub new {
  my $class = shift;
  my $self = { @_ };
  bless $self, $class;
  unless (exists $self->{pkit_pk} && exists $self->{pkit_pk}->{apr}){
    # if running outside of mod_perl
    $self->{pkit_pk}->{apr} ||= Apache2::PageKit::Param->new();
    $self->{pkit_pk}->{pnotes_param_object} ||= Apache2::PageKit::Param->new();
  }
  $self->{pkit_pk}->{output_param_object} ||= Apache2::PageKit::Param->new();
  $self->{pkit_pk}->{fillinform_object} ||= Apache2::PageKit::Param->new();
  $self->{pkit_pk}->{ignore_fillinform_fields} ||= [];

  return $self;
}

sub pkit_get_config_attr {
  my ( $model, $section, $page_or_view_id, $key ) = @_;
  return unless $section;

  my $config     = $model->{pkit_pk}->{config};
  my $config_dir = $config->{config_dir};

  my $href =
    ( $section eq 'USER' )       ? $Apache2::PageKit::Config::user_attr->{$config_dir}
    : ( $section eq 'GLOBAL' )   ? $Apache2::PageKit::Config::global_attr->{$config_dir}
    : ( $section eq 'SERVER' )   ? $Apache2::PageKit::Config::server_attr->{$config_dir}->{$config->{server}}
    : ( $section =~ /^PAGES?$/ ) ? $Apache2::PageKit::Config::page_attr->{$config_dir}
    : ( $section =~ /^SECTIONS?$/ ) ? $Apache2::PageKit::Config::section_attr->{$config_dir}
    : ( $section =~ /^VIEWS?$/ ) ? $Apache2::PageKit::Config::view_attr->{$config_dir}
    : undef;

  return $href if ( $section =~ /^(?:PAGE|VIEW|SECTION)S$/ );
  
  if ( $section =~ /^(?:PAGE|VIEW|SECTION)$/ ) {
    return undef unless $page_or_view_id;
    unless ( exists $href->{$page_or_view_id} ) {
      $href->{$page_or_view_id} = {};
    }
    $href = $href->{$page_or_view_id};
  } else {
    $key = $page_or_view_id;
  }
  return ( $key and $href ) ? $href->{$key} : $href;
}

sub pkit_get_session_id {
  my $model = shift;
  my $obj = tied(%{$model->{pkit_pk}->{session}});
  return $obj ? $obj->getid : undef;
}

sub pkit_get_page_session_id {
  my $model = shift;
  my $page_session = $model->{pkit_pk}->{page_session};
  return tied(%$page_session)->getid if $page_session;
}

# returns value of PerlSetVar PKIT_SERVER from httpd.conf
sub pkit_get_server_id {
  my $model = shift;
  my $apr = $model->{pkit_pk}->{apr};
  return $apr->dir_config('PKIT_SERVER') if $apr;
}

sub pkit_root {
  my $model = shift;
  my $apr = $model->{pkit_pk}->{apr};
  return $apr->dir_config('PKIT_ROOT') if $apr;
}

sub pkit_get_orig_uri {
  my $model = shift;
  return $model->{pkit_pk}->{apr}->notes->get('orig_uri');
}

sub pkit_get_page_id {
  my $model = shift;
  return $model->{pkit_pk}->{page_id};
}

sub pkit_lang {
  my $model = shift;
  return $model->{pkit_pk}->{lang};
}

sub pkit_user {
  my $model = shift;
  return $model->{pkit_pk}->{apr}->user;
}

sub pkit_set_errorfont {
  my ( $model, $field, $color_str) = @_;
  $color_str ||= $model->pkit_get_config_attr( GLOBAL => 'default_errorstr' ) || "#ff0000";
  my $begin_name = "PKIT_ERRORSPAN_BEGIN_$field";
  my $begin_value = $model->pkit_get_config_attr( GLOBAL => 'errorspan_begin_tag' ) || qq{<font color="$color_str">};
  $begin_value =~ s/<(!--)?\s*PKIT_ERRORSTR\s*(?(1)--)>/$color_str/gi;
  my $end_name = "PKIT_ERRORSPAN_END_$field";
  my $end_value = $model->pkit_get_config_attr( GLOBAL => 'errorspan_end_tag' ) || q{</font>};
  
  $model->output($begin_name => $begin_value);
  $model->output($end_name => $end_value);
}

# for now both are the same this may change.
# but only pkit_set_errorspan should change.
*pkit_set_errorspan = \&pkit_set_errorfont;

sub pkit_validate_input {
  my ($model, $input_profile) = @_;

  my $messages = delete $input_profile->{messages};

  my $validator = Data::FormValidator->new({default => $input_profile});

  # put the data from input into a %fdat hash so Data::FormValidator can read it
  my $input_hashref = $model->pkit_input_hashref;

  # put derived Model object in pkit_model
  # so form validation can access $dbh, etc
  # this is used, for example, to see if a login already exists
  $input_hashref->{'pkit_model'} = $model;

  my ($valids, $missings, $invalids, $unknowns) = $validator->validate($input_hashref, 'default');
  
  # put our messages back into the hash...  
  $input_profile->{messages} = $messages if defined $messages;

  # used to change apply changes from filter to apr
  while (my ($key, $value) = each %$valids){
    # if multiple request param, don't set, since formvalidator doesn't deal
    # with them yet
    $model->input($key,$value) unless ref($input_hashref->{$key}) eq 'ARRAY';
  }

  # used to change undef values to "", in case db field is defined as NOT NULL
  for my $field (keys %$input_hashref){
    $valids->{$field} ||= "";
  }

  for my $field (@$missings, @$invalids){
    $model->pkit_set_errorspan($field);
  }
  if(@$invalids || @$missings){
    if(@$invalids){
      foreach my $field (@$invalids){
	next unless exists $messages->{$field};
	my $value = $input_hashref->{$field};
	# gets error message for that field which was filled in incorrectly
	my $msg = $messages->{$field};

        $msg = $model->pkit_gettext($msg);

	# substitutes the value the user entered in the error message
	$msg =~ s/\%\%VALUE\%\%/$value/g;
	$model->pkit_message($msg, is_error => 1);
      }
      $model->pkit_gettext_message('Please try again.', is_error => 1);
    } else {
      # no invalid data, just missing fields
      $model->pkit_gettext_message(qq{You did not fill out all the required fields. Please fill the <font color="<PKIT_ERRORSTR>">red</font> fields.});
    }
    return;
  }
  if ($valids){
    return 1;
  }
}

sub pkit_component_params_hashref {
  return $_[0]->{pkit_pk}->{component_params_hashref};
}

sub pkit_input_hashref {
  my $model = shift;
  return $model->{pkit_input_hashref} if
    exists $model->{pkit_input_hashref};
  my $input_hashref = {};
  for my $key ($model->input){
    # we expect param to return an array if there are multiple values
    my @v = $model->input($key);
    $input_hashref->{$key} = scalar(@v)>1 ? \@v : $v[0];
  }
  $model->{pkit_input_hashref} = $input_hashref;
}

sub pkit_message {
  my $model = shift;
  my $message = shift;

  my $options = {@_};

  # translate from default_input_charset to default_output_charset if needed
  my $view = $model->{pkit_pk}->{view};
  my $input_charset = $view->{default_input_charset};
  $message = Encode::decode($input_charset, $message );
  
  my $default_error_str = $model->pkit_get_config_attr( GLOBAL => 'default_errorstr' ) || "#ff0000";
  $message  =~ s/<(!--)?\s*PKIT_ERRORSTR\s*(?(1)--)>/$default_error_str/gi;

  my $array_ref = $model->output('pkit_messages') || [];
  push @$array_ref, {pkit_message  => $message,
		    pkit_is_error  => $options->{'is_error'}};

  $model->output('pkit_messages',$array_ref);
}

sub pkit_internal_redirect {
  my ($model, $page_id) = @_;

  for ( $page_id ) {
    s!^\w+://+[^/]+!!; # strip proto and host
    s!\?.*$!!;         # strip parameters
    s!^/+!!;           # and leading /'s
  }

  unless ( $page_id =~ m:^\.?\./: ) {
    $model->{pkit_pk}->{page_id} = $page_id;
    return;
  }

  # relative url
  my @old    = split /\/+/, $model->{pkit_pk}->{page_id};
  my @new    = split /\/+/, $page_id;
  pop @old;
  foreach (@new) {
    if ( $_ eq '..' ) { pop @old }
    elsif ( $_ ne '.' ) { push @old, $_ }
  }
  $model->{pkit_pk}->{page_id} = join '/', @old;
}

sub pkit_internal_execute_redirect {
  my ($model, $page_id) = @_;

  my $pk = $model->{pkit_pk};
  my $old_page_id = $pk->{page_id};
  $model->pkit_internal_redirect($page_id);

  if  ( $old_page_id ne $pk->{page_id} ) {

    if ( $pk->{page_session} ) {
      # save session
      delete $pk->{page_session};
    }

    # load the page session if needed
    $pk->load_page_session;
  }
  $pk->page_code;
}

# currently input_param is just a wrapper around $apr
sub input {
  my $model = shift;
  
  if ( @_ > 1 && exists $model->{pkit_input_hashref} ) {
    # insert something, we must update the hashref
    my %params = @_;
    while ( my ( $key, $value ) = each %params ) {
      $model->{pkit_input_hashref}->{$key} = $value;
    }
  }

  if(wantarray){
    # deal with multiple value containing parameters
    my @list = $model->{pkit_pk}->{apr}->param(@_);
    return @list;
  } else {
    return $model->{pkit_pk}->{apr}->param(@_);
  }
}

sub fillinform {
  my $model = shift;
  my @params = @_;
  for ( @params ) {
    Encode::_utf8_off( $_ ) unless ref $_;
  }
  return $model->{pkit_pk}->{fillinform_object}->param(@params);
}

sub ignore_fillinform_fields {
  my $model = shift;
  push @{$model->{pkit_pk}->{ignore_fillinform_fields}}, @_;
}

sub output {
  return shift->{pkit_pk}->{output_param_object}->param(@_);
}

sub pkit_status_code {
  my $pk = shift->{pkit_pk};
  my $old_status_code = $pk->{status_code};
  $pk->{status_code} = $_[0] if ( @_ );
  return $old_status_code;
}

sub output_convert {
  my ($model, %p) = @_;
  my $view = $model->{pkit_pk}->{view};
  my $input_charset = exists $p{input_charset} ? $p{input_charset} : $view->{default_input_charset};
    &_change_params($input_charset, $p{output} ? %{$p{output}} : %p );
  $model->output( $p{output} || %p );
}

sub pnotes {
  my $model = shift;
  my $apr = $model->{pkit_pk}->{apr};
  if($apr->can('pnotes')){
    $apr->pnotes(@_);
  } else {
    # if running outside of mod_perl
    return $model->{pkit_pk}->{pnotes_param_object}->param(@_);
  }
}

# put here so that it can be overriden in derived classes
sub pkit_get_default_page {
  return shift->{pkit_pk}->{config}->get_global_attr('default_page') || 'index';
}

sub create {
  my ($model, $class) = @_;
  my $create_model = $class->new(pkit_pk => $model->{pkit_pk});
  return $create_model;
}

# this is experimental and subject to change
sub dispatch {
  warn "dispatch is depreciated - use create instead";
  my ($model, $class, $method, @args) = @_;
  my $dispatch_model = $class->new(pkit_pk => $model->{pkit_pk});
#  $dispatch_model->{pkit_pk} = $model->{pkit_pk} if exists $model->{pkit_pk};
  no strict 'refs';
  return &{$class . '::' . $method}($dispatch_model, @args);
}

sub dbh {
  my $model = shift;
  if (exists $model->{pkit_pk}->{dbh}){
    return $model->{pkit_pk}->{dbh};
  } else {
    unless ( defined($Apache2::PageKit::Model::dbh) && $Apache2::PageKit::Model::dbh->ping ) {
      $Apache2::PageKit::Model::dbh = $model->pkit_dbi_connect if $model->can('pkit_dbi_connect');
    }
    return $Apache2::PageKit::Model::dbh;
  }
}

sub apr {return shift->{pkit_pk}->{apr};}
# undocumented
sub config {return shift->{pkit_pk}->{config};}
sub session {return shift->{pkit_pk}->{session};}
sub page_session { return shift->{pkit_pk}->{page_session}; }

sub pkit_redirect {
  my ($model, $url) = @_;
  my $pk = $model->{pkit_pk};
  my $apr = $pk->{apr};
  
  # we may have created a new session. Add a cookie header if needed
  $pk->set_session_cookie;
  
  if(my $pkit_messages = $model->output('pkit_messages')){
    my $add_url = join("", map { "&pkit_" . ($_->{pkit_is_error} ? "error_" : "") . "messages=" . Apache2::Util::escape_path( $_->{pkit_message}, $apr->pool ) } @$pkit_messages);
    $add_url =~ s!^&!?! unless $url =~ m/\?/;
    $url .= $add_url;
  }
  $apr->headers_out->set(Location => $url);
  $pk->{status_code} = REDIRECT;
}

sub pkit_merge_sessions {
  my ($model, $old_session, $new_session) = @_;
  while(my ($k, $v) = each %$old_session){
    next if $k eq '_session_id';
    $new_session->{$k} = $v unless exists $new_session->{$k};
  }
}

sub pkit_gettext_message {
  my ( $model, $text ) = splice(@_, 0, 2);
  return $model->pkit_message($model->pkit_gettext($text), @_);
}

sub pkit_gettext {
  my ( $model, $text ) = @_;
  my $config = $model->config;
  my $use_locale = $config->get_global_attr('use_locale') || 'no';
  return $text if ( !exists &Locale::gettext::gettext || $use_locale ne 'yes' );
  unless ( $model->pnotes('pkit_env_lang_is_set') ) {
    $model->pnotes('pkit_env_lang_is_set' => 1);
    $ENV{LC_MESSAGES} = $model->{pkit_pk}->{lang} || 'en';

    # notice changes in the .mo file if reload eq 'yes'
    my $reload = $config->get_server_attr('reload') || 'no';
    if ( $reload eq 'yes' ) {
      #my ( $textdomain ) = $config->get_global_attr('model_base_class') =~ m/^([^:]+)/;
      my $textdomain = 'PageKit';
      Locale::gettext::textdomain($textdomain);
    }
  }
  return Locale::gettext::gettext($text);
}

sub pkit_query {
  my ($model, @p) = @_;
  my $pk = $model->{pkit_pk};
  my $view = $pk->{view};

  # will need to change once Template-Toolkit is supported
  unless(exists $view->{record}){
    $pk->open_view;
  }

  return $view->{record}->{html_template}->query(@p);
}

# $media_type and $content_encoding is optional
# $ref_or_fname can be a ref to a filenhandle, a ref to a scalar or a scalar,
# that holds the filename
sub pkit_send {
  my ($model, $ref_or_fname, $media_type, $content_encoding) = @_;

  my $type = ref $ref_or_fname;
  my $apr = $model->apr;
  unless ( $media_type ) {
    unless ( $type ) {
      # is filename
      require MIME::Types;
      ( $media_type ) = MIME::Types::by_suffix($ref_or_fname);
    }
   $media_type ||= 'application/octet-stream';
  }

  if ( $content_encoding && $media_type eq 'text/html' ) {
    $apr->content_encoding($content_encoding) 
  } elsif ( !$type ) {
    $apr->headers_out->set('Content-Length' => -s $ref_or_fname);
  }
  $apr->content_type($media_type) unless $apr->main;
  unless ($apr->header_only) {
    # NOT a head request, send the data
    if ( $type eq 'SCALAR' ) {
      $apr->print($$ref_or_fname);
    } elsif ( $type eq 'GLOB' ) {
      ## $apr->send_fd($ref_or_fname);
      
      my ( $t, $bytes );
      while (1) {
        $bytes = sysread( $ref_or_fname, $t, 8192 );
        if ( !defined $bytes ) {
          warn "sysread error $!";
	  return NOT_FOUND;
        }
        last unless $bytes;
        $apr->print($t);
      }
    } else {
      unless ( $apr->sendfile($ref_or_fname) == APR::Const::SUCCESS ) {
        warn "can not open file: $ref_or_fname ($!)";
        return NOT_FOUND;
      }
    }
  }
  return DONE;
}

# helper function for output_convert
# it converts all hash values to the desired charset INPLACE
# is this a good idea or better clone it?
sub _change_params {

  sub _change_array {
    my ($charset, $aref)  = @_;
    foreach (@$aref) {
      my $type = ref $_;
      if ( $type eq 'HASH' ) {
        _change_hash( $charset, $_ );
      } elsif ( $type eq 'ARRAY' ) {
        _change_array( $charset, $_ );
      } else {
        $_ = Encode::decode($charset, $_);
      }
    }
  }

  sub _change_hash {
    my ($charset, $href)  = @_;
    foreach ( values %$href ) {
      my $type = ref $_;
      if ( $type eq 'HASH' ) {
        _change_hash( $charset, $_ );
      } elsif ( $type eq 'ARRAY' ) {
        _change_array( $charset, $_ );
      } else {
        $_ = Encode::decode($charset, $_);
      }
    }
  }
  my $charset = shift;
  for ( my $i = 1 ; $i <= $#_ ; $i += 2 ) {
    my $type = ref $_[$i];
    if ( $type eq 'HASH' ) {
      _change_hash( $charset, $_[$i] );
    } elsif ( $type eq 'ARRAY' ) {
      _change_array( $charset, $_[$i] );
    } else {
      $_[$i] = Encode::decode($charset, $_[$i]);
    }
  }
}

1;

__END__

=head1 NAME

Apache2::PageKit::Model - Base Model Class

=head1 DESCRIPTION

This class provides a base class for the Modules implementing
the backend business logic for your web site.

This module also contains a wrapper to L<Data::FormValidator>.
It validates the form data from the L<Apache2::Request> object contained
in the L<Apache2::PageKit> object.

When deriving classes from Apache2::PageKit::Model, keep in mind that
all methods and hash keys that begin with pkit_ are reserved for
future use.

=head1 SYNOPSIS

Method in derived class.

  sub my_method {
    my $model = shift;

    # get database handle, session
    my $dbh = $model->dbh;
    my $session = $model->session;

    # get inputs (from request parameters)
    my $foo = $model->input('bar');

    # do some processing

    ...

    # set outputs in template
    $model->output(result => $result);
  }

=head1 AUTHORS

T.J. Mather (tjmather@anidea.com)

Boris Zentner (borisz@users.sourceforge.net)

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002, 2003, 2004, 2005 AnIdea Corporation.  All rights Reserved.  PageKit is
a trademark of AnIdea Corporation.

=head1 LICENSE

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the Ricoh Source Code Public License for more details.

You can redistribute this module and/or modify it only under the terms of the Ricoh Source Code Public License.

You should have received a copy of the Ricoh Source Code Public License along with this program; if not, obtain one at http://www.pagekit.org/license

=cut
