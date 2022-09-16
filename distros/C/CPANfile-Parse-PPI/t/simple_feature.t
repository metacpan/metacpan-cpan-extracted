#!/usr/bin/perl

use strict;
use warnings;

use CPANfile::Parse::PPI;
use Test::More;

ok 1;

my $required = <<'CPANFILE';
on build => sub {
    requires "Test2" => 2.311;
};
feature sqlite, "SQLite Support" => sub {
    requires "DBD::SQlite",
}
CPANFILE

my $cpanfile = CPANfile::Parse::PPI->new( \$required );

my $modules = $cpanfile->modules;
is_deeply $modules,
  [
    {
        name    => "Test2",
        stage   => "build",
        type    => "requires",
        feature => "",
        version => '2.311'
    },
    {
        name    => "DBD::SQlite",
        stage   => "",
        type    => "requires",
        feature => "sqlite",
        version => ''
    },
  ];

done_testing();
