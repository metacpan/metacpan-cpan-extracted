
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Bootylicious-Plugin-Gallery',
  NAME      => 'Bootylicious::Plugin::Gallery',
  AUTHOR    => "Konstantin\ Kapitanov\ \<perlovik\@gmail\.com\>",
  ABSTRACT  => "Gallery\ plugin\ for\ Bootylicious",
  VERSION   => '0.07',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Mojo" => '0.999910',
    "Image::Magick::Thumbnail::Fixed" => '0',
    "Digest::MD5" => '0',
    "Image::Magick" => '6.00',
  },
  test => {TESTS => 't/*.t'}
);

