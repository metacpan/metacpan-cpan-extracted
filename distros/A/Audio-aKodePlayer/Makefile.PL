use strict;
use warnings;
use ExtUtils::MakeMaker;

our (%config,$LIB,$CFLAGS);
{
  # parse command-line
  my (%params); @params{qw(AKODE_LIB AKODE_INCLUDES)}=();
  @ARGV = grep {
    my ($key, $val) = split(/=/, $_, 2);
    if (exists $params{$key}) { $config{$key} = $val; 0 } else { 1 }
  } @ARGV;
}

{
  if (defined $config{AKODE_LIB}) {
    $LIB = '-L'.$config{AKODE_LIB}.' -lakode';
  } else {
    $LIB = `akode-config --libs`;
    unless (defined $LIB) {
      warn "akode-config --cflags failed: try perl Makefile.PL AKODE_LIB=<path to libakode.so>\n";
      $LIB = '-L/usr/lib -lakode';
    }
  }
  if (defined $config{AKODE_INCLUDES}) {
    $CFLAGS = '-I'.$config{AKODE_INCLUDES}
  } else {
    $CFLAGS = `akode-config --cflags`;
    unless (defined $CFLAGS) {
      warn "akode-config --cflags failed: try perl Makefile.PL AKODE_INCLUDES=<path to akode/player.h\n";
      $CFLAGS = '-I/usr/include';
    }
  }
  print "Using libs:   $LIB\n";
  print "Using cflags: $CFLAGS\n";
}

my $CC = 'c++';

WriteMakefile(
    NAME                => 'Audio::aKodePlayer',
    AUTHOR              => 'Petr Pajas <pajas@matfyz.cz>',
    VERSION_FROM        => 'lib/Audio/aKodePlayer.pm',
    ABSTRACT_FROM       => 'lib/Audio/aKodePlayer.pm',
    PL_FILES            => {},

    LIBS                => [ $LIB ],
    DEFINE              => '', # e.g., '-DHAVE_SOMETHING'
    CC                  => $CC,
    LD                  => '$(CC)',
    INC                 => $CFLAGS,
    XSOPT               => '-C++ -prototypes',
    TYPEMAPS            => ['perlobject.map' ],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Audio-aKodePlayer-*' },
);
