package Dancer2::Plugin::FormValidator;

use Dancer2::Plugin;
use Dancer2::Core::Hook;
use Dancer2::Plugin::Deferred;
use Dancer2::Plugin::FormValidator::Config;
use Dancer2::Plugin::FormValidator::Processor;
use Data::FormValidator;
use Types::Standard qw(InstanceOf);

our $VERSION = '0.13';

plugin_keywords qw(validate validate_form errors);

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

sub validate_form {
    my ($self, $form) = @_;

    if (my $validator = $self->config_obj->form($form)) {
        my $input  = $self->dsl->body_parameters->as_hashref;
        my $result = $self->validate($input, $validator->new);

        return $result->success ? $result->valid : undef;
    }
    else {
        Carp::croak "Validator for $form is not defined\n";
    }
}

sub validate {
    my ($self, $input, $validator) = @_;

    if (ref $input ne 'HASH') {
        Carp::croak "Input data should be a hash reference\n";
    }

    my $role = 'Dancer2::Plugin::FormValidator::Role::HasProfile';
    if (not $validator->does($role)) {
        my $name = $validator->meta->name;
        Carp::croak "$name should implement $role\n";
    }

    my $processor = Dancer2::Plugin::FormValidator::Processor->new(
        config    => $self->config_obj,
        validator => $validator,
        results   => Data::FormValidator->check($input, $validator->profile),
    );

    my $result = $processor->result;

    if ($result->success != 1) {
        deferred(
            $self->config_obj->session_namespace,
            {
                messages => $result->messages,
                old      => $input,
            },
        );
    }

    return $result;
}

sub errors {
    return shift->_get_deferred->{messages};
}

sub _get_deferred {
    return deferred(shift->config_obj->session_namespace);
}

1;

__END__
# ABSTRACT: Dancer2 validation framework.

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::FormValidator - validate incoming request in declarative way.

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    use Dancer2::Plugin::FormValidator;
    use App::Http::Validators::Form;

    post '/form' => sub {
        if (my $valid_hash_ref = validate_form 'form') {
            save_user_input($valid_hash_ref);
            redirect '/success_page';
        }

        redirect '/form';
    };

=head1 DISCLAIMER

This is not stable version!

Please dont rely on it.
Interfaces would be changed in future, except of dsl keywords signatures.

If you like it - add it to your bookmarks. I intend to complete the development by the summer 2022.

B<Have any ideas?> Find this project on github (repo ref is at the bottom).

=head1 DESCRIPTION

This is micro-framework that provides validation in your Dancer2 application.
It consists of dsl's keywords and a set of agreements.
It is build around L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator>.

Uses two approaches: declarative and verbose with more control.

=head2 Validator

First, you need to create class which will implements
at least one main role: Dancer2::Plugin::FormValidator::Role::HasProfile.

This role requires profile method which should return a HashRef Data::FormValidator accepts:

    package App::Http::Validators::RegisterForm {
        use Moo;
        use Data::FormValidator::Constraints qw(:closures);

        with 'Dancer2::Plugin::FormValidator::Role::HasProfile';

        sub profile {
            return {
                required => [qw(name email)],
                constraint_methods => {
                    email => email,
                }
            };
        };
    }

=head2 Declarative approach

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
    use App::Http::Validators::RegisterForm;

    post '/register' => sub {
        if (my $valid_hash_ref = validate_form 'register_form') {
            if (login($valid_hash_ref)) {
                redirect '/success_page';
            }
        }

        redirect '/register';
    };

In you template you have access to $errors - this is hash with parameters names as keys
and error messages as values like:

    {
        name  => '<span>Name is missing.</span>',
        email => '<span>Email is invalid.</span>'
    }

=head1 CONFIGURATION

    ...
    plugins:
        FormValidator:
            session:
                namespace: '_form_validator'           # this is required
            messages:
                missing: '<span>%s is missing.</span>' # default is '%s is missing.'
                invalid: '<span>%s is invalid.</span>' # default is '%s is invalid.'
                ucfirst: 1                             # this is default
            forms:
                login_form: 'App::Http::Validators::LoginForm'
                support_form: 'App::Http::Validators::SupportForm'
                ...
    ...

=head1 DSL KEYWORDS

=head3 validate HashRef:$input => Object:$validator

=head3 validate_form String:$form

=head1 TODO

=over 4

=item Configuration details: list all fields and describe them.

=item Document Result object.

=item Document all Dsl.

=item Document all Verbose approach.

=item Document all Roles and HashRef structures.

=item Template test $errors.

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
