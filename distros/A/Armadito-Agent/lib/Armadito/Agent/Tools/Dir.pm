package Armadito::Agent::Tools::Dir;

use strict;
use warnings;
use base 'Exporter';

use UNIVERSAL::require();
use Encode;
use English qw(-no_match_vars);
use File::Path qw(make_path remove_tree);

our @EXPORT_OK = qw(
	makeDirectory
	readDirectory
);

sub makeDirectory {
	my (%params) = @_;

	unless ( -d $params{dirpath} ) {
		make_path( $params{dirpath} ) || warn "Can't make path $params{dirpath}";
	}
}

sub readDirectory {
	my (%params) = @_;
	my @entries = ();
	my $dh;

	if ( !defined( $params{filter} ) ) {
		$params{filter} = "none";
	}

	if ( !opendir( $dh, $params{dirpath} ) ) {
		die "unable to readdir $params{dirpath}.";
	}

	while ( readdir $dh ) {
		if ( my $selected_entry = _isSelected( $_, %params ) ) {
			push( @entries, $selected_entry );
		}
	}

	closedir $dh;
	return @entries;
}

sub _isSelected {
	my ( $entry, %params ) = @_;

	if ( $params{filter} eq "files-only" ) {
		if ( !-f $params{dirpath} . "/" . $entry ) {
			return;
		}
	}

	if ( $params{filter} eq "dirs-only" ) {
		if ( !-d $params{dirpath} . "/" . $entry ) {
			return;
		}
	}

	if ( $entry eq "." || $entry eq ".." ) {
		return;
	}

	return $entry;
}

1;
__END__

=head1 NAME

Armadito::Agent::Tools::Dir - Basic functions for directories manipulations used in Armadito Agent.

=head1 DESCRIPTION

This module provides some easy to use functions for directories manipulations.

=head1 FUNCTIONS

=head2 makeDirectory(%params)

Make directory and its subpaths if needed (mkdir -p).

=over

=item I<dirpath>

Path of the directory to create.

=back

=head2 readDirectory(%params)

Open given directory and read all files. This only read at first level deep. This is not a recursive read.

=over

=item I<dirpath>

Path of the directory to read.


