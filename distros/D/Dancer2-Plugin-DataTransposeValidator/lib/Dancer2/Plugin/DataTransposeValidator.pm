package Dancer2::Plugin::DataTransposeValidator;

use strict;
use warnings;

use Carp 'croak';
use Dancer2::Core::Types qw(HashRef Maybe Str);
use Data::Transpose::Validator;
use Path::Tiny;
use Module::Runtime qw/use_module/;

use Dancer2::Plugin 0.200000;

=head1 NAME

Dancer2::Plugin::DataTransposeValidator - Data::Transpose::Validator plugin for Dancer2

=head1 VERSION

Version 0.101

=cut

our $VERSION = '0.101';

has css_error_class => (
    is          => 'ro',
    isa         => Str,
    from_config => sub { 'has-error' },
);

has errors_hash => (
    is          => 'ro',
    isa         => Maybe [Str],
    from_config => sub { undef },
);

has rules => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} },
);

has rules_class => (
    is          => 'ro',
    isa         => Maybe[Str],
    from_config => sub { undef },
);

has rules_dir => (
    is  => 'ro',
    isa => sub {
        eval { path( $_[0] )->is_dir; 1 }
          or do { croak "rules directory does not exist" };
    },
    default => sub {
        my $plugin = shift;
        my $dir =
            $plugin->config->{rules_dir}
          ? $plugin->config->{rules_dir}
          : 'validation';
        path($plugin->app->setting('appdir'))->child($dir)->stringify;
    },
);

plugin_keywords 'validator';

sub BUILD {
    my $plugin = shift;
    croak __PACKAGE__ . " cannot use both of rules_class and rules_dir"
      if exists $plugin->config->{rules_class}
      && exists $plugin->config->{rules_dir};

    if ( exists $plugin->config->{rules_class} ) {
        use_module($plugin->config->{rules_class});
    }
}

sub validator {
    my ( $plugin, $params, $name, @additional_args ) = @_;
    my $rules;

    croak "params must be a hash reference" unless ref($params) eq 'HASH';

    if ( ref($name) eq '' ) {
        if ( !$plugin->rules->{$name} ) {
            if ( my $class = $plugin->rules_class ) {
                if ( $class->can($name) ) {
                    $plugin->rules->{$name} = \&{"${class}::$name"};
                }
                else {
                    croak "Rules class \"$class\" has no rule sub named: $name";
                }
            }
            else {
                # nasty old rules_dir
                my $path = path( $plugin->rules_dir )->child($name);
                croak "rules_file does not exist" unless $path->is_file;

                my $eval = do $path or croak "bad rules file: $path - $! $@";
                if ( ref($eval) eq 'CODE' ) {
                    $plugin->rules->{$name} = $eval;
                }
                else {
                    $plugin->rules->{$name} = sub { $eval };
                }
            }
        }
        $rules = $plugin->rules->{$name}->(@additional_args);
    }
    elsif (ref($name) eq 'HASH') {
        $rules = $name;
    }
    elsif (ref($name) eq 'CODE') {
        $rules = $name->(@additional_args);
    }
    else {
        my $ref = ref($name);
        croak "rules option reference type $ref not allowed";
    }

    my $options = $rules->{options} || {};
    my $prepare = $rules->{prepare} || {};

    my $dtv = Data::Transpose::Validator->new(%$options);
    $dtv->prepare(%$prepare);

    my $clean = $dtv->transpose($params);
    my $ret;

    if ($clean) {
        $ret->{valid}  = 1;
        $ret->{values} = $clean;
    }
    else {
        $ret->{valid}  = 0;
        $ret->{values} = $dtv->transposed_data;

        my $v_hash = $dtv->errors_hash;
        while ( my ( $key, $value ) = each %$v_hash ) {

            $ret->{css}->{$key} = $plugin->css_error_class;

            my @errors = map { $_->{value} } @{$value};

            if ( $plugin->errors_hash && $plugin->errors_hash eq 'joined' ) {
                $ret->{errors}->{$key} = join( ". ", @errors );
            }
            elsif ( $plugin->errors_hash && $plugin->errors_hash eq 'arrayref' )
            {
                $ret->{errors}->{$key} = \@errors;
            }
            else {
                $ret->{errors}->{$key} = $errors[0];
            }
        }
    }
    return $ret;

}

1;
__END__

=head1 SYNOPSIS

    use Dancer2::Plugin::DataTransposeValidator;

    post '/' => sub {
        my $params = params;
        my $data = validator($params, 'myrule');
        if ( $data->{valid} ) { ... }
    }


=head1 DESCRIPTION

Dancer2 plugin for for L<Data::Transpose::Validator>

=head1 FUNCTIONS

This module exports the single function C<validator>.

=head2 validator( $params, $rules, @additional_args? )

Where:

C<$params> is a hash reference of parameters to be validated.

C<$rules> is one of:

=over

=item * the name of a rule sub if you are using L</rules_class>

=item * the name of a rule file if you are using L</rules_dir>

=item * a hash reference of rules

=item * a code reference that will return a hashref of rules

=back

Any optional C<@additional_args> are passed as arguments to code
references/subs.

A hash reference with the following keys is returned:

=over 4

=item * valid

A boolean 1/0 showing whether the parameters validated correctly or not.

