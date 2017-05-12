#!/usr/bin/perl

use strict ;
use warnings ;

use App::Requirement::Arch::Requirements qw(create_requirement)  ;
use App::Requirement::Arch qw(get_template_files load_master_template) ;

use File::Slurp ;
use File::Basename ;
use Getopt::Long;

#------------------------------------------------------------------------------------------------------------------

sub display_help
{
warn <<'EOH' ;

NAME
	ra_new

SYNOPSIS

	$ ra_new.pl path/file_to_create.extension

DESCRIPTION
	This utility will create a requirement in the file passed as argument. The requirement is 
	based on the template found in './master_template.plt'.
	
	the name of the requirement will be set to 'file_to_create'.
	
	the utility will not override existing requirements.
	
ARGUMENTS
  --master_template_file    file containing the master template

AUTHORS
	Khemir Nadim ibn Hamouda.

EOH

exit(1) ;
}

#------------------------------------------------------------------------------------------------------------------

my ($master_template_file) ;

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

($master_template_file)  = get_template_files($master_template_file)   ;

my $file_name = $ARGV[0] || die display_help() ;

die "Requirement '$file_name' already exists!\n" if -e $file_name;

my ($requirement_name) = File::Basename::fileparse($file_name, ('\..*')) ;

my $requirement_template = load_master_template($master_template_file)->{REQUIREMENT} ;

my $requirement = create_requirement($requirement_template , {NAME => $requirement_name, ORIGINS =>['']}) ;

# write requirement
use Data::Dumper ;

$Data::Dumper::Indent = 1 ;

my $requirement_dump = Dumper $requirement ;

$requirement_dump =~ s/\$VAR1 =// ;
$requirement_dump =~ s/^\s*//gm ;

write_file($file_name, $requirement_dump) ;


