package CGI::Application::Plugin::Authentication::Driver::DBIC;

use warnings;
use strict;
use base 'CGI::Application::Plugin::Authentication::Driver';

=head1 NAME

CGI::Application::Plugin::Authentication::Driver::DBIC - DBIx::Class Authentication Driver

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Authentication;
    
 __PACKAGE__->authen->config( 
     DRIVER => [ 
        'DBIC',
        SCHEMA => My::DBIC->connect($dsn), # or existing $schema object
        CLASS => 'Users', # = My::DBIC::Users
        FIELD_METHODS => [qw(user MD5:passphrase)]
     ],
     CREDENTIALS => [qw(auth_username auth_password)],
 );

=head1 DESCRIPTION

This Authentication driver uses the L<DBIx::Class> module to allow you to 
authenticate against any I<DBIx::Class> class.  

=head1 PARAMETERS

The I<DBIx::Class> authentication driver accepts the following required
parameters.

=over 4

=item SCHEMA (required)

Specifies the I<DBIx::Class::Schema> object to use for authentication. 
This class must be loaded prior to use.

=item CLASS (required)

Specifies the I<DBIx::Class> class within the schema which contains 
authentication information.

=item FIELD_METHODS (required)

FIELD_METHODS is an arrayref of the methods in the I<DBIx::Class> class
specified by CLASS to be used during authentication. The order of these
methods needs to match the order of the CREDENTIALS. For example, if
CREDENTIALS is set to: 

  CREDENTIALS => [qw(auth_user auth_domain auth_password)]
  
Then FIELD_METHODS must be set to:
  
  FIELD_METHODS => [qw(userid domain password)]
    
FIELD_METHODS supports filters as specified by 
L<CGI::Application::Plugin::Authentication::Driver>

=back
    
=head1 METHODS

=head2 verify_credentials

This method will test the provided credentials against the values found in 
the database, according to the Driver configuration.

=cut

sub verify_credentials {
    my $self = shift;
    my @creds = @_;

    my @_options = $self->options;
    die "The Class::DBIx driver requires a hash of options" if @_options % 2;
    my %options = @_options;

    my $schema = $options{SCHEMA};
    die "SCHEMA option must be set." 
        unless($schema);
    die "SCHEMA must be a DBIx::Class::Schema." 
        unless($schema->isa('DBIx::Class::Schema'));

    my $class = $options{CLASS};
    die "CLASS option must be set." unless($class);

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
        $search{$_} = $creds[$i] unless /:/;
        $compare{$_} = $creds[$i] if /:/;
        my $column = $self->strip_field_names($_);
        die "Column $column not in ", $schema->class($class) 
            unless($schema->class($class)->can($column));
        $i++;
    }

    my @users = $schema->resultset($class)->search( %search );
    return unless(@users);

    # We want to return the value of the first column specified.
    # Could probably just return $creds[0] as that value should match
    # but I've chosen to return what's in the DB.
    my $field = ( @{ $options{FIELD_METHODS} } )[0];
    if (%compare) {
        foreach my $encoded ( keys(%compare) ) {
            my $column = $self->strip_field_names($encoded);
            # No point checking the rest of the columns if any of the encoded 
            #ones do not match.
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

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-authentication-driver-dbic at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-Authentication-Driver-DBIC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Application::Plugin::Authentication::Driver::DBIC

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Application-Plugin-Authentication-Driver-DBIC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Application-Plugin-Authentication-Driver-DBIC>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Application-Plugin-Authentication-Driver-DBIC>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Application-Plugin-Authentication-Driver-DBIC>

=back

=head1 THANKS

Cees Hek for I<CGI::Application::Plugin::Authentication>

Shawn Sorichetti for I<CGI::Application::Plugin::Authentication::Driver::CDBI>
which this module is shamelessly copied from.

=head1 AUTHOR

Jaldhar H. Vyas, C<< <jaldhar at braincells.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, Consolidated Braincells Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Application::Plugin::Authentication::Driver::DBIC
