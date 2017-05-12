#!/usr/bin/perl

use strict ;
use warnings ;
use Carp ;

use Proc::InvokeEditor ;
use App::Requirement::Arch::Requirements qw(create_requirement check_requirements get_requirements_structure)  ;
use App::Requirement::Arch qw(get_template_files load_master_template load_master_categories) ;
use App::Requirement::Arch::Categories qw(merge_master_categories) ;
use App::Requirement::Arch::Spellcheck qw(spellcheck)  ;

use File::Slurp ;
use File::Basename ;
use Getopt::Long;
use Data::Dumper ;
use Data::TreeDumper ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

#------------------------------------------------------------------------------------------------------------------

sub display_help
{
warn <<'EOH' ;

NAME
	ra_edit

SYNOPSIS

	$ ra_edit path/to/requirement

DESCRIPTION
	This script will open the requirement in a text editor, creating it from templates
	found in ~/.ra/

	On exit the file contents is checked for format validity. Extra checks are available through options
	
ARGUMENTS
  --master_template_file     file containing the master template
  --master_categories_file   file containing the categories template
  --free_form_template       user defined template matching the master template
  --no_check_categories      do not check the requirement categories
  --no_spellcheck            perform no spellchecking
  --no_backup                do not save a backup file

FILES
	~/.ra/templates/master_template.pl
	~/.ra/templates/master_categories.pl
	~/.ra/templates/free_form_template.rat

AUTHORS
	Khemir Nadim ibn Hamouda

EOH

exit(1) ;
}

#------------------------------------------------------------------------------------------------------------------

my ($master_template_file, $master_categories_file, $free_form_template) ;
my ($no_spellcheck, $raw, $no_backup, $no_check_categories) ;

die 'Error parsing options!'unless 
	GetOptions
		(
		'master_template_file=s' => \$master_template_file,
		'master_categories_file=s' => \$master_categories_file,
		'free_form_template=s' => \$free_form_template,
		'no_spellcheck' => \$no_spellcheck,
		'raw=s' => \$raw,
		'no_backup' => \$no_backup,
		'no_check_categories' => \$no_check_categories,
		'h|help' => \&display_help, 
		
		'dump_options' => 
			sub 
				{
				print join "\n", map {"-$_"} 
					qw(
					master_template_file
					master_categories_file
					free_form_template
					no_spellcheck
					raw
					no_backup
					no_check_categories
					help
					) ;
					
				exit(0) ;
				},

		) ;

($master_template_file, $master_categories_file, $free_form_template)  
	= get_template_files($master_template_file, $master_categories_file, $free_form_template)   ;

display_help() unless @ARGV == 1;
my $requirement_file = $ARGV[0] ;

my $requirement_text = $EMPTY_STRING ;
my $violations_text = $EMPTY_STRING ;

if( -e $requirement_file)
	{
	croak "Error: '$requirement_file' is not a file." unless( -f $requirement_file) ;
	croak "Error: '$requirement_file' is not writable." unless( -w $requirement_file) ;
	
	eval
		{
		my $violations 
			= check_requirement_file
				(
				$master_template_file, $master_categories_file, $requirement_file,
				$no_spellcheck, $no_check_categories
				) ;
		
		if(exists $violations->{$requirement_file})
			{
			$violations_text = DumpTree($violations->{$requirement_file}, 'Violations:', DISPLAY_ADDRESS => 0) ;
			$violations_text .= "\nDo not modify the violation text above, it will be automatically removed.\n" ;
			$violations_text =~ s/^/# /mg ;
			}
		} ;
	
	if($@)
		{
		$violations_text = "Error parsing the file as a requirement (this message changes the error message line numbers):\n$@\n" ;
		$violations_text .= "\nDo not modify the violation text above, it will be automatically removed.\n" ;
		$violations_text =~ s/^/# /mg ;
		}
	
		
	$requirement_text = $violations_text . read_file($requirement_file) ;
	}
else
	{
	my ($requirement_name) = File::Basename::fileparse($requirement_file, ('\..*')) ;
	
	#todo: accept raw source
	
	if(defined $free_form_template)
		{
		my $violations 
			= check_requirement_file
				(
				$master_template_file, $master_categories_file, $free_form_template,
				$no_spellcheck, $no_check_categories
				) ;
		
		if(exists $violations->{$free_form_template})
			{
			croak DumpTree $violations->{$free_form_template}, "Error: free form template has errors:" ;
			}
		else
			{
			$requirement_text = read_file($free_form_template) ;
			
			$requirement_text =~ s/NAME\s+=>\s'[^']*'/NAME => '$requirement_name'/ ;
			}
		}
	else
		{
		# create requirement from master template

		my $requirement_template = load_master_template($master_template_file)->{REQUIREMENT} ;
		
		my $requirement = create_requirement($requirement_template , {NAME => $requirement_name, ORIGINS =>['']}) ;
		
		$requirement_text = Dumper $requirement ;
		$requirement_text =~ s/\$VAR1 =// ;
		$requirement_text =~ s/^\s*//gm ;
		}
	}
	
eval
	{
	my $edited_requirement_text = Proc::InvokeEditor->edit($requirement_text, '.pl') ;

	# save backup
	write_file("$requirement_file.bak", $requirement_text) unless $no_backup ;

	# remove violation message
	$edited_requirement_text =~ s/\Q$violations_text// ;
	
	# save edited requirement
	write_file($requirement_file, $edited_requirement_text) ;

	# check
	my $violations = check_requirement_file
			(
			$master_template_file, $master_categories_file, $requirement_file,
			$no_spellcheck, $no_check_categories
			) ;
		
	if(exists $violations->{$requirement_file})
		{
		print DumpTree($violations->{$requirement_file}, 'Violations remaining in requirement:', DISPLAY_ADDRESS => 0) ;
		}
	} ;
	
die $@ if $@ ;


#------------------------------------------------------------------------------------------------------------------

sub check_requirement_file
{
	
my
(
$master_template_file, $master_categories_file, $requirement_file,
$no_spellcheck, $no_check_categories
) = @_ ;

my ($files, $ok_parsed, $requirements_with_errors, $violations) 
	= App::Requirement::Arch::Requirements::get_requirements_violations
		($master_template_file, $requirement_file) ;

unless($no_spellcheck)
	{
	my ($file_name_errors, $errors_per_file) = spellcheck($requirement_file) ;

	$violations->{$requirement_file}{spellchecking_errors} = $errors_per_file->{$requirement_file} if exists $errors_per_file->{$requirement_file}
	}
	
unless($no_check_categories)
	{
	my $category_structure = load_master_categories($master_categories_file) ;

	my ($requirements_structure, $requirements, $categories, $ok_parsed, $errors)
		= get_requirements_structure($requirement_file, $master_template_file) ;
	
	my ($in_master_only, $in_requirements_only) = merge_master_categories($category_structure, $requirements_structure, '') ;

	for ( grep {$_ ne '/NOT_CATEGORIZED' and $_ ne '/STATISTICS'} sort keys %{$in_requirements_only})
		{
		push @{ $violations->{$requirement_file}{not_in_master_categories}}, $_ ;
		}
	}
	
return $violations ;	
}

