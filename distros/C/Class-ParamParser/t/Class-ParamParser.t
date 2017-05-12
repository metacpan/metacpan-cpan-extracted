# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/Class-ParamParser.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..90\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::ParamParser 1.041;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

######################################################################

package ClassParamParserTest;
use strict;
use warnings;

use vars qw( @ISA );
@ISA = qw( Class::ParamParser );

# Set this to 1 for details on how the test data look before and after parsing
my $verbose = shift( @ARGV ) ? 1 : 0;  # set from command line

# Set this to 1 to do only the last test
my $only_last = shift( @ARGV ) ? 1 : 0;  # set from command line

######################################################################
# Here are some utility methods:

my $test_num = 1;  # same as the first test, above
my $test_fail;
my @test_msg;

sub start {
	$test_num++;
	$test_fail = 0;
	@test_msg = ();
}

sub end {
	print $test_fail ? "not ok $test_num @test_msg\n" : "ok $test_num\n";
}

sub failure {
	my ($fail_msg) = @_;
	$test_fail = 1;
	push( @test_msg, "$fail_msg; " );
}

sub result {
	my ($args, $src_num, $source, 
		$should_h, $was_h, $should_a, $was_a, 
		$fail_msg) = @_;
	
	$args = serialize( $args );
	$source = serialize( $source );
	$should_h = serialize( $should_h );
	$was_h = serialize( $was_h );
	$should_a = serialize( $should_a );
	$was_a = serialize( $was_a );
	
	if( $verbose ) {
		print <<__endquote;
--- DETAIL $test_num START ---
args:         $args
source num:   $src_num
source:       $source
hash should:  $should_h
hash did:     $was_h
array should: $should_a
array did:    $was_a
--- DETAIL $test_num END ---
__endquote
	}
	
	unless( $should_h eq $was_h ) {
		failure( "HASH $src_num: $fail_msg" );
	}
	
	unless( $should_a eq $was_a ) {
		failure( "ARRAY $src_num: $fail_msg" );
	}
}

sub serialize {
	my ($input,$is_key) = @_;
	return( join( '', 
		ref($input) eq 'HASH' ? 
			( '{ ', ( map { 
				( serialize( $_, 1 ), serialize( $input->{$_} ) ) 
			} sort keys %{$input} ), '}, ' ) 
		: ref($input) eq 'ARRAY' ? 
			( '[ ', ( map { 
				( serialize( $_ ) ) 
			} @{$input} ), '], ' ) 
		: defined($input) ?
			"'$input'".($is_key ? ' => ' : ', ')
		: "undef".($is_key ? ' => ' : ', ')
	) );
}

######################################################################
# Here is sample input data:

my %SOURCE = (
	1 => [ ], 
	2 => [ 'value', ], 
	3 => [ 'value1', 'value2', 'value3', ], 
	4 => [ 'Name1', 'value1', 'name2', 'value2', 'name3', 'value3', ], 
	5 => [ '-name1', 'value1', '-Name2', 'value2', '-name3', 'value3', ], 
	6 => [ { '-NAME2' => 'value2', 'name1' => 'value1', 'name3' => 'value3', }, ], 
	7 => [ { '-Name3' => 'value3', 'name2' => 'value2', '-name1' => 'value1', }, 'valueR', ], 
	8 => [ { 'name2' => 'value2', '-Name1' => 'value1', }, 'valueR1', 'valueR2', ], 
);

######################################################################
# Here are the tests, including expected output data

my $KFMSG = 'key_fail_msg';
my $KARGS = 'key_args';
my $KOUTH = 'key_out_hash';
my $KOUTA = 'key_out_array';

