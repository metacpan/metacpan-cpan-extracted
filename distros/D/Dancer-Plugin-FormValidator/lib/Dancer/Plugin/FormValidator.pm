#
# This file is part of Dancer-Plugin-FormValidator
#
# This software is copyright (c) 2013 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dancer::Plugin::FormValidator;
{
  $Dancer::Plugin::FormValidator::VERSION = '1.131620';
}

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Exception qw(:all);

use Data::FormValidator;
use Module::Load;

use 5.010;

#ABSTRACT: Easy validates user input (usually from an HTML form) based on input profile for Dancer applications.

#Register exception
register_exception('ProfileInvalidFormat',
    message_pattern => "Unknown format use yml, json or pl: %s"
);

my $dfv;
my $results;


register form_validator_error => sub {
    $results     = _dfv_check(@_);
    my $settings = plugin_setting;

    if ( $results->has_invalid || $results->has_missing ) {
        if ( $settings->{halt} ) {
            my @errors = keys(%{$results->{missing}});
            my $string;

            $string = scalar(@errors) == 1
                ? "$settings->{msg}->{single} @errors"
                : "$settings->{msg}->{several} @errors";

            return halt($string);
        }
        else {
            return $results->has_missing
                ? _error_return('missing')
                : _error_return('invalid');
        }
    }

    return 0;
};


register dfv => sub {
    _dfv_check(@_);
};

register_plugin for_versions => [2];

sub _error_return {
    my $reason   = shift;
    my $settings = plugin_setting;

    my @errors = keys(%{$results->{$reason}});
    my $errors;
    my $value;

    if ( $results->{profile}->{msgs}->{$reason} ) {
        $value = $results->{profile}->{msgs}->{$reason};
    }
    else {
        $value = $settings->{msg}->{single};
    }

    foreach my $msg_errors (@errors) {
        $errors->{$msg_errors} = $value;
    }

   return $errors;
}

sub _dfv_check {
    my ( $profile, $params ) = @_;

    _init_object_dfv() unless defined($dfv);
    $params //= params;
    $results  = $dfv->check($params, $profile);

    return $results;
}

sub _init_object_dfv {
    my $settings     = plugin_setting;
    my $path_file    = $settings->{profile_file} // 'profile.yml';
    my $profile_file = setting('appdir') . '/' . $path_file;

    my $available_deserializer = {
        json => sub {
            my ( $file ) = @_;

            load JSON::Syck;

            my $data = JSON::Syck::LoadFile($file);
            return $data;
        },
        yml => sub {
            my ( $file ) = @_;

            load YAML::Syck;

            my $data = YAML::Syck::LoadFile($file);
            return $data;
        },
        pl => sub {
            my ( $file )  = @_;

            my $exception;
            my $data;

            {
                local $@;
                $data      = do $file;
                $exception = $@;
            }

            die $exception if $exception;

            return $data;
        },
    };

    $profile_file =~ m/\.(\w+$)/;
    my $ext       = $1;

    if ( my $deserialize = $available_deserializer->{$ext} ) {
        $dfv = Data::FormValidator->new($deserialize->($profile_file));
    }
    else {
        raise ProfileInvalidFormat => $ext;
    }
}

1;

__END__

=pod

=head1 NAME

Dancer::Plugin::FormValidator - Easy validates user input (usually from an HTML form) based on input profile for Dancer applications.

=head1 VERSION

version 1.131620

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::FormValidator;

    get '/contact/form' => sub {
        my $input_hash = {
            Name    => $params->{name},
            Subject => $params->{subject},
            Body    => $params->{body},
        };

        my $error = form_validator_error( 'profile_contact', $input_hash );

        if ( ! $error ) {
            #the user provided complete and validates
            # data it's cool to proceed
        }
    };

    dance;

Example of profile file:

     {
         profile_contact => {
             'required' => [ qw(
                 Name Subject Body
              )],
              msgs => {
                missing => 'Not Here',
              }
         },
     }

Example with yml format:

    profile_contact:
      required:
        - name
        - subject
        - body
      msgs:
        missing: Not here

Example with json format:

    {
        "profile_contact": {
            "required": [
                "name",
                "subject",
                "body"
            ],
            "msgs": {
                "missing": "Not here"
            }
        }
    }

=head1 DESCRIPTION

Provides an easy validates user input based on input profile (Data::FormValidator)
keyword within your L<Dancer> application.

=head1 METHODS

=head2 form_validator_error

    form_validator_error('profile_name');
or
    form_validator_error('profile_name', $input);

Validate forms.

    input: (Str): Name of profile
           (HashRef): Data to be validated (optional) if is not present
                      getting params implicitly
    output: (HashRef): Field was missing or invalid or return 0 if all field is
                       valid

=head2 dfv

    if ( my $results = dfv('profile_name') ) {
        Do some stuff
    }
    else {
        Report some failure
    }
or
    if ( my $results = dfv ('profile_name', $input) ) {
        Do some stuff
    }
    else {
        Report some failure
    }

Validate forms.

    input: (Str): Name of profile
           (HashRef): Data to be validated (optional) if is not present
                      getting params implicitly
    output: A Data::FormValidator::Results object

=encoding utf8

=head1 CONFIGURATION

     plugins:
         FormValidator:
             profile_file: 'profile.pl'
             halt: 0
             msg:
                 single: 'Missing field'
                 several: 'Missing fields'

For the profile file it's possible to use json, yml or pl format.
The halt option is only available with form_validator_error function,
if you don't use halt option, a hashref is return with name of fields for the key and
reason of the value use msgs profile, if you missing specified a msgs in a profil,
msg single is use. The profile file it begins at the application root. The
default of profile_file name is profile.yml

=head1 CONTRIBUTING

This module is developed on Github at:

L<http://github.com/hobbestigrou/Dancer-Plugin-FormValidator>

Feel free to fork the repo and submit pull requests

=head1 ACKNOWLEDGEMENTS

Alexis Sukrieh and Franck Cuny

=head1 BUGS

Please report any bugs or feature requests in github.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::FormValidator

=head1 SEE ALSO

L<Dancer>
L<Data::FormValidator>
L<Dancer::Plugin::DataFormValidator>

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
