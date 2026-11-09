# ABSTRACT: a user or password not given is '', never DBI_USER / DBI_PASS (karr k392)
use strict;
use warnings;

use Test::More;

use DBIO::Storage::DBI;

# DBI->connect fills an undef user and password from $ENV{DBI_USER} and
# $ENV{DBI_PASS}. No environment variable stands in for a credential of the
# connect info, whatever form it has: the list form, the hash form and the
# answer of a broker are normalised to the empty string.

my $storage = DBIO::Storage::DBI->new;

sub args_of { $storage->_normalize_connect_info($_[0])->{arguments} }

for my $case (
  [ 'list, user only'      => [ 'dbi:Pg:dbname=x', 'bob' ],               [ 'dbi:Pg:dbname=x', 'bob', '' ] ],
  [ 'list, dsn only'       => [ 'dbi:Pg:dbname=x' ],                      [ 'dbi:Pg:dbname=x', '', '' ] ],
  [ 'list, undef user'     => [ 'dbi:Pg:dbname=x', undef, 'pw' ],         [ 'dbi:Pg:dbname=x', '', 'pw' ] ],
  [ 'list, undef password' => [ 'dbi:Pg:dbname=x', 'bob', undef, {} ],    [ 'dbi:Pg:dbname=x', 'bob', '' ] ],
  [ 'hash, user only'      => [ { dsn => 'dbi:Pg:dbname=x', user => 'bob' } ], [ 'dbi:Pg:dbname=x', 'bob', '' ] ],
  [ 'hash, dbname only'    => [ { dbname => 'dbi:Pg:dbname=x' } ],        [ 'dbi:Pg:dbname=x', '', '' ] ],
  [ 'list, given stay'     => [ 'dbi:Pg:dbname=x', 'bob', 'pw' ],         [ 'dbi:Pg:dbname=x', 'bob', 'pw' ] ],
) {
  my ($name, $in, $want) = @$case;
  is_deeply args_of($in), $want, $name;
}

my $maker = sub { };
is_deeply args_of([ $maker ]), [ $maker ], 'a coderef is left alone';

done_testing;