my @TESTS = (
	{
		$KFMSG => 'no arguments at all', 
		$KARGS => [], 
		$KOUTH => {
			1 => { }, 
			2 => { }, 
			3 => { }, 
			4 => { 'Name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			5 => { 'name1' => 'value1', 'Name2' => 'value2', 'name3' => 'value3', }, 
			6 => { 'name1' => 'value1', 'NAME2' => 'value2', 'name3' => 'value3', }, 
			7 => { 'name1' => 'value1', 'name2' => 'value2', 'Name3' => 'value3', }, 
			8 => { 'Name1' => 'value1', 'name2' => 'value2', }, 
		}, 
		$KOUTA => {
			1 => [ ], 
			2 => [ 'value', ], 
			3 => [ 'value1', 'value2', 'value3', ], 
			4 => [ ], 
			5 => [ ], 
			6 => [ ], 
			7 => [ ], 
			8 => [ ], 
		}, 
	}, 
	{
		$KFMSG => 'DEF is true, no other arguments', 
		$KARGS => [ 1 ], 
		$KOUTH => {
			1 => { }, 
			2 => { }, 
			3 => { }, 
			4 => { }, 
			5 => { 'name1' => 'value1', 'Name2' => 'value2', 'name3' => 'value3', }, 
			6 => { 'name1' => 'value1', 'NAME2' => 'value2', 'name3' => 'value3', }, 
			7 => { 'name1' => 'value1', 'name2' => 'value2', 'Name3' => 'value3', }, 
			8 => { 'Name1' => 'value1', 'name2' => 'value2', }, 
		}, 
		$KOUTA => {
			1 => [ ], 
			2 => [ 'value', ], 
			3 => [ 'value1', 'value2', 'value3', ], 
			4 => [ 'Name1', 'value1', 'name2', 'value2', 'name3', 'value3', ], 
			5 => [ ], 
			6 => [ ], 
			7 => [ ], 
			8 => [ ], 
		}, 
	}, 
	{
		$KFMSG => 'DEF is false, like names provided', 
		$KARGS => [ 0, [ 'name1', 'name2', 'name3', ], ], 
		$KOUTH => {
			1 => { }, 
			2 => { 'name1' => 'value', }, 
			3 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			4 => { 'Name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			5 => { 'name1' => 'value1', 'Name2' => 'value2', 'name3' => 'value3', }, 
			6 => { 'name1' => 'value1', 'NAME2' => 'value2', 'name3' => 'value3', }, 
			7 => { 'name1' => 'value1', 'name2' => 'value2', 'Name3' => 'value3', }, 
			8 => { 'Name1' => 'value1', 'name2' => 'value2', }, 
		}, 
		$KOUTA => {
			1 => [ ], 
			2 => [ 'value', ], 
			3 => [ 'value1', 'value2', 'value3', ], 
			4 => [ undef, 'value2', 'value3', ], 
			5 => [ 'value1', undef, 'value3', ], 
			6 => [ 'value1', undef, 'value3', ], 
			7 => [ 'value1', 'value2', undef, ], 
			8 => [ undef, 'value2', undef, ], 
		}, 
	}, 
	{
		$KFMSG => 'DEF is true, like names provided', 
		$KARGS => [ 1, [ 'name1', 'name2', 'name3', ], ], 
		$KOUTH => {
			1 => { }, 
			2 => { 'name1' => 'value', }, 
			3 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			4 => { 'name1' => 'Name1', 'name2' => 'value1', 'name3' => 'name2', }, 
			5 => { 'name1' => 'value1', 'Name2' => 'value2', 'name3' => 'value3', }, 
			6 => { 'name1' => 'value1', 'NAME2' => 'value2', 'name3' => 'value3', }, 
			7 => { 'name1' => 'value1', 'name2' => 'value2', 'Name3' => 'value3', }, 
			8 => { 'Name1' => 'value1', 'name2' => 'value2', }, 
		}, 
		$KOUTA => {
			1 => [ ], 
			2 => [ 'value', ], 
			3 => [ 'value1', 'value2', 'value3', ], 
			4 => [ 'Name1', 'value1', 'name2', 'value2', 'name3', 'value3', ], 
			5 => [ 'value1', undef, 'value3', ], 
			6 => [ 'value1', undef, 'value3', ], 
			7 => [ 'value1', 'value2', undef, ], 
			8 => [ undef, 'value2', undef, ], 
		}, 
	}, 
	{
		$KFMSG => 'DEF is false, like names provided, LC is true', 
		$KARGS => [ 0, [ 'name1', 'name2', 'name3', ], undef, undef, 1, ], 
		$KOUTH => {
			1 => { }, 
			2 => { 'name1' => 'value', }, 
			3 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			4 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			5 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			6 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			7 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			8 => { 'name1' => 'value1', 'name2' => 'value2', }, 
		}, 
		$KOUTA => {
			1 => [ ], 
			2 => [ 'value', ], 
			3 => [ 'value1', 'value2', 'value3', ], 
			4 => [ 'value1', 'value2', 'value3', ], 
			5 => [ 'value1', 'value2', 'value3', ], 
			6 => [ 'value1', 'value2', 'value3', ], 
			7 => [ 'value1', 'value2', 'value3', ], 
			8 => [ 'value1', 'value2', undef, ], 
		}, 
	}, 
	{
		$KFMSG => 'DEF is true, like names provided, LC is true', 
		$KARGS => [ 1, [ 'name1', 'name2', 'name3', ], undef, undef, 1, ], 
		$KOUTH => {
			1 => { }, 
			2 => { 'name1' => 'value', }, 
			3 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			4 => { 'name1' => 'Name1', 'name2' => 'value1', 'name3' => 'name2', }, 
			5 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			6 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			7 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			8 => { 'name1' => 'value1', 'name2' => 'value2', }, 
		}, 
		$KOUTA => {
			1 => [ ], 
			2 => [ 'value', ], 
			3 => [ 'value1', 'value2', 'value3', ], 
			4 => [ 'Name1', 'value1', 'name2', 'value2', 'name3', 'value3', ], 
			5 => [ 'value1', 'value2', 'value3', ], 
			6 => [ 'value1', 'value2', 'value3', ], 
			7 => [ 'value1', 'value2', 'value3', ], 
			8 => [ 'value1', 'value2', undef, ], 
		}, 
	}, 
	{
		$KFMSG => 'NAMES is set, LC is true, REM is set diff', 
		$KARGS => [ 0, [ 'name1', 'name2', 'name3', ], undef, 'name4', 1, ], 
		$KOUTH => {
			6 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			7 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', 'name4' => 'valueR', }, 
			8 => { 'name1' => 'value1', 'name2' => 'value2', 'name4' => [ 'valueR1', 'valueR2', ], }, 
		}, 
		$KOUTA => {
			6 => [ 'value1', 'value2', 'value3', ], 
			7 => [ 'value1', 'value2', 'value3', ], 
			8 => [ 'value1', 'value2', undef, ], 
		}, 
	}, 
	{
		$KFMSG => 'NAMES is set, LC is true, REM is set same', 
		$KARGS => [ 0, [ 'name1', 'name2', 'name3', ], undef, 'name3', 1, ], 
		$KOUTH => {
			6 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			7 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'valueR', }, 
			8 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => [ 'valueR1', 'valueR2', ], }, 
		}, 
		$KOUTA => {
			6 => [ 'value1', 'value2', 'value3', ], 
			7 => [ 'value1', 'value2', 'valueR', ], 
			8 => [ 'value1', 'value2', [ 'valueR1', 'valueR2', ], ], 
		}, 
	}, 
	{
		$KFMSG => 'NAMES is set, LC is true, RENAME set no collision', 
		$KARGS => [ 
			0, [ 'name1', 'name2', 'name3', ], { 
				'name1' => 'name5', 'name3' => 'name6'
			}, undef, 1, 
		], 
		$KOUTH => {
			1 => { }, 
			2 => { 'name1' => 'value', }, 
			3 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			4 => { 'name2' => 'value2', 'name5' => 'value1', 'name6' => 'value3', }, 
			5 => { 'name2' => 'value2', 'name5' => 'value1', 'name6' => 'value3', }, 
			6 => { 'name2' => 'value2', 'name5' => 'value1', 'name6' => 'value3', }, 
			7 => { 'name2' => 'value2', 'name5' => 'value1', 'name6' => 'value3', }, 
			8 => { 'name2' => 'value2', 'name5' => 'value1', }, 
		}, 
		$KOUTA => {
			1 => [ ], 
			2 => [ 'value', ], 
			3 => [ 'value1', 'value2', 'value3', ], 
			4 => [ undef, 'value2', undef, ], 
			5 => [ undef, 'value2', undef, ], 
			6 => [ undef, 'value2', undef, ], 
			7 => [ undef, 'value2', undef, ], 
			8 => [ undef, 'value2', undef, ], 
		}, 
	}, 
	{
		$KFMSG => 'NAMES is set, LC is true, RENAME set with collision', 
		$KARGS => [ 
			0, [ 'name1', 'name2', 'name3', ], { 
				'name1' => 'name5', 'name3' => 'name2'
			}, undef, 1, 
		], 
		$KOUTH => {
			1 => { }, 
			2 => { 'name1' => 'value', }, 
			3 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			4 => { 'name2' => 'value3', 'name5' => 'value1', }, 
			5 => { 'name2' => 'value3', 'name5' => 'value1', }, 
			6 => { 'name2' => 'value3', 'name5' => 'value1', }, 
			7 => { 'name2' => 'value2', 'name5' => 'value1', }, 
			8 => { 'name2' => 'value2', 'name5' => 'value1', }, 
		}, 
		$KOUTA => {
			1 => [ ], 
			2 => [ 'value', ], 
			3 => [ 'value1', 'value2', 'value3', ], 
			4 => [ undef, 'value3', undef, ], 
			5 => [ undef, 'value3', undef, ], 
			6 => [ undef, 'value3', undef, ], 
			7 => [ undef, 'value2', undef, ], 
			8 => [ undef, 'value2', undef, ], 
		}, 
	}, 
	{
		$KFMSG => 'NAMES is set, LC is true, RENAME set with deletion', 
		$KARGS => [ 
			0, [ 'name1', 'name2', 'name3', ], { 
				'name1' => '', 'name2' => ''
			}, undef, 1, 
		], 
		$KOUTH => {
			1 => { }, 
			2 => { 'name1' => 'value', }, 
			3 => { 'name1' => 'value1', 'name2' => 'value2', 'name3' => 'value3', }, 
			4 => { 'name3' => 'value3', }, 
			5 => { 'name3' => 'value3', }, 
			6 => { 'name3' => 'value3', }, 
			7 => { 'name3' => 'value3', }, 
			8 => { }, 
		}, 
		$KOUTA => {
			1 => [ ], 
			2 => [ 'value', ], 
			3 => [ 'value1', 'value2', 'value3', ], 
			4 => [ undef, undef, 'value3', ], 
			5 => [ undef, undef, 'value3', ], 
			6 => [ undef, undef, 'value3', ], 
			7 => [ undef, undef, 'value3', ], 
			8 => [ undef, undef, undef, ], 
		}, 
	}, 
	{
		$KFMSG => 'NAMES is set, LC is true, RENAME no col, REM is set diff', 
		$KARGS => [ 
			0, [ 'name1', 'name2', 'name3', ], { 
				'name1' => 'name5', 'name3' => 'name6'
			}, 'name4', 1, 
		], 
		$KOUTH => {
			6 => { 'name2' => 'value2', 'name5' => 'value1', 'name6' => 'value3', }, 
			7 => { 'name2' => 'value2', 'name4' => 'valueR', 'name5' => 'value1', 'name6' => 'value3', }, 
			8 => { 'name2' => 'value2', 'name4' => [ 'valueR1', 'valueR2', ], 'name5' => 'value1', }, 
		}, 
		$KOUTA => {
			6 => [ undef, 'value2', undef, ], 
			7 => [ undef, 'value2', undef, ], 
			8 => [ undef, 'value2', undef, ], 
		}, 
	}, 
	{
		$KFMSG => 'NAMES is set, LC is true, RENAME with col, REM is set same', 
		$KARGS => [ 
			0, [ 'name1', 'name2', 'name3', ], { 
				'name1' => 'name5', 'name3' => 'name2'
			}, 'name3', 1, 
		], 
		$KOUTH => {
			6 => { 'name2' => 'value3', 'name5' => 'value1', }, 
			7 => { 'name2' => 'value2', 'name3' => 'valueR', 'name5' => 'value1', }, 
			8 => { 'name2' => 'value2', 'name3' => [ 'valueR1', 'valueR2', ], 'name5' => 'value1', }, 
		}, 
		$KOUTA => {
			6 => [ undef, 'value3', undef, ], 
			7 => [ undef, 'value2', 'valueR', ], 
			8 => [ undef, 'value2', [ 'valueR1', 'valueR2', ], ], 
		}, 
	}, 
	{
		$KFMSG => 'NAMES is set, LC is true, RENAME with del, REM is set same', 
		$KARGS => [ 
			0, [ 'name1', 'name2', 'name3', ], { 
				'name1' => '', 'name2' => ''
			}, 'name3', 1, 
		], 
		$KOUTH => {
			6 => { 'name3' => 'value3', }, 
			7 => { 'name3' => 'valueR', }, 
			8 => { 'name3' => [ 'valueR1', 'valueR2', ], }, 
		}, 
		$KOUTA => {
			6 => [ undef, undef, 'value3', ], 
			7 => [ undef, undef, 'valueR', ], 
			8 => [ undef, undef, [ 'valueR1', 'valueR2', ], ], 
		}, 
	}, 
);

######################################################################

my $obj = bless( {}, 'ClassParamParserTest' );

######################################################################
# Do the methods exist and do they return correct var type.

start();
unless( (my $type = ref( $obj->params_to_hash() )) eq 'HASH' ) {
	failure( "params_to_hash() returned a '$type'" );
}
end();

start();
unless( (my $type = ref( $obj->params_to_array() )) eq 'ARRAY' ) {
	failure( "params_to_array() returned a '$type'" );
}
end();

######################################################################
# provide different method arguments and check results against expected

foreach my $test ($only_last ? $TESTS[-1] : @TESTS) {
	foreach my $i (sort { $a <=> $b } keys %{$test->{$KOUTH}}) {
		start();
		result(
			$test->{$KARGS}, 
			$i, 
			$SOURCE{$i}, 
			$test->{$KOUTH}->{$i},
			$obj->params_to_hash( $SOURCE{$i}, @{$test->{$KARGS}} ), 
			$test->{$KOUTA}->{$i},
			$obj->params_to_array( $SOURCE{$i}, @{$test->{$KARGS}} ), 
			$test->{$KFMSG},
		);
		end();
	}
}

######################################################################

1;