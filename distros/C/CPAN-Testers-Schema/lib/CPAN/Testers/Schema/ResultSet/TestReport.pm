use utf8;
package CPAN::Testers::Schema::ResultSet::TestReport;
our $VERSION = '0.015';
# ABSTRACT: Query the raw test reports

#pod =head1 SYNOPSIS
#pod
#pod     my $rs = $schema->resultset( 'TestReport' );
#pod     $rs->insert_metabase_fact( $fact );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This object helps to insert and query the raw test reports.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<CPAN::Testers::Schema::Result::TestReport>, L<DBIx::Class::ResultSet>,
#pod L<CPAN::Testers::Schema>
#pod
#pod =cut

use CPAN::Testers::Schema::Base 'ResultSet';
use Scalar::Util qw( blessed );

#pod =method dist
#pod
#pod     my $rs = $rs->dist( 'Perl 5', 'CPAN-Testers-Schema' );
#pod     my $rs = $rs->dist( 'Perl 5', 'CPAN-Testers-Schema', '0.012' );
#pod
#pod Fetch reports only for the given distribution, optionally for the given
#pod version. Returns a new C<CPAN::Testers::Schema::ResultSet::TestReport>
#pod object that will only return reports with the given data.
#pod
#pod This can be used to scan the full reports for specific data.
#pod
#pod =cut

sub dist( $self, $lang, $dist, $version=undef ) {
    return $self->search( {
        'report' => [ -and =>
            \[ "->> '\$.environment.language.name'=?", $lang ],
            \[ "->> '\$.distribution.name'=?", $dist ],
            ( defined $version ? (
                \[ "->> '\$.distribution.version'=?", $version ],
            ) : () ),
        ],
    } );
}

#pod =method insert_metabase_fact
#pod
#pod     my $row = $rs->insert_metabase_fact( $fact );
#pod
#pod Convert a L<Metabase::Fact> object to the new test report structure and
#pod insert it into the database. This is for creating backwards-compatible
#pod APIs.
#pod
#pod =cut

sub insert_metabase_fact( $self, $fact ) {
    my ( $fact_report ) = grep { blessed $_ eq 'CPAN::Testers::Fact::LegacyReport' } $fact->content->@*;
    my %fact_data = (
        $fact_report->content->%*,
        $fact->core_metadata->%{qw( creation_time guid )},
        $fact->core_metadata->{resource}->metadata->%{qw( dist_name dist_version dist_file cpan_id )},
    );

    my $user_id = $fact->core_metadata->{creator}->resource;
    my ( $metabase_user ) = $self->result_source->schema->resultset( 'MetabaseUser' )
        ->search( { resource => $user_id }, { order_by => '-id', limit => 1 } )->all;

    my %report = (
        reporter => {
            name => $metabase_user->fullname,
            email => $metabase_user->email,
        },
        environment => {
            system => {
                osname => $fact_data{osname},
                osversion => $fact_data{osversion},
            },
            language => {
                name => "Perl 5",
                version => $fact_data{perl_version},
                archname => $fact_data{archname},
            },
        },
        distribution => {
            name => $fact_data{dist_name},
            version => $fact_data{dist_version},
        },
        result => {
            grade => lc $fact_data{grade},
            output => {
                uncategorized => $fact_data{textreport},
            },
        }
    );

    my $format = DateTime::Format::ISO8601->new();
    my $creation = $format->parse_datetime( $fact->creation_time );

    return $self->create({
        id => $fact->guid,
        created => $creation,
        report => \%report,
    });
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Schema::ResultSet::TestReport - Query the raw test reports

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    my $rs = $schema->resultset( 'TestReport' );
    $rs->insert_metabase_fact( $fact );

=head1 DESCRIPTION

This object helps to insert and query the raw test reports.

=head1 METHODS

=head2 dist

    my $rs = $rs->dist( 'Perl 5', 'CPAN-Testers-Schema' );
    my $rs = $rs->dist( 'Perl 5', 'CPAN-Testers-Schema', '0.012' );

Fetch reports only for the given distribution, optionally for the given
version. Returns a new C<CPAN::Testers::Schema::ResultSet::TestReport>
object that will only return reports with the given data.

This can be used to scan the full reports for specific data.

=head2 insert_metabase_fact

    my $row = $rs->insert_metabase_fact( $fact );

Convert a L<Metabase::Fact> object to the new test report structure and
insert it into the database. This is for creating backwards-compatible
APIs.

=head1 SEE ALSO

L<CPAN::Testers::Schema::Result::TestReport>, L<DBIx::Class::ResultSet>,
L<CPAN::Testers::Schema>

=head1 AUTHORS

=over 4

=item *

Oriol Soriano <oriolsoriano@gmail.com>

=item *

Doug Bell <preaction@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Oriol Soriano, Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
