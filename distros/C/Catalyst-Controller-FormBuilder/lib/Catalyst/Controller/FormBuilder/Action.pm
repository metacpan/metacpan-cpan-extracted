package Catalyst::Controller::FormBuilder::Action;

use strict;
use CGI::FormBuilder;
use CGI::FormBuilder::Source::File;
use File::Spec;
use Class::Inspector;
use MRO::Compat;
use Scalar::Util ();

use base qw/Catalyst::Action Class::Data::Inheritable/;

__PACKAGE__->mk_classdata(qw/_source_class/);
__PACKAGE__->mk_accessors(qw/_attr_params _source_type/);
__PACKAGE__->_source_class('CGI::FormBuilder::Source::File');

sub _setup_form {
    my ( $self, $controller, $c ) = @_;

    # Load configured defaults from the user, and add in some
    # custom settings needed to meld FormBuilder with Catalyst
    my $config = $controller->config->{'Controller::FormBuilder'} || {};

    my %attr = (
        debug   => $c->debug ? 2 : 0,
        %{ $config->{new} || {} },
        %{ $self->_source_conf_data( $controller, $c ) || {} },
        params  => $c->req,
        action  => $c->req->uri->path,
        header  => 0,                    # always disable headers
        cookies => 0,                    # and cookies
        title   => __PACKAGE__,
        c       => $c,                   # allow \&validate to get $c,
    );

    $self->_create_formbuilder(\%attr);
}

sub _source_conf_data {
    my $self = shift;

    if ( my $source = $self->_source(@_) ) {
        s/^\.*/./ if $_;    # XX workaround for CGI::FormBuilder::Source::File bug
        my $adapter = $self->_create_source_adapter();
        return { $adapter->parse($source) };
    }
}

sub _create_formbuilder {
    my $self = shift;

    return CGI::FormBuilder->new( @_ );
}

sub _create_source_adapter {
    my $self = shift;

    my $class = $self->_source_type || $self->_source_class;
    unless ( Class::Inspector->loaded($class) ) {
        require Class::Inspector->filename($class);
    }

    return $class->new();
}

sub _source {
    my ( $self, $controller, $c ) = @_;

    my $config = $controller->config->{'Controller::FormBuilder'} || {};
    my $name  = $self->_attr_params->[0] || $self->reverse;

    # remove leading and trailing slashes
    $name =~ s#^/+##;
    $name =~ s#/+$##;

    my $fbdir = $self->_form_path($controller, $c);

    # Attempt to autoload config and template files
    # Cleanup suffix to allow ".fb" or "fb" in config

    my $fbsuf = exists( $config->{form_suffix} ) ? $config->{form_suffix} : 'fb';
    $fbsuf =~ s/^\.*/./ if $fbsuf;
    my $fbfile = "$name$fbsuf";

    $c->log->debug("Form ($name): Looking for config file $fbfile")
      if $c->debug;

    # Look for files relative to our current action url (/books/edit)
    for my $dir ( @$fbdir ) {
        my $conf = File::Spec->catfile( $dir, $fbfile );
        if ( -f $conf && -r _ ) {
            $c->log->debug("Form ($name): Found form config $conf")
              if $c->debug;
            return $conf;
        }
    }

    my $err = sprintf( "Form (%s): Can't find form config $fbfile in: %s",
        $name, join( ", ", @$fbdir ) );

    if ( $self->_attr_params->[0] ) {
        $c->log->error($err);
        $c->error($err);
    }
    else {
        $c->log->debug($err) if $c->debug;
    }

    return;
}

sub _form_path {
    my ( $self, $controller, $c ) = @_;

    my $config = $controller->config->{'Controller::FormBuilder'} || {};
    my $fbdir = [ File::Spec->catfile( $c->config->{home}, 'root', 'forms' ) ];

    if ( my $dir = $config->{form_path} ) {
        $fbdir = ref $dir ? $dir : [ split /\s*:\s*/, $dir ];
    }

    return $fbdir;
}

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    return $self->maybe::next::method(@_)
      unless exists $self->attributes->{ActionClass}
      && $self->attributes->{ActionClass}[0] eq
      $controller->_fb_setup->{action};

    my $form = $self->_setup_form(@_);
    Scalar::Util::weaken($form->{c});
    $controller->_formbuilder($form);
    $self->maybe::next::method(@_);
    $controller->_formbuilder($form);   # keep the same form in case of forwards

    $self->setup_template_vars( @_ );
}

1;
