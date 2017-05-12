#!/usr/bin/perl
#
use strict ;
use Test::More;

use App::Framework '+Args(open=none)' ;

# VERSION
our $VERSION = '1.00' ;

my $DEBUG=0;
my $VERBOSE=0;
my $SKIP=0;

	my $stdout="" ;
	my $stderr="" ;

	diag( "Testing args (array)" );

	my @array = (
		't/args/array.txt',
		't/args/exists.txt',
		't/args/file.txt',

		't/args/file.txt',

		't/args/array.txt',
		't/args/exists.txt',
		't/args/file.txt',
	) ;
	plan tests => (1 + scalar(@array) );

	my $app = App::Framework->new('exit_type'=>'die',
		'feature_config' => {
			'Args'	=> {
				'debug'	=> 0,
			}
		},
	) ;

	## Array input
	@ARGV = ('t/args/*.txt', 't/args/file.txt', 't/args/*.txt') ;

	eval {
		$SKIP=0 ;
		$app->go() ;
	} ;

	$@ =~ s/Died.*//m if $@ ;
	print "$@" if $@ ;



#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app, $opts_href, $args_href) = @_ ;
	return if $SKIP ;
	
$app->prt_data("args hash=", $args_href) ;

	# test array arg
	array_test("arg hash", $args_href->{'array'}) ;
}

sub array_test
{
	my ($src, $array_ref) = @_ ;

$app->prt_data("arg_test($src): list=", $array_ref) ;
		
		
	## Test for correct number of args
	is(scalar(@$array_ref), scalar(@array), "$src: Number of array args") ;

	my %got = map { $_ => $_ } @$array_ref ;

	## test each
	foreach my $expected (@array)
	{
		my $arg = $got{$expected} || '' ;
		is($arg, $expected, "$src: Array arg $arg") ;
	}
}

#=================================================================================
# SUBROUTINES
#=================================================================================



#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests named args handling

[ARGS]

* array=<f@		All args are input files


[DESCRIPTION]

B<$name> does some stuff.

