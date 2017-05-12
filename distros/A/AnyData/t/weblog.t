#!/usr/local/bin/perl -wT
use strict;
use warnings;

use Test::More;
plan tests => 10;

use AnyData;

my $table = adTie( 'Weblog', 't/weblog.tbl', 'r', {} );

ok( 1 == adRows($table), "Failed rows" );

#remotehost,username,authuser,date,request,status,bytes,client,referer
#12.34.56.78 - - [13/Mar/2008:07:38:53 +0100] "GET /creeper/image HTTP/1.1" 200 252 "http://www.example.com/" "Mozilla/5.0 (Windows; U; Windows NT 6.0; sv-SE; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12"

my $row = each %$table;
ok( '12.34.56.78'                 eq $row->{remotehost}, 'remotehost' );
ok( '-'                           eq $row->{username},   'username' );
ok( '-'                           eq $row->{authuser},   'authuser' );
ok( '13/Mar/2008:07:38:53 +0100'  eq $row->{date},       'date' );
ok( 'GET /creeper/image HTTP/1.1' eq $row->{request},    'request' );
ok( '200'                         eq $row->{status},     'status' );
ok( '252'                         eq $row->{bytes},      'bytes' );
ok(
'"Mozilla/5.0 (Windows; U; Windows NT 6.0; sv-SE; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12"'
      eq $row->{client},
    'client ' . $row->{client}
);
ok( '"http://www.example.com/"' eq $row->{referer},
    'referer: ' . $row->{referer} );

#write test
#TODO: looks like writing a weblog is broken
#print STDERR "\n---\n";
#print STDERR adExport( $table, 'Weblog', undef, {  } );
#print STDERR "\n---\n";
#ok(
#    <<'HERE' eq adExport( $table, 'Weblog', undef, {  } ), 'export weblog format' );
#HERE

__END__
