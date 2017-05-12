#!/bin/false

use strict;
use warnings;

package Catalyst::View::TT::Alloy;
$Catalyst::View::TT::Alloy::VERSION = '0.00007';
use parent qw( Catalyst::View );

use Carp qw( croak );
use Data::Dump qw( dump );
use Path::Class;
use Scalar::Util qw( weaken blessed );
use Template::Alloy qw( Compile Parse TT );

__PACKAGE__->mk_accessors('template');
__PACKAGE__->mk_accessors('include_path');

=head1 NAME

Catalyst::View::TT::Alloy - Template::Alloy (TT) View Class

=head1 VERSION

version 0.00007

=head1 SYNOPSIS

# use the helper to create your View
    myapp_create.pl view TT::Alloy TT::Alloy

# configure in myapp.yml

    'View::TT::Alloy':
      INCLUDE_PATH:
        - __path_to(root/src)__
        - __path_to(root/lib)__
      PRE_PROCESS: 'config/main'
      WRAPPER: 'site/wrapper'
      # optional
      TEMPLATE_EXTENSION: '.tt'
      CATALYST_VAR: 'Catalyst'

# example render view in lib/MyApp/Controller/Root.pm

    sub default : Private {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->stash->{message}  = 'Hello World!';
        return;
    }

    sub end : ActionClass('RenderView') {
    }

# access variables from template

    The message is: [% message %].

    # example when CATALYST_VAR is set to 'Catalyst'
    Context is [% Catalyst %]
    The base is [% Catalyst.req.base %]
    The name is [% Catalyst.config.name %]

    # example when CATALYST_VAR isn't set
    Context is [% c %]
    The base is [% base %]
    The name is [% name %]

=cut

sub _coerce_paths {
    my ( $paths, $dlim ) = shift;
    return () if ( !$paths );
    return @{$paths} if ( ref $paths eq 'ARRAY' );

    # tweak delim to ignore C:/
    unless ( defined $dlim ) {
        $dlim = ( $^O eq 'MSWin32' ) ? ':(?!\\/)' : ':';
    }
    return split( /$dlim/, $paths );
}

sub new {
    my ( $class, $c, $arguments ) = @_;
    my $config = {
        TEMPLATE_EXTENSION => '',
        %{ $class->config },
        %{$arguments},
    };
    if ( !( ref $config->{INCLUDE_PATH} eq 'ARRAY' ) ) {
        my $delim = $config->{DELIMITER};
        my @include_path = _coerce_paths( $config->{INCLUDE_PATH}, $delim );
        if ( !@include_path ) {
            my $root = $c->config->{root};
            my $base = Path::Class::dir( $root, 'base' );
            @include_path = ( "$root", "$base" );
        }
        $config->{INCLUDE_PATH} = \@include_path;
    }

    if ( $c->debug && $config->{DUMP_CONFIG} ) {
        $c->log->debug( "TT Config: ", dump($config) );
    }

    my $self = $class->next::method( $c, {%$config}, );

    # Set base include paths. Local'd in render if needed
    $self->include_path( $config->{INCLUDE_PATH} );

    $self->config($config);

    return $self;
}

sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template}
      || $c->action . $self->config->{TEMPLATE_EXTENSION};

    unless ( defined $template ) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return;
    }

    my $output;
    eval { $output = $self->render( $c, $template ); };

    if ( my $error = $@ ) {
        my $error_string = qq/Couldn't render template "$template"/;

        #Mostly copied from Catalyst::View::TT's error handling
        #Log::Dispatch barfs on ARRAY REF errors
        if ( blessed($error) && $error->isa('Template::Alloy::Exception') ) {
            $error = "$error_string: $error";
            $c->log->error($error);
            $c->error($error);
        }
        else {
            $c->log->error($error);
            $c->error($error);
            return;
        }
    }

    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }

    $c->response->body($output);

    return 1;
}

