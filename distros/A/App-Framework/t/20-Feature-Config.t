#!/usr/bin/perl
#
use strict ;
use Test::More;

use App::Framework '+Config' ;

# VERSION
our $VERSION = '1.00' ;

my $DEBUG=0;
my $VERBOSE=0;

	my $stdout="" ;
	my $stderr="" ;
	
	if (@ARGV)
	{
		$DEBUG = $ARGV[0] ;
		$VERBOSE = $ARGV[0] ;
		@ARGV = () ;
	}

	diag( "Testing config" );

my $read_dir = "t/config2" ;
my $write_dir = "t/config_wr" ;

my %expected = (
  'dbg-namestuff' => "config2 a name",
  debug => 56,
  default => "config2 default",
  default2 => "config2 b default",
  default3 => "a-new-value",
  log => "different log",
  name => "this-is-a-test",
  nomacro => 1,
) ;

my %expected_options = (
  config => "20-Feature-Config.conf",
  config_path => $read_dir,
  config_write => undef,
  config_writepath => $write_dir,
  %expected,
) ;

my %single_sections = (
	'server'	=> 1,
	'snmp-trap'	=> 1,
) ;
my %sections = (

	'server'	=> [
	{
		'port'		=> 32023,
		'tick'		=> 5,
	},
	],
	'snmp-trap'	=> [
	{
		'port'		=> 32161,
		'logfile'	=> '/tmp/ate_snmp.log',
	},
	],
	'tty'		=> [
	{
		name 		=> 'SC2-1', 		
		host 		=> 'tty-server2',
		port 		=> 2011, 
		prompt 		=> '/SC2-HWTC\s*>/i', 
		timeout		=> 90,
	},
	{
		name 		=> 'BBU-1',
		host 		=> 'tty-server2',
		port 		=> 2012, 
		prompt 		=> '/(RSS|\-)\s*>/i', 
		timeout		=> 90,
	},
	{
		name 		=> 'SC2-2', 		
		host 		=> 'tty-server2',
		port 		=> 2013, 
		prompt 		=> '/SC2-HWTC\s*>/i', 
		timeout		=> 90,
	},
	{
		name 		=> 'BBU-2', 		
		host 		=> 'tty-server2',
		port 		=> 2014, 
		prompt 		=> '/(RSS|\-)\s*>/i', 
		timeout		=> 90,
	},
	],
	'snmp'		=> [
	{
		name 		=> 'CTU4-1', 		
		host 		=> 'ctu4-1',
	},
	{
		name 		=> 'CTU4-2', 		
		host 		=> 'ctu4-2',
	},
	{
		name 		=> 'CTU4-3', 		
		host 		=> 'ctu4-3',
	},
	{
		name 		=> 'CTU4-4', 		
		host 		=> 'ctu4-4',
	},	
	],
) ;


	plan tests => 
		(scalar(keys %expected_options)) +
		(2*scalar(keys %expected)) + scalar(keys %sections) + scalar(keys %single_sections) + 
		(2*scalar(keys %expected)) + scalar(keys %sections) + scalar(keys %single_sections);

	## clear out write path
	if (-d $write_dir)
	{
		foreach my $f (glob("$write_dir"))
		{
			unlink $f ;
		}
		rmdir $write_dir ;
	}

	## no run tests
	my $app = App::Framework->new('exit_type'=>'die',
		'feature_config' => {
			'config' => {
				'debug' => $DEBUG,
			},
			'options' => {
				'debug' => $DEBUG,
			},
		},
	) ;

	@ARGV = (
		'-name',				'this-is-a-test',
		'-nomacro',
		'-default3',			'a-new-value',
		'-config_path',			't/config2',
		'-config_writepath',	't/config_wr',
	) ;
	eval {$app->go()} ;
	$@ =~ s/Died.*//m if $@ ;
	$@ =~ s/^\s+//gm if $@ ;
	$@ =~ s/\s+$//gm if $@ ;
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

$app->prt_data("Opts:", $opts_href) ;

	## check simple configuration 
	my @global = $app->feature('Config')->get_array() ;
	my %global = $app->feature('Config')->get_hash() ;
$app->prt_data("Global: array=", \@global, " hash=", \%global) if $DEBUG ;

	foreach my $option (keys %expected_options)
	{
		is ($opts_href->{$option}, $expected_options{$option}, "Check option $option") ;
	}

	foreach my $option (keys %expected)
	{
		is ($global[0]{$option}, $expected{$option}, "Check configuration array for $option") ;
		is ($global{$option}, $expected{$option}, "Check configuration hash for $option") ;
	}

	## check sections
	my $cfg = $app->feature('Config') ;
	foreach my $section (keys %sections)
	{
		my @conf = $cfg->get_array($section) ;
$app->prt_data("Check Section: $section got=", \@conf, " expected=", $sections{$section}) if $DEBUG  ;
		is_deeply(\@conf, $sections{$section}, "Checking section array $section") ;
	}	
	foreach my $section (keys %single_sections)
	{
		my %conf = $cfg->get_hash($section) ;
$app->prt_data("Check Single Section: $section got=", \%conf, " expected=", $sections{$section}) if $DEBUG ;
		is_deeply(\%conf, $sections{$section}[0], "Checking section hash $section") ;
	}	

	
	## check write
	$cfg->write() ;
	
	my $new_cfg = $cfg->new(
		'filename'		=> $opts_href->{'config'},
		'path'			=> $opts_href->{'config_writepath'},
		'write_path'	=> $opts_href->{'config_writepath'},
	) ;
	$new_cfg->read() ;

$app->prt_data("Readback config=", $new_cfg->configuration) ;

	## check simple configuration 
	@global = $new_cfg->get_array() ;
	%global = $new_cfg->get_hash() ;
$app->prt_data("Global: array=", \@global, " hash=", \%global) if $DEBUG ;

	foreach my $option (keys %expected)
	{
		is ($global[0]{$option}, $expected{$option}, "Check read configuration array for $option") ;
		is ($global{$option}, $expected{$option}, "Check read configuration hash for $option") ;
	}

	## check sections
	foreach my $section (keys %sections)
	{
		my @conf = $new_cfg->get_array($section) ;
$app->prt_data("Check Section: $section got=", \@conf, " expected=", $sections{$section}) if $DEBUG ;
		is_deeply(\@conf, $sections{$section}, "Checking read section array $section") ;
	}	
	foreach my $section (keys %single_sections)
	{
		my %conf = $new_cfg->get_hash($section) ;
$app->prt_data("Check Single Section: $section got=", \%conf, " expected=", $sections{$section}) if $DEBUG ;
		is_deeply(\%conf, $sections{$section}[0], "Checking read section hash $section") ;
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

Tests config file access

[DESCRIPTION]

B<$name> does some stuff.

