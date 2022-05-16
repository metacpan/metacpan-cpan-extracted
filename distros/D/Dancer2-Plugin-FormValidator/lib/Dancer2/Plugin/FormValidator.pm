package Dancer2::Plugin::FormValidator;

use 5.24.0;
use strict;
use warnings;

use Dancer2::Plugin;
use Dancer2::Core::Hook;
use Dancer2::Plugin::FormValidator::Config;
use Dancer2::Plugin::FormValidator::Factory::Extensions;
use Dancer2::Plugin::FormValidator::Registry;
use Dancer2::Plugin::FormValidator::Input;
use Dancer2::Plugin::FormValidator::Processor;
use Types::Standard qw(InstanceOf);

our $VERSION = '1.00';

plugin_keywords qw(validate validated errors);

has validator_config => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::FormValidator::Config'],
    lazy     => 1,
    builder  => sub {
        return Dancer2::Plugin::FormValidator::Config->new(
            config => $_[0]->config,
        );
    }
);

has registry => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::FormValidator::Registry'],
    lazy     => 1,
    default  => sub {
        my $factory = Dancer2::Plugin::FormValidator::Factory::Extensions->new(
            plugin     => $_[0],
            extensions => $_[0]->config->{extensions} // {},
        );

        return Dancer2::Plugin::FormValidator::Registry->new(
            extensions => $factory->build,
        );
    }
);

has plugin_deferred => (
    is       => 'ro',
    isa      => InstanceOf['Dancer2::Plugin::Deferred'],
    lazy     => 1,
    builder  => sub {
        return $_[0]->app->with_plugin('Dancer2::Plugin::Deferred');
    }
);

# Var for saving last success validation valid input.
has valid => (
    is       => 'rwp',
    clearer  => 1,
);

sub BUILD {
    $_[0]->_register_hooks;
    return;
}

sub validate {
    my ($self, %args) = @_;

    # We need to unset value of this var (if there was something).
    $self->clear_valid;

    # Arguments.
    my $profile = $args{profile};
    my $input   = $args{input} // $self->dsl->body_parameters->as_hashref_mixed;
    my $lang    = $args{lang};

    if (defined $lang) {
        $self->_validator_language($lang);
    }

    my $processor = Dancer2::Plugin::FormValidator::Processor->new(
        input    => Dancer2::Plugin::FormValidator::Input->new(input => $input),
        profile  => $profile,
        config   => $self->validator_config,
        registry => $self->registry,
    );

    my $result = $processor->run;

    if ($result->success != 1) {
        $self->plugin_deferred->deferred(
            $self->validator_config->session_namespace,
            {
                messages => $result->messages,
                old      => $input,
            },
        );
        return undef;
    }
    else {
        $self->_set_valid($result->valid);

        return $self->valid;
    }
}

sub validated {
    return $_[0]->valid;
}

sub errors {
    return $_[0]->_get_deferred->{messages};
}

