#!perl

use strict;
use warnings;
use Test::More tests => 11;
use CPAN::Reporter::Smoker::Safer;
use CPAN;  # CPAN::Distribution
$|=1;

my $dist = bless( {
                   'ID' => 'K/KY/KYLE/Acme-ExceptionEater-v0.0.1.tar.gz',
                   'UPLOAD_DATE' => '2007-09-11',
                   'RO' => {
                             'CPAN_USERID' => 'KYLE',
                             'CPAN_COMMENT' => undef
                           }
                 }, 'CPAN::Distribution' )
;
my $distDNE = bless( {
                   'ID' => 'A/AC/ACME/DNE__TEST_BLAH-1.23.456.tar.gz',
                   'UPLOAD_DATE' => '',
                   'RO' => {
                             'CPAN_USERID' => 'NO_ONE',
                             'CPAN_COMMENT' => undef
                           }
                 }, 'CPAN::Distribution' )
;

#		dist	result	days	reports	exceptions
check_filter($dist,	1,	0,	0,	() );
check_filter($dist,	0,	0,	0,	( qr/Acme/ ) );
check_filter($dist,	0,	99999,	0,	() );
check_filter($dist,	1,	0,	1,	() );
check_filter($dist,	0,	99999,	1,	() );
check_filter($dist,	0,	0,	99999,	() );
check_filter($dist,	0,	99999,	99999,	() );

check_filter($distDNE,	1,	0,	0,	() );
check_filter($distDNE,	0,	1,	0,	() );
check_filter($distDNE,	0,	0,	1,	() );
check_filter($distDNE,	0,	1,	1,	() );

exit;

#############################################################

sub check_filter {
  my ($dist, $expected, $min_days_old, $min_reports, @exclusions) = @_;
  local $CPAN::Reporter::Smoker::Safer::MIN_DAYS_OLD  = $min_days_old;
  local $CPAN::Reporter::Smoker::Safer::MIN_REPORTS   = $min_reports;
  local @CPAN::Reporter::Smoker::Safer::RE_EXCLUSIONS = @exclusions;
  local $CPAN::Reporter::Smoker::Safer::EXCLUDE_TESTED = 0;
  my $s = sprintf "[%s] %s reps>=%d,days>=%d,REs=%d", $dist->pretty_id, ($expected?'+':'-'), $min_reports, $min_days_old, scalar(@exclusions);
  is( CPAN::Reporter::Smoker::Safer->__filter( $dist ), $expected, $s );
}