sub render {
    my ( $self, $c, $template, $args ) = @_;

    $c->log->debug(qq/Rendering template "$template"/) if $c->debug;

    my $config = $self->config;
    $config->{INCLUDE_PATH} = $self->include_path;

    my $vars = {
        ( ref $args eq 'HASH' ? %$args : %{ $c->stash() } ),
        $self->_template_vars($c)
    };

    local $config->{INCLUDE_PATH} =
      [ @{ $vars->{additional_template_paths} }, @{ $config->{INCLUDE_PATH} } ]
      if ref $vars->{additional_template_paths};

    # until Template::Alloy either gives us a public method to change
    # INCLUDE_PATH, or supports a coderef there, we need to create a
    # new object for every call of render()
    my $tt = Template::Alloy->new($config);
    my $output;

    unless ( $tt->process( $template, $vars, \$output ) ) {
        croak $tt->error;
    }
    else {
        return $output;
    }
}

sub _template_vars {
    my ( $self, $c ) = @_;

    my $cvar = $self->config->{CATALYST_VAR};

    defined $cvar
      ? ( $cvar => $c )
      : (
        c    => $c,
        base => $c->req->base,
        name => $c->config->{name}
      );
}

1;

__END__

=head1 DESCRIPTION

This is the Catalyst view for the L<TT|Template> emulator
L<Template::Alloy>.

Your application should define a view class which is a subclass of
this module.  The easiest way to achieve this is using
C<script/myapp_create.pl> (replacing C<myapp> with the name of your
application).

    $ script/myapp_create.pl view TT::Alloy TT::Alloy

You can either manually forward to the C<TT::Alloy> as normal, or use
L<Catalyst::Action::RenderView> to do it for you.

    # In MyApp::Controller::Root

    sub end : ActionClass('RenderView') { }

=head2 RATIONAL

L<Template::Alloy> is a pure-perl module which emulates most common
features of L<TT|Template>, and in some cases is faster too. See
L<Template::Alloy::TT> for details of which features are missing.

L<Catalyst::View::TT::Alloy> is generally compatible with
L<Catalyst::View::TT>. The C<TIMER> configuration option isn't supported,
and the C<paths()> alias to C<include_path()> has been removed.

Although L<Template::Alloy> emulates several other
templating modules, the interface differs for each one. For this reason,
this module only provides the L<TT|Template> interface.

=head2 DYNAMIC INCLUDE_PATH

Sometimes it is desirable to modify INCLUDE_PATH for your templates at run time.

Additional paths can be added to the start of INCLUDE_PATH via the stash as
follows:

    $c->stash->{additional_template_paths} =
        [$c->config->{root} . '/test_include_path'];

If you need to add paths to the end of INCLUDE_PATH, there is also an
include_path() accessor available:

    push( @{ $c->view('TT')->include_path }, qw/path/ );

Note that if you use include_path() to add extra paths to INCLUDE_PATH, you
MUST check for duplicate paths. Without such checking, the above code will add
"path" to INCLUDE_PATH at every request, causing a memory leak.

A safer approach is to use include_path() to overwrite the array of paths
rather than adding to it. This eliminates both the need to perform duplicate
checking and the chance of a memory leak:

    $c->view('TT')->include_path([ qw/ path another_path / ]);

If you are calling C<render> directly then you can specify dynamic paths by
having a C<additional_template_paths> key with a value of additonal directories
to search. See L<CAPTURING TEMPLATE OUTPUT> for an example showing this.

=head2 RENDERING VIEWS

The view plugin renders the template specified in the C<template>
item in the stash.

    sub message : Global {
        my ( $self, $c ) = @_;

        $c->stash->{template} = 'message.tt2';

        $c->forward('MyApp::View::TT::Alloy');
    }

If C<template> isn't defined, then it builds the filename from
C<Catalyst/action> and the C<TEMPLATE_EXTENSION> config setting.
In the above example, this would be C<message>.

The items defined in the stash are passed to L<Template::Alloy> for
use as template variables.

    sub default : Private {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->stash->{message}  = 'Hello World!';
        $c->forward('MyApp::View::TT::Alloy');
    }

