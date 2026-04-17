#!perl -T

use 5.008;
use strict;
no strict 'subs'; # Constants throw this off.
use warnings FATAL => 'all';

use Test::More tests => 38;

#   ___                          _ _ ___         _ _          _____         _     
#  / __|___ _ __  _ __  ___ _ _ (_|_) __|___  __| (_)_ _  __ |_   _|__  ___| |___ 
# | (__/ _ \ '  \| '  \/ _ \ ' \ _ | (__/ _ \/ _` | | ' \/ _` || |/ _ \/ _ \ (_-< 
#  \___\___/_|_|_|_|_|_\___/_||_(_|_)___\___/\__,_|_|_||_\__, ||_|\___/\___/_/__/ 
#                                                        |___/
#  All Tests

BEGIN {
    use_ok('Common::CodingTools', qw( :all )) || BAIL_OUT("Bail out! Can't load Common::CodingTools qw(:all)");
}

my $test = '   test   ';

ok(TRUE       == 1, ' TRUE       = ' . TRUE);
ok(FALSE      == 0, ' FALSE      = ' . FALSE);
ok(ON         == 1, ' ON         = ' . ON);
ok(OFF        == 0, ' OFF        = ' . OFF);
ok(ACTIVE     == 1, ' ACTIVE     = ' . ACTIVE);
ok(INACTIVE   == 0, ' INACTIVE   = ' . INACTIVE);
ok(HEALTHY    == 1, ' HEALTHY    = ' . HEALTHY);
ok(UNHEALTHY  == 0, ' UNHEALTHY  = ' . UNHEALTHY);
ok(EXPIRED    == 1, 'EXPIRED    = ' . EXPIRED);
ok(NOTEXPIRED == 0, 'NOTEXPIRED = ' . NOTEXPIRED);
ok(CLEAN      == 1, 'CLEAN      = ' . CLEAN);
ok(DIRTY      == 0, 'DIRTY      = ' . DIRTY);
ok(HAPPY      == 1, 'HAPPY      = ' . HAPPY);
ok(UNHAPPY    == 0, 'UNHAPPY    = ' . UNHAPPY);
ok(SAD        == 0, 'SAD        = ' . SAD);
ok(ANGRY      == 0, 'ANGRY      = ' . ANGRY);
ok(SUCCESS    == 1, 'SUCCESS    = ' . SUCCESS);
ok(SUCCESSFUL == 1, 'SUCCESSFUL = ' . SUCCESSFUL);
ok(SUCCEEDED  == 1, 'SUCCEEDED  = ' . SUCCEEDED);
ok(FAILURE    == 0, 'FAILURE    = ' . FAILURE);
ok(FAILED     == 0, 'FAILED     = ' . FAILED);
ok(FAIL       == 0, 'FAIL       = ' . FAIL);
ok((4 * atan2(1, 1)) == PI, 'PI         = ' . PI);

my $slurp = slurp_file('README.md') || '';
ok($slurp ne '', 'slurp_file("README.me")');
ok(ltrim($test) eq 'test   ', 'ltrim                                            > "' . $test . '" to "' . ltrim($test) . '"');
ok(rtrim($test) eq '   test', 'rtrim                                            > "' . $test . '" to "' . rtrim($test) . '"');
ok(trim($test) eq 'test', 'trim                                             > "' . $test . '" to "' . trim($test) . '"');

my $tf = 'my super duper title and it is cool';
ok(tfirst($tf) eq 'My Super Duper Title and It Is Cool', 'tfirst                                           > "' . $tf . '" to "' . tfirst($tf) . '"');

ok(uc_lc('howdy there', 1) eq 'HoWdY tHeRe', 'uc_lc (upper first)                              > "howdy there" to "' . uc_lc('howdy there',1) . '"');
ok(uc_lc('howdy there', 0) eq 'hOwDy ThErE', 'uc_lc (lower first)                              > "howdy there" to "' . uc_lc('howdy there',0) . '"');

ok(leet_speak('some leet nerd said this', 1) eq 'SoMe LeEt NeRd SaId ThIs', 'leet_speak (upper first)                         > "some leet nerd said this" to "' . leet_speak('some leet nerd said this',1) . '"');
ok(leet_speak('some leet nerd said this', 0) eq 'sOmE lEeT nErD sAiD tHiS', 'leet_speak (lower first)                         > "some leet nerd said this" to "' . leet_speak('some leet nerd said this',0) . '"');

ok(center('centered', 20) eq '      centered      ', 'center (width of 20)                             > "centered" to "' . center('centered', 20) . '"');

my @array = (qw(xylophone dog apple zoo mountain));
my @schwartz = schwartzian_sort(@array);
ok(join(' ', @schwartz) eq 'apple dog mountain xylophone zoo', 'schwartzian sort (want array pass array)         > (' . join(', ',@array) . ') to (' . join(', ',@schwartz) . ')');
@schwartz = schwartzian_sort(\@array);
ok(join(' ', @schwartz) eq 'apple dog mountain xylophone zoo', 'schwartzian sort (want array pass reference)     > [' . join(', ',@array) . '] to (' . join(', ',@schwartz) . ')');

my $sb = schwartzian_sort(\@array);
ok(join(' ', @{$sb}) eq 'apple dog mountain xylophone zoo', 'schwartzian sort (want reference pass reference) > [' . join(', ', @array) . '] to [' . join(', ',@{$sb}) . ']');
$sb = schwartzian_sort(@array);
ok(join(' ', @{$sb}) eq 'apple dog mountain xylophone zoo', 'schwartzian sort (want reference pass array)     > (' . join(', ', @array) . ') to [' . join(', ',@{$sb}) . ']');
