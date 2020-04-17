#!/usr/bin/env perl

use lib 'blib/lib';

##!perl -T
use 5.8.0;
use strict;
use warnings;

use utf8;

our $VERSION='0.04';

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN,  ':encoding(UTF-8)';
# to avoid wide character in TAP output
# do this before loading Test* modules
use open ':std', ':encoding(utf8)';

use Test::More;
#use Test::Deep;

use Data::Random::Structure::UTF8;

use Data::Dump qw/pp/;
use Data::Dumper;

# we are dealing with a random generator
# so give it a change to produce some unicode
# eventually after so many trials, it usually does after 1-10 trials
my $MAXTRIALS=100;

############################
#### nothing to change below
srand 42+12;

my $num_tests = 0;

my ($perl_var, $found, $found1, $found2, $trials, $rc, $alength, $randomiser);

$randomiser = Data::Random::Structure::UTF8->new(
	max_depth => 5,
	max_elements => 20,
	'only-unicode' => 1, # that can have numbers and unicode strings
);
ok(defined $randomiser, 'Data::Random::Structure::UTF8->new()'." called."); $num_tests++;

is($randomiser->only_unicode(),1, "only unicode set to 1."); $num_tests++;

ok(0==scalar(grep{ $_ eq 'string' } @{$randomiser->{'_scalar_types'}}), "removed the string type."); $num_tests++;

ok(1, "found these types: '".join("','",  @{$randomiser->{'_scalar_types'}})."'."); $num_tests++;
$found = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate();
	if( ! defined $perl_var ){ ok(0, "generate() failed.");  $num_tests++; }

	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>1,
		'strings'=>0,
	}) ){ $found |= 1 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-unicode'=>1,
	}) ){ $found |= 2 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-plain'=>1,
	}) ){ $found |= 4 }
}
ok($found&1, "generate() : has numbers (after $MAXTRIALS trials)."); $num_tests++; 
ok($found&2, "generate() : has unicode strings (after $MAXTRIALS trials)."); $num_tests++; 
ok(!($found&4), "generate() : does not have non-unicode strings (after $MAXTRIALS trials)."); $num_tests++; 

$randomiser->only_unicode(2);
is($randomiser->only_unicode(),2, "only unicode set to 2."); $num_tests++;
ok($randomiser->{'_scalar_types'}->[0] eq 'string-UTF8', "has string-UTF8 set."); $num_tests++;
ok($#{$randomiser->{'_scalar_types'}}==0, "no other type is set."); $num_tests++;
ok(1, "found these types: '".join("','",  @{$randomiser->{'_scalar_types'}})."'."); $num_tests++;
$found = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate();
	if( ! defined $perl_var ){ ok(0, "generate() failed.");  $num_tests++; }

	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>1,
		'strings'=>0,
	}) ){ $found |= 1 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-unicode'=>1,
	}) ){ $found |= 2 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-plain'=>1,
	}) ){ $found |= 4 }
}
ok(!($found&1), "generate() : does not have numbers (after $MAXTRIALS trials)."); $num_tests++; 
ok($found&2, "generate() : has unicode strings (after $MAXTRIALS trials)."); $num_tests++; 
ok(!($found&4), "generate() : does not have non-unicode strings (after $MAXTRIALS trials)."); $num_tests++; 

$randomiser->only_unicode(0);
is($randomiser->only_unicode(),0, "only unicode set to 0."); $num_tests++;
ok(0<scalar(grep{ $_ eq 'string-UTF8' } @{$randomiser->{'_scalar_types'}}), "has string-UTF8 set."); $num_tests++;
ok(0<scalar(grep{ $_ eq 'string' } @{$randomiser->{'_scalar_types'}}), "has string set."); $num_tests++;
ok(1, "found these types: '".join("','",  @{$randomiser->{'_scalar_types'}})."'."); $num_tests++;
$found = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate();
	if( ! defined $perl_var ){ ok(0, "generate() failed.");  $num_tests++; }

	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>1,
		'strings'=>0,
	}) ){ $found |= 1 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-unicode'=>1,
	}) ){ $found |= 2 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-plain'=>1,
	}) ){ $found |= 4 }
}
ok($found&1, "generate() : has numbers (after $MAXTRIALS trials)."); $num_tests++; 
ok($found&2, "generate() : has unicode strings (after $MAXTRIALS trials)."); $num_tests++; 
ok($found&4, "generate() : has non-unicode strings (after $MAXTRIALS trials)."); $num_tests++; 

##### fresh object with only-unicode set to 2 (nothing else, no numbers no nothing)
$randomiser = Data::Random::Structure::UTF8->new(
	max_depth => 5,
	max_elements => 20,
	'only-unicode' => 2, # that can have numbers and unicode strings
);
ok(defined $randomiser, 'Data::Random::Structure::UTF8->new()'." called."); $num_tests++;

