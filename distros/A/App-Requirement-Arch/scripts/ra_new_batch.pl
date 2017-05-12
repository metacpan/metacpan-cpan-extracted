#!/usr/bin/perl

use strict ;
use warnings ;
use Carp ;

use App::Requirement::Arch::Requirements qw(create_requirement)  ;
use App::Requirement::Arch qw(load_master_template) ;

use File::Slurp ;
use File::Basename ;
use Text::Pluralize;

use Data::Dumper ;
use Getopt::Long ;

#------------------------------------------------------------------------------------------------------------------

sub display_help
{
warn <<'EOH' ;

NAME
	ra_new_batch

SYNOPSIS

	$ ra_new_batch.pl --master_template_file template_file batch_requirement_file

DESCRIPTION
	This utility will create requirements, in batch mode, the content of the batch file is:
	
	title of requirement starting at first character of the line
		
		data to be added in the long description
		...
		
	title of next requirement starting at first character of the line
		...
	
	The utility will not override existing requirements.
	
ARGUMENTS
	--master_template_file  file containing the master template

AUTHORS
	Khemir Nadim ibn Hamouda.

EOH

exit(1) ;
}

#------------------------------------------------------------------------------------------------------------------

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


display_help() unless defined $master_template_file ;

my $batch_file_name = $ARGV[0] || die display_help() ;

open my $batch_file , '<', $batch_file_name or die "Can't open '$batch_file_name': $!" ;

my $number_of_requirements_created = 0 ;

my ($title, $description) ;

while(<$batch_file>)
	{
	next if(/^#/) ;
	
	if(/^\w/)
		{
		if(defined $title)
			{
			create_new_batch_requirement($master_template_file, $title, $batch_file_name, $description) ;
			$number_of_requirements_created++ ;
			undef $title ;
			}
			
		chomp ;
		$title = $_ ;
		$title =~ s/(\/|\s+)/_/g ;
		
		$description = '' ;
		}
	else
		{
		$description .= $_ ;
		}
	}


if(defined $title)
	{
	create_new_batch_requirement($master_template_file, $title, $batch_file_name, $description)  ;
	$number_of_requirements_created++ ;
	}

print {*STDOUT} pluralize("Created $number_of_requirements_created requirement(s)\n", $number_of_requirements_created) ;

#------------------------------------------------------------------------------------------------------------------

sub create_new_batch_requirement
{
my ($master_template_file, $title, $batch_file_name, $description) = @_ ;

create_new_requirement
	(
	$master_template_file,
	$title . '.rat' ,
	{
		NAME => $title,
		ORIGINS =>[$batch_file_name],
		LONG_DESCRIPTION  => $description
	},
	) ;

}

#------------------------------------------------------------------------------------------------------------------

sub create_new_requirement
{
	
my ($master_template_file, $file_name, $requirement_data) = @_ ;

if(-e $file_name)
	{
	warn "Requirement '$file_name' already exists!\n" ;
	return ;
	}

my ($requirement_name) = File::Basename::fileparse($file_name, ('\..*')) ;

my $requirement_template = load_master_template($master_template_file)->{REQUIREMENT} ;

my $requirement = create_requirement($requirement_template , $requirement_data) ;

# write requirement
$Data::Dumper::Indent = 1 ;

my $requirement_dump = Dumper $requirement ;

$requirement_dump =~ s/\$VAR1 =// ;

write_file($file_name, $requirement_dump) ;

return(1) ;
}
