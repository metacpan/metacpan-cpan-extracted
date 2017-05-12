#!perl -T

use strict;
use warnings;

# Just to simplify using Config - the module might very well work even
# on older versions, but really, does anybody need them?
require 5.005_640;

# Tests using Unicode strings crash on perl 5.6.2 .
use Config;
use Test::More tests => (($Config{api_version} < 8) ? 21 : 25);

use Algorithm::AhoCorasick::SearchMachine;

is($Config{api_revision}, 5);

my $expected_pos;
my $expected_keyword;
my $break_flag = 0;
my $counter;

sub check {
    my ($pos, $keyword) = @_;

    ok(defined($pos));
    is($pos, $expected_pos);
    $expected_pos = undef;

    ok(defined($keyword));
    is($keyword, $expected_keyword);
    $expected_keyword = undef;

    return $break_flag;
}

sub count {
    ++$counter;

    return '';
}

my $machine = Algorithm::AhoCorasick::SearchMachine->new("be");

$expected_pos = 3;
$expected_keyword = "be";
my $rv = $machine->feed("To be or not to b", \&check);
ok(!defined($rv));

$rv = $machine->feed("", \&check);
ok(!defined($rv));


$expected_pos = -1;
$expected_keyword = "be";
$rv = $machine->feed("e", \&check);
ok(!defined($rv));

$machine = Algorithm::AhoCorasick::SearchMachine->new("be");
$counter = 0;
$rv = $machine->feed("To be or not to be", \&count);
ok(!defined($rv));
is($counter, 2);

$expected_pos = 3;
$expected_keyword = "be";
$break_flag = 42;
$machine = Algorithm::AhoCorasick::SearchMachine->new("be");
$rv = $machine->feed("To be or not to be", \&check);
is($rv, 42);

$machine = Algorithm::AhoCorasick::SearchMachine->new("sa", "se", "si", "so", "su");
$counter = 0;
$rv = $machine->feed("Un chasseur qui sache chasser ne chase jamais sans son chien", \&count);
ok(!defined($rv));
is($counter, 6);

if ($Config{api_version} >= 8) {
    use utf8;

    $machine = Algorithm::AhoCorasick::SearchMachine->new("pře");
    $expected_pos = 12;
    $expected_keyword = "pře";
    $machine->feed("skákal pes, přes oves", \&check);
}


