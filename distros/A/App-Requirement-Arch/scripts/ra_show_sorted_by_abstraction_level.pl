#!/usr/bin/perl

use strict ;
use warnings ;

use App::Requirement::Arch::Requirements qw(get_requirements_structure)  ;
use App::Requirement::Arch qw(get_template_files) ;

use Data::TreeDumper ;

sub display_help
{
warn <<'EOH' ;

NAME
	ra_show_sorted_by_abstraction_level

SYNOPSIS

	$ ra_show_sorted_by_abstraction_level path/to/requirements

DESCRIPTION
	This utility will parse the requirements and generate an output listing
	the requirements sorted by abstraction level.
	
ARGUMENTS
        --master_template_file        file containing the master template

AUTHORS
	Khemir Nadim ibn Hamouda.

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

my $sources = \@ARGV ;

my ($requirements_structure, $requirements) = get_requirements_structure($sources, $master_template_file) ;

my ($defined_requirements, $undefined_requirements, $requirements_at_level) = (0, 0, {}) ;

for my $requirement_name (keys %{$requirements})
	{
	if(exists $requirements->{$requirement_name}{DEFINITION})
		{
		$defined_requirements++ ;
		
		if(exists $requirements->{$requirement_name}{DEFINITION}{ABSTRACTION_LEVEL}) 
			{
			my $level = $requirements->{$requirement_name}{DEFINITION}{ABSTRACTION_LEVEL} ;
			
			$requirements_at_level->{$level}{$requirement_name} = $requirements->{$requirement_name} ;
			}
		}
	else
		{
		$undefined_requirements++ ;
		}
	}

print <<EOT ;

defined requirements: $defined_requirements
requirements without definition: $undefined_requirements

EOT

#~ print DumpTree $requirements, 'requirements', DISPLAY_ADDRESS => 1, USE_ASCII => 1 , NO_NO_ELEMENTS => 1 ;
print DumpTree $requirements_at_level, 'requirements', DISPLAY_ADDRESS => 0, USE_ASCII => 1 , NO_NO_ELEMENTS => 1, MAX_DEPTH => 2 ;