=item * values

The transposed values as a hash reference.

=item * errors

A hash reference containing one key for each parameter which failed validation.
See L</errors_hash> in L</CONFIGURATION> for an explanation of what the value
of each parameter key will be.

=item * css

A hash reference containing one key for each parameter which failed validation.
The value for each parameter is a css class. See L</css_error_class> in
L</CONFIGURATION>.

=back

=head1 CONFIGURATION

The following configuration settings are available (defaults are
shown here):

    plugins:
      DataTransposeValidator:
        css_error_class: has-error
        errors_hash: 0
        rules_class: MyApp::ValidationRules
        # OR:
        rules_dir: validation

=head2 css_error_class

The class returned as a value for parameters in the css key of the hash
reference returned by L</validator>.

=head2 errors_hash

This can has a number of different values:

=over 4

=item * 0

A false value (the default) means that only a single scalar error string will
be returned for each parameter error. This will be the first error returned
for the parameter by L<Data::Transpose::Validator/errors_hash>.

=item * joined

All errors for a parameter will be returned joined by a full stop and a space.

=item * arrayref

All errors for a parameter will be returned as an array reference.

=back

=head2 rules_class

This is much preferred over L</rules_dir> since it does not eval external files.

This is a class (package) name such as C<MyApp::Validator::Rules>. There should
be one sub for each rule name inside that class which returns a hash reference.
See L</RULES CLASS> for examples.

=head2 rules_dir

Subdirectory of L<Dancer2::Config/appdir> in which rules files are stored.
B<NOTE:> We recommend you do not use this approach since the rules files
are eval'ed with all the security risks that entails. Please use L</rules_class>
instead. B<You have been warned>. See L</RULES DIR> for examples.

=head2 RULES CLASS

The rules class allows the L</validator> to be configured using
all options available in L<Data::Transpose::Validator>. The rules class must
contain one sub for each rule name which will be passed any C<@optional_args>.

    package MyApp::ValidationRules;

    sub register {
        # simple hashref
        +{
            options => {
                stripwhite => 1,
                collapse_whitespace => 1,
                requireall => 1,
            },
            prepare => {
                email => {
                    validator => "EmailValid",
                },
                email2 => {
                    validator => "EmailValid",
                },
                emails => {
                    validator => 'Group',
                    fields => [ "email", "email2" ],
                },
            },
        };
    }

    sub change_password {
        # args and hashref
        my %args = @_;
        +{
            options => {
                requireall => 1,
            },
            prepare => {
                old_password => {
                    required  => 1,
                    validator => sub {
                        if ( $args{logged_in_user}->check_password( $_[0] ) ) {
                            return 1;
                        }
                        else {
                            return ( undef, "Password incorrect" );
                        }
                    },
                },
                password => {
                    required  => 1,
                    validator => {
                        class   => 'PasswordPolicy',
                        options => {
                            username      => $args{logged_in_user}->username,
                            minlength     => 8,
                            maxlength     => 70,
                            patternlength => 4,
                            mindiffchars  => 5,
                            disabled      => {
                                digits   => 1,
                                mixed    => 1,
                                specials => 1,
                            }
                        }
                    }
                },
                confirm_password => { required => 1 },
                passwords        => {
                    validator => 'Group',
                    fields    => [ "password", "confirm_password" ],
                },
            },
        };
    }

    1;

=head2 RULES DIR

The rules file format allows the L</validator> to be configured using
all options available in L<Data::Transpose::Validator>. The rules file
must contain a valid hash reference, e.g.: 

    {
        options => {
            stripwhite => 1,
            collapse_whitespace => 1,
            requireall => 0,
            unknown => "fail",
            missing => "undefine",
        },
        prepare => {
            email => {
                validator => "EmailValid",
                required => 1,
            },
            email2 => {
                validator => {
                    class => "MyValidator::EmailValid",
                    absolute => 1,
                }
            },
            field4 => {
                validator => {
                    sub {
                        my $field = shift;
                        if ( $field =~ /^\d+/ && $field > 0 ) {
                            return 1;
                        }
                        else {
                            return ( undef, "Not a positive integer" );
                        }
                    }
                }
            }
        }
    }

Note that the value of the C<prepare> key must be a hash reference since the
array reference form of L<Data::Transpose::Validator/prepare> is not supported.

As an alternative the rules file can contain a code reference, e.g.:

    sub {
        my $username = shift;
        return {
            options => {
                stripwhite => 1,
            },
            prepare => {
                password => {
                    validator => {
                        class => 'PasswordPolicy',
                        options => {
                            username  => $username,
                            minlength => 8,
                        }
                    }
                }
            }
        };
    }

The code reference receives the C<@additional_args> passed to L</validator>.
The code reference must return a valid hash reference.

=head1 SEE ALSO

L<Dancer2>, L<Data::Transpose>

=head1 ACKNOWLEDGEMENTS

Alexey Kolganov for L<Dancer::Plugin::ValidateTiny> which inspired a number
of aspects of the original version of this plugin.

Stefan Hornburg (Racke) for his valuable feedback.

=head1 AUTHOR

Peter Mottram (SysPete), C<< <peter@sysnix.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify
it under the same terms as the Perl 5 programming language system itself.

=cut
