package My::Test::Utils;
our $VERSION = '0.002';

use strict;
use warnings;
use SQL::Translator::Schema::Constants;
use SQL::Translator::Schema;

sub test_table {
  my $schema = SQL::Translator::Schema->new(
    name     => 'Foo',
    database => 'SQLite',
  );
  my $table = $schema->add_table(name => 'mini_me');

  for my $col (qw( a b c d e f g )) {
    $table->add_field(name => $col, data_type => 'integer');
  }

  $table->primary_key([qw(a b c)]);

  $table->add_constraint(
    name   => 'un',
    type   => UNIQUE,
    fields => [qw(d)],
  );

  $table->add_index(
    name   => 'ix',
    fields => [qw(e f)],
  );

  return $table;
}

1;
