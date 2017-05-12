#!/usr/bin/perl
#
use strict ;
use Test::More;

use App::Framework '+Args(open=none)' ;

# VERSION
our $VERSION = '2.01' ;

my $DEBUG=0;
my $VERBOSE=0;

	my $stdout="" ;
	my $stderr="" ;

	diag( "Testing args" );

	my $input_checks = 3 ;	
	my @args = (
		['src1',	't/args/file.txt'],
		['src2',	't/args/dir'],
		['src3',	't/args/exists.txt'],
		['out1',	't/args/outfile'],
		['out2',	't/args/outdir'],
		['out3',	't/args/outfile2'],
	) ;	
	my @array = (
		't/args/file.txt',
		't/args/exists.txt',
		't/args/array.txt',
	) ;
	plan tests => 1 + $input_checks + 1 + 2 + ((1 + (scalar(@args) * 2)) * 2 * 2) + ((1 + (scalar(@array)) ) * 2 );

	## These should not work	
	my $app = App::Framework->new('exit_type'=>'die') ;
	for(my $in=0; $in < $input_checks; ++$in)
	{
		@ARGV = () ;
		my $arg=0 ;
		foreach my $arg_aref (@args)
		{
			my $val = $arg_aref->[1] ;
			$val .= "_not_there" if $arg == $in ;
			push @ARGV, $val ;
			
			++$arg ;
		}
		push @ARGV, @array ; # array
		eval {
			local *STDOUT ;
			local *STDERR ;
	
			open(STDOUT, '>', \$stdout)  or die "Can't open STDOUT: $!" ;
			open(STDERR, '>', \$stderr) or die "Can't open STDERR: $!";
			$app->go() ;
		};
		print "reply: $stdout" ;
		like($stdout, qr/Error: Must specify/i, "Input checking") ;
	}

	## Array input
	foreach my $arg_aref (@args)
	{
		my $val = $arg_aref->[1] ;
		push @ARGV, $val ;
	}
	eval {
		local *STDOUT ;
		local *STDERR ;

		open(STDOUT, '>', \$stdout)  or die "Can't open STDOUT: $!" ;
		open(STDERR, '>', \$stderr) or die "Can't open STDERR: $!";
		$app->go() ;
	};
	print "reply: $stdout" ;
	like($stdout, qr/Error: Must specify/i, "Input array checking") ;

	## These should now work	
	@ARGV = () ;
	foreach my $arg_aref (@args)
	{
		push @ARGV, $arg_aref->[1] ;
	}
	foreach my $arg (@array)
	{
		push @ARGV, $arg ;
	}
	eval {$app->go()} ;
	$@ =~ s/Died.*//m if $@ ;
	$@ =~ s/\s+//gm if $@ ;
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

$app->prt_data("Args: passed hash=", $args_href) ;
	
	# Check args
	my @arglist = $app->feature('Args')->arg_list() ;
	my %arghash = $app->feature('Args')->arg_hash() ;

	my @arglist2 = $app->args() ;
	my @arglist3 = $app->Args() ;

$app->prt_data("Args: list=", \@arglist, "hash=", \%arghash) ;

	is_deeply($args_href, \%arghash, "HASH compare") ;
	is_deeply(\@arglist, \@arglist2, "ARRAY compare") ;
	is_deeply(\@arglist2, \@arglist3, "Access alias") ;

	# test retrived args
	arg_test("arg_list", \@arglist, \%arghash) ;
	arg_test("args", \@arglist2, \%arghash) ;
	
	arg_test("arg_list", \@arglist, $args_href) ;
	arg_test("args", \@arglist2, $args_href) ;


	# test array arg
	array_test("arg hash", $args_href->{'array'}) ;
	array_test("args", pop @arglist2) ;
}

sub arg_test
{
	my ($src, $arglist_aref, $arghash_href) = @_ ;

	## Test for correct number of args
	is(scalar(@$arglist_aref), scalar(@args)+1, "$src: Number of args") ;

	## test each
	foreach my $arg_aref (@args)
	{
		my $arg = $arg_aref->[0] ;
		my $expected = $arg_aref->[1] ;
		ok(exists($arghash_href->{$arg}), "$src: Arg $arg exists") ;
		is($arghash_href->{$arg}, $expected, "$src: Arg $arg") ;
	}
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
		my $arg = $array_ref->[$i++] ;
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

* src1=<f	Input file
* src2=d	Input directory
* src3=if	Existing
* out1=>f	Output file
* out2=>d	Output directory
* out3=>>f	Output file append
* array=<f@	All other args are input files


[DESCRIPTION]

B<$name> does some stuff.

