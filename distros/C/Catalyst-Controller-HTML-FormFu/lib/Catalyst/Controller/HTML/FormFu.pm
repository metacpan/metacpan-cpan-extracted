package Catalyst::Controller::HTML::FormFu;

# ABSTRACT: Catalyst integration for HTML::FormFu

use strict;

our $VERSION = '2.04'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;

use HTML::FormFu;
use Config::Any;
use Regexp::Assemble;
use Scalar::Util qw/ isweak weaken /;
use Carp qw/ croak /;

use namespace::autoclean;

# see https://rt.cpan.org/Ticket/Display.html?id=55780
BEGIN {
    extends 'Catalyst::Controller';
}

with 'Catalyst::Component::InstancePerContext';

has _html_formfu_config => ( is => 'rw' );

sub build_per_context_instance {
    my ( $self, $c ) = @_;
    return $self unless ( ref $c );
    $self->{c} = $c;

    weaken( $self->{c} )
        if !isweak( $self->{c} );

    return $self;
}

sub BUILD { }

after BUILD => sub {
    my ($self) = @_;

    my $app           = $self->_app;
    my $self_config   = $self->config->{'Controller::HTML::FormFu'} || {};
    my $parent_config = $app->config->{'Controller::HTML::FormFu'} || {};

    my %defaults = (
        request_token_enable          => 0,
        request_token_field_name      => '_token',
        request_token_session_key     => '__token',
        request_token_expiration_time => 3600,
        form_method                   => 'form',
        form_stash                    => 'form',
        form_attr                     => 'Form',
        config_attr                   => 'FormConfig',
        method_attr                   => 'FormMethod',
        form_action                   => "Catalyst::Controller::HTML::FormFu::Action::Form",
        config_action                 => "Catalyst::Controller::HTML::FormFu::Action::FormConfig",
        method_action                 => "Catalyst::Controller::HTML::FormFu::Action::FormMethod",

        multiform_method        => 'multiform',
        multiform_stash         => 'multiform',
        multiform_attr          => 'MultiForm',
        multiform_config_attr   => 'MultiFormConfig',
        multiform_method_attr   => 'MultiFormMethod',
        multiform_action        => "Catalyst::Controller::HTML::FormFu::Action::MultiForm",
        multiform_config_action => "Catalyst::Controller::HTML::FormFu::Action::MultiFormConfig",
        multiform_method_action => "Catalyst::Controller::HTML::FormFu::Action::MultiFormMethod",

        context_stash => 'context',

        model_stash => {},

        constructor           => {},
        multiform_constructor => {},

        config_callback => 1,
    );

    my %args = ( %defaults, %$parent_config, %$self_config );

    my $local_path = $app->path_to( 'root', 'formfu' );

    if (   !exists $args{constructor}{tt_args}
        || !exists $args{constructor}{tt_args}{INCLUDE_PATH} && -d $local_path ) {
        $args{constructor}{tt_args}{INCLUDE_PATH} = [$local_path];
    }

    $args{constructor}{query_type} ||= 'Catalyst';

    if ( !exists $args{constructor}{config_file_path} ) {
        $args{constructor}{config_file_path} = $app->path_to( 'root', 'forms' );
    }

    # build regexp of file extensions
    my $regex_builder = Regexp::Assemble->new;

    map { $regex_builder->add($_) } Config::Any->extensions;

    $args{_file_ext_regex} = $regex_builder->re;

    # save config for use by action classes
    $self->_html_formfu_config( \%args );

    # add controller methods
    no strict 'refs';    ## no critic (ProhibitNoStrict);
    *{"$args{form_method}"}      = \&_form;
    *{"$args{multiform_method}"} = \&_multiform;
};

sub _form {
    my $self   = shift;
    my $config = $self->_html_formfu_config;
    my $form   = HTML::FormFu->new( { %{ $self->_html_formfu_config->{constructor} }, ( @_ ? %{ $_[0] } : () ), } );

    $self->_common_construction($form);

    if ( $config->{request_token_enable} ) {
        $form->plugins(
            {   type            => 'RequestToken',
                context         => $config->{context_stash},
                field_name      => $config->{request_token_field_name},
                session_key     => $config->{request_token_session_key},
                expiration_time => $config->{request_token_expiration_time}
            }
        );
    }

    return $form;
}

