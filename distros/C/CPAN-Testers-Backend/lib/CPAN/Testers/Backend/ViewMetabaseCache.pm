package CPAN::Testers::Backend::ViewMetabaseCache;
our $VERSION = '0.004';
# ABSTRACT: View an entry from the old metabase cache

#pod =head1 SYNOPSIS
#pod
#pod     beam run <container> <service> [--force | -f]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This task allows viewing the data in the C<metabase.metabase> table to
#pod make sure it's accurate and correct.
#pod
#pod =cut

use CPAN::Testers::Backend::Base 'Runnable';
with 'Beam::Runnable';
use Getopt::Long qw( GetOptionsFromArray );
use Data::FlexSerializer;
use JSON::MaybeXS qw( encode_json );
use CPAN::Testers::Report;
use CPAN::Testers::Fact::TestSummary;
use CPAN::Testers::Fact::LegacyReport;
use CPAN::Testers::Backend::Migrate::MetabaseCache;
use Data::Dumper;

#pod =attr metabase_dbh
#pod
#pod The L<DBI> object connected to the C<metabase> database.
#pod
#pod =cut

has metabase_dbh => (
    is => 'ro',
    isa => InstanceOf['DBI::db'],
    required => 1,
);

sub run( $self, @args ) {

    my $row = $self->metabase_dbh->selectrow_hashref(
        "SELECT * FROM metabase WHERE guid=?", {}, $args[0],
    );
    my $migrate = "CPAN::Testers::Backend::Migrate::MetabaseCache";

    say "----- Fact column";
    my $fact = $migrate->parse_metabase_report( {
        fact => $row->{fact},
        guid => $row->{guid},
        id => $row->{id},
        updated => $row->{updated},
    } );
    say Dumper $fact;

    say "----- Report column";
    my $report = $migrate->parse_metabase_report( {
        report => $row->{report},
        guid => $row->{guid},
        id => $row->{id},
        updated => $row->{updated},
    } );
    say Dumper $report;
}

1;

__END__

=pod

=head1 NAME

CPAN::Testers::Backend::ViewMetabaseCache - View an entry from the old metabase cache

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    beam run <container> <service> [--force | -f]

=head1 DESCRIPTION

This task allows viewing the data in the C<metabase.metabase> table to
make sure it's accurate and correct.

=head1 ATTRIBUTES

=head2 metabase_dbh

The L<DBI> object connected to the C<metabase> database.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
