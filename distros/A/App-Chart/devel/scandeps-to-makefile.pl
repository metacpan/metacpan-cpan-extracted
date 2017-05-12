#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

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


# Usage: ./scandeps-to-makefile.pl
#
# Recursion into submodules of things used ends up excessive.
#

use strict;
use warnings;
use ExtUtils::Manifest;
use File::Find;
use File::Spec;
use FindBin;
use Module::CoreList;
use Module::Depends::Intrusive;
use Module::ScanDeps;
use version;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $minimum_perl_version = version->new('5.10.0');


my $toplevel_dir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
print "toplevel $toplevel_dir\n";
push @INC, $toplevel_dir;

my $manifest_file = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
my $manifest = ExtUtils::Manifest::maniread ($manifest_file);

my @check_files = sort keys %$manifest;
@check_files = grep { /\.pm$|\.t$|^chart$/ } @check_files;
@check_files = grep { ! m{maybe/} } @check_files;
@check_files = grep { ! m{misc/} } @check_files;
# @check_files = map { File::Spec->catfile ($toplevel_dir, $_) } @check_files;
# splice @check_files,3;
#
print "Check: ",join("\n",@check_files),"\n";

my %own_files;
foreach my $file (@check_files) {
  my $bare = Module::ScanDeps::path_to_inc_name ($file, 1);
  $own_files{$bare} = 1;
}

#
# @check_files = glob('../lib/Gtk2/Ex/*.pm');
#

my $deps = Module::ScanDeps::scan_deps (files => \@check_files,
                                        recurse => 0);
print Dumper ($deps);

my %used_files;
foreach my $file (@check_files) {
  my $file = Module::ScanDeps::path_to_inc_name ($file, 1);
  my $uses = $deps->{$file}->{'uses'};  # arrayref
  print "$file uses: ",Dumper($uses);
  foreach my $used (@$uses) {
    if ($own_files{$used}) { next; }
    $used_files{$used} = 1;
  }
}

sub file_to_module {
  my ($file) = @_;
  my $module = $file;
  $module =~ s{/}{::}g;
  $module =~ s/\.pm$//i;
  return $module;
}
sub module_to_file {
  my ($module) = @_;
  my $file = $module;
  $file =~ s{::}{/}g;
  $file .= '.pm';
  return $file;
}

foreach my $file (sort keys %used_files) {
  my $module = file_to_module ($file);
  my $version = Module::CoreList->first_release ($module);

  if (defined $version) {
    if ($version <= $minimum_perl_version) {
      delete $used_files{$file};
      next;
    }
    print "$module   since perl $version\n";

  } else {
    print "$module\n";
  }
}

my $makefile_prereq;
{
  my $deps = Module::Depends::Intrusive->new;
  $deps->dist_dir($toplevel_dir);
  $deps->find_modules;
  if (my $err = $deps->error) {
    die "Cannot get Makefile.PL dependencies: $err";
  }
  $makefile_prereq = $deps->{'requires'}; # hashref
}

foreach my $file (sort keys %used_files) {
  my $module = file_to_module ($file);
  if (! exists $makefile_prereq->{$module}) {
    print "not in Makefile.PL: $module\n";
  }
}
foreach my $module (sort keys %$makefile_prereq) {
  my $file = module_to_file ($module);
  if (! exists $used_files{$file}) {
    print "extra in Makefile.PL: $module\n";
  }
}

exit 0;
