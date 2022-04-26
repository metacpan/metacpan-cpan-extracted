package Dancer2::Plugin::FormValidator;

use 5.24.0;

use Dancer2::Plugin;
use Module::Load qw(autoload);
use Dancer2::Core::Hook;
use Dancer2::Plugin::FormValidator::Validator;
use Dancer2::Plugin::FormValidator::Config;
use Types::Standard qw(InstanceOf HashRef ArrayRef);

our $VERSION = '0.80';

# Global var for saving last success validation valid input.
my $valid_input;

plugin_keywords qw(validate validated errors);

has config_validator => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::FormValidator::Config'],
    builder  => sub {
        return Dancer2::Plugin::FormValidator::Config->new(
            config => shift->config,
        );
    }
);

has config_extensions => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub {
        return shift->config->{extensions} // {},
    }
);

has extensions => (
    is       => 'ro',
    isa      => ArrayRef,
    builder  => sub {
        my $self = shift;

        my @extensions = map {
            my $extension = $self->config_extensions->{$_}->{provider};
            autoload $extension;

            $extension->new(
                plugin => $self,
                config => $self->config_extensions->{$_},
            );
        } keys %{ $self->config_extensions };

        return \@extensions;
    }
);

has plugin_deferred => (
    is       => 'ro',
    isa      => InstanceOf ['Dancer2::Plugin::Deferred'],
    builder  => sub {
        return shift->app->with_plugin('Dancer2::Plugin::Deferred');
    }
);

sub BUILD {
    shift->_register_hooks;
    return;
}

sub validate {
    my ($self, %args) = @_;

    # We need to unset value of this global var.
    undef $valid_input;

    # Now works with arguments.
    my $profile = %args{profile};
    my $input   = %args{input} // $self->dsl->body_parameters->as_hashref_mixed;
    my $lang    = %args{lang};

    if (defined $lang) {
        $self->_validator_language($lang);
    }

    my $validator = Dancer2::Plugin::FormValidator::Validator->new(
        config            => $self->config_validator,
        input             => $input,
        extensions        => $self->extensions,
        validator_profile => $profile,
    );

    my $result = $validator->validate;

    if ($result->success != 1) {
        $self->plugin_deferred->deferred(
            $self->config_validator->session_namespace,
            {
                messages => $result->messages,
                old      => $input,
            },
        );

        return undef;
    }
    else {
        $valid_input = $result->valid;
        return $valid_input;
    }
}

sub validated {
    my $valid = $valid_input;
    undef $valid_input;

    return $valid;
}

sub errors {
    return shift->_get_deferred->{messages};
}

sub _register_hooks {
    my $self = shift;

    $self->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template_render',
            code => sub {
                my $tokens = shift;
                my $errors = {};
                my $old    = {};

                if (my $deferred = $tokens->{deferred}->{$self->config_validator->session_namespace}) {
                    $errors = delete $deferred->{messages};
                    $old    = delete $deferred->{old};
                }

                $tokens->{errors} = $errors;
                $tokens->{old}    = $old;

                return;
            },
        )
    );

    return;
}

sub _validator_language {
    shift->config_validator->language(shift);
    return;
}

sub _get_deferred {
    my $self = shift;
    return $self->plugin_deferred->deferred($self->config_validator->session_namespace);
}

1;

__END__
# ABSTRACT: Dancer2 validation framework.

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::FormValidator - neat and easy to start form validation plugin for Dancer2.

=head1 VERSION

version 0.80

=head1 SYNOPSIS

    ### If you need a simple and easy validation in your project,
    ### then this module is what you need.

    use Dancer2::Plugin::FormValidator;

    ### First create form validation profile class.

    package RegisterForm {
         use Moo;
         with 'Dancer2::Plugin::FormValidator::Role::Profile';

        ### Here you need to declare validators.

        sub profile {
            return {
                username     => [ qw(required alpha_num_ascii length_min:4 length_max:32) ],
                email        => [ qw(required email length_max:127) ],
                password     => [ qw(required length_max:40) ],
                password_cnf => [ qw(required same:password) ],
                confirm      => [ qw(required accepted) ],
            };
        }
    }

    ### Now you can use it in your Dancer2 project.

    post '/form' => sub {
        if (validate profile => RegisterForm->new) {
            my $valid_hash_ref = validated;

            save_user_input($valid_hash_ref);
            redirect '/success_page';
        }

        redirect '/form';
    };

