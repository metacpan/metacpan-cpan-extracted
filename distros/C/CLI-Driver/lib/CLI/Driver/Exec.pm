package CLI::Driver::Exec;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use YAML ();
use Carp;
use Sort::Naturally;

##############################################################################
# PUBLIC ATTRIBUTES
##############################################################################

##############################################################################
# PRIVATE_ATTRIBUTES
##############################################################################

##############################################################################
# PUBLIC METHODS
##############################################################################

method sortDriverFile (Str  :$driverFile!,
                       Bool :$writeStdout) {

    $YAML::Preserve  = 1;
	$YAML::UseHeader = 0;

	my $yaml = YAML::LoadFile($driverFile);
    my @keys = keys %$yaml;
     
    my @sorted = ('---');
	foreach my $key ( nsort( keys %$yaml ) ) {
		push @sorted, YAML::Dump( { $key => $yaml->{$key} } );
	}

    my $sorted = join "\n", @sorted;
    
	if ($writeStdout) {
		print $sorted;
	}
	else {
		open( my $fh, '>', $driverFile )
		  or confess "failed to open $driverFile: $!";
		print $fh $sorted;
		close($fh);
	}
}

##############################################################################
# PRIVATE METHODS
##############################################################################

1;
