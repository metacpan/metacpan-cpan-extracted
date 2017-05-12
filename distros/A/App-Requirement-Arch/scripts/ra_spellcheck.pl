#!/usr/bin/perl

use strict ;
use warnings ;
use Carp ;

use Data::TreeDumper ;
#~ use Text::Pluralize ;
use Getopt::Long;

use App::Requirement::Arch::Spellcheck qw(spellcheck)  ;

#------------------------------------------------------------------------------------------------------------------

sub display_help
{
warn << 'EOH' ;

NAME
	ra_spellcheck

SYNOPSIS

	$ perl ra_spellcheck path/to/requirements [[path/to/requirements] ...]

DESCRIPTION
	This script will run aspell on the contents of the requirements passed
	as arguments and the requirement file name. It will display the 
	errors it finds for each requirement as well as a statistic of what
	misspelled words are found.

ARGUMENTS

DEPENDENCY
	aspell
       
AUTHORS
	Khemir Nadim ibn Hamouda
	Ian Kumlien

EOH

exit(1) ;
}

#---------------------------------------------------------------------------------------------------------------------

my ($user_dictionary)  ;

croak 'Error parsing options!'unless 
	GetOptions
		(
		'h|help' => \&display_help, 
		'user_dictionary=s' => \$user_dictionary,
		
		'dump_options' => 
			sub 
				{
				print join "\n", map {"-$_"} 
					qw(
					user_dictionary
					help
					) ;
				exit(0) ;
				},
		) ;

@ARGV || die display_help() ;

my ($file_name_errors, $errors_per_file) = spellcheck(\@ARGV) ;

print DumpTree $file_name_errors, 'File name spelling errors:', DISPLAY_ADDRESS => 0 if scalar(keys %{$file_name_errors}) ;
print DumpTree $errors_per_file, 'Spelling errors per file:', DISPLAY_ADDRESS => 0 if scalar(keys %{$errors_per_file}) ;

#---------------------------------------------------------------------------------------------------------------------

#~ my (%all_errors, $total_spellcheck_errors) ;
#~ merge_errors(\%all_errors, $file_name_errors, $errors_per_file) ;
#~ $total_spellcheck_errors +=  $all_errors{$_} for(keys %all_errors) ;

#~ print DumpTree 
	#~ \%all_errors,
	#~ 'All spelling errors (' . pluralize ('{0|1|%d} invalid word{||s}, {No|%d} error{s||s}) :', scalar(keys %all_errors), $total_spellcheck_errors),
	#~ DISPLAY_ADDRESS => 0
		#~ if scalar(keys %all_errors) ;

#---------------------------------------------------------------------------------------------------------------------

#~ sub merge_errors
#~ {
#~ my ($merge_destination, @merge_sources) = @_ ;

#~ for my $merge_source (@merge_sources)
	#~ {
	#~ for (keys %{$merge_source})
		#~ {
		#~ for my $error (@{$merge_source->{$_}})
			#~ {
			#~ $merge_destination->{$error}++ ;  
			#~ }
		#~ }
	#~ }
#~ }

