#!/usr/bin/perl
#
use strict ;
use Test::More;

use App::Framework::Lite '+Args(open=none)' ;

# VERSION
our $VERSION = '2.01' ;

my $DEBUG=0;
my $VERBOSE=0;
my $SKIP=0;

	my $stdout="" ;
	my $stderr="" ;

	diag( "Testing args (array)" );

	my @array = (
		't/args/file.txt',
		't/args/exists.txt',
		't/args/array.txt',
	) ;
	plan tests => 1 + (1 + scalar(@array) );

	my $app = App::Framework::Lite->new('exit_type'=>'die',
		'feature_config' => {
			'Args'	=> {
				'debug'	=> 0,
			}
		},
	) ;

	@ARGV = () ;
	eval {
		local *STDOUT ;
		local *STDERR ;

		open(STDOUT, '>', \$stdout)  or die "Can't open STDOUT: $!" ;
		open(STDERR, '>', \$stderr) or die "Can't open STDERR: $!";
		$SKIP=1;
		$app->go() ;
	};
	print "reply: $stdout" ;
	like($stdout, qr/Error: Must specify/i, "Input array checking") ;

	## Array input
	foreach my $val (@array)
	{
		push @ARGV, $val ;
	}
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

	## test each
	my $i=0;
	foreach my $expected (@array)
	{
		my $arg = $array_ref->[$i++] || '' ;
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

