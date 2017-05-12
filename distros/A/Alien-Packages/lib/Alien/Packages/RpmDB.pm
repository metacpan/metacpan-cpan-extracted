package Alien::Packages::RpmDB;

use strict;
use warnings;
use vars qw($VERSION @ISA);

=head1 NAME

Alien::Packages::RpmDB - acesses the RPM database directly

=cut

$VERSION = "0.003";

require Alien::Packages::Base;
use Carp qw(croak);

@ISA = qw(Alien::Packages::Base);

=head1 ISA

    Alien::Packages::RpmDB
    ISA Alien::Packages::Base

=head1 SUBROUTINES/METHODS

=head2 usable

Returns true when the rpm database can be accessed via L<RPM::Database>.

=cut

sub usable
{
    unless ( defined( $INC{'RPM/Database.pm'} ) )
    {
        eval {
            require RPM;
            require RPM::Database;
        };

        defined( $INC{'RPM.pm'} ) and RPM->import(qw($err));
        defined( $INC{'RPM/Database.pm'} ) and RPM::Database->import();
    }

    return $INC{'RPM/Database.pm'};
}

=head2 new

Instantiates a new Alien::Packages::RpmDB object and initializes a
connection to the rpm database.

=cut

sub new
{
    my ( $class, @options ) = @_;
    my $self = $class->SUPER::new(@options);

    my %h;
    tie %h, "RPM::Database" or croak $RPM::err;
    $self->{rpmdb} = \%h unless ($RPM::err);

    return $self;
}

=head2 pkgtype

Returns the pkg type "rpm".

=cut

sub pkgtype
{
    return "rpm";
}

=head2 list_packages

Queries the list of installed I<rpm> packages from the database.

=cut

sub list_packages
{
    my $self = $_[0];
    my @packages;

    while ( my ( $rpm_name, $rpm_header ) = each( %{ $self->{rpmdb} } ) )
    {
        my @nvr = $rpm_header->NVR();
        push( @packages, [ $nvr[0], $nvr[1], $rpm_header->summary() ] );
    }

    return @packages;
}

=head2 list_fileowners

Queries the list of I<rpm> packages from the database which have an
association to the requested file(s).

=cut

sub list_fileowners
{
    my ( $self, @files ) = @_;
    my %file_owners;

    foreach my $file (@files)
    {
        my ($rpm_header) = ( tied %{ $self->{rpmdb} } )->find_by_file($file);
        if ($rpm_header)
        {
            my @nvr = $rpm_header->NVR();
            push( @{ $file_owners{$file} }, { Package => $nvr[0] } );
        }
    }

    return %file_owners;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