The html result could be like:

=begin html

<p>
  <img alt="Screenshot register form" src="https://raw.githubusercontent.com/AlexP007/dancer2-plugin-formvalidator/main/assets/screenshot_register.png" width="500px">
</p>

=end html

=head1 DISCLAIMER

This is alpha version, not stable.

Interfaces may change in future:

=over 4

=item *
Roles: Dancer2::Plugin::FormValidator::Role::Extension, Dancer2::Plugin::FormValidator::Role::Validator.

=item *
Validators.

=back

Won't change:

=over 4

=item *
Dsl keywords.

=item *
Template tokens.

=item *
Roles: Dancer2::Plugin::FormValidator::Role::Profile, Dancer2::Plugin::FormValidator::Role::HasMessages, Dancer2::Plugin::FormValidator::Role::ProfileHasMessages.

=back

If you like it - add it to your bookmarks. I intend to complete the development by the summer 2022.

B<Have any ideas?> Find this project on github (repo ref is at the bottom).
Help is always welcome!

=head1 DESCRIPTION

This is micro-framework that provides validation in your Dancer2 application.
It consists of dsl's keywords: validate, validator_language, errors.
It has a set of built-in validators that can be extended by compatible modules (extensions).
Also proved runtime switching between languages, so you can show proper error messages to users.

Uses simple and declarative approach to validate forms:

=head2 Validator

First, you need to create class which will implements
at least one main role: Dancer2::Plugin::FormValidator::Role::Profile.

This role requires profile method which should return a HashRef Data::FormValidator accepts:

    package RegisterForm

    use Moo;
    with 'Dancer2::Plugin::FormValidator::Role::Profile';

    sub profile {
        return {
            username     => [ qw(required alpha_num_ascii length_min:4 length_max:32) ],
            email        => [ qw(required email length_max:127) ],
            password     => [ qw(required length_max:40) ],
            password_cnf => [ qw(required same:password) ],
            confirm      => [ qw(required accepted) ],
        };
    };

=head3 Profile method

Profile method should always return a HashRef[ArrayRef] where keys are input fields names
and values are ArrayRef with list of validators.

=head2 Application

Then you need to set basic configuration:

     set plugins => {
            FormValidator => {
                session => {
                    namespace => '_form_validator' # This is required field
                },
            },
        };

