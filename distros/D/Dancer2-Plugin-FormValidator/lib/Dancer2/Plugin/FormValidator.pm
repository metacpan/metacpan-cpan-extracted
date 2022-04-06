package Dancer2::Plugin::FormValidator;

use 5.24.0;

use Dancer2::Plugin;
use Dancer2::Core::Hook;
use Dancer2::Plugin::FormValidator::Config;
use Dancer2::Plugin::FormValidator::Registry;
use Dancer2::Plugin::FormValidator::Processor;
use Storable qw(dclone);
use Hash::Util qw(lock_hashref);
use Module::Load;
use Types::Standard qw(InstanceOf HashRef);

our $VERSION = '0.50';

plugin_keywords qw(validate_form errors validator_language);

has config_obj => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::FormValidator::Config'],
    required => 1,
    builder  => sub {
        return Dancer2::Plugin::FormValidator::Config->new(
            config => shift->config,
        );
    }
);

has plugin_deferred => (
    is       => 'ro',
    isa      => InstanceOf ['Dancer2::Plugin::Deferred'],
    required => 1,
    builder  => sub {
        return shift->app->with_plugin('Dancer2::Plugin::Deferred');
    }
);

has extensions => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub {
        return shift->config->{extensions} // {},
    }
);

sub BUILD {
    my $self = shift;

    $self->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template_render',
            code => sub {
                my $tokens = shift;
                my $errors = {};
                my $old    = {};

                if (my $deferred = $tokens->{deferred}->{$self->config_obj->session_namespace}) {
                    $errors = delete $deferred->{messages};
                    $old    = delete $deferred->{old};
                }

                $tokens->{errors} = $errors;
                $tokens->{old}    = $old;

                return;
            },
        )
    );
}

sub validator_language {
    shift->config_obj->language(shift);
    return;
}

sub validate_form {
    my ($self, $form) = @_;

    if (my $validator_profile = $self->config_obj->form($form)) {
        autoload $validator_profile;

        my $input  = $self->dsl->body_parameters->as_hashref_mixed;
        my $result = $self->validate($input, $validator_profile->new);

        return $result->success ? $result->valid : undef;
    }
    else {
        Carp::croak "Validator for $form is not defined\n";
    }
}

sub validate {
    my ($self, $input, $validator_profile) = @_;

    if (ref $input ne 'HASH') {
        Carp::croak "Input data should be a hash reference\n";
    }

    my $role = 'Dancer2::Plugin::FormValidator::Role::Profile';
    if (not $validator_profile->does($role)) {
        my $name = $validator_profile->meta->name;
        Carp::croak "$name should implement $role\n";
    }

    my $processor = Dancer2::Plugin::FormValidator::Processor->new(
        input             => $self->_clone_and_lock_input($input),
        config            => $self->config_obj,
        registry          => $self->_registry,
        validator_profile => $validator_profile,
    );

    my $result = $processor->result;

    if ($result->success != 1) {
        $self->plugin_deferred->deferred(
            $self->config_obj->session_namespace,
            {
                messages => $result->messages,
                old      => $input,
            },
        );
    }

    return $result;
}

sub _clone_and_lock_input {
    # Copy input to work with isolated HashRef.
    my $input = dclone($_[1]);

    # Lock input to prevent accidental modifying.
    return lock_hashref($input);
}

sub _registry {
    my $self = shift;

    # First build extensions.
    my @extensions = map
    {
        my $extension = $self->extensions->{$_}->{provider};
        autoload $extension;

        $extension->new(
            plugin => $self,
            config => $self->extensions->{$_},
        );
    }
        keys %{ $self->extensions };

    return Dancer2::Plugin::FormValidator::Registry->new(
        extensions => \@extensions,
    );
}

sub errors {
    return shift->_get_deferred->{messages};
}

sub _get_deferred {
    my $self = shift;

    return $self->plugin_deferred->deferred($self->config_obj->session_namespace);
}

1;

__END__
# ABSTRACT: Dancer2 validation framework.

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::FormValidator - neat and easy to start form validation plugin for Dancer2.

=head1 VERSION

version 0.50

=head1 SYNOPSIS

    use Dancer2::Plugin::FormValidator;

    post '/form' => sub {
        if (my $valid_hash_ref = validate_form 'form') {
            save_user_input($valid_hash_ref);
            redirect '/success_page';
        }

        redirect '/form';
    };

=head1 DISCLAIMER

This is alpha version, not stable.

Interfaces may change in future:

=over 4

=item *
Template tokens: errors.

=item *
Roles: Dancer2::Plugin::FormValidator::Role::Extension, Dancer2::Plugin::FormValidator::Role::Validator.

=item *
Validators.

=back

Won't change:

=over 4

=item *
Dsl keywords: validate_form, validator_language, errors.

=item *
Template tokens: old.

=item *
Roles: Dancer2::Plugin::FormValidator::Role::Profile, Dancer2::Plugin::FormValidator::Role::HasMessages, Dancer2::Plugin::FormValidator::Role::ProfileHasMessages.

=back

If you like it - add it to your bookmarks. I intend to complete the development by the summer 2022.

B<Have any ideas?> Find this project on github (repo ref is at the bottom).
Help is always welcome!

=head1 DESCRIPTION

This is micro-framework that provides validation in your Dancer2 application.
It consists of dsl's keywords and a set of agreements.
It has a set of built-in validators that can be extended by compatible modules (extensions).
Also proved runtime switching between languages, so you can show proper error messages to users.

Uses simple and declarative approach to validate forms:

=head2 Validator

First, you need to create class which will implements
at least one main role: Dancer2::Plugin::FormValidator::Role::HasProfile.

