#!/usr/bin/perl -w

use Test::More 'no_plan';
use lib::abs;

my @tests = (
    'test.rar',
);

use_ok ( 'Archive::Any' );
use_ok ( 'Archive::Any::Plugin::Rar' );
chdir(lib::abs::path('data'));

for my $file (@tests) {

    my $arc = Archive::Any->new($file, 'rar');
    ok defined $arc, 'explicit type ok';

}
