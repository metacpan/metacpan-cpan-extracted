#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2012, 2013, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./makefile-to-debs.pl
#
# Look at Makefile.PL and compare the declared PREREQ_PM modules, and their
# versions, against what's in the Depends line of the debian/control file.
#

use strict;
use warnings;
use AptPkg::Config;
use Data::Dumper;
use File::Spec;
use FindBin;
use List::Util;
use Memoize;
use Module::CoreList;
use Module::Depends::Intrusive;
use Module::Util;
use Parse::DebControl;
use File::Slurp;
use version;

#use Smart::Comments;

# modules in perl from $minimum_perl_version onwards are considered core
my $minimum_perl_version = version->new('v5.10');

my $toplevel_dir = File::Spec->curdir;
my $makefile_filename = File::Spec->catdir ($toplevel_dir, 'Makefile.PL');
if (! -f $makefile_filename) {
  $toplevel_dir = File::Spec->catdir ($toplevel_dir, File::Spec->updir);
  $makefile_filename = File::Spec->catdir ($toplevel_dir, 'Makefile.PL');
  if (! -f $makefile_filename) {
    die "Cannot find Makefile.PL in current directory or parent directory\n";
  }
}
print "toplevel: $toplevel_dir\n";


my $makefile_contents = File::Slurp::slurp ($makefile_filename);
if ($makefile_contents =~ /^use (5\.[0-9.]+)/m) {
  $minimum_perl_version = version->new ($1);
  print "Makefile.PL: perl version $minimum_perl_version\n";
} else {
  print "Makefile.PL: no use perl version, leave at $minimum_perl_version\n";
}

my $deps = Module::Depends::Intrusive->new;
$deps->dist_dir($toplevel_dir);
$deps->find_modules;
if (my $err = $deps->error) {
  die "Cannot get Makefile.PL dependencies: $err";
}

$Data::Dumper::Sortkeys = 1;
my $requires = $deps->{'requires'}; # hashref
print "Module::Depends::Intrusive gives ", Dumper ($requires);


