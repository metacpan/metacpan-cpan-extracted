package Repo;

use strict;
use warnings;
use Path::Tiny qw( path );
use File::chdir;
use File::Temp qw( tempdir );
use Archive::Tar;
use base qw( Exporter );

our @EXPORT = qw( example1 );

my $corpus = path(__FILE__)->absolute->parent->parent->parent->child('corpus');

sub example1
{
  my $dir = tempdir( CLEANUP => 1 );
  
  local $CWD = "$dir";
  
  my $tar = Archive::Tar->new($corpus->child('example1.tar'));
  $tar->extract;
  
  path($dir)->child('example1')->stringify;
}

1;
