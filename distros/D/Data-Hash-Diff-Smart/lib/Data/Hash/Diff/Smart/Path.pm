package Data::Hash::Diff::Smart::Path;

use strict;
use warnings;

=head1 NAME

Data::Hash::Diff::Smart::Path

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

sub join {
	my ($base, $part) = @_;
	return $base eq '' ? "/$part" : "$base/$part";
}

1;
