package App::Framework::Settings ;

=head1 NAME

App::Framework::Settings - Application framework configuration

=head1 DESCRIPTION

Contains various configuration settings for the application framework objects.

=cut

use strict ;
use Carp ;

our $VERSION = "1.000" ;


#============================================================================================
# GLOBALS
#============================================================================================

=head2 MODULES

An array of the modules that will be imported into the application automatically:

	Cwd 
	File::Basename
	File::Path
	File::Temp
	File::Spec
	File::Find
	File::Copy
	Pod::Usage
	File::DosGlob qw(glob)
	Date::Manip
	Getopt::Long qw(:config no_ignore_case)
	
=cut

our @MODULES = (
	'Cwd', 
	'File::Basename',
	'File::Path',
	'File::Temp',
	'File::Spec',
	'File::Find',
	'File::Copy',
	"File::DosGlob 'glob'",
	
	'Pod::Usage',
	'Date::Manip',
	'Getopt::Long qw(:config no_ignore_case)',
	
) ;


=head2 DATE_TZ

If Date::Manip is automatically imported, then this variable should be set to the local timezone setting.

=cut

our $DATE_TZ = 'GMT' ;

=head2 DATE_FORMAT

If Date::Manip is automatically imported, then this variable should be set to the local date format setting.

=cut

our $DATE_FORMAT = 'non-US' ;


=head1 AUTHOR

Steve Price, C<< <sdprice at cpan.org> >>

=cut

# ============================================================================================
# END OF PACKAGE
1;

__END__


