# -*- mode: perl; -*-
requires 'perl' => '5.008009';

on configure => sub {
  requires 'Alien::Build'        => '1.41';
  requires 'Alien::Build::MM'    => '1.41';
  requires 'ExtUtils::MakeMaker' => 0;
};

on build => sub {
  requires 'Alien::Build'        => '1.41';
  requires 'Alien::Build::MM'    => '1.41';
  requires 'Alien::gmake'        => 0;
  requires 'ExtUtils::MakeMaker' => 0;
  requires 'HTML::LinkExtor' => 0;
  requires 'IO::Socket::SSL' => 0;
  requires 'Net::SSLeay'     => 0;
  requires 'HTTP::Tiny'      => '0.044';
  requires 'Sort::Versions'  => 0;
  requires 'URI'             => 0;
  requires 'URI::Escape'     => 0;
};

on develop => sub {
  ## faster without App::af
  requires 'App::af' => 0 unless $ENV{CI};
  requires 'Test::Pod' => 0;
  requires 'Test::Pod::Coverage' => 0;
  requires 'Test::CPAN::Changes' => 0;
};

feature release => 'release testing' => sub {
  test_requires 'Test::Kwalitee' => 0;
};

test_requires 'Test::More' => '0.88';
