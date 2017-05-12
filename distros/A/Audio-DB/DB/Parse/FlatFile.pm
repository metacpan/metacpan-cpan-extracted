package Audio::DB::Parse::FlatFile;

# Subroutines for parsing a tab-delimited flat file of songs

use strict;
use vars qw/@ISA/;

@ISA = qw/Audio::DB::Build/;

sub parse_files {
  my ($name,$self,$provided_files,$columns) = @_;

  # provided_files could be a mixture of files and directories.
  # I need to determine their type first...
  my @files;
  foreach my $check_this (@$provided_files) {
    if (-d $check_this) {
      $check_this = ($check_this =~ /\/$/) ? $check_this : $check_this . '/';
      opendir DIR,$check_this;
      while (my $file = readdir(DIR)) {
	next if ($file =~ /^\./);
	push (@files,$check_this . $file);
      }
      closedir DIR;
    } elsif (-e $check_this) {
      push (@files,$check_this);
    }
  }
  
  foreach my $file (@files) {
    open IN,$file;
    while (my $song = <IN>) {
      chomp $song;
      my $tag = {};
      # Fetch the order of the columns.
      my @fields = split("\t",$song);

      # Mapped the data into the tag hash reference
      # to mimic the handling of individual mp3 files.
      my $i;
      for ($i = 0; $i < @$columns; $i++) {
	$tag->{$columns->[$i]} = $fields[$i];
      }

      # I need to convert the duration into seconds...
      $tag->{duration} =~ /(\d+):(\d+)/;
      my $minutes = $1;
      my $seconds = $2;
      $tag->{seconds} = ($minutes * 60) + $seconds;

      $self->cache_song($tag);
    }
    close IN;
  }
}

=pod

=head1 Audio::DB::Parse::FlatFile.pm

Glean information on music files from a flat file of music file data.

=head1 DESCRIPTION

Audio::DB::Parse::FlatFile.pm is used internally by Audio::DB. It's
internal, private methods will be called when trying to create or update
a music database using the 'files' option:

      $mp3->load_database(-files   =>'/path/to/music_summary.txt',
                          -columns => [qw/artist album song year/],
		          -verbose  => 100);

All methods of Audio::DB::Parse::FlatFile are private (for now). You
will never need to interact with Audio::DB::Parse::FlatFile objects
directly.

=head1 REQUIRES

=head1 EXPORTS

No methods are exported.

=head1 METHODS

No public methods available.

=head1 PRIVATE METHODS

=head2 parse_files;
  
 Title   : parse_flatfiles
 Usage   : $mp3->parse_files;
 Function: Process list of text files containing ID3 information
 Returns : Nothing
 Args    : none
 Status  : Private

Used for loading pre-generated data from flat files into the database. 
Finds all the text files contained within top level directories
provided during calls to the new() method. Processes each file, farming
off a line at a time to cache_song.

=head1 AUTHOR

Copyright 2002-2004, Todd W. Harris <harris@cshl.org>.

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.

=head1 SEE ALSO

L<Audio::DB>

=cut




1;
