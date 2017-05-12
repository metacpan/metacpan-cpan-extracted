package Audio::DB::Parse::ReadFiles;

# $Id: ReadFiles.pm,v 1.2 2005/02/27 16:56:25 todd Exp $
# Parse tag information directly from MP3 files

use strict;
use vars qw/@ISA/;

use MP3::Info;
use File::Basename 'dirname','basename'; # Lincoln's recursive approach
use File::Find;      # For recursing into directories via my method...
use LWP::MediaTypes; # NOT YET IN USE

@ISA = qw/Audio::DB::Build/;

# Ripped from Apache::MP3
# But not yet being used
# Some audio file types...

# .. and some translations just to be nice
my %modes = (
	     0 => 'stereo',
	     1 => 'joint stereo',
	     2 => 'dual stereo',
	     3 => 'mono'             # Early beatles, ya know
	    );
my @suffix      = qw(.ogg .OGG .wav .WAV .mp3 .MP3 .mpeg .MPEG);
my %supported_types = (
		       # type                 condition                     handler method
		       'audio/mpeg'        => eval "use MP3::Info; 1;"   && 'read_mpeg',
		       'application/x-ogg' => eval "use Ogg::Vorbis; 1;" && 'read_vorbis',
		       'audio/x-wav'       => eval "use Audio::Wav; 1;"  && 'read_wav',
		      );



# sub routines for directly reading tag information from files
# This should just return full path of all mp3s
# option for processing or not...
my $cur_obj;
sub _process_directories {
  my ($name,$self,$top_dirs) = @_;
  $cur_obj = $self;
  foreach (@$top_dirs) {
    if (defined $self->{shout}) { print STDERR "Finding MP3-containing subdirectories within $_...\n"; };
    finddepth(\&_store,$_);
  }

  my @dirs = keys %{$self->{recursed_dirs}};
  if (defined $self->{shout}) { print STDERR "Processing " . scalar @dirs . " directories...\n"; };

  foreach my $path (@dirs) {
    $self->{counters}->{dirs_processed}++;
    opendir(DIR,$path);
    while (my $file = readdir(DIR)) {
      my $full_path = $path . $file;

      # Files to ignore for now
      # This should be handled by the recursive directory listing
      # THis should be done within the directory option
      next unless ($file =~ /.*\.mp3/);
      
      # LATER, TRY TO BE MORE SPECIFC - COULD EVEN HANDLE IMAGES FOR BUILDING
      # HTML PAGES  JPG GIF HTML TXT, ETC
      next if ($file =~ /^\./);
      next if ($file =~ /.*\.txt/);

      # Parse the data directly from the file
      my $tags  = {};
      my $info = {};
      ($tags,$info) = $self->_get_tags($full_path,$file);

      # TODO
      # No reasonable way of dealing with songs lacking tags yet
      if ($tags->{artist} eq '\N' || $tags->{album} eq '\N') {
	push (@{$self->{couldnt_read}},$full_path);
	next;
      }

      $self->cache_song($tags);
    }
  }
  return @dirs;
}


# I can't pass any extra parameters to _store
# through the finddepth subroutine.
# Ugliness!  Have to define the $cur_obj parameter.
sub _store {
  my $pwd = `pwd`;
  chomp $pwd;
  $pwd .= '/';
  if (-d $pwd) {
    $cur_obj->{recursed_dirs}->{$pwd}++;
  }
}

