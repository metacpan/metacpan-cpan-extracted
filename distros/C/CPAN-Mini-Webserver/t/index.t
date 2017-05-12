#!perl
use strict;
use warnings;

use Test::InDistDir;
use Test::More;
use CPAN::Mini::Webserver::Index;

plan tests => 1;

my $index = CPAN::Mini::Webserver::Index->new;
$index->_index_items_with( sub{ $_[1], uc $_[1] }, "test" );
is_deeply [ $index->search_word( "test" ) ], [ "test" ], "items are not added in duplicate";