A number of other template variables are also added:

    c      A reference to the context object, $c
    base   The URL base, from $c->req->base()
    name   The application name, from $c->config->{ name }

These can be accessed from the template in the usual way:

<message.tt2>:

    The message is: [% message %]
    The base is [% base %]
    The name is [% name %]


The output generated by the template is stored in C<< $c->response->body >>.

=head2 CAPTURING TEMPLATE OUTPUT

If you wish to use the output of a template for some other purpose than
displaying in the response, e.g. for sending an email, this is possible using
L<Catalyst::Plugin::Email> and the L<render> method:

  sub send_email : Local {
    my ($self, $c) = @_;

    $c->email(
      header => [
        To      => 'me@localhost',
        Subject => 'A TT Email',
      ],
      body => $c->view('TT::Alloy')->render($c, 'email.tt', {
        additional_template_paths => [ $c->config->{root} . '/email_templates'],
        email_tmpl_param1 => 'foo'
        }
      ),
    );
  # Redirect or display a message
  }

=head2 METHODS

=over 4

=item new

The constructor for the TT::Alloy view.

=item process

Renders the template specified in C<< $c->stash->{template} >> or
C<< $c->action >> (the private name of the matched action.  Calls C<render>
to perform actual rendering. Output is stored in C<< $c->response->body >>.

=item render

Arguments: ($c, $template, \%args)

Renders the given template and returns output, or croaks on error.

The template variables are set to C<%$args> if $args is a hashref, or
$C<< $c->stash >> otherwise. In either case the variables are augmented with
C<base> set to C< << $c->req->base >>, C<c> to C<$c> and C<name> to
C<< $c->config->{name} >>. Alternately, the C<CATALYST_VAR> configuration item
can be defined to specify the name of a template variable through which the
context reference (C<$c>) can be accessed. In this case, the C<c>, C<base> and
C<name> variables are omitted.

=item config

This method allows your view subclass to pass additional settings to
the TT configuration hash, or to set the options as below:

=over 2

=item C<CATALYST_VAR>

Allows you to change the name of the Catalyst context object. If set, it will also
remove the base and name aliases, so you will have access them through <context>.

For example:

    MyApp->config({
        name     => 'MyApp',
        root     => MyApp->path_to('root'),
        'View::TT::Alloy' => {
            CATALYST_VAR => 'Catalyst',
        },
    });

F<message.tt2>:

    The base is [% Catalyst.req.base %]
    The name is [% Catalyst.config.name %]

=item C<TEMPLATE_EXTENSION>

A sufix to add when building the template name, when
C<< $c->stash->{template} >> is not set.

For example:

  package MyApp::Controller::Test;
  sub test : Local { .. }

Would by default look for a template in C<< <root>/test/test >>.

If you set TEMPLATE_EXTENSION to '.tt', it will look for
C<< <root>/test/test.tt >>.

=back

=back

=head2 HELPERS

The L<Catalyst::Helper::View::TT::Alloy> module is provided to create
your view module. It is invoked by the C<myapp_create.pl> script:

    $ script/myapp_create.pl view TT::Alloy TT::Alloy

=head1 SUPPORT

Catalyst Mailing List:

L<http://lists.rawmode.org/mailman/listinfo/catalyst>

=head1 GIT REPOSITORY

L<https://github.com/djzort/Catalyst-View-TT-Alloy>

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper::View::TT::Alloy>, L<Template::Alloy>

=head1 AUTHORS

Carl Franks, C<cfranks@cpan.org>

Based on the code of C<Catalyst::View::TT>, by

Sebastian Riedel, C<sri@cpan.org>

Marcus Ramberg, C<mramberg@cpan.org>

Jesse Sheidlower, C<jester@panix.com>

Andy Wardley, C<abw@cpan.org>

=head1 CONTRIBUTORS

Moritz Onken, C<onken@netcubed.de>

Dean Hamstead C<dean@bytefoundry.com.au>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
