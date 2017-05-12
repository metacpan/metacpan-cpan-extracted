# t/02-readonly.t
#
# vim: syntax=perl

use Test::More tests => 3;

use strict;
use warnings;

BEGIN {
    use vars qw( $gittestdir );
    $gittestdir = 't/02-no-db.git';
    use Path::Class;
    use DateTime;
    dir($gittestdir)->rmtree;
}


my $ver1 = '7dd8415a7e1cd131fba134c1da4c603ecf4974e2';
my $ver2 = 'a573e9bbcaeed0be9329b25e2831a930f5b656ca';
my $ver3 = '3b5047486706e55528a2684daef195bb4f9d0923';

use_ok( 'Config::Versioned' );


my $cfg;
eval ' $cfg = Config::Versioned->new( {dbpath => $gittestdir }); 1;';
ok( !-d $gittestdir, "should not autocreate repo dir");
ok(  !defined($cfg), 'should not create an object instance' ) || 
    diag("cfg=$cfg");
