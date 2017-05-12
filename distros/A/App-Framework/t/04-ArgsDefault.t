#!/usr/bin/perl
#
use strict ;
use Test::More;

use App::Framework ;

# VERSION
our $VERSION = '2.01' ;

my $DEBUG=0;
my $VERBOSE=0;

	my $stdout="" ;
	my $stderr="" ;

	diag( "Testing args (open handles with defaults)" );

	# 0 = arg name
	# 1 = arg value (filename/dirname)
	# 2 = check for opened
	# 3 = check output file
	# 4 = output file append
	# 5 = input file
	my @args = (
	#    0          1                   	2  3  4  5
		['src1',	't/args/file.txt',		1, 0, 0, 1],
		['src2',	't/args/dir',			0, 0, 0, 0],
		['src3',	't/args/exists.txt',	1, 0, 0, 1],
		['out1',	't/args/outfile',		1, 1, 0, 0],
		['out2',	't/args/outdir',		0, 0, 0, 0],
		['out3',	't/args/outfile2',		1, 1, 1, 0],
	) ;	
	
	my $open_checks = 0 ;
	foreach my $arg_aref (@args)
	{
		$open_checks++ if $arg_aref->[2] ;
	}
	
	my $infile = 0 ;
	my %contents ;
	foreach my $arg_aref (@args)
	{
		if ($arg_aref->[5])
		{
			$infile++ ;
			$contents{$arg_aref->[0]} = getfile($arg_aref->[1]) ;
		}
	}
	
	my $outfile = 0 ;
	foreach my $arg_aref (@args)
	{
		if ($arg_aref->[3])
		{
			my $file = $arg_aref->[1] ;
			unlink $file if -f $file ;			
			$outfile++ ;
			
			# create some contents
			open my $fh, ">$file" ; 
			print $fh $contents{'src1'} ;
			close $fh ;
		}
	}

	
	plan tests => 2 # array & hash check
	+ ((2 + (scalar(@args) * 2)) * 2 * 2) # 4 x arg_test = 4 x (6*2 + 2) = 56
	+ (2 * $open_checks)  # 2 * 4 = 8
	#+2+2 
	+ (1 * $outfile) 
	+ (1 * $infile) 
	+ $outfile 
	#+ 1 
	;

	@ARGV = () ;
#	foreach my $arg_aref (@args)
#	{
#		push @ARGV, $arg_aref->[1] ;
#	}
	App::Framework->new(
		'feature_config' => {
			'Args' => {
				'debug'	=> $DEBUG,
			},
		},
	)->go() ;

	


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

$app->prt_data("Args: list=", \@arglist, "hash=", \%arghash) ;

	is_deeply($args_href, \%arghash, "HASH compare") ;
	is_deeply(\@arglist, \@arglist2, "ARRAY compare") ;

	# test retrived args
	arg_test("arg_list", \@arglist, \%arghash) ;
	arg_test("args", \@arglist2, \%arghash) ;
	
	arg_test("arg_list", \@arglist, $args_href) ;
	arg_test("args", \@arglist2, $args_href) ;


	## Opened file handle
	foreach my $arg_aref (@args)
	{
		if ($arg_aref->[2])
		{
			my $arg = $arg_aref->[0] ;
			ok(exists($args_href->{"${arg}_fh"}), "FH $arg exists") ;
			ok($args_href->{"${arg}_fh"}, "FH $arg not null") ;
		}
	}
	
#	## Array should have STDIN open
#	ok(exists($args_href->{"array_fh"}), "FH array exists") ;
#	ok($args_href->{"array_fh"}, "FH array not null") ;
#	is(ref($args_href->{"array_fh"}), 'ARRAY', "FH array is an array ref") ;

#	my @a = $app->args() ;
#	my $aref = pop @a ;
#	ok(scalar(@$aref)==1, "Last arg array length is 1") ;
#	is($aref->[0], 'STDIN', "Last arg array value is STDIN") ;
		
	
	## Created file
	foreach my $arg_aref (@args)
	{
		if ($arg_aref->[3])
		{
			my $file = $arg_aref->[1] ;
			ok(-f $file, "File $file exists") ;
		}
	}
	
	## Input files
	foreach my $arg_aref (@args)
	{
		if ($arg_aref->[5])
		{
			my $arg = $arg_aref->[0] ;
			my $expected = $contents{$arg} ;
			my $data = getfh($args_href->{"${arg}_fh"}) ;
			is($data, $expected, "File $arg read contents match") ;
		}
	}
	
	## Output files
	my $new_content = $contents{'src3'} ;
	foreach my $arg_aref (@args)
	{
		if ($arg_aref->[3])
		{
			my $arg = $arg_aref->[0] ;
			my $fh = $args_href->{"${arg}_fh"} ;
			print $fh $new_content ;
		}
	}
	
}


#----------------------------------------------------------------------
sub app_end
{
	## Check written files
	foreach my $arg_aref (@args)
	{
		if ($arg_aref->[3])
		{
			my $expected = "" ;
			my $md = "write" ;
			if ($arg_aref->[4])
			{
				## appended to original
				$expected = $contents{'src1'} ;
				$md = "append" ;
			}
			$expected .= $contents{'src3'} ;
			my $got = getfile($arg_aref->[1]) ;
			is($got, $expected, "Compare output fh $md contents") ;
			
			unlink $arg_aref->[1] ;
		}
	}
}


#=================================================================================
# SUBROUTINES
#=================================================================================

#----------------------------------------------------------------------
sub getfh
{
	my ($fh) = @_ ;
	local $/ = undef ;
	my $data = <$fh> ;
	return $data ;
}

#----------------------------------------------------------------------
sub getfile
{
	my ($file) = @_ ;
	open my $fh, "<$file" ;
	my $data = getfh($fh) ;
	close $fh ;
	return $data ;
}

#----------------------------------------------------------------------
sub arg_test
{
	my ($src, $arglist_aref, $arghash_href) = @_ ;
		
	## Test for correct number of args
	# HASH should have N more, where N=number of open files
	is(scalar(@$arglist_aref), scalar(@args), "$src: Number of args (array)") ;
	is(scalar(keys %$arghash_href), scalar(@args)+$open_checks, "$src: Number of args (hash)") ;

	## test each
	foreach my $arg_aref (@args)
	{
		my $arg = $arg_aref->[0] ;
		my $expected = $arg_aref->[1] ;
		ok(exists($arghash_href->{$arg}), "$src: Arg $arg exists") ;
		is($arghash_href->{$arg}, $expected, "$src: Arg $arg") ;
	}
}



#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests named args handling

[ARGS]

* src1=f	Input file				[default=t/args/file.txt]
* src2=d	Input directory			[default=t/args/dir]
* src3=if	Existing				[default=t/args/exists.txt]
* out1=>f	Output file				[default=t/args/outfile]
* out2=>d	Output directory		[default=t/args/outdir]
* out3=>>f	Output file append		[default=t/args/outfile2]

[DESCRIPTION]

B<$name> does some stuff.

