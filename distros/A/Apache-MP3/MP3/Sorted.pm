package Apache::MP3::Sorted;
# $Id: Sorted.pm,v 1.4 2006/01/03 19:37:52 lstein Exp $
# example of how to subclass Apache::MP3 in order to provide
# control over the sorting of the rows of the MP3 table

use strict;
use Apache::MP3;
use CGI qw/:standard *TR param/;

use vars qw(@ISA $VERSION);
@ISA = 'Apache::MP3';

$VERSION = 2.02;

use constant DEBUG => 0;

# to choose the right type of sort for each of the mp3 fields
my %sort_modes = (
		  # config        field       sort type
		  title       => [qw(title        alpha)],
		  artist      => [qw(artist       alpha)],
		  duration    => [qw(seconds      numeric)],
		  seconds     => [qw(seconds      numeric)],
		  genre       => [qw(genre        alpha)],
		  album       => [qw(album        alpha)],
		  comment     => [qw(comment      alpha)],
		  description => [qw(description  alpha)],
		  bitrate     => [qw(bitrate      numeric)],
		  filename    => [qw(filename     alpha)],
		  kbps        => [qw(kbps         numeric)],
		  samplerate  => [qw(samplerate   numeric)],
		  track       => [qw(track        numeric)],
		  year        => [qw(year         numeric)],
		 );

sub sort_fields {
  my $self       = shift;
  my $field_spec = lc param('sort') if param('sort');
  # If there is not SortFields var, look for SortField, which is the var used
  # by the one sort field Apache::MP3::Sorted. This should retain a good amount
  # of backward compatibility
  $field_spec  ||= lc($self->r->dir_config('SortFields')
                      || $self->r->dir_config('SortField'));
  return split /[^\w+-]+/, $field_spec;
}

# sort MP3s
sub sort_mp3s {
  my $self   = shift;
  my $files  = shift;
  my @sort_info = (); # holds info about how to sort each field

  # Verify the sorting fields and build up our @sort_info data structure that
  # keep track of how everything should work.
  foreach ($self->sort_fields) {
    my ($reverse_sort, $field) = /^([+-]?)(.*)/;
    $reverse_sort = ($reverse_sort eq '-');
    if (exists($sort_modes{$field})) {
      # each @sort_info entry is [sort_order, sort_field, sort_type]
      push(@sort_info, [$reverse_sort, $sort_modes{$field}[0], $sort_modes{$field}[1]]);
    } else {
      $self->r->warn("Ignoring unsupported sort field $_ in sort_mp3s().");
    }
  }

  if (!@sort_info) {
    # no known sort types given
    $self->r->warn("No recognized sort fields passed to sort_mp3s()") if DEBUG;
    return $self->SUPER::sort_mp3s($files);
  }

  # Create an anonymous subroutine so we have closure of @sort_info and $files
  my $by_fields_sorter =
    sub {
      my $val = 0;
      foreach (@sort_info) {
        my ($reverse_sort, $field, $sort_type) = @$_;
        my ($x, $y) = ($files->{$a}{$field}, $files->{$b}{$field});
        ($x, $y) = ($y, $x) if $reverse_sort; # swap args for reverse sort
        if ($sort_type eq 'alpha') {
          $val = $x cmp $y;
        } elsif ($sort_type eq 'numeric') {
          $val = $x <=> $y;
        }
        last if $val;
      }
      return $val; # Found no compare difference between elements
    };

  return sort $by_fields_sorter keys %$files;
}

sub format_table_fields {
  my $self = shift;
  my $sort = param('sort') || '';
  my @fields;

  foreach ($self->fields) {
    $_ ||= '';
    my $sort = $sort eq lc($_)  ? lc("-$_") : lc($_);
    push @fields,a({-href=>"?sort=$sort"},
      $self->x(ucfirst($_))
    );
  }
  @fields;
}

# Add hidden field for sorting
sub mp3_list_bottom {
  my $self = shift;
  print hidden('sort');
  $self->SUPER::mp3_list_bottom(@_);
}


1;

=head1 NAME

Apache::MP3::Sorted - Generate sorted streamable directories of MP3 files

=head1 SYNOPSIS

 # httpd.conf or srm.conf
 AddType audio/mpeg    mp3 MP3

 # httpd.conf or access.conf
 <Location /songs>
   SetHandler perl-script
   PerlHandler Apache::MP3::Sorted
   PerlSetVar  SortFields    Album,Title,-Duration
   PerlSetVar  Fields        Title,Artist,Album,Duration
 </Location>

=head1 DESCRIPTION

Apache::MP3::Sorted subclasses Apache::MP3 to allow for sorting of MP3
listings by various criteria.  See L<Apache::MP3> for details on
installing and using.

=head1 CUSTOMIZING

This class adds one new Apache configuration variable, B<SortFields>.
This is a list of the names of the fields to sort by default when the
MP3 file listing is first displayed, after which the user can change
the sort field by clicking on the column headers.

=over 4

=item SortFields I<field>

The value of B<SortFields> may contain the names of any of the fields
in the listing, such as I<Title>, or I<Album> I<Duration>.  By
default, the sort direction will be alphabetically or numerically
ascending.  Reverse this by placing a "-" in front of the field name
(for symmetry, you can also prepend a "+" to signify normal ascending
order).  After the initial sort, the user can change the sort order by
clicking on the column headings of the file listing table.

Examples:

  PerlSetVar SortFields  Album,Title    # sort ascending by album, then title
  PerlSetVar SortFields  +Artist,-Kbps  # sort ascending by artist, descending by kbps

When constructing a playlist from a recursive directory listing,
sorting will be B<global> across all directories.  If no sort order is
specified, then the module reverts to sorting by file and directory
name.  A good value for SortFields is to sort by Artist,Album and
track:

  PerlSetVar SortFields Artist,Album,Track

Alternatively, you might want to sort by Description, which
effectively sorts by title, artist and album.

The following are valid fields:

    Field        Description

    album	 The album
    artist       The artist
    bitrate      Streaming rate of song in kbps
    comment      The comment field
    description	 Description, as controlled by DescriptionFormat
    duration     Duration of the song in hour, minute, second format
    filename	 The physical name of the .mp3 file
    genre        The genre
    samplerate   Sample rate, in KHz
    seconds      Duration of the song in seconds
    title        The title of the song
    track	 The track number

Field names are case insensitive.

=back

=head1 METHODS

Apache::MP3::Sorted overrides the following methods:

 sort_mp3s()  mp3_table_header()   mp3_list_bottom()

It adds one new method:

=over 4

=item $field = $mp3->sort_fields

Returns a list of the names of the fields to sort on by default.

=back

=head1 BUGS

Let me know.

=head1 AUTHOR

Copyright 2000, Lincoln Stein <lstein@cshl.org>.

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.

=head1 ACKNOWLEDGEMENTS

Tim Ayers <tayers@bridge.com> conceived and implemented the multiple
field sorting system.

=head1 SEE ALSO

L<Apache::MP3>, L<MP3::Info>, L<Apache>


=cut
