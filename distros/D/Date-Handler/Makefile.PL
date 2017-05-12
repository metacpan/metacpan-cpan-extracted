#!/usr/bin/perl

use strict;
use Getopt::Long;
use Data::Dumper;
use ExtUtils::MakeMaker;

my $options = {};
my $test_config = {};

GetOptions($options, "extended_tests");

if(defined $options->{extended_tests})
{
	$test_config->{locale} = 1;
}
	
WriteTestConfig($test_config);

WriteMakefile(
	'NAME'		=> 'Date::Handler',
	'VERSION_FROM'	=> 'Handler.pm', 
	'AUTHOR'       => 'Benoit Beausejour <bbeausej\@pobox.com>',
	'clean'        => { 'FILES' => 'pod2htm*', },
	'dist'    	=> { 'PREOP' => 'pod2text Handler.pod > README; pod2html Handler.pod README.html', },
);



sub WriteTestConfig
{
	my $test_config = shift();

	$test_config = Dumper($test_config);

	$test_config =~ s/\$VAR1 \=//g;

	print STDERR "Writing t/config\n";	
	open(CONFIG, ">t/config") || die "Cannot write to t/config: $!";
	print CONFIG $test_config;
	close CONFIG;
}

