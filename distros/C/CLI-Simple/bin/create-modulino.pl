#!/usr/bin/perl

use strict;
use warnings;

use File::Which qw(which);
use File::Copy;
use File::Basename qw(dirname);
use Data::Dumper;
use Getopt::Long;

########################################################################
sub create_modulino_name {
########################################################################
  my ($module_name) = @_;

  my @module_parts = map {lcfirst} split /::/xsm, $module_name;

  my $modulino_name = join q{-}, @module_parts;

  return $modulino_name;
}

########################################################################
sub usage {
########################################################################
  print <<'END_OF_USAGE';
usage: create-modulino.pl options

Options
-------
-h, --help     help
-m, --module   module name
-b, --bindir   executable directory
-d, --destdir  optional prefix for installation
-a, --alias    alias or symbolic link name

Example:

 create-modulino.pl -b /usr/local/bin -a find-requires -m Module::ScanDeps::FindRequires

END_OF_USAGE

  return 0;
}

########################################################################
sub main {
########################################################################
  my @option_specs = qw(
    bindir=s
    destdir=s
    alias=s
    module=s
    help
  );

  my %options;

  GetOptions( \%options, @option_specs );

  my $module = $options{module};

  if ( $options{help} ) {
    exit usage();
  }

  die "--module is a require option\n"
    if !$module;

  my $path = which 'modulino';

  die "no path to modulino\n"
    if !$path;

  my $executable_path = dirname $path;

  my $bindir = $options{bindir} // $executable_path;

  my $destdir = $options{destdir} // q{};

  my $alias = $options{alias};

  my $modulino_name = create_modulino_name( $options{module} );
  my $modulino_path = sprintf '%s%s/%s', $destdir, $bindir, $modulino_name;

  if ( -e "$modulino_path" ) {
    unlink "$modulino_path";
  }

  copy( $path, "$modulino_path" );

  chmod oct('0755'), "$modulino_path";

  if ($alias) {
    symlink "$modulino_path", "$destdir$bindir/$alias";
  }

  return 0;
}

exit main();

1;
