package Business::DPD::SK;

use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Business::DPD::SK - DPD Slovakia integrations

=head1 SYNOPSIS

    use Business::DPD::SK::GeoRDB;

    my $geordb = Business::DPD::SK::GeoRDB->new;
    my $new_zip = $geordb->update;    # undef when nothing newer exists

=head1 DESCRIPTION

This distribution groups modules for working with DPD Slovakia (business
unit C<016>). This module only carries the distribution version.

=over 4

=item L<Business::DPD::SK::GeoRDB>

downloads the GeoRDB routing database from the DPD SFTP server and reads its
tables.

=item L<Business::DPD::SK::API>

creates shipments and fetches parcel labels through the DPD Slovakia
shipment JSON API.

=back

=head1 FILES

=over 4

=item F<etc/dpd-sk/geordb.ini>

SFTP connection settings for the GeoRDB download. It is installed into the
system configuration directory (for example F</etc/dpd-sk/geordb.ini>); see
L<Business::DPD::SK::SPc>.

The file holds the SFTP password, so C<./Build install> installs it with mode
C<0640>. On upgrades the mode never becomes more permissive than it was, so a
stricter mode set by the admin is kept. The install does not change the
owner; give the group of the user that runs the download read access.

=item F<etc/dpd-sk/api.ini>

Endpoint URL and account settings for L<Business::DPD::SK::API>. The shipped
copy selects the DPD test endpoint and holds placeholder credentials; the
production URL is present but commented out. It is installed next to
F<geordb.ini>, with the same C<0640> mode handling, because it holds the API
key.

=item F<var/lib/dpd-sk/>

holds the most recent downloaded GeoRDB zip file. The user that runs
L<Business::DPD::SK::GeoRDB/update> needs write access to it; the install
does not change ownership.

=back

=head1 AUTHOR

Jozef Kutej

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