is($randomiser->only_unicode(),2, "only unicode set to 1."); $num_tests++;

ok(0==scalar(grep{ $_ eq 'string' } @{$randomiser->{'_scalar_types'}}), "removed the string type."); $num_tests++;

ok(1, "found these types: '".join("','",  @{$randomiser->{'_scalar_types'}})."'."); $num_tests++;
is($randomiser->only_unicode(),2, "only unicode set to 2."); $num_tests++;
ok($randomiser->{'_scalar_types'}->[0] eq 'string-UTF8', "has string-UTF8 set."); $num_tests++;
ok($#{$randomiser->{'_scalar_types'}}==0, "no other type is set."); $num_tests++;
ok(1, "found these types: '".join("','",  @{$randomiser->{'_scalar_types'}})."'."); $num_tests++;
$found = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate();
	if( ! defined $perl_var ){ ok(0, "generate() failed.");  $num_tests++; }

	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>1,
		'strings'=>0,
	}) ){ $found |= 1 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-unicode'=>1,
	}) ){ $found |= 2 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-plain'=>1,
	}) ){ $found |= 4 }
}
ok(!($found&1), "generate() : does not have numbers (after $MAXTRIALS trials)."); $num_tests++; 
ok($found&2, "generate() : has unicode strings (after $MAXTRIALS trials)."); $num_tests++; 
ok(!($found&4), "generate() : does not have non-unicode strings (after $MAXTRIALS trials)."); $num_tests++; 

##### fresh object with this setting only-unicode set to zero, default behaviour
$randomiser = Data::Random::Structure::UTF8->new(
	max_depth => 5,
	max_elements => 20,
	'only-unicode' => 0, # that can have numbers and unicode strings
);
ok(defined $randomiser, 'Data::Random::Structure::UTF8->new()'." called."); $num_tests++;
is($randomiser->only_unicode(),0, "only unicode set to 0."); $num_tests++;
ok(0<scalar(grep{ $_ eq 'string-UTF8' } @{$randomiser->{'_scalar_types'}}), "has string-UTF8 set."); $num_tests++;
ok(0<scalar(grep{ $_ eq 'string' } @{$randomiser->{'_scalar_types'}}), "has string set."); $num_tests++;
ok(1, "found these types: '".join("','",  @{$randomiser->{'_scalar_types'}})."'."); $num_tests++;
$found = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate();
	if( ! defined $perl_var ){ ok(0, "generate() failed.");  $num_tests++; }

	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>1,
		'strings'=>0,
	}) ){ $found |= 1 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-unicode'=>1,
	}) ){ $found |= 2 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-plain'=>1,
	}) ){ $found |= 4 }
}
ok($found&1, "generate() : has numbers (after $MAXTRIALS trials)."); $num_tests++; 
ok($found&2, "generate() : has unicode strings (after $MAXTRIALS trials)."); $num_tests++; 
ok($found&4, "generate() : has non-unicode strings (after $MAXTRIALS trials)."); $num_tests++; 

##### fresh object with no setting for unicode
$randomiser = Data::Random::Structure::UTF8->new(
	max_depth => 5,
	max_elements => 20,
);
ok(defined $randomiser, 'Data::Random::Structure::UTF8->new()'." called."); $num_tests++;
is($randomiser->only_unicode(),0, "only unicode set to 0."); $num_tests++;
ok(0<scalar(grep{ $_ eq 'string-UTF8' } @{$randomiser->{'_scalar_types'}}), "has string-UTF8 set."); $num_tests++;
ok(0<scalar(grep{ $_ eq 'string' } @{$randomiser->{'_scalar_types'}}), "has string set."); $num_tests++;
ok(1, "found these types: '".join("','",  @{$randomiser->{'_scalar_types'}})."'."); $num_tests++;
$found = 0;
for($trials=$MAXTRIALS;$trials-->0;){
	$perl_var = $randomiser->generate();
	if( ! defined $perl_var ){ ok(0, "generate() failed.");  $num_tests++; }

	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>1,
		'strings'=>0,
	}) ){ $found |= 1 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-unicode'=>1,
	}) ){ $found |= 2 }
	if( Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
		'numbers'=>0,
		'strings-plain'=>1,
	}) ){ $found |= 4 }
}
ok($found&1, "generate() : has numbers (after $MAXTRIALS trials)."); $num_tests++; 
ok($found&2, "generate() : has unicode strings (after $MAXTRIALS trials)."); $num_tests++; 
ok($found&4, "generate() : has non-unicode strings (after $MAXTRIALS trials)."); $num_tests++; 

done_testing($num_tests);
