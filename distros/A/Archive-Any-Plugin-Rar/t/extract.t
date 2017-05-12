#!/usr/bin/perl -w

use Test::More 'no_plan';
use lib::abs;

my %tests = (
    'test.rar' => [qw{
        README
    }],
);

use_ok ( 'Archive::Any::Plugin::Rar' );
chdir(lib::abs::path('data'));

while( my($file, $expect) = each %tests ) {

    my @files = Archive::Any::Plugin::Rar->files($file);
    ok( eq_set(\@files, $expect), 'right list of files');
    is( Archive::Any::Plugin::Rar->extract($file), 0, 'no errors by extracting' );
    foreach my $file (@files) {
        ok( -e $file, "  $file" );
        unlink $file;
    }

}
