#!perl
#
# check correctness of versions and so on; developer's stuff
#

use strict;
use warnings;
use Test::More;
use ExtUtils::MakeMaker;

eval "use YAML";
plan skip_all => "YAML required for author tests" if $@;

if ($ENV{RELEASE_TESTING}) {
  plan(tests => 3);
} else {
  plan(skip_all => "Author tests not required for installation");
}

#-----------------------------------------------------------------------------
# auxiliary functions

sub make_version($) {
  my ($string) = @_;

  if (not $string) {
    # default version number
    $string = "0.01";
  }

  $string =~ s/^v|\s+$//g;

  my @ve = split /\./, $string;

  # fill to 3 numbers, with 0s standing for missing ones
  push @ve, 0 for @ve .. 2;

  return join ".", map { sprintf "%03d", $_ } @ve;
}

#-----------------------------------------------------------------------------
# META.yml

my $module_name;
my $meta_version;
do {
  my $meta = YAML::LoadFile("META.yml");
  $module_name  = $meta->{name};
  $meta_version = make_version $meta->{version};
};

#-----------------------------------------------------------------------------
# git tag

my $git_version;
do {
  my @tags = sort map { make_version $_ } grep { /^v(\d+\.)+\d+$/ } `git tag`;

  $git_version = $tags[-1];
};

#-----------------------------------------------------------------------------
# module itself

my $module_version;
do {
  my $module_file = MM->_installed_file_for_module($module_name);
  $module_version = MM->parse_version($module_file);
  $module_version = make_version $module_version;
};

#-----------------------------------------------------------------------------
# Changes

my $changelog_version;
eval {
  open my $f, "<", "Changes" or die "Can't open changelog: $!";
  local $/ = undef;
  my $changelog = <$f>;
  my $date = qr/\w{3} \w{3} [ 0-3][0-9] \d\d:\d\d:\d\d /;
  my @changes = ($changelog =~ /\n\n+((?:\d+\.)+\d+)\s*$date/);
  @changes = sort map { make_version $_ } @changes;
  $changelog_version = $changes[-1];
};
warn $@ if $@;

#-----------------------------------------------------------------------------
# cheap tests

note('"correct" is the version from module itself');
is($meta_version, $module_version, "META.yml version == module version");
is($changelog_version, $module_version, "`Changes' version == module version");

#-----------------------------------------------------------------------------
# difficult test with git tags

if (not defined $git_version) {
  diag("no git tag found");
  fail("git tag == module version");
} elsif ($git_version eq $module_version) {
  pass("git tag == module version");
} else {
  my @git = map { 0 + $_ } split /\./, $git_version;
  my @mod = map { 0 + $_ } split /\./, $module_version;

  if ($git[0] == $mod[0] && $git[1] == $mod[1] && $git[2] + 1 == $mod[2]) {
    diag("git tag off by one patchlevel");
    pass("git tag == module version");
  } elsif ($git[0] == $mod[0] && $git[1] + 1 == $mod[1] && $mod[2] == 0) {
    diag("git tag off by one minor version");
    pass("git tag == module version");
  } else {
    diag("git tag incompatible: ", explain {
      git => $git_version,
      module => $module_version,
    });
    fail("git tag == module version");
  }
}

#-----------------------------------------------------------------------------
# vim:ft=perl:nowrap