Now you can validate POST parameters in your controller:

    use Dancer2::Plugin::FormValidator;
    use RegisterForm;

    post '/register' => sub {
        if (my $valid_hash_ref = validate profile => RegisterForm->new) {
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

In you template you have access to: $errors - this is HashRef with fields names as keys
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

            <!-- Other fields -->
            ...
            ...
            ...
            <!-- Other fields end -->

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
                namespace: '_form_validator'         # this is required
            messages:
                language: en                         # this is default
                ucfirst: 1                           # this is default
                validators:
                    required:
                        en: %s is needed from config # custom en message
                        de: %s ist erforderlich      # custom de message
                    ...
            extensions:
                dbic:
                    provider: Dancer2::Plugin::FormValidator::Extension::DBIC
                    ...
    ...

=head2 session

=head3 namespace

Session storage key where this module stores data, like: errors or old vars.

=head2 messages

=head3 language

Default language for error messages.

=head3 ucfirst

Apply ucfirst function to messages or not.

=head3 validators

Key => values, where key is validator name and value is messages
dictionary for different languages.

=head2 extensions

Key => values, where key is extension short name and values is its configuration.

=head1 DSL KEYWORDS

=head3 validate

    validate(Hash $params): HashRef|undef

Accept arguments as hash:

    (
        profile => Object implementing Dancer2::Plugin::FormValidator::Role::Profile # required
        input   => HashRef of values to validate, default is body_parameters->as_hashref_mixed
        lang    => Accepts two-lettered language id, default is 'en'
    )

Profile is required, input and lang is optional.

Returns valid input HashRef if validation succeed, otherwise returns undef.

    ### You can use HashRef returned from validate.

    if (my $valid_hash_ref = validate profile => RegisterForm->new) {
        # Success, data is valid.
    }


    ### Or more declarative approach with validated keyword.

    if (validate profile => RegisterForm->new) {
        # Success, data is valid.
        my $valid_hash_ref = validated;

        # Do some operations...
    }
    else {
        # Error, data is invalid.
        my $errors = errors; # errors keyword returns error messages.

        # Redirect or show errors...
    }

=head3 validated

    validated(): HashRef|undef

No arguments.
Returns valid input HashRef if validate succeed.
Undef value will be returned after first call within one validation process.

    my $valid_hash_ref = validated;

=head3 errors

    errors(): HashRef

No arguments.
Returns HashRef[ArrayRef] if validation failed.

    my $errors_hash_multi = errors;

=head1 Validators

=head3 accepted

Validates that field B<exists> and one of the listed: (yes on 1).

    field => [ qw(accepted) ]

=head3 alpha:encoding=ascii

Validate that string only contain of alphabetic symbols.
By default encoding is ascii, i.e /^[[:alpha:]]+$/a.

    field => [ qw(alpha) ]

To set encoding to unicode you need to pass 'u' argument:

    field => [ qw(alpha:u) ]

Then the validation rule will be /^[[:alpha:]]+$/.

=head3 alpha_num

Validate that string only contain of alphabetic symbols, underscore and numbers 0-9.
By default encoding is ascii, i.e. /^\w+$/a.

    field => [ qw(alpha_num) ]

To set encoding to unicode you need to pass 'u' argument:

    field => [ qw(alpha_num:u) ]

Rule will be /^\w+$/.

=head3 email

Validate that field is valid email(rfc822).

    field => [ qw(email) ]

=head3 email_dns

Validate that field is valid email(rfc822) and dns exists.

    field => [ qw(email_dns) ]

=head3 enum:value1,value2

Validate that field is one of listed values.

    field => [ qw(enum:value1,value2) ]

=head3 integer

Validate that field is integer.

    field => [ qw(integer) ]

=head3 length_max:num

Validate that string length <= num.

    field => [ qw(length_max:32) ]

=head3 length_min:num

Validate that string length >= num.

    field => [ qw(length_max:4) ]

=head3 max:num

Validate that field is number <= num.

    field => [ qw(max:32) ]

=head3 min:num

Validate that field is number >= num.

    field => [ qw(min:4) ]

=head3 numeric

Validate that field is number.

    field => [ qw(numeric) ]

=head3 required

Validate that field exists and not empty string.

    field => [ qw(required) ]

=head3 same:field

Validate that field is exact value as another.

    field_1 => [ qw(required) ]
    field_2 => [ qw(required same:field_1) ]

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
        }

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
            };
        }
    }

=head1 EXTENSIONS

=head2 Writing custom extensions

You can extend the set of validators by writing extensions:

    package Extension {
        use Moo;

        with 'Dancer2::Plugin::FormValidator::Role::Extension';

        sub validators {
            return {
                is_true  => 'IsTrue',   # Full class name
                email    => 'Email',    # Full class name
                restrict => 'Restrict', # Full class name
            }
        }
    }

Extension should implement Role: Dancer2::Plugin::FormValidator::Role::Extension.

Custom validators:

    package IsTrue {
        use Moo;

        with 'Dancer2::Plugin::FormValidator::Role::Validator';

        sub message {
            return {
                en => '%s is not a true value',
            };
        }

        sub validate {
            my ($self, $field, $input) = @_;

            if (exists $input->{$field}) {
                if ($input->{$field} == 1) {
                    return 1;
                }
                else {
                    return 0;
                }
            }

            return 1;
        }
    }

Validator should implement Role: Dancer2::Plugin::FormValidator::Role::Validator.

Config:

    set plugins => {
        FormValidator => {
            session    => {
                namespace => '_form_validator'
            },
            extensions => {
                extension => {
                    provider => 'Extension',
                }
            }
        },
    };

=head2 Extensions modules

There is a set of ready-made extensions available on cpan:

=over 4

=item *
L<Dancer2::Plugin::FormValidator::Extension::Password|https://metacpan.org/pod/Dancer2::Plugin::FormValidator::Extension::Password>
- for validating passwords.

=item *
L<Dancer2::Plugin::FormValidator::Extension::DBIC|https://metacpan.org/pod/Dancer2::Plugin::FormValidator::Extension::DBIC>
- for checking fields existence in table rows.

=back

=head1 TODO

=over 4

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
