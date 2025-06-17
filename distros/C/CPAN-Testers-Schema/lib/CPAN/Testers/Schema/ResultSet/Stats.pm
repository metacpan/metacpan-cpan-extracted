use utf8;
package CPAN::Testers::Schema::ResultSet::Stats;
our $VERSION = '0.028';
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
use Carp ();

#pod =method since
#pod
#pod     my $rs = $rs->since( $iso_dt );
#pod
#pod Restrict the resultset to reports submitted since the given date/time (in ISO8601 format).
#pod
#pod =cut

sub since( $self, $date ) {
    my $fulldate = $date =~ s/[-:T]//gr;
    $fulldate = substr $fulldate, 0, 12; # 12 digits makes YYYYMMDDHHNN
    return $self->search( { fulldate => { '>=', $fulldate } } );
}

#pod =method perl_maturity
#pod
#pod     $rs = $rs->perl_maturity( 'stable' ) # or 'dev'
#pod
#pod Restrict the resultset to reports submitted for either C<stable> or
#pod C<dev> Perl versions.
#pod
#pod =cut

sub perl_maturity( $self, $maturity ) {
    my $devel = $maturity eq 'stable' ? 0 : $maturity eq 'dev' ? 1
        : Carp::croak "Unknown maturity: $maturity; Must be one of: 'stable', 'dev'";
    if ( !$devel ) {
        # Patch versions are not stable either
        return $self->search(
            { 'perl_version.devel' => 0, 'perl_version.patch' => 0 },
            { join => 'perl_version' },
        );
    }
    return $self->search(
        { -or => { 'perl_version.devel' => 1, 'perl_version.patch' => 1 } },
        { join => 'perl_version' },
    );
}

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
    $LOG->infof( 'Updating stats row (report %s)', $guid );
    my $data = $report->report;
    my $created = $report->created;

    # attempt to find an uploadid, which is required for cpanstats
    my @uploads = $schema->resultset('Upload')->search({
        dist => $data->{distribution}{name},
        version => $data->{distribution}{version},
    })->all;

    if ( !@uploads ) {
        $LOG->warnf(
            'No upload matches for dist %s version %s (report %s). Creating provisional record.',
            $data->{distribution}->@{qw( name version )}, $guid,
        );
        @uploads = (
          $schema->resultset('Upload')->create({
            dist => $data->{distribution}{name},
            $data->{distribution}->%{qw( version )},
            type => 'unknown',
            author => '',
            filename => '',
            released => 0,
          }),
        );
    }
    elsif ( @uploads > 1 ) {
        $LOG->warnf(
            'Multiple upload matches for dist %s version %s (report %s)',
            $data->{distribution}->@{qw( name version )}, $guid,
        );
    }
    my $uploadid = $uploads[0]->uploadid;

    my $encoded_name = $data->{reporter}{name} =~ s/([^[:ascii:]])/'&#' . ord( $1 ) . ';'/ger;
    my $stat = {
        guid => $guid,
        state => lc($data->{result}{grade}),
        postdate => $created->strftime('%Y%m'),
        tester => qq["] . $encoded_name . qq[" <$data->{reporter}{email}>],
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

version 0.028

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'Stats' );
    $rs->insert_test_report( $schema->resultset( 'TestReport' )->first );

=head1 DESCRIPTION

This object helps to insert and query the legacy test reports (cpanstats).

=head1 METHODS

=head2 since

    my $rs = $rs->since( $iso_dt );

Restrict the resultset to reports submitted since the given date/time (in ISO8601 format).

=head2 perl_maturity

    $rs = $rs->perl_maturity( 'stable' ) # or 'dev'

Restrict the resultset to reports submitted for either C<stable> or
C<dev> Perl versions.

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

This software is copyright (c) 2018 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
