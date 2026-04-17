#!perl -T
use 5.008;
use strict;
no strict 'subs'; # Constants throw this off.
use warnings FATAL => 'all';
use Test::More tests => 15;

#   ___                          _ _ ___         _ _          _____         _     
#  / __|___ _ __  _ __  ___ _ _ (_|_) __|___  __| (_)_ _  __ |_   _|__  ___| |___ 
# | (__/ _ \ '  \| '  \/ _ \ ' \ _ | (__/ _ \/ _` | | ' \/ _` || |/ _ \/ _ \ (_-< 
#  \___\___/_|_|_|_|_|_\___/_||_(_|_)___\___/\__,_|_|_||_\__, ||_|\___/\___/_/__/ 
#                                                        |___/
#  Functions Tests

BEGIN {
    use_ok('Common::CodingTools', qw(:functions)) || BAIL_OUT("Bail out! Can't load Common::CodingTools qw(:functions)!\n");
}

my $test = '   test   ';
ok(slurp_file('README.md') ne '', ' slurp_file("README.me")');
ok(ltrim($test) eq 'test   ', ' ltrim                                            > "' . $test . '" to "' . ltrim($test) . '"');
ok(rtrim($test) eq '   test', ' rtrim                                            > "' . $test . '" to "' . rtrim($test) . '"');
ok(trim($test) eq 'test', ' trim                                             > "' . $test . '" to "' . trim($test) . '"');

my $tf = 'my super duper title and it is cool';
ok(tfirst($tf) eq 'My Super Duper Title and It Is Cool', ' tfirst                                           > "' . $tf . '" to "' . tfirst($tf) . '"');

ok(uc_lc('howdy there', 1) eq 'HoWdY tHeRe', ' uc_lc (upper first)                              > "howdy there" to "' . uc_lc('howdy there',1) . '"');
ok(uc_lc('howdy there', 0) eq 'hOwDy ThErE', ' uc_lc (lower first)                              > "howdy there" to "' . uc_lc('howdy there',0) . '"');

ok(leet_speak('super duper mega-nerd', 1) eq 'SuPeR dUpEr MeGa-NeRd', ' leet_speak (upper first)                         > "super duper mega-nerd" to "' . leet_speak('super duper mega-nerd',1) . '"');
ok(leet_speak('super duper mega-nerd', 0) eq 'sUpEr DuPeR mEgA-nErD', 'leet_speak (lower first)                         > "super duper mega-nerd" to "' . leet_speak('super duper mega-nerd',0 . '"'));

ok(center('centered',20) eq '      centered      ', 'center (width of 20)                             > "centered" to "' . center('centered',20) . '"');

my @array = (qw(dog apple zoo mountain));
my @schwartz = schwartzian_sort(@array);
ok(join(' ',@schwartz) eq 'apple dog mountain zoo', 'schwartzian sort (want array pass array)         > (' . join(', ',@array) . ') to (' . join(', ',@schwartz) . ')');
@schwartz = schwartzian_sort(\@array);
ok(join(' ',@schwartz) eq 'apple dog mountain zoo', 'schwartzian sort (want array pass reference)     > [' . join(', ',@array) . '] to (' . join(', ',@schwartz) . ')');

my $sb = schwartzian_sort(@array);
ok(join(' ',@{$sb}) eq 'apple dog mountain zoo', 'schwartzian sort (want reference pass array)     > (' . join(', ', @array) . ') to [' . join(', ',@{$sb}) . ']');
$sb = schwartzian_sort(\@array);
ok(join(' ',@{$sb}) eq 'apple dog mountain zoo', 'schwartzian sort (want reference pass reference) > [' . join(', ', @array) . '] to [' . join(', ',@{$sb}) . ']');
