# t/03-subclass.t
#
# vim: syntax=perl

use Test::More tests => 2;

my $ver1 = '7dd8415a7e1cd131fba134c1da4c603ecf4974e2';
my $ver2 = 'a573e9bbcaeed0be9329b25e2831a930f5b656ca';
my $ver3 = '3b5047486706e55528a2684daef195bb4f9d0923';

my $gittestdir = 't/01-initdb.git';

package MyConfig;
use Moose;

extends 'Config::Versioned';

package main;

if ( not -d $gittestdir ) {
    die "Test repo not found - did you run 01-initdb.t already?";
}

my $cfg = MyConfig->new( { dbpath => $gittestdir } );
ok( $cfg, 'created MyConfig instance' );
is( $cfg->version, $ver3, 'check version of HEAD' );
