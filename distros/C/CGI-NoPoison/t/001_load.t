# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 7;

BEGIN {
	use CGI;
	use_ok( 'CGI::NoPoison' ); 
}

my $m = CGI->new();
isa_ok ($m, 'CGI');

$m->param(
    -name=>'amplifier',
    -value=>['nine', 'ten', 'up to eleven'],
);
my %h = $m->Vars();
ok( ref($h{amplifier}) eq 'ARRAY', "Vars() returns anon array for hash when list values > 1");

ok($h{amplifier}->[2] eq 'up to eleven', "Dereferencing works properly");

my @ary = $m->param('amplifier');
ok( scalar @ary == 3, "correct num. of array elements");

$m->param(
	-name=>'singleton',
	-value=>["unary"],
);

my %h2 = $m->Vars();

ok( ref($h2{singleton}) eq '', "Vars() returns empty string for hash when list values = 1");

ok ( $h2{singleton} eq 'unary', "No dereferencing necessary for single values");

