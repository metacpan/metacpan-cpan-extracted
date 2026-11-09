use strict;
use warnings;

use Test::More;
use mro ();

use DBIO::PostgreSQL::Storage;

# The storage declares its method resolution order, as every storage class of
# core does (karr k121). Only the MRO is declared: the inheritance list is the
# one it was, so the layering and the lazy driver resolution are untouched.

my $class = 'DBIO::PostgreSQL::Storage';

is mro::get_mro($class), 'c3', 'the storage declares the c3 MRO';

{
  no strict 'refs';
  is_deeply [ @{"${class}::ISA"} ], ['DBIO::Storage::DBI'],
    'the inheritance list is DBIO::Storage::DBI alone';
}

my @linear = @{ mro::get_linear_isa($class) };
is $linear[0], $class, 'the class is first in its own linearisation';

my %pos = map { $linear[$_] => $_ } 0 .. $#linear;
ok exists $pos{'DBIO::Storage::DBI'} && exists $pos{'DBIO::Storage'},
  'DBIO::Storage::DBI and DBIO::Storage are in the linearisation';
ok $pos{$class} < $pos{'DBIO::Storage::DBI'}
  && $pos{'DBIO::Storage::DBI'} < $pos{'DBIO::Storage'},
  'descendants come before their ancestors';

done_testing;
