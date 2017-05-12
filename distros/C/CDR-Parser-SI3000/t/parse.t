#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 12;

BEGIN {
    use_ok( 'CDR::Parser::SI3000' ) || print "Bail out!\n";
}

my $calc_ok = 0;
my($cdrs, $failed) = ();
eval {
    ($cdrs, $failed) = CDR::Parser::SI3000->parse_file('t/test.ama');
    $calc_ok = 1;
};
die $@ if($@);

ok($calc_ok, 'File parsed');
is($failed, 0, 'No parse errors');
ok($cdrs, 'File parsed');
is($cdrs && scalar(@$cdrs), 15, 'Found 15 calls');

my $cdr = $cdrs->[0];
is($cdr->{cli}, '3001305', 'CLI');
is($cdr->{cld}, '002906914', 'CLD');
is($cdr->{start_time}, '2013-09-29 02:04:11.00', 'Start Time');
is($cdr->{end_time}, '2013-09-29 02:17:23.00', 'End Time');
is($cdr->{call_duration_ms}, '791690', 'Duration, ms');
is($cdr->{call_release_cause_code}, '16', 'Normal call end');
is($cdr->{call_id}, '1003385', 'Call ID');
