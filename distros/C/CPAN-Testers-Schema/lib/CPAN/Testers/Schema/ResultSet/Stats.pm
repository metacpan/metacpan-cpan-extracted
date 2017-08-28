use utf8;
package CPAN::Testers::Schema::ResultSet::Stats;
our $VERSION = '0.019';
# ABSTRACT: Query the raw test reports

#pod =head1 SYNOPSIS
#pod
#pod     my $rs = $schema->resultset( 'Stats' );
#pod     $rs->insert_test_report( $schema->resultset( 'TestReport' )->first );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This object helps to insert and query the legacy test reports (cpanstats).
#pod
#pod =head1 SEE ALSO
#pod
#pod L<CPAN::Testers::Schema::Result::Stats>, L<DBIx::Class::ResultSet>,
#pod L<CPAN::Testers::Schema>
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'ResultSet';
use Log::Any '$LOG';

#pod =method insert_test_report
#pod
#pod     my $stat = $rs->insert_test_report( $report );
#pod
#pod Convert a L<CPAN::Testers::Schema::Result::TestReport> object to the new test
#pod report structure and insert it into the database. This is for creating
#pod backwards-compatible APIs.
#pod
#pod Returns an instance of L<CPAN::Testers::Schema::Result::Stats> on success.
#pod Note that since an uploadid is required for the cpanstats table, this method
#pod throws an exception when an upload cannot be determined from the given
#pod information.
#pod
#pod =cut

sub insert_test_report ( $self, $report ) {
    my $schema = $self->result_source->schema;

    my $guid = $report->id;
    my $data = $report->report;
    my $created = $report->created;

    # attempt to find an uploadid, which is required for cpanstats
    my @uploads = $schema->resultset('Upload')->search({
        dist => $data->{distribution}{name},
        version => $data->{distribution}{version},
    })->all;

    die $LOG->warn("No upload match for GUID $guid") unless @uploads;
    $LOG->warn("Multiple upload matches for GUID $guid") if @uploads > 1;
    my $uploadid = $uploads[0]->uploadid;

    my $stat = {
        guid => $guid,
        state => lc($data->{result}{grade}),
        postdate => $created->strftime('%Y%m'),
        tester => qq["$data->{reporter}{name}" <$data->{reporter}{email}>],
        dist => $data->{distribution}{name},
        version => $data->{distribution}{version},
        platform => $data->{environment}{language}{archname},
        perl => $data->{environment}{language}{version},
        osname => $data->{environment}{system}{osname},
        osvers => $data->{environment}{system}{osversion},
        fulldate => $created->strftime('%Y%m%d%H%M'),
        type => 2,
        uploadid => $uploadid,
    };

    return $schema->resultset('Stats')->update_or_create($stat, { key => 'guid' });
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::ResultSet::Stats - Query the raw test reports

=head1 VERSION

version 0.019

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'Stats' );
    $rs->insert_test_report( $schema->resultset( 'TestReport' )->first );

=head1 DESCRIPTION

This object helps to insert and query the legacy test reports (cpanstats).

=head1 METHODS

=head2 insert_test_report

    my $stat = $rs->insert_test_report( $report );

Convert a L<CPAN::Testers::Schema::Result::TestReport> object to the new test
report structure and insert it into the database. This is for creating
backwards-compatible APIs.

Returns an instance of L<CPAN::Testers::Schema::Result::Stats> on success.
Note that since an uploadid is required for the cpanstats table, this method
throws an exception when an upload cannot be determined from the given
information.

=head1 SEE ALSO

L<CPAN::Testers::Schema::Result::Stats>, L<DBIx::Class::ResultSet>,
L<CPAN::Testers::Schema>

=head1 AUTHORS

=over 4

=item *

Oriol Soriano <oriolsoriano@gmail.com>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
