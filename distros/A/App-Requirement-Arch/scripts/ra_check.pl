#!/usr/bin/perl

use strict ;
use warnings ;

use App::Requirement::Arch::Requirements qw(check_requirements) ;
use App::Requirement::Arch qw(get_template_files) ;

#------------------------------------------------------------------------------------------------------------------

sub display_help
{
warn <<'EOH' ;

NAME
	ra_check

SYNOPSIS

	$ ra_check path/to/requirements [ [path/to/requirements] ...]

DESCRIPTION
	This script will check the requirements format against the master requirement
	template.

ARGUMENTS
	--master_template_file  file containing the master template

AUTHORS
	Khemir Nadim ibn Hamouda

EOH

exit(1) ;
}

#------------------------------------------------------------------------------------------------------------------

use Getopt::Long;

my ($master_template_file, $master_categories_file) ;

die 'Error parsing options!'unless 
	GetOptions
		(
		'master_template_file=s' => \$master_template_file,
		'h|help' => \&display_help, 
		
		'dump_options' => 
			sub 
				{
				print join "\n", map {"-$_"} 
					qw(
					master_template_file
					help
					) ;
				exit(0) ;
				},
		) ;

($master_template_file, $master_categories_file)  = get_template_files($master_template_file, $master_categories_file)   ;

display_help() unless @ARGV ;

check_requirements($master_template_file, \@ARGV) ;

