#!/usr/bin/perl

=head1 NAME

Build.PL - Build script generator for AI::Perceptron

=head1 SYNOPSIS

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

=cut

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name        => 'AI::Perceptron',
   dist_version_from  => 'lib/AI/Perceptron.pm',
   create_makefile_pl => 'passthrough',
   create_readme      => 1,
   license            => 'perl',
   build_requires     => {
			  'Test::More'    => '0.01',
			  'Module::Build' => '0.20',
		         },
   requires           => {
			  'accessors'     => '0.01',
		         },
  );

$build->create_build_script;


__END__

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=cut

