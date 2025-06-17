use utf8;
package CPAN::Testers::Schema::Result::ReleaseStat;
our $VERSION = '0.028';
# ABSTRACT: A single test report reduced to a simple pass/fail

#pod =head1 SYNOPSIS
#pod
#pod     my $release_stats = $schema->resultset( 'ReleaseStat' )->search({
#pod         dist => 'My-Dist',
#pod         version => '1.001',
#pod     });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This table contains information about individual reports, reduced to
#pod a pass/fail.
#pod
#pod These stats are built from the `cpanstats` table
#pod (L<CPAN::Testers::Schema::Result::Stats>), and collected and combined
#pod into the `release_summary` table
#pod (L<CPAN::Testers::Schema::Result::Release>).
#pod
#pod B<XXX>: This intermediate table between a report and the release summary
#pod does not seem necessary and if we can remove it, we should.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<DBIx::Class::Row>, L<CPAN::Testers::Schema>
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'Result';
table 'release_data';

#pod =attr dist
#pod
#pod The name of the distribution.
#pod
#pod =cut

column dist => {
    data_type => 'varchar',
    is_nullable => 0,
};

#pod =attr version
#pod
#pod The version of the distribution.
#pod
#pod =cut

column version => {
    data_type => 'varchar',
    is_nullable => 0,
};

#pod =attr id
#pod
#pod The ID of this report from the `cpanstats` table. See
#pod L<CPAN::Testers::Schema::Result::Stats>.
#pod
#pod =cut

column id => {
    data_type => 'int',
    is_nullable => 0,
};

#pod =attr guid
#pod
#pod The GUID of this report from the `cpanstats` table. See
#pod L<CPAN::Testers::Schema::Result::Stats>.
#pod
#pod =cut

column guid => {
    data_type => 'char',
    size => 36,
    is_nullable => 0,
};

__PACKAGE__->set_primary_key(qw( id guid ));

#pod =attr oncpan
#pod
#pod The installability of this release: C<1> if the release is on CPAN. C<2>
#pod if the release has been deleted from CPAN and is only on BackPAN.
#pod
#pod =cut

column oncpan => {
    data_type => 'int',
    is_nullable => 0,
};

#pod =attr distmat
#pod
#pod The maturity of this release. C<1> if the release is stable and
#pod ostensibly indexed by CPAN. C<2> if the release is a developer release,
#pod unindexed by CPAN.
#pod
#pod =cut

column distmat => {
    data_type => 'int',
    is_nullable => 0,
};

#pod =attr perlmat
#pod
#pod The maturity of the Perl these reports were sent by: C<1> if the Perl is
#pod a stable release. C<2> if the Perl is a developer release.
#pod
#pod =cut

column perlmat => {
    data_type => 'int',
    is_nullable => 0,
};

#pod =attr patched
#pod
#pod The patch status of the Perl that sent the report. C<2> if the Perl reports
#pod being patched, C<1> otherwise.
#pod
#pod =cut

column patched => {
    data_type => 'int',
    is_nullable => 0,
};

#pod =attr pass
#pod
#pod C<1> if this report's C<state> was C<PASS>.
#pod
#pod =cut

column pass => {
    data_type => 'int',
    is_nullable => 0,
};

#pod =attr fail
#pod
#pod C<1> if this report's C<state> was C<FAIL>.
#pod
#pod =cut

column fail => {
    data_type => 'int',
    is_nullable => 0,
};

#pod =attr na
#pod
#pod C<1> if this report's C<state> was C<NA>.
#pod
#pod =cut

column na => {
    data_type => 'int',
    is_nullable => 0,
};

#pod =attr unknown
#pod
#pod C<1> if this report's C<state> was C<UNKNOWN>.
#pod
#pod =cut

column unknown => {
    data_type => 'int',
    is_nullable => 0,
};

#pod =attr uploadid
#pod
#pod The ID of this upload from the `uploads` table.
#pod
#pod =cut

column uploadid => {
    data_type => 'int',
    extra       => { unsigned => 1 },
    is_nullable => 0,
};

#pod =method upload
#pod
#pod Get the related row from the `uploads` table. See
#pod L<CPAN::Testers::Schema::Result::Upload>.
#pod
#pod =cut

belongs_to upload => 'CPAN::Testers::Schema::Result::Upload' => 'uploadid';

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::Result::ReleaseStat - A single test report reduced to a simple pass/fail

=head1 VERSION

version 0.028

=head1 SYNOPSIS

    my $release_stats = $schema->resultset( 'ReleaseStat' )->search({
        dist => 'My-Dist',
        version => '1.001',
    });

=head1 DESCRIPTION

This table contains information about individual reports, reduced to
a pass/fail.

These stats are built from the `cpanstats` table
(L<CPAN::Testers::Schema::Result::Stats>), and collected and combined
into the `release_summary` table
(L<CPAN::Testers::Schema::Result::Release>).

B<XXX>: This intermediate table between a report and the release summary
does not seem necessary and if we can remove it, we should.

=head1 ATTRIBUTES

=head2 dist

The name of the distribution.

=head2 version

The version of the distribution.

=head2 id

The ID of this report from the `cpanstats` table. See
L<CPAN::Testers::Schema::Result::Stats>.

=head2 guid

The GUID of this report from the `cpanstats` table. See
L<CPAN::Testers::Schema::Result::Stats>.

=head2 oncpan

The installability of this release: C<1> if the release is on CPAN. C<2>
if the release has been deleted from CPAN and is only on BackPAN.

=head2 distmat

The maturity of this release. C<1> if the release is stable and
ostensibly indexed by CPAN. C<2> if the release is a developer release,
unindexed by CPAN.

=head2 perlmat

The maturity of the Perl these reports were sent by: C<1> if the Perl is
a stable release. C<2> if the Perl is a developer release.

=head2 patched

The patch status of the Perl that sent the report. C<2> if the Perl reports
being patched, C<1> otherwise.

=head2 pass

C<1> if this report's C<state> was C<PASS>.

=head2 fail

C<1> if this report's C<state> was C<FAIL>.

=head2 na

C<1> if this report's C<state> was C<NA>.

=head2 unknown

C<1> if this report's C<state> was C<UNKNOWN>.

=head2 uploadid

The ID of this upload from the `uploads` table.

=head1 METHODS

=head2 upload

Get the related row from the `uploads` table. See
L<CPAN::Testers::Schema::Result::Upload>.

=head1 SEE ALSO

L<DBIx::Class::Row>, L<CPAN::Testers::Schema>

=head1 AUTHORS

=over 4

=item *

Oriol Soriano <oriolsoriano@gmail.com>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
