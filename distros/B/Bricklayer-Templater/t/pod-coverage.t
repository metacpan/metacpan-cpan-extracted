#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan tests => 4 unless $@;

pod_coverage_ok('Bricklayer::Templater');
pod_coverage_ok('Bricklayer::Templater::Handler');
pod_coverage_ok('Bricklayer::Templater::Parser');
pod_coverage_ok('Bricklayer::Templater::Sequencer');
