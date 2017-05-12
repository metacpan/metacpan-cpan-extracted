## Babble/Encode.pm
## Copyright (C) 2004 Gergely Nagy <algernon@bonehunter.rulez.org>
##
## This file is part of Babble.
##
## Babble is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; version 2 dated June, 1991.
##
## Babble is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

package Babble::Encode;

use strict;
require Exporter;
use base qw/Exporter/;
our @EXPORT = qw(to_utf8);

=pod

=head1 NAME

Babble::Encode - Encoding wrapper for Babble

=head1 SYNOPSIS

 use Babble::Encode;
 ...
 $encoded = to_utf8 ($string);
 ...

=head1 DESCRIPTION

This module provides a wrapper around either Encode or Text::Iconv,
whichever is installed on ones computer, to convert an arbitrary
string to UTF-8.

=head1 METHODS

=over 4

=item to_utf8

Converts its only argument to UTF-8.

=cut

sub to_utf8 ($) {
	my ($text) = @_;
	eval q{
		use Encode;
	};
	if ($@) {
		use Text::Iconv;
		my $c = Text::Iconv ('iso-8859-2', 'utf-8');
		return $c->convert ($text) || $text;
	} else {
		return Encode::encode ('utf-8', $text);
	}
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Encode, Text::Iconv

=cut

1;

# arch-tag: 6393c26f-c780-4533-900b-6133ed0dec1f
