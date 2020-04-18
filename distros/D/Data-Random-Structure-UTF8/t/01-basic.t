#!perl -T
use 5.8.0;
use strict;
use warnings;

use utf8;

our $VERSION='0.06';

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN,  ':encoding(UTF-8)';
# to avoid wide character in TAP output
# do this before loading Test* modules
use open ':std', ':encoding(utf8)';

use Test::More;
use Data::Random::Structure::UTF8;
use Data::Dump qw/pp/;
use Data::Dumper;

# we are dealing with a random generator
# so give it a change to produce some unicode
# eventually after so many trials, it usually does after 1-10 trials
my $MAXTRIALS=100;

############################
#### nothing to change below
my $num_tests = 0;

my ($perl_var, $found, $found1, $found2, $trials, $rc, $alength);

my $randomiser = Data::Random::Structure::UTF8->new(
	max_depth => 5,
	max_elements => 20,
);
ok(defined $randomiser, 'Data::Random::Structure::UTF8->new()'." called."); $num_tests++;

$found = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate();
	ok(defined $perl_var, "generate() called."); $num_tests++;
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'strings-unicode' => 1,
	}) ){ $found=1; last }
}
ok($found==1, "generate() : produced unicode content (after ".($MAXTRIALS-$trials)." trials)."); $num_tests++; 

$found = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate_scalar();
	ok(defined $perl_var, "generate_scalar() called."); $num_tests++;
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'strings-unicode' => 1,
	}) ){ $found=1; last }
}
ok($found==1, "generate_scalar() : produced unicode content (after ".($MAXTRIALS-$trials)." trials)."); $num_tests++; 

$found = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate_hash();
	ok(defined $perl_var, "generate_hash() called."); $num_tests++;
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'strings-unicode' => 1,
	}) ){ $found=1; last }
}
ok($found==1, "generate_hash() : produced unicode content (after ".($MAXTRIALS-$trials)." trials)."); $num_tests++; 

$found = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate_array();
	ok(defined $perl_var, "generate_array() called."); $num_tests++;
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'strings-unicode' => 1,
	}) ){ $found=1; last }
}
ok($found==1, "generate_array() : produced unicode content (after ".($MAXTRIALS-$trials)." trials)."); $num_tests++; 

# check if pp still complains about lc
$found1 = 0; $found2 = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate_scalar();
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'strings-unicode' => 1,
	}) ){
		$rc = eval { my $x=Data::Dump::pp($perl_var); 1 };
		if( $@ || ! $rc ){ $found1=1; last }
		$rc = eval { my $x=Dumper($perl_var); 1 };
		if( $@ || ! $rc ){ $found2=1; last }
	}
}
if( $found1==1 ){ ok(1==1, "good to know, Data::Dump still complains"); $num_tests++; }
else { ok(1==1, "Data::Dump stopped complaining?"); $num_tests++; }
if( $found2==1 ){ ok(1==1, "good to know, Data::Dumper still complains"); $num_tests++; }
else { ok(1==1, "Data::Dumper stopped complaining?"); $num_tests++; }

#print pp($perl_var);

done_testing($num_tests);
