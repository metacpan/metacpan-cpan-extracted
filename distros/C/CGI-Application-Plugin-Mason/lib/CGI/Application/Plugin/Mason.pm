package CGI::Application::Plugin::Mason;

=pod

=head1 NAME

CGI::Application::Plugin::Mason - HTML::Mason plugin for CGI::Application

=head1 VERSION

1.01

=head1 SYNOPSIS

  package YourApp;

  use strict;
  use base qw(CGI::Application);
  use CGI::Application::Plugin::Stash; # require!
  use CGI::Application::Plugin::Mason;

  # cgiapp_init
  sub cgiapp_init {
    my $self = shift;
    $self->interp_config( comp_root => "/path/to/root", data_dir => "/tmp/mason" );
  }

  # runmode
  sub start {
    my $self = shift;

    # Catalyst like
    $self->stash->{name} = "kurt";
    $self->stash->{age}  = 27;
    # template path
    $self->stash->{template} = "/start.mason";
    return $self->interp_exec;
  }

  # start.mason
  <%args>
  $name
  $age
  </%args>
  <html>
  <head>
  <% # $c is YourApp object %>
  <title><% $c->get_current_runmode %></title>
  </head>

  <body>
  name : <% $name | h %><br>
  age : <% $age | h %>
  </body>
  </html>

=head1 DESCRIPTION

CGI::Application::Plugin::Mason is Plug-in that offers HTML::Mason template engine.

=cut

use base qw(Exporter);
use strict;
use warnings;
use Carp;
use Cwd;
use Exporter;
use File::Spec;
use HTML::Mason;

our(@EXPORT, $VERSION);

@EXPORT  = qw(interp interp_config interp_exec);
$VERSION = 1.00;

sub import {

    my $pkg = caller;
    # register new hook
    $pkg->new_hook("interp_pre_exec");
    $pkg->new_hook("interp_post_exec");
    # register hook
    $pkg->add_callback("interp_pre_exec", \&interp_pre_exec);
    $pkg->add_callback("interp_post_exec", \&interp_post_exec);
    goto &Exporter::import;
}

=pod

=head1 METHOD

=head2 interp_config

Initialize HTML::Mason::Interp method.

Option:

  comp_root          : HTML::Mason root dir(default: Cwd::getcwd value)
  data_dir           : HTML::Mason cache and object file directory(default: /tmp/mason)
  template_extension : template extension(default: .mason)

Example:

  sub cgiapp_init {
    my $self = shift;
    $self->interp_config( comp_root => "/path/to/comp_root", data_dir => "/tmp/mason" );

    # When pass other HTML::Mason option
    $self->interp_config(
                        comp_root            => "/path/to/comp_root",
                        default_escape_flags => [ "h" ],
                        autohandler_name     => "autohandler",
                        );
  }

=cut

sub interp_config {

    my($self, %args) = @_;

    # C::A::P::Stash check
    if(!$self->can("stash")){
        croak("C::A::P::Stash module is not load to your app"); 
    }

    # config option
    $self->{__CAP_INTERP_CONFIG} = {};
    # output buffer
    $self->{__CAP_INTERP_OUTPUT} = "";
    # HTML::Mason::Interp object
    $self->{__CAP_INTERP_OBJECT} = "";
    
    my %config = %args;
    # comp_root
    $config{comp_root}           ||= getcwd;
    # data_dir
    $config{data_dir}            ||= File::Spec->catfile(File::Spec->tmpdir, "mason");
    # allow_globals
    $config{allow_globals}       = [ '$c' ];
    # template_extension
    $config{template_extension}  ||= ".mason";

    $self->{__CAP_INTERP_CONFIG} = { %config };
    
    delete $config{template_extension};
    my $interp = HTML::Mason::Interp->new(
                               %config,
                               out_method => \$self->{__CAP_INTERP_OUTPUT}
                             );
    $interp->set_global( '$c' => $self );
    # VERSION 1.01 add h
    $interp->set_escape( h  => \&h );

    $self->{__CAP_INTERP_OBJECT} = $interp;
}

=pod

=head2 interp 

HTML::Mason::Interp object wrapper

Example:

  # HTML::Mason::Interp#set_escape
  $self->interp->set_escape( uc => sub { ${$_[0]} =~ tr/a-z/A-Z/ } );
  # HTML::Mason::Interp#comp_root
  my $comp_root = $self->interp->comp_root;

=cut

sub interp { 
    
    my $self = shift;
    if(ref($self->{__CAP_INTERP_OBJECT}) ne "HTML::Mason::Interp"){
        croak("HTML::Mason::Interp has not been loaded. Execute unpalatable \$self->interp_config.");
    }
    return $self->{__CAP_INTERP_OBJECT};
}

