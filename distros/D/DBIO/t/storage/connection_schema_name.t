# ABSTRACT: names that reach a driver as identifiers are refused in core when no driver could take them (ADR 0077, karr k391)
use strict;
use warnings;

use Test::More;

use DBIO::Storage::DBI;
use DBIO::Exception;

# CLAIM: the connect key 'schema' is an identifier. A name with ';', a line
# break or NUL is refused in core, with a DBIO::Exception that names the key and
# never the value. Every other name, however odd (quote, blank, backslash), is
# the driver's to quote or to refuse.

my @conn = ('dbi:Karr391:db=t', 'user', 'pass');

{
  package Karr391::Driver;
  use base 'DBIO::Storage::DBI';
}

my %refused = (
  semicolon => "a;b",
  newline   => "a\nb",
  cr        => "a\rb",
  nul       => "a\0b",
);

for my $label (sort keys %refused) {
  my $storage = Karr391::Driver->new;
  my $err = do { local $@; eval { $storage->connect_info([ @conn, { schema => $refused{$label} } ]); 1 } ? undef : $@ };
  isa_ok $err, 'DBIO::Exception', "schema with $label: the exception";
  like "$err", qr/connect key 'schema'/, "schema with $label: names the key";
  unlike "$err", qr/\Q$refused{$label}\E/, "schema with $label: never quotes the value";
}

my %passes = ('double quote' => 'a"b', blank => 'a b', backslash => 'a\\b');
for my $label (sort keys %passes) {
  my $storage = Karr391::Driver->new;
  eval { $storage->connect_info([ @conn, { schema => $passes{$label} } ]) };
  is $@, '', "schema with $label passes core: quoting is the driver's";
  is $storage->connection_schema, $passes{$label}, '... and is kept as given';
}

done_testing;
