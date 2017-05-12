#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2016 Kevin Ryde

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


# Usage: ./makefile-from-grep.pl
#
# Grep through the sources in the MANIFEST file and compare the modules and
# their versions against what's in Makefile.PL.
#

use strict;
use warnings;
use ExtUtils::Manifest;
use File::chdir;
use File::Find;
use File::Spec;
use FindBin;
use Module::CoreList;
use Module::Depends::Intrusive;
use Perl6::Slurp;  # for :gzip layer
use version;
use YAML;

# uncomment this to run the ### lines
#use Smart::Comments;

# use lib::abs File::Spec->catdir ($FindBin::Bin, 'lib');
use lib::abs $FindBin::RealBin;
use MyExtractUse;

my $verbose = 0;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $minimum_perl_version = version->new('5');
# version->new('v5.6.0');

if (@ARGV && $ARGV[0] eq '--verbose') {
  $verbose = 1;
  shift @ARGV;
}

my $toplevel_dir = File::Spec->curdir;
# File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
print "toplevel $toplevel_dir\n";

# for Module::Depends::Intrusive ...
push @INC, File::Spec->catdir ($toplevel_dir, 'inc');

my $makefile_filename = File::Spec->catdir ($toplevel_dir, 'Makefile.PL');
my $makefile_contents = Perl6::Slurp::slurp ($makefile_filename);
if ($makefile_contents =~ /^(use|require) (5\.[0-9.]+)/m) {
  $minimum_perl_version = version->new ($2);
  print "Makefile.PL: perl version $minimum_perl_version\n";
}

my $manifest_file = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
# hash of { FILENAME => COMMENT }
my $manifest = ExtUtils::Manifest::maniread ($manifest_file);

my @main_files = sort keys %$manifest;
sub split_out {
  my ($dest, $regexp) = @_;
  @main_files = grep { $_ =~ $regexp ? do{push @$dest,$_;0} : 1 } @main_files;
}

my @test_files;
split_out (\@test_files, qr{^t/});
@test_files = grep { /\.pm$|\.t$/ } @test_files; # not data files
@test_files = grep { ! m{MyTestHelpers} } @test_files;

my @devel_files;
split_out (\@devel_files, qr{^devel/|^inc/my_|^xt/});

my @examples_files;
split_out (\@examples_files, qr{^examples/});

@main_files = grep { ! m{^xt/} } @main_files;
@main_files = grep { ! m{^misc/} } @main_files;
@main_files = grep { ! m{^maybe/} } @main_files;
@main_files = grep { /\.pm$|\.t$|^chart$/ } @main_files;
unshift @main_files, makefile_exe_files();
@main_files = map { File::Spec->catfile ($toplevel_dir, $_) } @main_files;
#
# splice @main_files,3;
print "Check: \n  ",join("\n  ",@main_files),"\n";

