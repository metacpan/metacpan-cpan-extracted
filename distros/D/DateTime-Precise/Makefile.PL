# This -*- perl -*- script writes the Makefile for this package.

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'	 => 'DateTime::Precise',
  'VERSION_FROM' => 'lib/DateTime/Precise.pm', # finds $VERSION
  'dist'         => {
    'COMPRESS'   => 'gzip',
    'SUFFIX'     => 'gz'
  },
);	
