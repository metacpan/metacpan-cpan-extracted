# Copyright 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


package App::Chart::Texinfo::Util;
use 5.004;
use strict;
use warnings;
use Exporter;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION);
@ISA = qw(Exporter);
@EXPORT_OK = qw(node_to_html_anchor);
%EXPORT_TAGS = (all => \@EXPORT_OK);


# Nodes "HTML Xref Node Name Expansion"
# and   "HTML Xref 8-bit Character Expansion" in the Texinfo manual
# Given $node is wide-char.
#
sub node_to_html_anchor {
  my ($node) = @_;

  # precomposed characters where possible
  if ($node =~ /[^[:ascii:]]/) {
    require Unicode::Normalize;
    $node = Unicode::Normalize::NFC ($node);
  }

  # rule 3 multiple space,tab,newline become one space
  $node =~ s/[ \t\n]+/ /g;

  # rule 4 lose leading and trailing space
  $node =~ s/^ +//;
  $node =~ s/ +$//;

  # rule 6 chars except ascii alnum and the "-" (just inserted) become hex
  $node =~ s/([^ A-Za-z0-9])/_escape_char($1)/ge;

  # rule 5 remaining spaces become dashes
  $node =~ tr/ /-/;

  # rule 7 prepend "g_t" if doesn't begin with alpha
  if ($node =~ /^[^A-Za-z]/) {
    $node = 'g_t' . $node;
  }
  return $node;
}
# ENHANCE-ME: For EBCDIC presumably a UTF-EBCDIC -> unicode conversion is
# needed here, instead of just ord().
sub _escape_char {
  my ($c) = @_; # single-char string
  $c = ord($c);
  if ($c <= 0xFFFF) {
    return sprintf ('_%04x', $c);
  } elsif ($c <= 0xFF_FFFF) {
    return sprintf ('__%06x', $c);
  }
}

1;
__END__

=for stopwords texinfo Texinfo utf unicode

=head1 NAME

App::Chart::Texinfo::Util -- some texinfo utilities

=for test_synopsis my ($anchor, $node)

=head1 SYNOPSIS

 use App::Chart::Texinfo::Util;
 $anchor = App::Chart::Texinfo::Util::node_to_html_anchor ($node);

 # or imported
 use App::Chart::Texinfo::Util ':all';
 $anchor = node_to_html_anchor ($node);

=head1 DESCRIPTION

A function which hasn't found a better place to live yet.

=head1 FUNCTIONS

=over 4

=item C<$string = App::Chart::Texinfo::Util::node_to_html_anchor ($node)>

Return a HTML anchor for a Texinfo node name, as per anchor generation
specified in the Texinfo manual "HTML Xref Node Name Expansion" and "HTML
Xref 8-bit Character Expansion".  It encodes various spaces and
non-alphanumeric characters as hexadecimal "_HHHH" sequences.  For example,

    App::Chart::Texinfo::Util::node_to_html_anchor ('My Node-Name')
    # returns 'My-Node_002dName'

Perl utf8 wide-char strings can be passed here.  Characters beyond 255 are
taken to be unicode and encoded as 4 or 6 hex digits per the Texinfo spec.

=back

=head1 SEE ALSO

L<Texinfo::Menus>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2016 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
