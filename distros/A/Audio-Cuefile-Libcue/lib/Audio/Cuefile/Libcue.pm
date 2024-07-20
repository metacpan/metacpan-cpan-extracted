package Audio::Cuefile::Libcue;

use 5.006002;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration	use Audio::Cuefile::Libcue ':all';
our %EXPORT_TAGS = (
  'all' => [ qw(
    cue_from_string
    cue_from_file
    cd_get_cdtext
    cd_get_cdtextfile
    cd_get_mode
    cd_get_ntrack
    cd_get_rem
    cd_get_track
    cdtext_get
    cue_parse_file
    cue_parse_string
    rem_get
    track_get_cdtext
    track_get_filename
    track_get_index
    track_get_isrc
    track_get_length
    track_get_mode
    track_get_rem
    track_get_start
    track_get_sub_mode
    track_get_zero_post
    track_get_zero_pre
    track_is_set_flag
  ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ();

our $VERSION = '2.3.0';

# C INTERFACE

require XSLoader;
XSLoader::load( 'Audio::Cuefile::Libcue', $VERSION );

# PERL INTERFACE

# CONSTANTS

# disc modes
# DATA FORM OF MAIN DATA (5.29.2.8)
use constant {
  MODE_CD_DA     => 0,    # CD-DA
  MODE_CD_ROM    => 1,    # CD-ROM mode 1
  MODE_CD_ROM_XA => 2,    # CD-ROM XA and CD-I
};

# track modes
# 5.29.2.8 DATA FORM OF MAIN DATA
# Table 350 - Data Block Type Codes
use constant {
  MODE_AUDIO          => 0,    # 2352 byte block length
  MODE_MODE1          => 1,    # 2048 byte block length
  MODE_MODE1_RAW      => 2,    # 2352 byte block length
  MODE_MODE2          => 3,    # 2336 byte block length
  MODE_MODE2_FORM1    => 4,    # 2048 byte block length
  MODE_MODE2_FORM2    => 5,    # 2324 byte block length
  MODE_MODE2_FORM_MIX => 6,    # 2332 byte block length
  MODE_MODE2_RAW      => 7,    # 2352 byte block length
};

# sub-channel mode
# 5.29.2.13 Data Form of Sub-channel
# NOTE: not sure if this applies to cue files
use constant {
  SUB_MODE_RW     => 0,    # RAW Data
  SUB_MODE_RW_RAW => 1,    # PACK DATA (written R-W)
};

# track flags
# Q Sub-channel Control Field (4.2.3.3, 5.29.2.2)
use constant {
  FLAG_NONE           => 0x00,    # no flags set
  FLAG_PRE_EMPHASIS   => 0x01,    # audio recorded with pre-emphasis
  FLAG_COPY_PERMITTED => 0x02,    # digital copy permitted
  FLAG_DATA           => 0x04,    # data track
  FLAG_FOUR_CHANNEL   => 0x08,    # 4 audio channels
  FLAG_SCMS           => 0x10,    # SCMS (not Q Sub-ch.) (5.29.2.7)
  FLAG_ANY            => 0xff,    # any flags set
};

# cdtext pack type indicators
use constant {
  PTI_TITLE      => 0,            # title of album or track titles
  PTI_PERFORMER  => 1,            # name(s) of the performer(s)
  PTI_SONGWRITER => 2,            # name(s) of the songwriter(s)
  PTI_COMPOSER   => 3,            # name(s) of the composer(s)
  PTI_ARRANGER   => 4,            # name(s) of the arranger(s)
  PTI_MESSAGE    => 5,            # message(s) from the content provider and/or artist
  PTI_DISC_ID    => 6,            # (binary) disc identification information
  PTI_GENRE      => 7,            # (binary) genre identification and genre information
  PTI_TOC_INFO1  => 8,            # (binary) table of contents information
  PTI_TOC_INFO2  => 9,            # (binary) second table of contents information
  PTI_RESERVED1  => 10,           # reserved
  PTI_RESERVED2  => 11,           # reserved
  PTI_RESERVED3  => 12,           # reserved
  PTI_RESERVED4  => 13,           # reserved for content provider only
  PTI_UPC_ISRC   => 14,           # UPC/EAN code of the album and ISRC code of each track
  PTI_SIZE_INFO  => 15,           # (binary) size information of the block
  PTI_END        => 16,           # terminating PTI (for stepping through PTIs)
};

use constant {
  REM_DATE                  => 0,    # date of cd/track
  REM_REPLAYGAIN_ALBUM_GAIN => 1,
  REM_REPLAYGAIN_ALBUM_PEAK => 2,
  REM_REPLAYGAIN_TRACK_GAIN => 3,
  REM_REPLAYGAIN_TRACK_PEAK => 4,
  REM_END                   => 5,    # terminating REM (for stepping through REMs)
};

#### ####

sub _cdtext {
  my $cdtext = shift;

  my @mapping = qw(
    TITLE
    PERFORMER
    SONGWRITER
    COMPOSER
    ARRANGER
    MESSAGE
    DISC_ID
    GENRE
    TOC_INFO1
    TOC_INFO2
    RESERVED1
    RESERVED2
    RESERVED3
    RESERVED4
    UPC_ISRC
    SIZE_INFO
  );

  my %result;

  for ( my $i = 0 ; $i < PTI_END ; $i++ ) {
    my $val = cdtext_get( $i, $cdtext );
    $result{ $mapping[$i] } = $val if $val;
  }

  return unless %result;

  return \%result;
}

sub _rem {
  my $rem = shift;

  my @mapping = qw(
    DATE
    REPLAYGAIN_ALBUM_GAIN
    REPLAYGAIN_ALBUM_PEAK
    REPLAYGAIN_TRACK_GAIN
    REPLAYGAIN_TRACK_PEAK
  );

  my %result;

  for ( my $i = 0 ; $i < REM_END ; $i++ ) {
    my $val = rem_get( $i, $rem );
    $result{ $mapping[$i] } = $val if $val;
  }

  return unless %result;

  return \%result;
}

# use the functions in the xs to parse the cue
sub _cue {
  my $cd = shift;

  my %c;
  my $v;

  # CD mode
  $v = cd_get_mode($cd);
  if ( $v == MODE_CD_DA ) {
    $c{mode} = 'CD_DA';
  } elsif ( $v == MODE_CD_ROM ) {
    $c{mode} = 'CD_ROM';
  } elsif ( $v == MODE_CD_ROM_XA ) {
    $c{mode} = 'CD_ROM_XA';
  } else {
    die "Unknown CD mode $v";
  }

  # CD-level text
  $v = cd_get_cdtextfile($cd);
  $c{cdtextfile} = $v if $v;

  $v = _cdtext( cd_get_cdtext($cd) );
  $c{cdtext} = $v if $v;

  # REM info
  $v = _rem( cd_get_rem($cd) );
  $c{rem} = $v if $v;

  # ALL TRACKS
  #my $track_count = cd_get_ntrack($cd);

  # there are 1 to 99 tracks maybe
  my %tracks;

  for my $i ( 1 .. 99 ) {
    my $track = cd_get_track( $cd, $i );

    if ($track) {
      my %t;

      $v = track_get_filename($track);
      $t{filename} = $v if $v;

      $v = track_get_start($track);
      $t{start} = $v if $v >= 0;

      $v = track_get_length($track);
      $t{length} = $v if $v >= 0;

      $v = track_get_mode($track);
      if ( $v == MODE_AUDIO ) {
        $t{mode} = 'AUDIO';
      } elsif ( $v == MODE_MODE1 ) {
        $t{mode} = 'MODE1';
      } elsif ( $v == MODE_MODE1_RAW ) {
        $t{mode} = 'MODE1_RAW';
      } elsif ( $v == MODE_MODE2 ) {
        $t{mode} = 'MODE2';
      } elsif ( $v == MODE_MODE2_FORM1 ) {
        $t{mode} = 'MODE2_FORM1';
      } elsif ( $v == MODE_MODE2_FORM2 ) {
        $t{mode} = 'MODE2_FORM2';
      } elsif ( $v == MODE_MODE2_FORM_MIX ) {
        $t{mode} = 'MODE2_FORM_MIX';
      } elsif ( $v == MODE_MODE2_RAW ) {
        $t{mode} = 'MODE2_RAW';
      } else {
        die "Unknown track $i mode $v";
      }

      my $v = track_get_sub_mode($track);
      if ( $v == SUB_MODE_RW ) {
        $t{sub_mode} = 'RW';
      } elsif ( $v == SUB_MODE_RW_RAW ) {
        $t{sub_mode} = 'RW_RAW';
      } else {
        die "Unknown track $i sub mode $v";
      }

      if ( track_is_set_flag( $track, FLAG_PRE_EMPHASIS ) ) {
        $t{flags}{PRE_EMPHASIS} = 1;
      }
      if ( track_is_set_flag( $track, FLAG_COPY_PERMITTED ) ) {
        $t{flags}{COPY_PERMITTED} = 1;
      }
      if ( track_is_set_flag( $track, FLAG_DATA ) ) {
        $t{flags}{DATA} = 1;
      }
      if ( track_is_set_flag( $track, FLAG_FOUR_CHANNEL ) ) {
        $t{flags}{FOUR_CHANNEL} = 1;
      }
      if ( track_is_set_flag( $track, FLAG_SCMS ) ) {
        $t{flags}{SCMS} = 1;
      }

      $v = track_get_zero_pre($track);
      $t{zero_pre} = $v if $v >= 0;

      $v = track_get_zero_post($track);
      $t{zero_post} = $v if $v >= 0;

      $v = track_get_isrc($track);
      $t{isrc} = $v if $v;

      $v = _cdtext( track_get_cdtext($track) );
      $t{cdtext} = $v if $v;

      # REM info
      $v = _rem( track_get_rem($track) );
      $t{rem} = $v if $v;

      my %index;
      for my $j ( 0 .. 99 ) {
        $v = track_get_index( $track, $j );
        $index{$j} = $v if $v >= 0;
      }
      $t{index} = \%index if %index;

      $tracks{$i} = \%t if %t;
    }
  }

  $c{track} = \%tracks if %tracks;

  warn "Track count does not match counted tracks" unless cd_get_ntrack($cd) == scalar keys %{ $c{track} };

  return \%c;
}

sub cue_from_string {
  my $string = shift;

  my $xs = Audio::Cuefile::Libcue::cue_parse_string($string);

  return _cue($xs);
}

sub cue_from_file {
  my $file = shift;

  my $xs = Audio::Cuefile::Libcue::cue_parse_file($file);

  return _cue($xs);
}

1;
__END__
# Below is documentation for the module.

=head1 NAME

Audio::Cuefile::Libcue

=head1 VERSION

Version 2.3.0

=head1 SYNOPSIS

Perl interface to the C<libcue> cuesheet reading library

=head1 USAGE

  use Audio::Cuefile::Libcue;

  my $cuesheet = cue_from_string($string);
  print Dumper($cuesheet);

=head1 DESCRIPTION

This is a Perl interface to C<libcue>, a cuesheet parsing library written in C.
C<libcue> itself was forked from the C<cuetools> project and further enhanced.
The library can read cuesheets in many common formats.

The C interface is made available to Perl, but users should not need those.
Instead, use the one-shot parsing functions to read a cuesheet into a Perl data
structure.

=head2 Perl Interface

  my $cue = cue_from_string($string);

  # or if you have an open filehandle,
  $cue = cue_from_file($filehandle);

These two functions read a cuefile from a string or open filehandle, parse it
using the C functions, and return a hash structure.  The filehandle can be closed
after this call.

An example of the Perl usage is in F<t/perl_interface.t>.  Note that the C<tracks> and C<index>, despite being numeric, are stored as string hash keys.  Use a numeric sort (C<sort { $a E<lt>=E<gt> $b }>) when iterating through the keys.

=head2 C Interface

If preferred, the C functions from F<libcue.h> are mapped into Perl functions, with the exception of C<cd_delete()> as it is automatically called when needed.  

  # Open a cuesheet
  my $cd = cue_parse_string($cue);

  print "Tracks in CD: " . cd_get_ntrack($cd) . "\n";

  $track_1 = cd_get_track( $cd, 1 );
  print "Track 1 filename: " . track_get_filename($track_1) . "\n";
  # etc

Refer to C<libcue> for a list of available functions, or F<t/c_interface.t> for further examples.

=head2 Exportable functions

  # Perl interface
  cue_from_string($string)
  cue_from_file($filehandle)

  // C interface
  struct Cd* cue_parse_file(FILE* fp)
  struct Cd* cue_parse_string(const char* string)

  enum DiscMode cd_get_mode(const struct Cd *cd)
  const char *cd_get_cdtextfile(const struct Cd *cd)

  struct Cdtext *cd_get_cdtext(const struct Cd *cd)
  struct Cdtext *track_get_cdtext(const struct Track *track)
  const char *cdtext_get(enum Pti pti, const struct Cdtext *cdtext)

  struct Rem* cd_get_rem(const struct Cd* cd)
  struct Rem* track_get_rem(const struct Track* track)
  const char* rem_get(enum RemType cmt, const struct Rem* rem)

  int cd_get_ntrack(const struct Cd *cd)
  struct Track *cd_get_track(const struct Cd *cd, int i)

  const char *track_get_filename(const struct Track *track)
  long track_get_start(const struct Track *track)
  long track_get_length(const struct Track *track)
  enum TrackMode track_get_mode(const struct Track *track)
  enum TrackSubMode track_get_sub_mode(const struct Track *track)
  int track_is_set_flag(const struct Track *track, enum TrackFlag flag)
  long track_get_zero_pre(const struct Track *track)
  long track_get_zero_post(const struct Track *track)
  const char *track_get_isrc(const struct Track *track)
  long track_get_index(const struct Track *track, int i)

None of the constants are exportable.

=head1 HISTORY

=over

=item 2.3.0

Original version; created by h2xs 1.23 with options

        -A
        -C
        -b
        5.6.2
        -v
        2.3.0
        -n
        Audio::Cuefile::Libcue
        -x
        libcue/libcue.h

=back

=head1 SEE ALSO

L<https://github.com/greg-kennedy/p5-Audio-Cuesheet-Libcue> - repository for Audio::Cuesheet::Libcue development

L<https://github.com/lipnitsk/libcue> - repository for the C libcue library

Other Cuesheet modules:

=over

=item * L<Audio::Cuefile::Parser>, an older pure Perl cuesheet parser

=item * L<Audio::Cuefile::ParserPlus>, a newer Perl module which can also I<write> cuesheets.

=item * L<MP3::Tag::Cue>, a cue parser used as part of L<MP3::Tag>.

=back

=head1 REFERENCES

L<https://en.wikipedia.org/wiki/Cue_sheet_(computing)> - Wikipedia article on Cuesheets

L<https://wiki.hydrogenaud.io/index.php?title=Cue_sheet> - Hydrogen Audio article on Cuesheets, with more detail and examples

=head1 AUTHOR

Greg Kennedy, E<lt>kennedy.greg@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Greg Kennedy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.36.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