# Register Dancer2 hook to add custom template tokens: errors, old.
sub _register_hooks {
    my ($self) = @_;

    $self->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template_render',
            code => sub {
                my ($tokens) = @_;

                my $errors   = {};
                my $old      = {};

                if (my $deferred = $tokens->{deferred}->{$self->validator_config->session_namespace}) {
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

# Set validator to language to $lang.
sub _validator_language {
    my ($self, $lang) = @_;

    $self->validator_config->language($lang);
    return;
}

# Returned deferred message from session storage.
sub _get_deferred {
    return $_[0]->plugin_deferred->deferred(
        $_[0]->validator_config->session_namespace
    );
}

1;

__END__
# ABSTRACT: Dancer2 validation framework.

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::FormValidator - neat and easy to start form validation plugin for Dancer2.

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    ### If you need a simple and easy validation in your project,
    ### This module is what you need.

    use Dancer2;
    use Dancer2::Plugin::FormValidator;

    ### First create form validation profile class.

    package RegisterForm {
        use Moo;
        with 'Dancer2::Plugin::FormValidator::Role::Profile';

        ### Here you need to declare fields => validators.

        sub profile {
            return {
                username     => [ qw(required alpha_num length_min:4 length_max:32) ],
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

=head1 DESCRIPTION

This is micro-framework that provides validation in your Dancer2 application.
It consists of dsl's keywords: validate, validated, errors.
It has a set of built-in validators that can be extended by compatible modules (extensions).
Also proved runtime switching between languages, so you can show proper error messages to users.

This module has a minimal set of dependencies and does not require the mandatory use of DBIc or Moose.

Uses simple and declarative approach to validate forms.

=head2 Validator

First, you need to create class which will implements
at least one main role: Dancer2::Plugin::FormValidator::Role::Profile.

This role requires profile method which should return a I<HashRef> Data::FormValidator accepts:

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

Profile method should always return a I<HashRef[ArrayRef]> where keys are input fields names
and values are ArrayRef with list of validators.

=head2 Application

Then you need to set basic configuration:

    use Dancer2;

     set plugins => {
            FormValidator => {
                session => {
                    namespace => '_form_validator' # This is required field
                },
            },
        };

Now you can validate POST parameters in your controller:

    use Dancer2;
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

In you template you have access to: $errors - this is I<HashRef[ArrayRef]> with fields names as keys
and error messages values and $old - contains old input values.

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

Returns valid input I<HashRef> if validation succeed, otherwise returns undef.

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
Returns valid input I<HashRef> if validate succeed.
I<Undef> value will be returned after first call within one validation process.

    my $valid_hash_ref = validated;

=head3 errors

    errors(): HashRef

No arguments.
Returns I<HashRef[ArrayRef]> if validation failed.

    my $errors_hash_multi = errors;

=head1 Validators

=head3 accepted

    accepted(): Bool

Validates that field B<exists> and one of the listed: (yes on 1).

    field => [ qw(accepted) ]

=head3 alpha

    alpha(String $encoding = 'a'): Bool

Validate that string only contain of alphabetic symbols.
By default encoding is ascii, i.e B</^[[:alpha:]]+$/a>.

    field => [ qw(alpha) ]

To set encoding to unicode you need to pass 'u' argument:

    field => [ qw(alpha:u) ]

Then the validation rule will be B</^[[:alpha:]]+$/>.

=head3 alpha_num

    alpha_num(String $encoding = 'a'): Bool

Validate that string only contain of alphabetic symbols, underscore and numbers 0-9.
By default encoding is ascii, i.e. B</^\w+$/a>.

    field => [ qw(alpha_num) ]

To set encoding to unicode you need to pass 'u' argument:

    field => [ qw(alpha_num:u) ]

Rule will be B</^\w+$/>.

=head3 email

    email(): Bool

Validate that field is valid email(B<rfc822>).

    field => [ qw(email) ]

=head3 email_dns

    email_dns(): Bool

Validate that field is valid email(B<rfc822>) and dns exists.

    field => [ qw(email_dns) ]

=head3 enum

    enum(Array @values): Bool

Validate that field is one of listed values.

    field => [ qw(enum:value1,value2) ]

=head3 integer

    integer(): Bool

Validate that field is integer.

    field => [ qw(integer) ]

=head3 length_max

    length_max(Int $num): Bool

Validate that string length <= num.

    field => [ qw(length_max:32) ]

=head3 length_min

    length_min(Int $num): Bool

Validate that string length >= num.

    field => [ qw(length_max:4) ]

=head3 max

    max(Int $num): Bool

Validate that field is number <= num.

    field => [ qw(max:32) ]

=head3 min

    min(Int $num): Bool

Validate that field is number >= num.

    field => [ qw(min:4) ]

=head3 numeric

    numeric(): Bool

Validate that field is number.

    field => [ qw(numeric) ]

=head3 required

    required(): Bool

Validate that field exists and not empty string.

    field => [ qw(required) ]

=head3 required_with

    required_with(String $field_name): Bool

Validate that field exists and not empty string if another field is exists and not empty.

    field_1 => [ qw(required) ]
    field_2 => [ qw(required_with:field_1) ]

=head3 same

    same(String $field_name): Bool

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

=head1 HOOKS

There is hook_before method available, which allows your Profile object to make
decisions depending on the input data. You could use it with Moo around modifier:

    around hook_before => sub {
        my ($orig, $self, $profile, $input) = @_;

        # If there is specific input value.
        if ($input->{name} eq 'Secret') {
            # Delete all validators for field 'surname'.
            delete $profile->{surname};
        }

        return $orig->($self, $profile, $input);
    };

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

B<Hint:> you could reassign built-in validator with your custom one.

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

=head1 ROLES

=over 4

=item *
Dancer2::Plugin::FormValidator::Role::Profile - for profile classes.

=item *
Dancer2::Plugin::FormValidator::Role::HasMessages - for classes, that implements custom error messages.

=item *
Dancer2::Plugin::FormValidator::Role::ProfileHasMessages - brings together Profile and HasMassages.

=item *
Dancer2::Plugin::FormValidator::Role::Extension - for extension classes.

=item *
Dancer2::Plugin::FormValidator::Role::Validator - for custom validators.

=back

=head1 HINTS

If you don't want to create separated classes for your validation logic,
you could create one base class and reuse it in your project.

    ### Validator class

    package Validator {
        use Moo;
        with 'Dancer2::Plugin::FormValidator::Role::Profile';

        has profile_hash => (
            is       => 'ro',
            required => 1,
        );

        sub profile {
            return $_[0]->profile_hash;
        }
    }

    ### Application

    use Dancer2

    my $validator = Validator->new(profile_hash =>
        {
            email => [qw(required email)],
        }
    );

    post '/subscribe' => sub {
        if (not validate profile => $validator) {
            to_json errors;
        }
    };

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
