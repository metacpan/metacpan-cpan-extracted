$| = 1;
use strict;

use Test::More;
use Class::DBI::Sweet;
Class::DBI::Sweet->default_search_attributes({ use_resultset_cache => 1 });
Class::DBI::Sweet->cache(Cache::MemoryCache->new(
    { namespace => "SweetTest", default_expires_in => 60 } ) ); 


BEGIN {
	eval "use Cache::MemoryCache";
	plan skip_all => "needs Cache::Cache for testing" if $@;
}

eval { require Time::Piece::MySQL };
plan skip_all => "Need Time::Piece::MySQL for this test" if $@;

eval { require 't/cdbi-t/testlib/Log.pm' };
plan skip_all => "Need MySQL for this test" if $@;

plan tests => 2;

package main;

my $log = Log->insert( { message => 'initial message' } );
ok eval { $log->datetime_stamp }, "Have datetime";
diag $@ if $@;

$log->message( 'a revised message' );
$log->update;
ok eval { $log->datetime_stamp }, "Have datetime after update";
diag $@ if $@;

