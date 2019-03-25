#!/usr/bin/env perl

use strict;
use v5.20;
use warnings;

use Module::Build;

my $builder = Module::Build->new(

  add_to_cleanup => ['App-ppll-*'],

  configure_requires => {

    'Module::Build' => '0',

  },

  create_readme => 1,

  dist_author => 'Theo -q Willows <theo@willows.se>',

  dist_version_from => 'lib/App/ppll.pm',

  license => 'perl',

  meta_merge => {

    resources => {

      bugtracker => {
        web => 'https://gitlab.com/munkei-software/ppll/issues',
      },

      homepage => 'https://gitlab.com/munkei-software/ppll',

      repository => {
        type => 'git',
        url  => 'git@gitlab.com:munkei-software/ppll.git',
        web  => 'https://gitlab.com/munkei-software/ppll',
      },

    },

  },

  module_name => 'App::ppll',

  recursive_test_files => 1,

  release_status => 'stable',

  requires => {

    'DateTime'           => 1.50,
    'IPC::Run'           => '20180523.0',
    'List::Flatten'      => 0.01,
    'Readonly'           => 2.05,
    'String::ShellQuote' => 1.04,
    'Sys::CPU'           => 0,
    'Term::ReadKey'      => 2.38,
    'Time::Duration'     => 1.20,
    'perl'               => 'v5.20',
    'utf8::all'          => 0.024,

  },

  test_requires => {

    'Test::DescribeMe' => 0,
    'Test::Most'       => 0,
    'Test::Output'     => 1.031,

    $ENV{AUTHOR_TESTING}
    ? (

      'Task::Perl::Critic'   => 0,
      'Test::CPAN::Changes'  => 0,
      'Test::CPAN::Meta'     => 0,
      'Test::MinimumVersion' => 0,
      'Test::Perl::Critic'   => 0,
      'Test::Pod'            => 0,
      'Test::Pod::Coverage'  => 0,

      )
    : (),

  },

);

$builder->create_build_script();
