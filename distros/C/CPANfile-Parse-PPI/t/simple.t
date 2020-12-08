#!/usr/bin/perl

use strict;
use warnings;

use CPANfile::Parse::PPI;
use Test::More;

ok 1;

my $required = <<'CPANFILE';
requires "CPANfile::Parse::PPI" => 3.6;;
on build => sub {
    recommends "Dist::Zilla" => 4.0;
    requires "Test2" => 2.311;
};
CPANFILE

my $cpanfile = CPANfile::Parse::PPI->new( \$required );

my $modules = $cpanfile->modules;
is_deeply $modules, [
     {
         name    => "CPANfile::Parse::PPI",
         stage   => "",
         type    => "requires",
         version => '3.6'
     },
     {
         name    => "Dist::Zilla",
         stage   => "build",
         type    => "recommends",
         version => '4.0'
     },
     {
         name    => "Test2",
         stage   => "build",
         type    => "requires",
         version => '2.311'
     }
];

done_testing();
