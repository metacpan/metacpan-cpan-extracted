use Test2::V0 -no_srand => 1;
use Alien::Base::ModuleBuild::Repository;
use File::chdir;
use Path::Tiny qw( path );

@INC = map { path($_)->absolute->stringify } @INC;

my $default = { 
  protocol => 'test',
  host     => 'ftp.gnu.org',
  location => '/gnu/gsl',
};

{
  my $repo = Alien::Base::ModuleBuild::Repository::Test->new($default);

  my @filenames = $repo->list_files;

  my @files = $repo->probe();

  is( scalar @files, scalar @filenames, 'without pattern, probe returns an object for each file');
  isa_ok( $files[0], 'Alien::Base::ModuleBuild::File' );
}

{
  my $pattern = qr/^gsl-[\d\.]+\.tar\.gz$/;
  local $default->{pattern} = $pattern;
  my $repo = Alien::Base::ModuleBuild::Repository::Test->new($default);

  my @filenames = grep { $_ =~ $pattern } $repo->list_files;

  my @files = $repo->probe();

  is( scalar @files, scalar @filenames, 'with pattern, probe returns an object for each matching file');
  isa_ok( $files[0], 'Alien::Base::ModuleBuild::File' );
  ok( ! defined $files[0]->version, 'without capture, no version information is available');
}

{
  my $pattern = qr/^gsl-([\d\.]+)\.tar\.gz$/;
  local $default->{pattern} = $pattern;
  my $repo = Alien::Base::ModuleBuild::Repository::Test->new($default);

  my @filenames = grep { $_ =~ $pattern } $repo->list_files;

  my @files = $repo->probe();

  is( scalar @files, scalar @filenames, 'with pattern, probe returns an object for each matching file');
  isa_ok( $files[0], 'Alien::Base::ModuleBuild::File' );
  ok( defined $files[0]->version, 'with capture, version information is available');
}

{
  my $filename = 'gsl-1.9.tar.gz.sig';
  local $default->{exact_filename} = $filename;
  my $repo = Alien::Base::ModuleBuild::Repository::Test->new($default);

  my @files = $repo->probe();

  is( scalar @files, 1, 'with exact filename, probe returns one object');
  isa_ok( $files[0], 'Alien::Base::ModuleBuild::File' );
  is( $files[0]->{filename}, $filename, 'the name of the object is the given filename');
  ok( ! defined $files[0]->version, 'without exact version, no version information is available');
}

{
  my $filename = 'gsl-1.9.tar.gz.sig';
  local $default->{exact_filename} = $filename;
  local $default->{exact_version} = '1.9';
  my $sha1 = '17f8ce6a621da79d8343a934100dfd4278b2a5e9';
  local $default->{sha1} = $sha1;
  my $sha256 = 'eb154b23cc82c5c0ae0a7fb5f0b80261e88283227a8bdd830eea29bade534c58';
  local $default->{sha256} = $sha256;
  my $repo = Alien::Base::ModuleBuild::Repository::Test->new($default);

  my @files = $repo->probe();

  is( scalar @files, 1, 'with exact filename, probe returns one object');
  isa_ok( $files[0], 'Alien::Base::ModuleBuild::File' );
  is( $files[0]->{filename}, $filename, 'the name of the object is the given filename');
  is( $files[0]->version, '1.9', 'with exact version, the version of the object if the given version');
  if (eval 'require Digest::SHA') {
      is( $files[0]->{sha1}, $sha1, 'the SHA-1 hash of the given filename');
      is( $files[0]->{sha256}, $sha256, 'the SHA-256 hash of the given filename');
  }
}

subtest 'exact_filename trailing slash' => sub {

  my $repo = Alien::Base::ModuleBuild::Repository->new(
    protocol       => 'https',
    host           => 'github.com',
    location       => 'hunspell/hunspell/archive',
    exact_filename => 'v1.3.4.tar.gz',
  );
  is $repo->location, 'hunspell/hunspell/archive/', 'exact filename implies trailing /';

  $repo = Alien::Base::ModuleBuild::Repository->new(
    protocol       => 'https',
    host           => 'github.com',
    location       => 'hunspell/hunspell/archive/',
    exact_filename => 'v1.3.4.tar.gz',
  );
  is $repo->location, 'hunspell/hunspell/archive/', 'exact filename with trailing slash already there';

  $repo = Alien::Base::ModuleBuild::Repository->new(
    protocol       => 'https',
    host           => 'github.com',
    location       => 'hunspell/hunspell/archive',
    pattern        => '^v([0-9\.]+).tar.gz$',
  );
  is $repo->location, 'hunspell/hunspell/archive', 'no exact filename does not imply trailing /';

};

done_testing;

package Alien::Base::ModuleBuild::Repository::Test;

use strict;
use warnings;
use parent 'Alien::Base::ModuleBuild::Repository';

sub list_files {
  my $self = shift;
  #files from GNU GSL FTP server, fetched 1/24/2012
  my @files = ( qw/
    gsl-1.0-gsl-1.1.patch.gz
    gsl-1.0.tar.gz
    gsl-1.1-gsl-1.1.1.patch.gz
    gsl-1.1.1-gsl-1.2.patch.gz
    gsl-1.1.1.tar.gz
    gsl-1.1.tar.gz
    gsl-1.10-1.11.patch.gz
    gsl-1.10-1.11.patch.gz.sig
    gsl-1.10.tar.gz
    gsl-1.10.tar.gz.sig
    gsl-1.11-1.12.patch.gz
    gsl-1.11-1.12.patch.gz.sig
    gsl-1.11.tar.gz
    gsl-1.11.tar.gz.sig
    gsl-1.12-1.13.patch.gz
    gsl-1.12-1.13.patch.gz.sig
    gsl-1.12.tar.gz
    gsl-1.12.tar.gz.sig
    gsl-1.13-1.14.patch.gz
    gsl-1.13-1.14.patch.gz.sig
    gsl-1.13.tar.gz
    gsl-1.13.tar.gz.sig
    gsl-1.14.tar.gz
    gsl-1.14.tar.gz.sig
    gsl-1.15.tar.gz
    gsl-1.15.tar.gz.sig
    gsl-1.2-gsl-1.3.patch.gz
    gsl-1.2.tar.gz
    gsl-1.3-gsl-1.4.patch.gz
    gsl-1.3-gsl-1.4.patch.gz.asc
    gsl-1.3.tar.gz
    gsl-1.4-gsl-1.5.patch.gz
    gsl-1.4-gsl-1.5.patch.gz.sig
    gsl-1.4.tar.gz
    gsl-1.4.tar.gz.asc
    gsl-1.5-gsl-1.6.patch.gz
    gsl-1.5-gsl-1.6.patch.gz.sig
    gsl-1.5.tar.gz
    gsl-1.5.tar.gz.sig
    gsl-1.6-gsl-1.7.patch.gz
    gsl-1.6-gsl-1.7.patch.gz.sig
    gsl-1.6.tar.gz
    gsl-1.6.tar.gz.sig
    gsl-1.7-1.8.patch.gz
    gsl-1.7-1.8.patch.gz.sig
    gsl-1.7.tar.gz
    gsl-1.7.tar.gz.sig
    gsl-1.8-1.9.patch.gz
    gsl-1.8-1.9.patch.gz.sig
    gsl-1.8.tar.gz
    gsl-1.8.tar.gz.sig
    gsl-1.9-1.10.patch.gz
    gsl-1.9-1.10.patch.gz.sig
    gsl-1.9.tar.gz
    gsl-1.9.tar.gz.sig
  / );

  return @files;
}
