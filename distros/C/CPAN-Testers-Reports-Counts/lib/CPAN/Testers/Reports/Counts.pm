package CPAN::Testers::Reports::Counts;
$CPAN::Testers::Reports::Counts::VERSION = '0.05';
# ABSTRACT: counts of CPAN Testers reports by month or year
use strict;
use warnings;
use 5.008;

use parent 'Exporter';
use Net::HTTP::Tiny qw(http_get);

our @EXPORT_OK   = qw(reports_counts_by_month reports_counts_by_year);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );
my $reports_by_month;
my $reports_by_year;

sub _initialise
{
    $reports_by_month = {};
    $reports_by_year  = {};
    _load_counts('http://stats.cpantesters.org/stats/stats1.txt');
    _load_counts('http://stats.cpantesters.org/stats/stats3.txt');
    _lock_data($reports_by_month);
    _lock_data($reports_by_year);
}

sub _load_counts
{
    my $url     = shift;
    my $content = http_get($url);
    my @lines   = split(/[\r\n]+/, $content);
    my @header  = split(/,/, shift @lines);
    my $year;

    foreach my $line (@lines) {
        my ($month, @fields) = split(/,/, $line);
        ($year = $month) =~ s/..$//;
        $month =~ s/(..)$/-$1/;

        FIELD:
        for (my $i = 0; $i < @fields; $i++) {
            my $key = $header[$i+1];

            # Don't double-count FAIL: column appears in both files
            next FIELD if exists($reports_by_month->{$month}->{$key});

            $reports_by_month->{$month}->{$key}  = $fields[$i];
            $reports_by_year->{$year}->{$key}   += $fields[$i];
        }
    }
}

sub _lock_data
{
    my $ref = shift;

    foreach my $period (keys %$ref) {
        foreach my $key (keys %{ $ref->{$period} }) {
            Internals::SvREADONLY($ref->{$period}->{$key}, 1);
        }
        Internals::SvREADONLY(%{ $ref->{$period} }, 1);
    }
    Internals::SvREADONLY(%$ref, 1);
}

sub reports_counts_by_month
{
    _initialise() if not defined($reports_by_month);
    return $reports_by_month;
}

sub reports_counts_by_year
{
    _initialise() if not defined($reports_by_year);
    return $reports_by_year;
}

1;

=head1 NAME

CPAN::Testers::Reports::Count - counts of CPAN Testers reports by month or year

=head1 SYNOPSIS

 use CPAN::Testers::Reports::Counts ':all';

 $counts = reports_counts_by_year();

 foreach my $year (sort keys %$counts) {
     print "$year:\n";
     foreach my $category (qw(REPORTS PASS FAIL NA UNKNOWN)) {
         print "   $category = $counts->{$year}->{$category}\n";
     }
 }

=head1 DESCRIPTION

This module gives you the number of CPAN Testers reports that
were submitted in every month or year that CPAN Testers has been running.
The data is returned as a hash reference, with the keys identifying
either years or year/month pairs. For each month or year there are five
numbers available:

=over 4

=item * B<REPORTS>: the total number of reports submitted.

=item * B<PASS>: the number of successful test reports.

=item * B<FAIL>: the number of failing test reports.

=item * B<NA>: the number of "Not Applicable" results. Eg the version of Perl wasn't supported.

=item * B<UNKNOWN>: the number of Unknown tests. Eg the dist doesn't have any tests.

=back

More detailed definitions of these can be found on the
L<CPAN Testers wiki|http://wiki.cpantesters.org/wiki/Reports>.

The data is grabbed from the L<CPAN Testers Statistics|http://stats.cpantesters.org>
web site, so you must have a working internet connection when you use this module.

There are two functions, used to get the reports counts either by year or by month.

=head2 reports_counts_by_year

This function returns a hashref which is keyed off the years for which reports
have been submitted:

 use CPAN::Testers::Reports::Counts 'reports_counts_by_year';
 $counts = reports_counts_by_year();
 print "total = $counts->{2013}->{REPORTS}\n";

The value in the hash for each year is another hashref, which is keyed off
the report grades listed above.

=head2 reports_counts_by_month

This function returns a hashref which is keyed off the months for which reports
have been submitted. The months are in the format 'YYYY-MM'.

 use CPAN::Testers::Reports::Counts 'reports_counts_by_month';
 $counts = reports_counts_by_month();
 print "Dec 2013 = $counts->{'2013-12'}->{REPORTS}\n";

=head1 SEE ALSO

L<CPAN Testers Statistics|http://stats.cpantesters.org>,
L<CPAN Testers wiki|http://wiki.cpantesters.org/wiki/Reports>.
L<CPAN::Testers::Data::Generator> - a module used to download and summarize CPAN Testers data.

=head1 REPOSITORY

L<https://github.com/neilb/CPAN-Testers-Reports-Counts>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

