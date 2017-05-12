#!perl -T
BEGIN {
    use lib qw( ./erecipes/perl/lib );
}
use strict;
use warnings;
use Test::More qw(no_plan);
BEGIN {
    use lib qw( ./erecipes/perl/lib );
    $ENV{SITE_ROOT} = './erecipes'
}
use DBI;
our $dbh = DBI->connect(
               'dbi:SQLite:dbname=' . $ENV{SITE_ROOT} . '/data/recipes.sqlite', '', '', 
               { RaiseError => 1 }
           );

use_ok( 'CGI::Ex::Recipes::Cache' );
our $cache;
ok( $cache = CGI::Ex::Recipes::Cache->new({dbh=>$dbh}) );
our $blablakey = 'key';
our $blablavalue = 'value';
ok( $cache->set($blablakey, $blablavalue), 
    'Set a cache entry.         key:' . $blablakey . ' value:' . $blablavalue );
our $v;
ok( $v = $cache->get($blablakey) , 
    'Get the set cache entry.   key:' . $blablakey . ' value:' .$v  );

ok( $cache->{cache_hash}{$blablakey}{value}, 'entry:' . $blablakey . ' is in $cache->{cache_hash} too. ');
ok( $cache->clear(),                        'Clear all cache.' );
is( $cache->get($blablakey), undef,          $blablakey.' value is undef now.');

TODO:{
    local $TODO = "freeze() and thaw() are not used yet.";
    my $struct = {something=>'else', is=>'reference'};
    ok( $cache->freeze($blablakey,$struct), '$struct freezed!!!' );
    my $thawed;
    ok( $thawed = $cache->thaw($blablakey), '$struct thawed!!!' );
    is_deeply( $thawed, $struct, '$thawed is the same as original $struct.' );
}






