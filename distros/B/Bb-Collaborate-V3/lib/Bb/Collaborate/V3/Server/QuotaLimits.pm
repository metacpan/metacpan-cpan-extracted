package Bb::Collaborate::V3::Server::QuotaLimits;
use warnings; use strict;

use Mouse;

extends 'Elive::DAO::Singleton','Bb::Collaborate::V3';

use Scalar::Util;

=head1 NAME

Bb::Collaborate::V3::Server::QuotaLimits - Gets quota limits and usage information

=cut

=head1 DESCRIPTION

This class is used to determine how much of your quotas you have used.

=cut

__PACKAGE__->entity_name('QuotaLimits');

=head1 PROPERTIES

=head2 versionId (Int)

The version number as a 4 digit integer, e.g. C<1002>.

=cut

has 'versionId' => (is => 'rw', isa => 'Int');

=head2 quotaName (Str)

The name of the quota. This may be one of the following:

=over 4

=item * C<session> - The number of sessions.

=item * C<disk> - The number of bytes of disk storage.

=item * C<recordingConversion> - The number of conversions of recordings.

=item * C<recordingPlayback> - The number of times
recordings have been played back in the past 12
months.

=back

=cut

has 'quotaName' => (is => 'rw', isa => 'Str');

=head2 quotaUsage (Int)

How many have been used.

=cut

has 'quotaUsage' => (is => 'rw', isa => 'Int');

=head2 quotaAvailable (Int)

The number available

=cut

has 'quotaAvailable' => (is => 'rw', isa => 'Int');

=head1 METHODS

=cut

=head2 list

    my $server_version = Bb::Collaborate::V3::Server::QuotaLimits->get;
    print "ELM version is: ".$server_version->versionName."\n";

Returns the server version information for the current connection.

=cut

sub list {
    my ($class, %opt) = @_;

    $opt{command} ||= 'GetQuotaLimits';

    return $class->SUPER::list(%opt);
}

1;
