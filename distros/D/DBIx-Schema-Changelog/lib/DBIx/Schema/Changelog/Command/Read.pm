package DBIx::Schema::Changelog::Command::Read;

=head1 NAME

DBIx::Schema::Changelog::Command::Read - Create a new changeset project from template for DBIx::Schema::Changelog!

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use strict;
use warnings FATAL => 'all';
use DBI;
use Pod::Usage;
use Pod::Find qw(pod_where);
use DBIx::Schema::Changelog;

=head1 SUBROUTINES/METHODS

=head2 run

=cut

sub run {
    my ( $self, $config ) = @_;
    if ( $config->{help} ) {
        pod2usage( -verbose => 1, -input => pod_where( { -inc => 1 }, __PACKAGE__ ) );
    }

    $config->{driver} = ( defined $config->{driver} ) ? $config->{driver} : 'SQLite';
    my $dbi = "dbi:$config->{driver}:database=$config->{db}";
    my $dbh =
      ( defined $config->{user} )
      ? DBI->connect( $dbi, $config->{user}, $config->{pass} )
      : DBI->connect($dbi);
    my $insert = { dbh => $dbh };
    $insert->{file_type} = $config->{type}   if ( defined $config->{type} );
    $insert->{db_driver} = $config->{driver} if ( defined $config->{driver} );
    DBIx::Schema::Changelog->new($insert)->read( $config->{dir} || '.' );
    $dbh->disconnect();
}

no Moose;

1;

__END__

=head1 SYNOPSIS

=over 4

    changelog-run --read [options]
    ...

    changelog-run -r [options]
    ...

=back

=head1 OPTIONS

=over 4

    Options:
    -d, --dir               : Directory of new file or driver
    -dr, --driver           : Driver to use by running changelog (default SQLite)
    -t, --type              : File type for reading changesets (default Yaml)
    -db, --database         : Database to use by running changelog (default SQLite)
    -u, --user              : User to connect with remote db
    -p, --pass              : Pass for user to connect with remote db

=back

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
