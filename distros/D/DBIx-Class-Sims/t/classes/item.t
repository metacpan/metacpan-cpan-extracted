# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing ok ); #subtest match is bag item );
use Test::Trap; # Needed for trap()

my $item = DBIx::Class::Sims::Item->new(
  runner => undef,
  source => undef,
  spec   => {},
);

package Source {
  sub new { my $c = shift; bless {@_}, $c }
  sub name { shift->{name} }
  sub columns { @{ shift->{columns} } }
  sub relationships { @{ shift->{relationships} } }
}

package Column {
  sub new { my $c = shift; bless {@_}, $c }
  sub name { shift->{name} }
}
sub column { my $n = shift; Column->new(name => $n) }

package Relationship {
  sub new { my $c = shift; bless {@_}, $c }
  sub name { shift->{name} }
  sub self_fk_col { shift->{self_fk_col} }
  sub foreign_fk_col { shift->{foreign_fk_col} }
}
sub relationship {
  my ($name, $me, $you) = @_;
  return Relationship->new(
    name => $name,
    self_fk_col => $me,
    foreign_fk_col => $you,
  );
}

=pod
subtest create_search => sub {
  subtest 'base case' => sub {
    my $source = Source->new(
      name => 'Foo',
      columns => [],
      relationships => [],
    );
    my ($cond, $extra) = $item->create_search($source, {});
    is( $cond, {}, 'Cond is expected' );
    is( $extra, {}, 'Extra is expected' );
  };

  subtest 'simple case (one column)' => sub {
    my $source = Source->new(
      name => 'Foo',
      columns => [ column('a') ],
      relationships => [],
    );
    my ($cond, $extra) = $item->create_search($source, { a => 1 });
    is( $cond, { 'me.a' => 1 }, 'Cond is expected' );
    is( $extra, {}, 'Extra is expected' );
  };

  subtest 'simple case (two columns)' => sub {
    my $source = Source->new(
      name => 'Foo',
      columns => [ column('a'), column('b') ],
      relationships => [],
    );
    my ($cond, $extra) = $item->create_search($source, { a => 1, b => 2 });
    is( $cond, { 'me.a' => 1, 'me.b' => 2 }, 'Cond is expected' );
    is( $extra, {}, 'Extra is expected' );
  };

  subtest 'column missing' => sub {
    my $source = Source->new(
      name => 'Foo',
      columns => [ column('b') ],
      relationships => [],
    );
    trap {
      $item->create_search($source, { a => 1 });
    };
    is $trap->leaveby, 'die', 'died as expected';
    is $trap->die . '', match(qr/Foo has no column or relationship 'a'/), 'Error message as expected';
  };

  subtest 'one simple relationship' => sub {
    my $source = Source->new(
      name => 'Foo',
      columns => [ column('a') ],
      relationships => [ relationship('b', 'b_id', 'id') ],
    );

    my ($cond, $extra) = $item->create_search($source, { b => 1 });
    is( $cond, { 'b.id' => 1 }, 'Cond is expected' );
    is( $extra, { join => bag { item 'b' } }, 'Extra is expected' );
  };

  subtest 'multiple simple relationships' => sub {
    my $source = Source->new(
      name => 'Foo',
      columns => [ column('a') ],
      relationships => [
        relationship('b', 'b_id', 'id'),
        relationship('c', 'c_id', 'id'),
      ],
    );

    my ($cond, $extra) = $item->create_search($source, { b => 1, c => 2 });
    is( $cond, { 'b.id' => 1, 'c.id' => 2 }, 'Cond is expected' );
    is( $extra, { join => bag { item 'b'; item 'c' } }, 'Extra is expected' );
  };

  # Cases:
  #   * { x => { y => 1 } }
  #     $cond->{'y.fk_y'} = 1
  #     join => { 'x' => 'y' }
  #   * { x => { y => 1, z => 1 } }
  #     $cond->{'y.fk_y'} => 1
  #     $cond->{'z.fk_z'} => 1
  #     join => { 'x' => [ 'y', 'z'] }
};
=cut

ok 1;

done_testing;
