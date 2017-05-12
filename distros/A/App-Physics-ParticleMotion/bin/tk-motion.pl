#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';
use lib '../lib';
use App::Physics::ParticleMotion;

if ( not @ARGV == 1 ) {
	die "Usage: $0 CONFIGURATION_FILE\nDocumentation availlable via 'perldoc App::Physics::ParticleMotion'.\n";
}
elsif ( $ARGV[0] =~ /^--?h(?:elp)?$/ ) {
	exec('perldoc App::Physics::ParticleMotion');
}

my $app = App::Physics::ParticleMotion->new();
$app->config(shift);
$app->run();