This role requires profile method which should return a HashRef Data::FormValidator accepts:

    package App::Http::Validators::RegisterForm {
        use Moo;
        with 'Dancer2::Plugin::FormValidator::Role::Profile';

        sub profile {
            return {
                name  => [qw(required length_min:4 length_max:32)]
                email => [qw(required email)],
            };
        };
    }

=head2 Application

Then you need to set an form => validator association in config:

     set plugins => {
            FormValidator => {
                session => {
                    namespace => '_form_validator' # This is required field
                },
                forms   => {
                    register_form => 'App::App::Http::Validators::RegisterForm',
                },
            },
        };

Now you can validate POST parameters in your controller:

    use Dancer2::Plugin::FormValidator;

    post '/register' => sub {
        if (my $valid_hash_ref = validate_form 'register_form') {
            if (login($valid_hash_ref)) {
                redirect '/success_page';
            }
        }

        redirect '/register';
    };

    get '/register' => sub {
        template 'app/register' => {
            title  => 'Register page',
        };
    };

=head2 Template

In you template you have access to: $errors - this is HashRef with parameters names as keys
and error messages as ArrayRef values and $old - contains old input values.

Template app/register:

    <div class="w-3/4 max-w-md bg-white shadow-lg py-4 px-6">
        <form method="post" action="/register">
            <div class="py-2">
                <label class="block font-normal text-gray-400" for="name">
                    Name
                </label>
                <input
                        type="text"
                        id="name"
                        name="name"
                        value="<: $old[name] :>"
                        class="border border-2 w-full h-5 px-4 py-5 mt-1 rounded-md
                        hover:outline-none focus:outline-none focus:ring-1 focus:ring-indigo-100"
                >
                <: for $errors[name] -> $error { :>
                    <small class="pl-1 text-red-400"><: $error :></small>
                <: } :>
            </div>
            <div class="py-2">
                <label class="block font-normal text-gray-400" for="email">
                    Name
                </label>
                <input
                        type="text"
                        id="email"
                        name="email"
                        value="<: $old[email] :>"
                        class="border border-2 w-full h-5 px-4 py-5 mt-1 rounded-md
                        hover:outline-none focus:outline-none focus:ring-1 focus:ring-indigo-100"
                >
                <: for $errors[email] -> $error { :>
                    <small class="pl-1 text-red-400"><: $error :></small>
                <: } :>
            </div>
            <button
                    type="submit"
                    class="mt-4 bg-sky-600 text-white py-2 px-6 rounded-md hover:bg-sky-700"
            >
                Register
            </button>
        </form>
    </div>

=head1 CONFIGURATION

    ...
    plugins:
        FormValidator:
            session:
                namespace: '_form_validator' # this is required
            messages:
                language: en                 # this is default
                ucfirst: 1                   # this is default
                validators:
                    required:
                        en: %s is needed from config
                        de: %s ist erforderlich
                    ...
            forms:
                login_form: 'App::Http::Validators::LoginForm'
                support_form: 'App::Http::Validators::SupportForm'
                ...
            extensions:
                upload:
                    provider: ...
                    ...
    ...

=head1 DSL KEYWORDS

=head3 validate

    my $valid_hash_ref = validate_form $form

Returns $valid_hash_ref if validation succeed, otherwise returns undef.

=head3 validator_language

    validator_language $lang

=head3 errors

    my $errors_hash_multi = errors

Returns HashRef[ArrayRef] if validation failed.

=head1 Validators

=head3 accepted

=head3 alpha

Validate that string only contain of alphabetic utf8 symbols, i.e. /^[[:alpha:]]+$/.

=head3 alpha_ascii

Validate that string only contain of latin alphabetic ascii symbols, i.e. /^[[:alpha:]]+$/a.

=head3 alpha_num

Validate that string only contain of alphabetic utf8 symbols, underscore and numbers 0-9, i.e. /^\w+$/.

=head3 alpha_num_ascii

Validate that string only contain of latin alphabetic ascii symbols, underscore and numbers 0-9, i.e. /^\w+$/a.

=head3 email

=head3 email_dns

=head3 enum

=head3 integer

=head3 length_max

=head3 length_min

=head3 max

=head3 min

=head3 numeric

=head3 required

Validate that field exists and not empty string.

=head3 same

=head1 CUSTOM MESSAGES

To define custom error messages for fields/validators your Validator should implement
Role: Dancer2::Plugin::FormValidator::Role::ProfileHasMessages.

    package Validator {
        use Moo;

        with 'Dancer2::Plugin::FormValidator::Role::ProfileHasMessages';

        sub profile {
            return {
                name  => [qw(required)],
                email => [qw(required email)],
            };
        };

        sub messages {
            return {
                name => {
                    required => {
                        en => 'Specify your %s',
                    },
                },
                email => {
                    required => {
                        en => '%s is needed',
                    },
                    email => {
                        en => '%s please use valid email',
                    }
                }
            }
        }
    }

=head1 TODO

=over 4

=item *
Configuration details: list all fields and describe them.

=item *
Document with example and descriptions DSL's.

=item *
Document with example all validators.

=item *
Document all config field with explanation.

=item *
Document all Roles and HashRef structures.

=item *
Extensions docs.

=item *
Contribution and help details.

=back

=head1 BUGS AND LIMITATIONS

If you find one, please let me know.

=head1 SOURCE CODE REPOSITORY

L<https://github.com/AlexP007/dancer2-plugin-formvalidator|https://github.com/AlexP007/dancer2-plugin-formvalidator>.

=head1 AUTHOR

Alexander Panteleev <alexpan at cpan dot org>.

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Alexander Panteleev.
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