=pod

=head2 interp_exec

Return HTML::Mason::Interp#exec result.

The specification of the template file

Example:

  # file name
  $self->stash->{template} = "/template.mason"
  # file handle
  open my $fh, "/path/to/template.mason" or croak("can not open file");
  $self->stash->{template} = $fh;
  # scalarref
  $self->stash->{template} = \q{<%args>$name</%args> my name is <% $name %>};

default template name is /package_name/runmode_method_name . ${template_extension}

Example:

  # ex1
  package MyApp;
  sub start {
    my $self = shift;
    do something...
 
    # The file passing used at this time is /MyApp/start.mason
    return $self->interp_exec;
  }

  # ex2
  package My::App;
  sub start {
    my $self = shift;
    do something...
 
    # The file passing used at this time is /My/App/start.mason
    return $self->interp_exec;
  }

Specification of variable allocated in template

Example:

  # ex1
  sub start {
    my $self = shift;
    # stash method setting
    $self->stash->{name} = "kurt";
    $self->stash->{age}  = 27;
    return $self->interp_exec;
  }

  # ex2
  sub start {
    my $self = shift;
    # interp_exec param setting
    return $self->interp_exec( name => "kurt", age => 27 );
  }

=cut

sub interp_exec {

    my($self, %args) = @_;

    %args = %{$self->stash} if !keys %args;

    my $template = $self->stash->{template};

    $template = _get_interp_template_path($self) if !defined $template;

    # interp_pre_exec
    $self->call_hook("interp_pre_exec", $template, \%args);

    # component
    my $comp = undef;
    if(ref($template) eq "SCALAR"){
        $comp = $self->interp->make_component( comp_source => ${$template} );
    }elsif(ref($template) eq "GLOB"){
        $comp = $self->interp->make_component( comp_source => do { local $/ = undef; <$template> } );
        close $template;
    }else{

        $comp = $template;
        if($comp !~ m#^/#){
            $comp = File::Spec->catfile("/", $comp);
        }
    }

    # interp->exec
    $self->interp->exec( $comp, %args );

    # interp_post_exec
    $self->call_hook("interp_post_exec", \$self->{__CAP_INTERP_OUTPUT});

    return $self->{__CAP_INTERP_OUTPUT};
}


=pod

=head2 interp_pre_exec

Trigger method before interp_exec. the argument is $temlate, and $arg.

  $template : $self->{template} value
  $args     : $self->{stash} or $self->interp_exec args hashref

Example:

  sub interp_pre_exec {
    my($self, $template, $args) = @_;
    $args->{newval} = "interp_pre_exec setting value!";
  }

  # or

  $self->add_callback("interp_pre_exec", sub {
    my($self, $template, $args) = @_;
    $args->{newval} = "interp_pre_exec setting value!";
  });  

=cut

sub interp_pre_exec {

    my($self, $template, $args) = @_;
    # do something...
}

=pod

=head2 interp_post_exec

Trigger method after interp_exec. the argument is $bodyref.

  $bodyref : content value scalarref

Example:

  sub interp_post_exec {
    my($self, $bodyref) = @_;
    ${$bodyref} = encode("shiftjis", decode("utf8", ${$bodyref}));
  }

  # or

  $self->add_callback("interp_post_exec", sub {
    my($self, $bodyref) = @_;
    ${$bodyref} = encode("shiftjis", decode("utf8", ${$bodyref}));
  });  

=cut

sub interp_post_exec {

    my($self, $bodyref) = @_;
    # do something...
}

=pod

=head1 ESCAPE METHOD

=head2 h

html escape

=cut

sub h {

    &HTML::Mason::Escapes::basic_html_escape($_[0]);
    ${$_[0]} =~ s/'/&#039;/g;
}


=pod

=head1 PRIVATE METHOD

=head2 _get_interp_template_path

Get default template path. 

=cut

sub _get_interp_template_path {

    my $self = shift;
    my $path = File::Spec->catfile(split(/::/, ref($self)), $self->get_current_runmode);
    $path .= $self->{__CAP_INTERP_CONFIG}->{template_extension};
    return File::Spec->catfile("/", $path);
}

1;

__END__

=head1 SEE ALSO

L<CGI::Application> L<CGI::Application::Plugin::Stash> L<HTML::Mason>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT AND LICENSE

This library is free software.
You can redistribute it and/or modify it under the same terms as perl itself.

Copyright (C) 2007 Akira Horimoto

=cut

