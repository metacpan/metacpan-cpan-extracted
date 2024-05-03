package CPAN::Changes::Entry;
use strict;
use warnings;

our $VERSION = '0.500004';
$VERSION =~ tr/_//d;

use Moo;

with 'CPAN::Changes::HasEntries';

has text    => (is => 'ro');
has line    => (is => 'ro');

sub serialize {
  my ($self, %args) = @_;
  my $indents = $args{indents} || [];
  my $styles = $args{styles} || [];
  my $width = $args{width} || 75;

  my $indent = $indents->[0];
  my $style = $styles->[0];
  my $text = $self->text;
  if (length($style) < 2) {
    my $space = ' ' x (2 * length $style);
    $width -= length $space;
    $text =~ s/\G[ \t]*([^\n]{1,$width}|[^ \t\r\n]+)([ \t\r\n]+|$)/$1\n/mg;
    $text =~ s/[ \t]+\n/\n/g;
    $text =~ s/^(.)/$space$1/mg;
    substr $text, 0, length($style), $style;
  }
  # can't wrap this style
  elsif (length($style) % 2 == 0) {
    my $length = length($style) / 2;
    $text = substr($style, 0, $length) . $text . substr($style, $length) . "\n";
  }
  else {
    die "invalid changelog entry style '$style'";
  }
  return $text;
}

1;
__END__

=head1 NAME

CPAN::Changes::Entry - A change entry in a CPAN Changes file

=head1 SYNOPSIS

  my $entry = CPAN::Changes::Entry->new(
    text    => 'A change entry'
    entries => [
      'A sub-entry',
      'Another sub-entry',
    ],
  );

=head1 DESCRIPTION

A changelog is made up of one or more releases. This object provides access to
all of the key data that embodies a release including the version number, date
of release, and all of the changelog information lines.

=head1 ATTRIBUTES

=head2 text

The text of the change entry.

=head2 entries

An array ref of sub-entries under this change entry.

=head2 line

The line number that the change entry starts at.

=head1 METHODS

=head2 serialize

Returns the changes entry in string form.

=head2 clone

Returns a new release object with the same data. Can be given any attributes to
set them differently in the new object.

=head2 has_entries

Returns true if there are sub-entries for this entry.

=head2 find_entry

Accepts a string or a regex, returns a matching sub-entry object.

=head2 add_entry

Adds a changes sub-entry. Accepts a changes sub-entry object or a string.

=head2 remove_entry

Given a string or a changes entry object, removes the entry from the release.

=head1 SEE ALSO

=over 4

=item * L<CPAN::Changes>

=back

=head1 AUTHORS

See L<CPAN::Changes> for authors.

=head1 COPYRIGHT AND LICENSE

See L<CPAN::Changes> for the copyright and license.

=cut
