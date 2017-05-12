package CGI::Application::Plugin::Authentication::Driver::CDBI;

use warnings;
use strict;

use base 'CGI::Application::Plugin::Authentication::Driver';

=head1 NAME

THIS MODULE IS UNSUPPORTED! YOU CAN ADOPT IT IF YOU LIKE IT! WRITE TO
modules@perl.org IF YOU WANT TO MAINTAIN IT.

CGI::Application::Plugin::Authentication::Driver::CDBI - Class::DBI Authentication Driver

=head1 VERSION

Version 0.03

THIS MODULE IS UNSUPPORTED! YOU CAN ADOPT IT IF YOU LIKE IT! WRITE TO
modules@perl.org IF YOU WANT TO MAINTAIN IT.

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use base qw(CGI::Application);
  use CGI::Application::Plugin::Authentication;

  __PACKAGE__->authen->config(
    DRIVER => [ 'CDBI',
      CLASS   => 'My::CDBI::Users',
      FIELD_METHODS => [qw(user MD5:passphrase)]
    ],
    CREDENTIALS => [qw(auth_username auth_password)],
  );

=head1 DESCRIPTION

This Authentication driver uses the Class::DBI module to allow you to 
authenticate against any Class::DBI class.  

=head1 PARAMETERS

The Class::DBI authentication driver accepts the following required
parameters.

=head2 CLASS (required)

Specifies the Class::DBI class to use for authentication. This class must
be loaded prior to use.

=head2 FIELD_METHODS (required)

FIELD_METHODS is an arrayref of the methods in the Class::DBI class
specified by CLASS to be used during authentication. The order of these
methods needs to match the order of the CREDENTIALS. For example, if
CREDENTIALS is set to: 

  CREDENTIALS => [qw(auth_user auth_domain auth_password)]

Then FIELD_METHODS must be set to:

  FIELD_METHODS => [qw(userid domain password)]

FIELD_METHODS supports filters as specified by 
CGI::Application::Plugin::Authentication::Driver

=head1 METHODS

=head2 verify_credentials

This method will test the provided credentials against the values found in 
the database, according to the Driver configuration.

=cut

sub verify_credentials {
  my $self = shift;
  my @creds = @_;

  my @_options=$self->options;
  die "The Class::DBI driver requires a hash of options" if @_options % 2;
  my %options=@_options;

  my $cdbiclass=$options{CLASS};
  die "CLASS option must be set." unless($cdbiclass);

  return unless(scalar(@creds) eq scalar(@{$options{FIELD_METHODS}}));

  my @crednames=@{$self->authen->credentials};

  my %search;
  my %compare;
  my $i=0;

  # There's a lot of remapping lists/arrays into hashes here
  # Most of this is due to needing a hash to perform a search,
  # and another hash to perform comparisions if the search is
  # encrypted. Also verify that columns that exist have been specified.
  for(@{$options{FIELD_METHODS}}) {
    $search{$_}=$creds[$i] unless /:/;
    $compare{$_}=$creds[$i] if /:/;
    my $column=$self->strip_field_names($_);
    die "Column $column not in $cdbiclass" unless($cdbiclass->can($column));
    $i++;
  }

  my @users=$options{CLASS}->search( %search );
  return unless(@users);

  # We want to return the value of the first column specified.
  # Could probably just return $creds[0] as that value should match
  # but I've chosen to return what's in the DB.
  my $field = ( @{ $options{FIELD_METHODS} } )[0];
  if (%compare) {
    foreach my $encoded ( keys(%compare) ) {
      my $column = $self->strip_field_names($encoded);
      # No point checking the rest of the columns if any of the encoded ones
      # do not match.
      return
        unless (
        $self->check_filtered(
          $encoded, $compare{$encoded}, $users[0]->$column
        )
        );
    }
  }
  # If we've made it this far, we have a valid user. Set the user object and
  # Return the value of the first credentail.
  return $users[0]->$field;
}

=head1 SEE ALSO

L<CGI::Application::Plugin::Authentication::Driver>, 
L<CGI::Application::Plugin::Authentication>, perl(1)

=head1 AUTHOR

Shawn Sorichetti, C<< <ssoriche@coloredblocks.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-authentication-driver-cdbi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-Authentication-Driver-CDBI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Special thanks to Cees Hek for writing CGI::Application::Plugin::Authentication 
and his assistance in writing this module.

=head1 COPYRIGHT & LICENSE

THIS MODULE IS UNSUPPORTED! YOU CAN ADOPT IT IF YOU LIKE IT! WRITE TO
modules@perl.org IF YOU WANT TO MAINTAIN IT.

Copyright 2005 Shawn Sorichetti, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Application::Plugin::Authentication::Driver::CDBI
