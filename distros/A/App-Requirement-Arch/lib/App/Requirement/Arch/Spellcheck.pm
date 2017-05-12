
package App::Requirement::Arch::Spellcheck;

use strict;
use warnings ;
use Carp qw(carp croak confess) ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw
				(
				spellcheck
				) ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.01';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use App::Requirement::Arch::Requirements qw(get_files_to_check)  ;
use IPC::Open2;
use File::Slurp ;

#-------------------------------------------------------------------------------

=head1 NAME - App::Requirement::Arch::Spellcheck

=head1 SYNOPSIS

=head1 DOCUMENTATION

=head1 SUBROUTINES/METHODS

=cut

#--------------------------------------------------------------------------------------------------------------

sub spellcheck
{

=head2 spellcheck(\@sources, $user_dictionary)

I<Arguments>

=over 2 

=item * $sources -

=item * $user_dictionary -

=back

I<Returns> - $spellchek_errors_structure

I<Exceptions>

See C<xxx>.

=cut

my ($sources, $user_dictionary) = @_ ;

my @files_to_check = get_files_to_check($sources) ;

my $file_name_errors = spellcheck_data(\@files_to_check, file_name_provider(@files_to_check), $user_dictionary) ;
my $errors_per_file = spellcheck_data(\@files_to_check, file_content_provider(@files_to_check), $user_dictionary) ;

return $file_name_errors, $errors_per_file ;
}

#-------------------------------------------------------------------------------------------------------------------

sub spellcheck_data
{
my ($files_to_check, $data_provider, $user_dictionary) = @_ ;

$user_dictionary ||= 'ra_spellcheck_dictionary.txt' ;

# regenerate user dictionary
`aspell --lang=en create master ./ra_aspell_dictionary < $user_dictionary` ;

my $spellcheck_command = 'aspell list --ignore-case --extra-dicts ./ra_aspell_dictionary' ;

my $child_pid = open2(\*OUT, \*IN, $spellcheck_command) ;

while(my $data = $data_provider->()) 
	{
	print IN 'enadkheomatic', join "\n", split(/(\/| )/, $data) 
	}
	
close IN ;

my ($file_index, $file, %errors) = (0);

while(<OUT>)
	{
	if(/enadkheomatic/ )
		{
		$file = $files_to_check->[$file_index++] ;
		}
	else
		{
		chomp ;
		push @{$errors{$file}}, $_ ;
		}
	}

close OUT ;
waitpid ($child_pid, 0);

return \%errors ;
}

#---------------------------------------------------------------------------------------------------------------------

sub file_name_provider
{
my (@files_to_check) = @_ ;

return sub
	{
	return shift @files_to_check ;
	}
}

#---------------------------------------------------------------------------------------------------------------------

sub file_content_provider
{
my (@files_to_check) = @_ ;

return sub
	{
	return read_file(shift @files_to_check) if  @files_to_check;
	}
}

#---------------------------------------------------------------------------------------------------------------------

1 ;

