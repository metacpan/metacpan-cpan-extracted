package CLI::Driver::Exec;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use Carp;
use Sort::Naturally;
use YAML::Syck;

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

    $YAML::Syck::ImplicitTyping = 1;
    $YAML::Syck::Headless = 1;
    $YAML::Syck::SortKeys = 1;

	my $yaml = YAML::Syck::LoadFile($driverFile);
    my @keys = keys %$yaml;
     
    my @sorted = ('---');
	foreach my $key ( nsort( keys %$yaml ) ) {
		push @sorted, YAML::Syck::Dump( { $key => $yaml->{$key} } );
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

__PACKAGE__->meta->make_immutable;

1;
