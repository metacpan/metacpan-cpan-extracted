use strict;
use warnings;

use Test::More;
use DBI;

my $class = "DBIx::Class::Storage::DBI::MariaDB";
use_ok $class;

my @untyped = qw/
  int
  text
  mediumtext
  json
  /;
my @typed = qw/
  blob
  tinyblob
  mediumblob
  longblob
  /;

for my $s ( map { $_ => uc($_) } @untyped ) {
    is( scalar( $class->bind_attribute_by_data_type($s) ), undef,
        "No type for $s" );
}

for my $s ( map { $_ => uc($_) } @typed ) {
    is( $class->bind_attribute_by_data_type($s),
        DBI::SQL_BINARY, "Type for $s" );
}

done_testing();
