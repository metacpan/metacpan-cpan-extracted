# Copyright (C) 2023  Alex Schroeder <alex@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package App::news;

use Modern::Perl '2018';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(wrap html_unwrap ranges sranges);

our $VERSION = 1.07;

=head1 NAME

App::news - a web front-end for a news server

=head1 DESCRIPTION

This is a collection of functions for F<script/news>, which see.

    use App::news qw(wrap);
    $body = wrap($body);

B<wrap> does text wrapping appropriate for plain text message bodies as used in
mail and news articles.

If a line is shorter than 50 characters, it is not wrapped.

Lines are wrapped to be 72 characters or shorter.

Quotes are handled as long as only ">" is used for quoting.

B<ranges> translates a list of message numbers into an array of numbers or
arrays suitable for XOVER.

B<sranges> translates the output of I<ranges> into a string for humans to read,
i.e. "1-2,4".

=head1 AUTHOR

Alex Schroeder

=head1 LICENSE

GNU Affero General Public License

=cut

sub wrap {
  my @lines = split(/\n/, shift);
  my @result;
  my $min = 50;
  my $max = 72;
  my $buffer;
  my $prefix = '';
  for (@lines) {
    my ($new_prefix) = /^([> ]*)/;
    my $no_wrap = (/^$prefix\s*$/ or length() < $min);
    # end old paragraph with the old prefix if the prefix changed or a short line
    # came up
    if ($buffer and ($new_prefix ne $prefix or $no_wrap)) {
      push(@result, $prefix . $buffer);
      $buffer = '';
    }
    # set new prefix
    $prefix = $new_prefix;
    # print short lines without stripping trailing whitespace
    if ($no_wrap) {
      push(@result, $_);
      next;
    }
    # continue old paragraph
    $buffer .= " " if $buffer;
    # strip the prefix
    $buffer .= substr($_, length($prefix));
    # wrap what we have
    while (length($buffer) > $max) {
      # if there's a word boundary at $max, break before
      if (substr($buffer, 0, $max - length($prefix) + 1) =~ /(\s+(\S+))\S$/) {
        push(@result, $prefix . substr($buffer, 0, $max - length($prefix) - length($1)));
        $buffer = substr($buffer, $max - length($prefix) - length($2));
      } else {
        my $line = substr($buffer, 0, $max - length($prefix));
        $line =~ s/\s+$//;
        push(@result, $prefix . $line);
        $buffer = substr($buffer, $max - length($prefix));
        $buffer =~ s/^\s+//;
      }
    }
  }
  push(@result, $prefix . $buffer) if $buffer;
  return join("\n", @result) . "\n";
}

sub html_unwrap {
  my @lines = split(/\n/, shift);
  my $result;
  my $depth = 0;
  for (@lines) {
    chomp;
    my ($prefix) = /^([> ]*)/;
    my $new_depth = () = $prefix =~ />/g;
    s/^([> ]*)//;
    my $closed = 0;
    while ($new_depth < $depth) {
      $result .= "</blockquote>";
      $depth--;
      $closed = 1;
    }
    $result .= "\n" unless $closed; # closing blockquote already added a break
    while ($depth < $new_depth) {
      $result .= '<blockquote>';
      $depth++;
    }
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    $result .= $_;
  }
  while ($depth > 0) {
    $result .= "</blockquote>";
    $depth--;
  }
  return $result;
}

sub ranges {
  return [] unless @_;
  my $last = shift;
  my $curr = $last;
  my $ranges = [];
  for my $n (@_) {
    if ($n == $curr + 1) {
      $curr = $n;
    } elsif ($last == $curr) {
      push(@$ranges, $last);
      $last = $curr = $n;
    } else {
      push(@$ranges, [$last, $curr]);
      $last = $curr = $n;
    }
  }
  if ($curr > $last) {
    push(@$ranges, [$last, $curr]);
  } else {
    push(@$ranges, $curr);
  }
  return $ranges;
}

sub sranges {
  my $ranges = shift;
  join(",", map { ref ? join("-", @$_) : $_ } @$ranges);
}

1;