sub depends_to_hash {
  my ($str) = @_;
  my %hash;
  foreach my $elem (split (/, */, $str)) {
    my $package = $elem;
    my $version = 0;
    if ($elem =~ / \(>= (.*)\)/) {
      $package = $`;
      $version = $1;
    }
    $hash{$package} = $version;
  }
  return \%hash;
}

my $parser = Parse::DebControl->new;
my $control_filename = File::Spec->catfile ($toplevel_dir,'debian','control');
print "control file: $control_filename\n";
my $control = $parser->parse_file ($control_filename, {stripComments=>1});
print "Parse::DebControl gives ", Dumper ($control);
my $source = $control->[0];
my $binary = $control->[1];

my $control_depends = $binary->{'Depends'};
if (! defined $control_depends) {
  die "Oops, no Depends line\n";
}
print "Got Depends: $control_depends\n";
$control_depends = depends_to_hash ($control_depends);
{ ## no critic (RequireInterpolationOfMetachars)
  delete $control_depends->{'${misc:Depends}'};
}

my $build_depends = $source->{'Build-Depends'};
if (! defined $build_depends) {
  die "Oops, no Depends line\n";
}
print "Got Build-Depends: $build_depends\n";
$build_depends = depends_to_hash ($build_depends);


sub file_to_deb {
  my ($filename) = @_;
  ### file_to_deb(): $filename
  foreach my $prog (# 'dlocate',
                    # 'dloc',
                    'dpkg') {
    my $matches = `$prog -S $filename`;
    if ($matches =~ m{(.*): /usr/(share|lib)/perl/5.*/$filename}) {
      return 'perl';
    } elsif ($matches =~ m{(.*): /usr/(share|lib)/perl5/$filename}) {
      return $1;
    } else {
      print "Oops, $filename not found\n$prog gave:\n";
      print $matches;
    }
  }
  return undef;
}
memoize('file_to_deb');

sub module_to_deb {
  my ($module, $module_version) = @_;
  ### module_to_deb(): $module, $module_version

  my $perl_version = Module::CoreList->first_release($module, $module_version);
  ### $perl_version
  if (defined $perl_version) {
    $perl_version = version->new($perl_version);
    if ($perl_version > $minimum_perl_version) {
      # my $filename = Module::Util::module_path ($module);
      # ### $filename
      my $file = $module;
      $file =~ s{::}{/}g;
      $file .= '.pm';
      my $deb = file_to_deb ($file);
      print "$module $module_version builtin since $perl_version, drop to guess $deb\n";
      return $deb;
    }
    print "$module $module_version builtin since $perl_version\n";
  }

  my $file = $module;
  $file =~ s{::}{/}g;
  $file .= '.pm';
  return file_to_deb ($file);
}

sub max_version {
  return List::Util::reduce {$a > $b ? $a : $b}
    map {version->new($_)}
      @_;
}

$AptPkg::Config::_config->init;
my $apt_versioning = $AptPkg::Config::_config->system->versioning;
print "AptPkg::Version is '",$apt_versioning->label,"'\n";

sub deb_version_max {
  my @versions = @_;
  @versions = grep {defined} @versions;
  if (@versions <= 1) { return $versions[0]; }

  return List::Util::reduce
    { $apt_versioning->rel_compare ($a, $b) >= 0 ? $a : $b } @versions;
  #   return List::Util::reduce
  #     { (system ('dpkg', '--compare-versions', $a, '>>', $b) == 0)
  #         ? $a : $b } @versions;
}
my %deb_version_epoch = ('libglib-perl' => '1:',
                         'libgtk2-perl' => '1:');
sub cpan_version_to_deb_version {
  my ($version, $deb) = @_;
  if (my $epoch = $deb_version_epoch{$deb}) {
    $version = "$epoch$version";
  }
  return $version;
}

my %makefile_depends;
foreach my $module (sort keys %$requires) {
  my $version = $requires->{$module};
  my $deb = module_to_deb ($module, $version);
  $version = cpan_version_to_deb_version ($version, $deb);
  print "$module   $deb   $version\n";
  $makefile_depends{$deb}
    = deb_version_max ($makefile_depends{$deb}, $version);
}

{ my $perl_version = $minimum_perl_version;
  if ($makefile_contents =~ /^use ([0-9.]+)/) {
    $perl_version = max_version ($perl_version, $1);
  }
  # 5.010 becomes 5.10.0
  $perl_version = version->new($perl_version)->normal;
  $perl_version =~ s/^v//;
  $makefile_depends{'perl'} = $perl_version;
}

print "\n";
print "Depends: ", join (', ',
                         sort
                         map { my $deb = $_;
                               my $version = $makefile_depends{$deb};
                               ($version ? "$deb (>= $version)" : $deb) }
                         keys %makefile_depends),
  "\n";


foreach my $deb (sort keys %makefile_depends) {
  if (! exists $control_depends->{$deb}
      && ! exists $build_depends->{$deb}) {
    my $version = $makefile_depends{$deb};
    print "not in control file: $deb (>= $version)\n";
  }
}
my @control_list = sort keys %$control_depends, keys %$build_depends;
foreach my $deb (@control_list) {
  if (! exists $makefile_depends{$deb}) {
    my $version = $control_depends->{$deb};
    print "extra in control file: $deb",$version ? " >= $version" : '',"\n";
  }
}
foreach my $deb (@control_list) {
  if (exists $makefile_depends{$deb}) {
    my $control_version = $control_depends->{$deb};
    my $makefile_version = $makefile_depends{$deb};
    $control_version //= 0;
    if ($apt_versioning->compare ($control_version, $makefile_version) != 0) {
      print "$deb different versions: makefile $makefile_version, control $control_version\n";
    }
  }
}

exit 0;