# Fetch tags and file_info for the current file
# and load into into a temporary hash ref
sub _get_tags {
  my ($self,$fullpath,$file) = @_;
  my $flag;
  my $tag = get_mp3tag($fullpath) || $flag++;
  if ($flag) {
    push (@{$self->{couldnt_read}},$fullpath);
    $tag = undef;
    return $tag;
  }
  
  return unless my $info = get_mp3info($fullpath);
  
  my ($title,$artist,$album,$year,$comment,$genre,$track) = 
    @{$tag}{qw(TITLE ARTIST ALBUM YEAR COMMENT GENRE TRACKNUM)} if $tag;
  my $duration = sprintf "%d:%2.2d", $info->{MM}, $info->{SS};
  my $seconds  = ($info->{MM} * 60) + $info->{SS};
  
  # Need to build up the temporary hash with
  # renamed hash keys

  # THIS PLACEHOLDER SHOULD BE DSN SPECIFIC -
  # SHOULD INITIALIZE PLACEHOLDER THERE
  my $ph = '\N';
  
  my ($track,$tot_tracks) = _parse_tracks($track);
  my $data = {
	      title        => $title             || $ph,
	      artist       => $artist            || $ph,
	      duration     => $duration          || $ph,
	      genre        => $genre             || $ph,
	      album        => $album             || $ph,
	      comment      => $comment           || $ph,
	      year         => $year              || $ph,
	      min          => $info->{MM}        || $ph,
	      sec          => $info->{SS}        || $ph,
	      seconds      => $seconds           || $ph,
	      lyrics       => $tag->{LYRICS}     || $ph,
	      track        => $track             || $ph,
	      total_tracks => $tot_tracks        || $ph,
	      bitrate      => $info->{BITRATE}   || $ph,
	      samplerate   => $info->{FREQUENCY} || $ph,
	      filename     => $file,
	      filepath     => $fullpath,
	      filesize     => $info->{SIZE}      || $ph,
	      tagtypes     => $tag->{TAGVERSION} || $ph,
	      fileformat   => $info->{LAYER}     || $ph,
	      channels     => $modes{$info->{MODE}} || $ph,
	      vbr          => $info->{VBR}       || $ph,
	      rating       => $tag->{RATING}     || $ph,
              playcount    => $tag->{PLAYCOUNT}  || $ph,
	     };
  
  #  if ($DEBUG) {
  #    foreach (keys %$data) {
  #      print $_,"\t",$data->{$_},"\n";
  #    }
  #  }
  return ($data,$info);
}


sub _parse_tracks {
  my $tracks = shift;
  $tracks =~ /(.*)\/(.*)/;
  my $track = $1;
  my $tot_tracks = $2;
  return ($track,$tot_tracks);
}


=pod

=head1 Audio::DB::Parse::ReadFiles.pm

Glean information on music files directly from their ID3 tags.

=head1 DESCRIPTION

Audio::DB::Parse::ReadFiles.pm is used internally by Audio::DB. It's
internal, private methods will be called when trying to create or update
a music database using the 'dirs' option:

      $mp3->load_database(-dirs =>['/path/to/MP3s/'],
		          -tmp  =>'/tmp/');

All methods of Audio::DB::Parse::ReadFiles are private (for now). You
will never need to interact with Audio::DB::Parse::ReadFiles objects
directly.

=head1 REQUIRES
    
B<MP3::Info> for reading ID3 tags, B<LWP::MediaTypes> for distinguising 
types of readable files;

=head1 EXPORTS

No methods are exported.

=head1 METHODS

No public methods available.

=head1 PRIVATE METHODS

=head2 _process_directories

 Title   : _process_directories
 Usage   : $mp3->_process_directories;
 Function: Fetches all mp3s at top level directories.
 Returns : Nothing
 Args    : none
 Status  : Private

Fetches all the mp3s within the top level directories provided
during calls to the new() method. Farms off a file at a time
to cache_song for processing.

=head2 _parse_tracks

 Title   : _parse_tracks
 Usage   : _parse_tracks($artist);
 Function: Splits the track tag into track and total tracks.
 Returns : track, total tracks
 Args    : raw track field from ID3 tag
 Status  : Private

=head1 AUTHOR

Copyright 2002-2004, Todd W. Harris <harris@cshl.org>.

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.

=head1 ACKNOWLEDGEMENTS

Chris Nandor <pudge@pudge.net> wrote MP3::Info, the module responsible for 
reading MP3 tags. Without, this module would be a best-selling pulp
romance novel behind the gum at the grocery store checkout. Chris has
been really helpful with issues that arose with various MP3 tags from 
different taggers. Kudos, dude!

Lincoln (Dr. Leichtenstein) Stein <lstein@cshl.org> wrote much of the original 
adaptor code as part of the l<Bio::DB::GFF> module. Much of that code is 
incorporated here, albeit in a pared-down form.  The code for reading ID3 tags 
from files only with appropriate MIME-types is borrowed from his <Apache::MP3> 
module. This was a much more elegant than my lame solution of checking for .mp3!
Lincoln tolerates having me in his lab, too, even though I use a Mac.

=head1 SEE ALSO

L<Audio::DB>,L<MP3::Info>

=cut


1;