sub _multiform {
    my $self = shift;

    require HTML::FormFu::MultiForm;

    my $multi = HTML::FormFu::MultiForm->new(
        {   %{ $self->_html_formfu_config->{constructor} },
            %{ $self->_html_formfu_config->{multiform_constructor} },
            ( @_ ? %{ $_[0] } : () ),
        }
    );

    $self->_common_construction($multi);

    return $multi;
}

sub _common_construction {
    my ( $self, $form ) = @_;

    croak "form or multi arg required" if !defined $form;

    $form->query( $self->{c}->request );

    my $config = $self->_html_formfu_config;

    if ( $config->{config_callback} ) {
        $form->config_callback(
            {   plain_value => sub {
                    return if !defined $_;
                    s{__uri_for\((.+?)\)__}
                     { $self->{c}->uri_for( split( '\s*,\s*', $1 ) ) }eg
                        if /__uri_for\(/;

                    s{__path_to\(\s*(.+?)\s*\)__}
                     { $self->{c}->path_to( split( '\s*,\s*', $1 ) ) }eg
                        if /__path_to\(/;

                    s{__config\((.+?)\)__}
                     { $self->{c}->config->{$1}  }eg
                        if /__config\(/;
                }
            }
        );

        weaken( $self->{c} )
            if !isweak( $self->{c} );
    }

    if ( $config->{languages_from_context} ) {
        $form->languages( $self->{c}->languages );
    }

    if ( $config->{localize_from_context} ) {
        $form->add_localize_object( $self->{c} );
    }

    if ( $config->{default_action_use_name} ) {
        my $action = $self->{c}->uri_for( $self->{c}->{action}->name );

        $self->{c}->log->debug("FormFu - Setting default action by name: $action")
            if $self->{c}->debug;

        $form->action($action);
    }
    elsif ( $config->{default_action_use_path} ) {
        my $action = $self->{c}->{request}->base . $self->{c}->{request}->path;

        $self->{c}->log->debug("FormFu - Setting default action by path: $action")
            if $self->{c}->debug;

        $form->action($action);
    }

    my $context_stash = $config->{context_stash};
    $form->stash->{$context_stash} = $self->{c};
    weaken( $form->stash->{$context_stash} );

    my $model_stash = $config->{model_stash};

    for my $model ( keys %$model_stash ) {
        $form->stash->{$model} = $self->{c}->model( $model_stash->{$model} );
    }

    return;
}

sub create_action {
    my $self = shift;
    my %args = @_;

    my $config = $self->_html_formfu_config;

    for my $type (
        qw/
        form
        config
        method
        multiform
        multiform_config
        multiform_method /
    ) {
        my $attr = $config->{"${type}_attr"};

        if ( exists $args{attributes}{$attr} ) {
            $args{_attr_params} = delete $args{attributes}{$attr};
        }
        elsif ( exists $args{attributes}{"$attr()"} ) {
            $args{_attr_params} = delete $args{attributes}{"$attr()"};
        }
        else {
            next;
        }

        push @{ $args{attributes}{ActionClass} }, $config->{"${type}_action"};
        last;
    }

    $self->SUPER::create_action(%args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Controller::HTML::FormFu - Catalyst integration for HTML::FormFu

=head1 VERSION

version 2.04

=head1 SYNOPSIS

    package MyApp::Controller::My::Controller;

    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; }

    sub index : Local {
        my ( $self, $c ) = @_;

        # doesn't use an Attribute to make a form
        # can get an empty form from $self->form()

        my $form = $self->form();
    }

    sub foo : Local : Form {
        my ( $self, $c ) = @_;

        # using the Form attribute is equivalent to:
        #
        # my $form = $self->form;
        #
        # $form->process;
        #
        # $c->stash->{form} = $form;
    }

    sub bar : Local : FormConfig {
        my ( $self, $c ) = @_;

        # using the FormConfig attribute is equivalent to:
        #
        # my $form = $self->form;
        #
        # $form->load_config_filestem('root/forms/my/controller/bar');
        #
        # $form->process;
        #
        # $c->stash->{form} = $form;
        #
        # so you only need to do the following...

        my $form = $c->stash->{form};

        if ( $form->submitted_and_valid ) {
            do_something();
        }
    }

    sub baz : Local : FormConfig('my_config') {
        my ( $self, $c ) = @_;

        # using the FormConfig attribute with an argument is equivalent to:
        #
        # my $form = $self->form;
        #
        # $form->load_config_filestem('root/forms/my_config');
        #
        # $form->process;
        #
        # $c->stash->{form} = $form;
        #
        # so you only need to do the following...

        my $form = $c->stash->{form};

        if ( $form->submitted_and_valid ) {
            do_something();
        }
    }

    sub quux : Local : FormMethod('load_form') {
        my ( $self, $c ) = @_;

        # using the FormMethod attribute with an argument is equivalent to:
        #
        # my $form = $self->form;
        #
        # $form->populate( $c->load_form );
        #
        # $form->process;
        #
        # $c->stash->{form} = $form;
        #
        # so you only need to do the following...

        my $form = $c->stash->{form};

        if ( $form->submitted_and_valid ) {
            do_something();
        }
    }

    sub load_form {
        my ( $self, $c ) = @_;

        # Automatically called by the above FormMethod('load_form') action.
        # Called as a method on the controller object, with the context
        # object as an argument.

        # Must return a hash-ref suitable to be fed to $form->populate()
    }

You can also use specially-named actions that will only be called under certain
circumstances.

    sub edit : Chained('group') : PathPart : Args(0) : FormConfig { }

    sub edit_FORM_VALID {
        my ( $self, $c ) = @_;

        my $form  = $c->stash->{form};
        my $group = $c->stash->{group};

        $form->model->update( $group );

        $c->response->redirect( $c->uri_for( '/group', $group->id ) );
    }

    sub edit_FORM_NOT_SUBMITTED {
        my ( $self, $c ) = @_;

        my $form  = $c->stash->{form};
        my $group = $c->stash->{group};

        $form->model->default_values( $group );
    }

=head1 METHODS

=head2 form

This creates a new L<HTML::FormFu> object, passing as it's argument the
contents of the L</constructor> config value.

This is useful when using the ConfigForm() or MethodForm() action attributes,
to create a 2nd form which isn't populated using a config-file or method return
value.

    sub foo : Local {
        my ( $self, $c ) = @_;

        my $form = $self->form;
    }

Note that when using this method, the form's L<query|HTML::FormFu/query> method
is not populated with the Catalyst request object.

=head1 SPECIAL ACTION NAMES

An example showing how a complicated action method can be broken down into
smaller sections, making it clearer which code will be run, and when.

    sub edit : Local : FormConfig {
        my ( $self, $c ) = @_;

        my $form  = $c->stash->{form};
        my $group = $c->stash->{group};

        $c->detach('/unauthorised') unless $c->user->can_edit( $group );

        if ( $form->submitted_and_valid ) {
            $form->model->update( $group );

            $c->response->redirect( $c->uri_for('/group', $group->id ) );
            return;
        }
        elsif ( !$form->submitted ) {
            $form->model->default_values( $group );
        }

        $self->_add_breadcrumbs_nav( $c, $group );
    }

Instead becomes...

    sub edit : Local : FormConfig {
        my ( $self, $c ) = @_;

        $c->detach('/unauthorised') unless $c->user->can_edit(
            $c->stash->{group}
        );
    }

    sub edit_FORM_VALID {
        my ( $self, $c ) = @_;

        my $group = $c->stash->{group};

        $c->stash->{form}->model->update( $group );

        $c->response->redirect( $c->uri_for('/group', $group->id ) );
    }

    sub edit_FORM_NOT_SUBMITTED {
        my ( $self, $c ) = @_;

        $c->stash->{form}->model->default_values(
            $c->stash->{group}
        );
    }

    sub edit_FORM_RENDER {
        my ( $self, $c ) = @_;

        $self->_add_breadcrumbs_nav( $c, $c->stash->{group} );
    }

For any action method that uses a C<Form>, C<FormConfig> or C<FormMethod>
attribute, you can add extra methods that use the naming conventions below.

These methods will be called after the original, plainly named action method.

=head2 _FORM_VALID

Run when the form has been submitted and has no errors.

=head2 _FORM_SUBMITTED

Run when the form has been submitted, regardless of whether or not there was
errors.

=head2 _FORM_COMPLETE

For MultiForms, is run if the MultiForm is completed.

=head2 _FORM_NOT_VALID

Run when the form has been submitted and there were errors.

=head2 _FORM_NOT_SUBMITTED

Run when the form has not been submitted.

=head2 _FORM_NOT_COMPLETE

For MultiForms, is run if the MultiForm is not completed.

=head2 _FORM_RENDER

For normal C<Form> base classes, this subroutine is run after any of the other
special methods, unless C<< $form->submitted_and_valid >> is true.

For C<MultiForm> base classes, this subroutine is run after any of the other
special methods, unless C<< $multi->complete >> is true.

=head1 CUSTOMIZATION

You can set your own config settings, using either your controller config or
your application config.

    $c->config( 'Controller::HTML::FormFu' => \%my_values );

    # or

    MyApp->config( 'Controller::HTML::FormFu' => \%my_values );

    # or, in myapp.conf

    <Controller::HTML::FormFu>
        default_action_use_path 1
    </Controller::HTML::FormFu>

=head2 form_method

Override the method-name used to create a new form object.

See L</form>.

Default value: C<form>.

=head2 form_stash

Sets the stash key name used to store the form object.

Default value: C<form>.

=head2 form_attr

Sets the attribute name used to load the
L<Catalyst::Controller::HTML::FormFu::Action::Form> action.

Default value: C<Form>.

=head2 config_attr

Sets the attribute name used to load the
L<Catalyst::Controller::HTML::FormFu::Action::Config> action.

Default value: C<FormConfig>.

=head2 method_attr

Sets the attribute name used to load the
L<Catalyst::Controller::HTML::FormFu::Action::Method> action.

Default value: C<FormMethod>.

=head2 form_action

Sets which package will be used by the Form() action.

Probably only useful if you want to create a sub-class which provides custom
behaviour.

Default value: C<Catalyst::Controller::HTML::FormFu::Action::Form>.

=head2 config_action

Sets which package will be used by the Config() action.

Probably only useful if you want to create a sub-class which provides custom
behaviour.

Default value: C<Catalyst::Controller::HTML::FormFu::Action::Config>.

=head2 method_action

Sets which package will be used by the Method() action.

Probably only useful if you want to create a sub-class which provides custom
behaviour.

Default value: C<Catalyst::Controller::HTML::FormFu::Action::Method>.

=head2 constructor

Pass common defaults to the L<HTML::FormFu constructor|HTML::FormFu/new>.

These values are used by all of the action attributes, and by the C<<
$self->form >> method.

Default value: C<{}>.

=head2 config_callback

Arguments: bool

If true, a coderef is passed to C<< $form->config_callback->{plain_value} >>
which replaces any instance of C<__uri_for(URI)__> found in form config files
with the result of passing the C<URI> argument to L<Catalyst/uri_for>.

The form C<< __uri_for(URI, PATH, PARTS)__ >> is also supported, which is
equivalent to C<< $c->uri_for( 'URI', \@ARGS ) >>. At this time, there is no
way to pass query values equivalent to C<< $c->uri_for( 'URI', \@ARGS,
\%QUERY_VALUES ) >>.

The second codeword that is being replaced is C<__path_to( @DIRS )__>. Any
instance is replaced with the result of passing the C<DIRS> arguments to
L<Catalyst/path_to>. Don't use qoutationmarks as they would become part of the
path.

Default value: 1

=head2 default_action_use_name

If set to a true value the action for the form will be set to the currently
called action name.

Default value: C<false>.

=head2 default_action_use_path

If set to a true value the action for the form will be set to the currently
called action path. The action path includes concurrent to action name
additioal parameters which were code inside the path.

Default value: C<false>.

Example:

    action: /foo/bar
    called uri contains: /foo/bar/1

    # default_action_use_name => 1 leads to:
    $form->action = /foo/bar

    # default_action_use_path => 1 leads to:
    $form->action = /foo/bar/1

=head2 model_stash

Arguments: \%stash_keys_to_model_names

Used to place Catalyst models on the form stash.

If it's being used to make a L<DBIx::Class> schema available for
L<HTML::FormFu::Model::DBIC/options_from_model>, for C<Select> and other
Group-type elements - then the hash-key must be C<schema>. For example, if your
schema model class is C<MyApp::Model::MySchema>, you would set C<model_stash>
like so:

    <Controller::HTML::FormFu>
        <model_stash>
            schema MySchema
        </model_stash>
    </Controller::HTML::FormFu>

=head2 context_stash

To allow your form validation packages, etc, access to the catalyst context, a
weakened reference of the context is copied into the form's stash.

    $form->stash->{context};

This setting allows you to change the key name used in the form stash.

Default value: C<context>

=head2 languages_from_context

If you're using a L10N / I18N plugin such as L<Catalyst::Plugin::I18N> which
provides a C<languages> method that returns a list of valid languages to use
for the currect request - and you want to use formfu's built-in I18N packages,
then setting L</languages_from_context>

=head2 localize_from_context

If you're using a L10N / I18N plugin such as L<Catalyst::Plugin::I18N> which
provides it's own C<localize> method, you can set L<localize_from_context> to
use that method for formfu's localization.

=head2 request_token_enable

If true, adds an instance of L<HTML::FormFu::Plugin::RequestToken> to every
form, to stop accidental double-submissions of data and to prevent CSRF
attacks.

=head2 request_token_field_name

Defaults to C<_token>.

=head2 request_token_session_key

Defaults to C<__token>.

=head2 request_token_expiration_time

Defaults to C<3600>.

=head1 DISCONTINUED CONFIG SETTINGS

=head2 config_file_ext

Support for this has now been removed. Config files are now searched for, with
any file extension supported by Config::Any.

=head2 config_file_path

Support for this has now been removed. Use C<< {constructor}{config_file_path}
>> instead.

=head1 CAVEATS

When using the C<Form> action attribute to create an empty form, you must call
L<< $form->process|HTML::FormFu/process >> after populating the form. However,
you don't need to pass any arguments to C<process>, as the Catalyst request
object will have automatically been set in L<< $form->query|HTML::FormFu/query
>>.

When using the C<FormConfig> and C<FormMethod> action attributes, if you make
any modifications to the form, such as adding or changing it's elements, you
must call L<< $form->process|HTML::FormFu/process >> before rendering the form.

=head1 AUTHORS

=over 4

=item *

Carl Franks <cpan@fireartist.com>

=item *

Nigel Metheringham <nigelm@cpan.org>

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007-2018 by Carl Franks / Nigel Metheringham / Dean Hamstead.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Catalyst::Controller::HTML::FormFu

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Catalyst-Controller-HTML-FormFu>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Catalyst-Controller-HTML-FormFu>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Controller-HTML-FormFu>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Catalyst-Controller-HTML-FormFu>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Catalyst-Controller-HTML-FormFu>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Catalyst-Controller-HTML-FormFu>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Catalyst-Controller-HTML-FormFu>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/C/Catalyst-Controller-HTML-FormFu>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Catalyst-Controller-HTML-FormFu>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Catalyst::Controller::HTML::FormFu>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-catalyst-controller-html-formfu at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Catalyst-Controller-HTML-FormFu>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/FormFu/Catalyst-Controller-HTML-FormFu>

  git clone https://github.com/FormFu/Catalyst-Controller-HTML-FormFu.git

=head1 CONTRIBUTORS

=for stopwords Aran Deltac bricas dandv fireartist lestrrat marcusramberg mariominati Moritz Onken Nigel Metheringham omega Petr Písař

=over 4

=item *

Aran Deltac <aran@ziprecruiter.com>

=item *

bricas <brian.cassidy@gmail.com>

=item *

dandv <ddascalescu@gmail.com>

=item *

fireartist <fireartist@gmail.com>

=item *

lestrrat <lestrrat+github@gmail.com>

=item *

marcusramberg <marcus.ramberg@gmail.com>

=item *

mariominati <mario.minati@googlemail.com>

=item *

Moritz Onken <1nd@gmx.de>

=item *

Moritz Onken <onken@netcubed.de>

=item *

Nigel Metheringham <nm9762github@muesli.org.uk>

=item *

omega <andreas.marienborg@gmail.com>

=item *

Petr Písař <ppisar@redhat.com>

=back

=cut
