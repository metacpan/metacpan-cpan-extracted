# t/06-cfgver.t
#
# vim: syntax=perl

use Test::More tests => 2;

use strict;
use warnings;

my $cfgver     = 'bin/cfgver';
my $gittestdir = qw( t/01-initdb.git );
my $ver1 = '7dd8415a7e1cd131fba134c1da4c603ecf4974e2';
my $ver2 = 'a573e9bbcaeed0be9329b25e2831a930f5b656ca';
my $ver3 = '3b5047486706e55528a2684daef195bb4f9d0923';

if ( not -d $gittestdir ) {
    die "Test repo not found - did you run 01-initdb.t already?";
}

my $result = `$^X $cfgver --dbpath $gittestdir`;
chomp $result;
is( $result, $ver3, 'show current version' );

my $result1 = `$^X $cfgver --dbpath $gittestdir --version $ver1`;
chomp $result1;
is( $result1, $ver1, 'show initial version' );

