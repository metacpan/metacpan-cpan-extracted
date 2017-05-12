#!perl

use Test::More tests => 2;

BEGIN {
    use_ok( 'Data::PerlSurvey2007' );
}

my $line = q{
ID,"Year of birth",Sex,"Country of birth","Country of residence","Primary language spoken",Income,Industry/ies,"Years programming Perl","Years programming (total)","Programming languages known","Other programming languages known","Proportion of Perl","Perl versions",Platforms,"Subscribed to Perl Mongers list","Posted to Perl Mongers list","Subscribed to other list","Posted to other list",Perlmonks,"Contributed to websites","Attended Perl Mongers","Attended Perl Mongers (non-local)","Attended conference","Attended conference (non-local)","Presented at conference","Contributed to CPAN","Contributed to Perl 5","Contributed to Perl 6","Contributed to other projects","Led other projects","Provided feedback","CPAN modules maintained","Date survey completed"
};

$line =~ s/^\s+//;
$line =~ s/\s+$//;

my @columns = Data::PerlSurvey2007::split_csv( $line );
is( scalar @columns, 34, 'Got all my columns' );
