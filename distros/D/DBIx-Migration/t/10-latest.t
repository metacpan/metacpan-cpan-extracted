use strict;
use warnings;

use Test::More import => [ qw( is ) ], tests => 2;
use Test::Fatal qw( dies_ok );

use Path::Tiny qw( cwd );

require DBIx::Migration;

is +DBIx::Migration->latest( cwd->child( qw( t sql advanced ) )->stringify ), 3,
  'latest() class method call with string "dir"';

dies_ok { DBIx::Migration->latest( cwd->child( qw( t sql invalid ) ) ) }
'latest() throws an exception because "dir" does not contain any valid migrations';
