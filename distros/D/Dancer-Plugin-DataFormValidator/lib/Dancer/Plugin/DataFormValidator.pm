package Dancer::Plugin::DataFormValidator;
{
  $Dancer::Plugin::DataFormValidator::VERSION = '0.002';
}
# ABSTRACT: Easy access to Data::FormValidator from within Dancer applications

use strict;
use warnings;
use Data::Dump qw{pp};
use Dancer ':syntax';
use Dancer::Plugin;
use Data::FormValidator;


register dfv => sub {
    my ($profile, $input) = @_;

    debug 'Checking for explicit input';
    unless ($input) {
        debug 'Getting params implicitly';
        $input = params;
    }

    debug "input is " . pp $input;

    debug 'Checking for explicit profile';
    if (ref $profile) {
        debug 'Checking using explicit profile';
        return Data::FormValidator->check ($input, $profile);
    }
    elsif ($profile) {
        debug 'Looking for cached Data::FormValidator object';
        my $dfv = config->{validator}->{_dfv};
        unless ($dfv) {
            debug 'Creating Data;:FormValidator object for the first time';
            config->{validator}->{_dfv} = $dfv = Data::FormValidator->new (join '/', setting ('appdir'), plugin_setting->{profile_file});
        }
        debug 'Creating Data;:FormValidator object for the first time';
        debug 'Checking using named profile';
        return $dfv->check ($input, $profile);
    } else {
        error 'No profile specified for doing validation';
    }

    return 0;
};

register_plugin;

1;

__END__
=pod

=head1 NAME

Dancer::Plugin::DataFormValidator - Easy access to Data::FormValidator from within Dancer applications

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Dancer;
  use Dancer::Plugin::DataFormValidator;

  post '/foo' => sub {
    if (my $results = dfv ('foo')) {
      # Do some stuff
    } else {
      # Report some failure
    }
  }

=head1 DESCRIPTION

Provides an easy way to validate user input based on an input profile
(specified as per L<Data::FormValidator>) using a C<dfv()> keyword
within your L<Dancer> application.

=head2 Configuration

In the simplest case you can use C<Dancer::Plugin::DataFormValidator>
without any configuration at all, passing validation profiles each
time you call C<dfv()>.

To reduce visual clutter when dealing with complex validation
profiles, you may optionally specify a profile in the dancer
configuration that will be loaded on first use, and which contains
multiple validation profiles you can then refer to by name:

 plugins:
   DataFormValidator:
     profile: 'profiles'

=head2 dfv()

The C<dfv()> routine can be called several different ways.  In all
cases it I<must> include either a validation profile name (which must
be present in the file loaded via the profile configuration
parameter), or a hashref containing the validation profile to be used
(see L<Data::FormValidator> for details on what that profile may
contain).

If nothing else is included, the parameters L<Dancer> found for the
handler will be used.  Otherwise, you may hand it a hashref of
whatever data you wish it to check.

It will return a L<Data::FormValidator::Results> object you can use
however you please.

=head2 Explicit validation profile, explicit params

    post '/jazz' => sub {
        if (my $results = dfv ({required => [qw{Name}]}, {Name => 'HorseFeathers'})) {
            do_something ($results->valid)
        } else {
            messages = $results->msgs;
        }
    };

=head2 Named validation profile, implicit params

    post '/contact/form' => sub {
        if (my $results = dfv ('contact')) {
            do_something ($results->valid)
        } else {
            messages = $results->msgs;
        }
    };

=encoding utf8

=head1 CONTRIBUTING

This module is developed on Github at:

L<http://github.com/mdorman/Dancer-Plugin-DataFormValidator>

Feel free to fork the repo and submit pull requests.

=head1 ACKNOWLEDGEMENTS

Derived, in intent if not actual code, from
L<Dancer::Plugin::FormValidator> by Natal Ngétal, C<<
<hobbestigrou@erakis.im> >>

=head1 SEE ALSO

L<Dancer>
L<Data::FormValidator>

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ironic Design, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

