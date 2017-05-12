package Armadito::Agent::Tools;

use strict;
use warnings;
use base 'Exporter';
use English qw(-no_match_vars);

our @EXPORT_OK = qw(
	getNoWhere
	trimWhitespaces
	getOSTempDir
);

sub getNoWhere {
	return $OSNAME eq 'MSWin32' ? 'nul' : '/dev/null';
}

sub trimWhitespaces {
	my ($string) = @_;

	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	$string =~ s/\s+/ /g;

	return $string;
}

sub getOSTempDir {
	return $OSNAME eq 'MSWin32' ? 'C:\\Temp\\' : '/tmp/';
}

1;
__END__

=head1 NAME

Armadito::Agent::Tools - Various tools used in Armadito Agent.

=head1 DESCRIPTION

This module provides some basic functions for multiple usages.

=head1 FUNCTIONS

=head2 getNoWhere()

Get OS noWhere. For example: /dev/null on Linux.

=head2 getOSTempDir()

Get OS temp directory path. For example: C:\Temp on Windows.

=head2 trimWhitespaces($string)

Remove leading and trailing whitespace, and fold multiple whitespace
characters into a single one.
