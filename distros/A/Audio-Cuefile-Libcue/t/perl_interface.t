#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Audio::Cuefile::Libcue') }

#########################

# sample cue sheet to use
open my $cue, '<:raw', 't/standard.cue' or die "Failed to open standard.cue: $!";

my $cd = Audio::Cuefile::Libcue::cue_from_file($cue);
ok( $cd, "error parsing CUE" );

close $cue;

# expected structure from Perl cue builder
my %expected = (
  mode   => 'CD_DA',
  cdtext => {
    TITLE     => 'Loveless',
    PERFORMER => 'My Bloody Valentine',
    GENRE     => 'Alternative'
  },
  rem => {
    DATE => '1991'
  },
  track => {
    1 => {
      filename => 'My Bloody Valentine - Loveless.wav',
      mode     => 'AUDIO',
      sub_mode => 'RW',
      start    => 0,
      length   => 19327,
      cdtext   => {
        TITLE     => 'Only Shallow',
        PERFORMER => 'My Bloody Valentine'
      },
      index => {
        1 => 0
      }
    },
    2 => {
      filename => 'My Bloody Valentine - Loveless.wav',
      mode     => 'AUDIO',
      sub_mode => 'RW',
      start    => 19327,
      cdtext   => {
        TITLE     => 'Loomer',
        PERFORMER => 'My Bloody Valentine'
      },
      index => {
        1 => 19327
      }
    }
  }
);

is_deeply( $cd, \%expected, "deep compare" );