sub makefile_exe_files {
  $makefile_contents =~ /EXE_FILES.*=>.*(\[.*)/ or return;
  return @{eval $1};
}

my %own_module;

sub dependencies_from_file {
  my ($file, $usedref, $optionalref) = @_;
  print "$file:\n";
  # if (-l $file) { next; }

  my $mode = '<';
  if ($file =~ /\.gz$/) {
    $mode .= ':gzip';
  }
  my $content = Perl6::Slurp::slurp ($mode, $file);
  ### slurp size: length($content)
  while ($content =~ /^package ([A-Za-z0-9:_]+)/mg) {
    print "  package $1\n";
    $own_module{$1} = $file;
  }

  foreach my $used (MyExtractUse->from_file ($file)) {
    my $package = $used->{'package'};
    my $version = $used->{'version'};
    if ($used->{'eval'}) {
      $optionalref->{$package} = version_max ($optionalref->{$package}, $version);
    } else {
      $usedref->{$package} = version_max ($usedref->{$package}, $version);
    }
    print "  $package ", $version//'undef', ($used->{'eval'} ? ' [optional]' : ''), "\n";
  }

  #   require Module::ExtractUse;
  #   my $extractor = Module::ExtractUse->new;
  #   $extractor->extract_use(\$content);
  #   # my @used = $extractor->array;
  #   my $h = $extractor->used;
  #   print "  ", scalar keys %$h, " used: ",join (', ',sort keys %$h),"\n";
  #   %$usedref = (%$usedref, %$h);
  #   %$optionalref = ();
}

sub delete_own_modules {
  my ($usedref) = @_;

  foreach my $module (sort keys %$usedref) {
    if ($own_module{$module}) {
      delete $usedref->{$module};
    }
  }
}

sub get_distvname {
  my $str = Perl6::Slurp::slurp ('Makefile')
    || die 'No Makefile';
  $str =~ /^DISTVNAME = (.*)/m
    or die 'No DISTVNAME in Makefile';
  my $distvname = $1;
  print "DISTVNAME $distvname\n";
  return $distvname;
}

my $makefile_prereq = {};
my $makefile_devel_prereq = {};
my $makefile_examples_prereq = {};
my $makefile_test_optional = {};
{
  my $deps = MyModuleDepends->new;
  #  my $deps = Module::Depends::Intrusive->new;
  $deps->dist_dir($toplevel_dir);
  $deps->find_modules;
  if (my $err = $deps->error) {
    die "Cannot get Makefile.PL dependencies: $err";
  }
  $makefile_prereq = $deps->requires; # hashref
  print "Makefile.PL: ", Dumper($makefile_prereq);

  # my $extra_meta = $deps->{'extra_meta'};
  # my $yaml = YAML::Load ("--- #YAML:1.0\n$extra_meta");

  my $yaml;
  {
    local $File::chdir::CWD = $toplevel_dir;
    my $distvname = get_distvname;
    system ("make metafile") == 0
      or die "Cannot make metafile META.yml";
    my $meta_yml_filename = "$distvname/META.yml";
    print "read $meta_yml_filename\n";
    $yaml = YAML::LoadFile ("$distvname/META.yml");
  }
  if ($verbose) { print "Makefile.PL yaml: ", Dumper($yaml); }

  my $optional_features = $yaml->{'optional_features'};

  if (my $maximum_devel = $optional_features->{'maximum_devel'}) {
    $makefile_devel_prereq = $maximum_devel->{'requires'};
  }
  print "Makefile.PL maximum_devel: ", Dumper($makefile_devel_prereq);

  if (my $makefile_examples = $optional_features->{'maximum_examples'}) {
    $makefile_examples_prereq = $makefile_examples->{'requires'};
  }
  print "Makefile.PL maximum_examples: ", Dumper($makefile_examples_prereq);

  if (my $makefile_test = $optional_features->{'maximum_tests'}) {
    $makefile_test_optional &&= $makefile_test->{'requires'};
  }
  print "Makefile.PL maximum_tests: ", Dumper($makefile_test_optional);
}

my %used_module;
my %optional_module;
my %test_used_module;
my %test_optional_module;
my %devel_used_module;
my %examples_used_module;

foreach my $file (@main_files) {
  dependencies_from_file ($file, \%used_module, \%optional_module);
}
delete_own_modules (\%used_module);

foreach my $file (@test_files) {
  dependencies_from_file ($file, \%test_used_module, \%test_optional_module);
}
delete_own_modules (\%test_used_module);
while (my ($package, $version) = each %test_used_module) {
  $used_module{$package} = version_max ($used_module{$package}, $version);
}

foreach my $file (@examples_files) {
  dependencies_from_file ($file, \%examples_used_module);
}
delete_own_modules (\%examples_used_module);

foreach my $file (@devel_files) {
  dependencies_from_file ($file, \%devel_used_module);
}
delete_own_modules (\%devel_used_module);

drop_core (\%used_module);
drop_core (\%optional_module);
drop_core (\%test_used_module);
drop_core (\%test_optional_module);
drop_core (\%examples_used_module);
drop_core (\%devel_used_module);

sub drop_core {
  my ($usedref) = @_;
  delete $usedref->{'MyTestHelpers'};
  foreach my $module (sort keys %$usedref) {
    my $module_version = $usedref->{$module};

    my $perlver = Module::CoreList->first_release ($module, $module_version);
    if (defined $perlver) {
      if ($perlver <= $minimum_perl_version) {
        print "$module $module_version   drop builtin since $perlver\n";
        delete $usedref->{$module};
        next;
      }
      print "$module $module_version   since perl $perlver\n";

    } else {
      print "$module  ($usedref->{$module})\n";
    }
  }
}

sub version_max {
  return List::Util::reduce { ! defined $a ? $b
                              : ! defined $b ? $a
                              : $a >= $b ? $a : $b } @_;
}
sub version_min {
  return List::Util::reduce { ! defined $a ? $b
                              : ! defined $b ? $a
                              : $a <= $b ? $a : $b } @_;
}

print "main used: ",     join (', ', keys %used_module), "\n";
print "test optional: ", join (', ', keys %test_optional_module), "\n";
print "examples used: ", join (', ', keys %examples_used_module), "\n";
print "devel used: ",    join (', ', keys %devel_used_module), "\n";

used_vs_makefile ('main',     \%used_module, $makefile_prereq);
used_vs_makefile ('tests',    \%test_optional_module, $makefile_test_optional);
used_vs_makefile ('examples', \%examples_used_module, $makefile_examples_prereq);
# used_vs_makefile ('devel',    \%devel_used_module, $makefile_devel_prereq);

sub used_vs_makefile {
  my ($name, $usedref, $prereq) = @_;
  $prereq || return;
  my $ok = 1;

  foreach my $module (sort keys %$usedref) {
    my $module_version = $usedref->{$module};
    if (! (exists $makefile_prereq->{$module}
           || exists $prereq->{$module})) {
      print "$name: not in Makefile.PL $name: $module $module_version\n";
      $ok = 0;
    } else {
      my $prereq_version = $makefile_prereq->{$module} || $prereq->{$module}
        || version->new(0);
      if ($prereq_version < $module_version) {
        print "$name: $module Makefile.PL only $prereq_version but require $module_version\n";
        $ok = 0;
      }
    }
  }
  foreach my $module (sort keys %$prereq) {
    if (! exists $usedref->{$module}) {
      print "$name: extra in Makefile.PL $name: $module\n";
      $ok = 0;
    }
  }
  if ($ok) {
    print "$name: ok\n";
  }
}

exit 0;

#------------------------------------------------------------------------------
package MyModuleDepends;
use Devel::StackTrace;
use base 'Module::Depends::Intrusive';

sub requires {
  my $self = shift;
  if (@_) {
    # store
    my $trace = Devel::StackTrace->new;
    my $frame = $trace->frame(2)
      || die "oops, no frame(2):\n$trace";
    my %writeargs = $frame->args;
    $self->{'extra_meta'} = $writeargs{'EXTRA_META'};
  }
  return $self->SUPER::requires (@_);
}
