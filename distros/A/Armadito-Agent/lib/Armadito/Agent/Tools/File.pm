package Armadito::Agent::Tools::File;

use strict;
use warnings;
use base 'Exporter';

use UNIVERSAL::require();
use Encode;
use English qw(-no_match_vars);
use Memoize;
use File::Which;
use Armadito::Agent::Tools qw (getNoWhere);

our @EXPORT_OK = qw(
	readFile
	writeFile
	canRun
	rmFile
);

if ( $OSNAME ne 'MSWin32' ) {
	memoize('canRun');
}

sub rmFile {
	my (%params) = @_;

	if ( -f $params{filepath} ) {
		unlink( $params{filepath} );
	}
}

sub readFile {
	my (%params) = @_;
	my $fh;

	if ( !open( $fh, "<", $params{filepath} ) ) {
		die "Error io $params{filepath} : $!";
	}

	return do { local $/; <$fh> };
}

sub writeFile {
	my (%params) = @_;
	my $fh;

	if ( !open( $fh, $params{mode}, $params{filepath} ) ) {
		die "Error io $params{filepath} : $!";
	}

	binmode $fh;
	print $fh $params{content};
	close $fh;
	return 1;
}

sub canRun {
	my ($binary) = @_;

	return $binary =~ m{^/} ? -x $binary :    # full path
		scalar( which($binary) );             # executable name
}

1;
__END__

=head1 NAME

Armadito::Agent::Tools::File - Basic I/O functions used in Armadito Agent.

=head1 DESCRIPTION

This module provides some high level I/O functions for easy use.

=head1 FUNCTIONS

=head2 readFile(%params)

Read file and return its content in a scalar.

=over

=item I<filepath>

Path of the file to be read.

=back

=head2 writeFile(%params)

Write a scalar to a file in binary mode.

=over

=item I<content>

Content to write (scalar).

=item I<filepath>

Path of the file where content will be written to.

=item I<mode>

File opening mode.

=back

=head2 canRun($binary)

Returns true if given binary can be executed.

=head2 rmFile(%params)

Remove a file if it exists.

=over

=item I<filepath>

Path of the file to remove.

