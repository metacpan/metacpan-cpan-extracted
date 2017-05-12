#!/usr/bin/perl

# Build.PL
#  Script to build and install this distribution
#
# $Id$

use strict;
use warnings;

use lib 'inc';
use My::Builder;

use Env '@PATH';

my $builder = My::Builder->new(
  module_name           => 'Alien::Libjio',
  license               => 'unrestricted',
  dist_author           => 'Jonathan Yu <jawnsy@cpan.org>',
  dist_version_from     => 'lib/Alien/Libjio.pm',
  dynamic_config        => 1,

  # Prerequisites generated from dist.ini by ModuleBuild::Custom
  'build_requires' => {
    'ExtUtils::CBuilder' => '0',
    'ExtUtils::ParseXS' => '0',
    'Module::Build' => '0.2808_01',
    'Test::More' => '0.62',
    'Test::NoWarnings' => '0.084'
  },
  'configure_requires' => {
    'Module::Build' => '0.2808_01'
  },
  'requires' => {
    'perl' => '5.006'
  },

  add_to_cleanup => [ 'Alien-Libjio-*' ],
);

# Use Alien::Libjio to see if it's already installed
use lib 'lib';
use Alien::Libjio;

my $jio = Alien::Libjio->new();

unless ($jio->installed) {
  # Ask the user if they'd like to install this; if not, then exit
  $builder->y_n('libjio was not found on your system. Install it now?', 'y')
    or exit;

  $builder->notes(build_libjio => 1);

  # Ask the user what 'make' program to invoke
  my $make;
  if (exists($ENV{MAKE}) && length($ENV{MAKE})) {
    $make = $ENV{MAKE};
  }
  else {
    use Config '%Config';
    $make = $Config{make};

    # Probe for GNU Make (useful on BSD/Unix variants)
    if ($make eq 'make' && grep { -x $_ . '/gmake' } @PATH) {
      $make = 'gmake';
      warn 'your system is a BSD variant but gmake was not found'
        if ($^O =~ /bsd$/);
    }
  }
  $make = $builder->prompt('What is your system "make" command?', $make);

  $builder->notes(make => $make);

  # Figure out if we should do a full install
  my $extra = $builder->y_n('libjio includes other files including Python ' .
    'bindings. Install them too?', 'n');
  $builder->notes(extra => $extra);
}

$builder->create_build_script();
