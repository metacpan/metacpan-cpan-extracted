#!/usr/bin/env perl
# Build ShadyTars to test that the protections MechaCPAN takes to prevent
# attack vectors by tar archives. This script should deterministicly produce
# the same archives every time.

use strict;
use warnings;
use Archive::Tar;
use Archive::Tar::Constant qw/FILE SYMLINK HARDLINK COMPRESS_GZIP/;
use File::Basename qw/dirname/;
use File::Spec;

my $basedir = dirname( File::Spec->rel2abs(__FILE__) );
my $pwd     = File::Spec->catfile( $basedir, 'ShadyTars' );
chdir $pwd;

# Make sure the attributes are consistent
my %attrs = (
  mtime => 0,
  uid   => 0,
  gid   => 0,
  uname => '',
  gname => '',
);

sub gen_tar
{
  my ( $name, @contents ) = @_;

  my $path = File::Spec->catfile( $pwd, $name );
  my $tar  = Archive::Tar->new;

  foreach my $file (@contents)
  {
    $tar->add_data(@$file);
  }
  $tar->write( $path, COMPRESS_GZIP );

  print "wrote $path\n";
}

# .. traversal in name
gen_tar 'traversal.tar.gz' => (
  [
    '../escape.txt' => 'traversal payload',
    { %attrs, type => FILE }
  ]
);

# absolute path
gen_tar 'absolute_path.tar.gz' => (
  [
    '/tmp/escape.txt' => 'absolute payload',
    { %attrs, type => FILE }
  ]
);

# absolute symlink destination
gen_tar 'symlink_absolute.tar.gz' => (
  [
    'link' => '',
    { %attrs, type => SYMLINK, linkname => '/tmp' }
  ],
);

# symlink with .. traversal in target
gen_tar 'symlink_traversal.tar.gz' => (
  [
    'link' => '',
    { %attrs, type => SYMLINK, linkname => '../etc' }
  ]
);

# hardlink with absolute target
gen_tar 'hardlink_absolute.tar.gz' => (
  [
    'hardlink' => '',
    { %attrs, type => HARDLINK, linkname => '/tmp/etc/passwd' }
  ]
);

# symlink write-through
# first entry creates a symlink pointing outside, then the second entry write
# through to a target file
gen_tar 'symlink_writethrough.tar.gz' => (
  [
    'escape' => '',
    { %attrs, type => SYMLINK, linkname => '/tmp' }
  ],
  [
    'escape/payload.txt' => 'wrote through symlink',
    { %attrs, type => FILE }
  ],
);

# benign control tar
my $mfpl = "use ExtUtils::MakeMaker;\nWriteMakefile(NAME => 'Foo');\n";
my $lib  = "package Foo;\nour \$VERSION = '1.0';\n1;\n";
gen_tar 'benign.tar.gz' => (
  [
    'dist-1.0/Makefile.PL' => $mfpl,
    { %attrs, type => FILE }
  ],
  [
    'dist-1.0/lib/Foo.pm' => $lib,
    { %attrs, type => FILE }
  ],
);
