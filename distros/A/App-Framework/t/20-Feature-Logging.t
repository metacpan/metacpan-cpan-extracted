#!/usr/bin/perl
#
use strict ;
use Test::More ;

use App::Framework ':Script +Logging' ;

# VERSION
our $VERSION = '1.000' ;

plan tests => 3 + 1 ;

my $FILE = 't/logfile.log' ;

	@ARGV = ('-log', $FILE) ;
	my $app = App::Framework->new();
	$app->go() ;


#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app) = @_ ;

	feature_check($app, 'Logging') ;

	my $log = $app->feature("Logging") ;

	my @array = (
	'line 1',
	'line 2',
	'line 3',
	);
	$app->Logging("Array:", \@array) ;
	
	my %hash = (
		'cmd'	=> 'ffmpeg',
		'args'	=> [
			'-i', 'somefile',
			'-target', 'dvd',
		],
		'nice'	=> 10,
	) ;
	
	my $scalar="a scalar" ;
	$log->logging("HASH:", \%hash, \$scalar, " some more: ", "text\n", 'array', \@array) ;
	
	
	## compare logfile with expected
	comp_log($app, $FILE, 'expected') ;
}

#=================================================================================
# SUBROUTINES
#=================================================================================

#----------------------------------------------------------------------
#
sub feature_check
{
	my ($app, $name) = @_ ;

	my $lc_name = lc $name ;
	
	my $feat1 = $app->feature($name) ;
	my $class1 = ref($feat1) ;
	
	is($class1, "App::Framework::Feature::$name", "$name feature class check") ;
	
	my $feat = $app->$lc_name ;
	my $class = ref($feat) ;
	is($feat, $feat1, "$name object check") ;

	my $feat2 = $app->$name ;
	is($feat, $feat2, "$name object check (access alias)") ;
}

#----------------------------------------------------------------------
#
sub comp_log
{
	my ($app, $logfile, $data) = @_ ;

	# get log & strip out comments
	my $log_data = getfile($logfile) ;
	$log_data =~ s/#.*$//mg ;
	
	# get expected
	my $expected = $app->Data($data) ;
	
	is($log_data, $expected, "Log file comparison") ;
}

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


#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests run feature

__DATA__ expected
Array:line 1
line 2
line 3
HASH:{ 
  args => 
    [ 
      -i,
      somefile,
      -target,
      dvd,
    ],
  cmd => ffmpeg,
  nice => 10,
},

a scalar some more: text
arrayline 1
line 2
line 3

