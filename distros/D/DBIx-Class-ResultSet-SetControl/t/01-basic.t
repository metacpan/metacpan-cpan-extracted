use Test::Most;
use Test::DBIx::Class 
  -schema_class => 'Test::DBIx::Class::Example::Schema',
  -resultsets => [qw/Person/];
 
ok my $schema = Schema();
isa_ok $schema, 'Test::DBIx::Class::Example::Schema'
  => 'Got Correct Schema';

# Dynamically add the component
ok ref($schema->resultset('Person'))
  ->load_components('ResultSet::SetControl');

fixtures_ok sub {
    my $schema = shift @_;
    my $person_rs = $schema->resultset('Person');
    my ($john, $vincent, $vanessa) = $person_rs->populate([
        ['person_id','name', 'age', 'email'],
        [1,'John', 40, 'john@nowehere.com'],
        [2, 'Vincent', 15, 'vincent@home.com'],
        [3, 'Vanessa', 35, 'vanessa@school.com'],
        [4, 'Joe', 25, 'joe@school.com'],
        [5, 'James', 55, 'james@school.com'],

    ]);
}, 'Installed fixtures';

{
    my @expected = (
      { id=>1, count=>1, index=>0, first=>1, even=>0, odd=>1 },
      { id=>2, count=>2, index=>1, first=>0, even=>1, odd=>0 },
      { id=>3, count=>3, index=>2, first=>0, even=>0, odd=>1 },
      { id=>4, count=>4, index=>3, first=>0, even=>1, odd=>0 },
      { id=>5, count=>5, index=>4, first=>0, even=>0, odd=>1 },
    );

    ok $schema
      ->resultset('Person')
      ->each(sub {
        my ($each, $row) = @_;
        my $expected = shift @expected;

        is $row->id, $expected->{id},
          'Got $row->id of ('.$row->id.') == $expected->{id} of ('.$expected->{id}.')';

        is $each->count, $expected->{count},
          'Got $each->count of ('.$each->count.') == $expected->{count} of ('.$expected->{count}.')';

        is $each->index, $expected->{index},
          'Got $each->index of ('.$each->index.') == $expected->{index} of ('.$expected->{index}.')';

        is $each->is_first, $expected->{first},
          'Got $each->first of ('.$each->is_first.') == $expected->{first} of ('.$expected->{first}.')';

        is $each->is_even, $expected->{even},
          'Got $each->even of ('.$each->is_even.') == $expected->{even} of ('.$expected->{even}.')';

        is $each->is_odd, $expected->{odd},
          'Got $each->odd of ('.$each->is_odd.') == $expected->{odd} of ('.$expected->{odd}.')';

      });
}

{
    my @expected = (
      { id=>2, count=>1, index=>0, first=>1, even=>0, odd=>1 },
      { id=>3, count=>2, index=>1, first=>0, even=>1, odd=>0 },
      { id=>4, count=>3, index=>2, first=>0, even=>0, odd=>1 },
      { id=>5, count=>4, index=>3, first=>0, even=>1, odd=>0 },
    );

    ok $schema
      ->resultset('Person')
      ->each(sub {
        my ($each, $row) = @_;
        my $expected = { id=>1, count=>1, index=>0, first=>1, even=>0, odd=>1 };

        is $row->id, $expected->{id},
          'Got $row->id of ('.$row->id.') == $expected->{id} of ('.$expected->{id}.')';

        is $each->count, $expected->{count},
          'Got $each->count of ('.$each->count.') == $expected->{count} of ('.$expected->{count}.')';

        is $each->index, $expected->{index},
          'Got $each->index of ('.$each->index.') == $expected->{index} of ('.$expected->{index}.')';

        is $each->is_first, $expected->{first},
          'Got $each->first of ('.$each->is_first.') == $expected->{first} of ('.$expected->{first}.')';

        is $each->is_even, $expected->{even},
          'Got $each->even of ('.$each->is_even.') == $expected->{even} of ('.$expected->{even}.')';

        is $each->is_odd, $expected->{odd},
          'Got $each->odd of ('.$each->is_odd.') == $expected->{odd} of ('.$expected->{odd}.')';

        return $each->escape;
      })
      ->each(sub {
        my ($each, $row) = @_;
        my $expected = shift @expected;

        is $row->id, $expected->{id},
          'Got $row->id of ('.$row->id.') == $expected->{id} of ('.$expected->{id}.')';

        is $each->count, $expected->{count},
          'Got $each->count of ('.$each->count.') == $expected->{count} of ('.$expected->{count}.')';

        is $each->index, $expected->{index},
          'Got $each->index of ('.$each->index.') == $expected->{index} of ('.$expected->{index}.')';

        is $each->is_first, $expected->{first},
          'Got $each->first of ('.$each->is_first.') == $expected->{first} of ('.$expected->{first}.')';

        is $each->is_even, $expected->{even},
          'Got $each->even of ('.$each->is_even.') == $expected->{even} of ('.$expected->{even}.')';

        is $each->is_odd, $expected->{odd},
          'Got $each->odd of ('.$each->is_odd.') == $expected->{odd} of ('.$expected->{odd}.')';
      })
      ->each(
        sub {
          fail 'should not see this';
        }, sub {
          pass 'got a proper fail';
        }
      );
}

{
    my @expected = (
      { id=>1, count=>1, index=>0, first=>1, even=>0, odd=>1 },
      { id=>2, count=>2, index=>1, first=>0, even=>1, odd=>0 },
      { id=>3, count=>3, index=>2, first=>0, even=>0, odd=>1 },
      { id=>4, count=>4, index=>3, first=>0, even=>1, odd=>0 },
      { id=>5, count=>5, index=>4, first=>0, even=>0, odd=>1 },
    );

    ok $schema
      ->resultset('Person')
      ->each(sub {
        my ($each, $row) = @_;
        my $expected = shift @expected;

        $each
          ->first(sub {
            ok $expected->{first}, 'Got First as expected';
          })
          ->not_first(sub {
            ok !$expected->{first}, 'Got Not First as expected';
          })
          ->odd(sub {
            ok $expected->{odd}, 'Got Odd as expected';
          })
          ->even(sub {
            ok $expected->{even}, 'Got Even as expected';
          })
          ->if(1, sub { ok 1, 'got one!'})
          ->if(0, undef, sub { ok 1, 'got zero!'})
          ->if
          (
              sub {
                my $each = shift;
                return $each->is_odd;
              },
              sub { ok $expected->{odd}, 'Got Odd as expected' },
              sub { ok $expected->{even}, 'Got Even as expected' },
          );
      });
}

{
  my @expected = (
    { id=>1, count=>1, index=>0, first=>1, even=>0, odd=>1 },
    { id=>2, count=>2, index=>1, first=>0, even=>1, odd=>0 },
    { id=>3, count=>3, index=>2, first=>0, even=>0, odd=>1 },
    { id=>4, count=>4, index=>3, first=>0, even=>1, odd=>0 },
    { id=>5, count=>5, index=>4, first=>0, even=>0, odd=>1 },
  );

  my $cb = sub {
    my ($each, $row) = @_;
    my $expected = shift @expected;

    is $row->id, $expected->{id},
      'Got $row->id of ('.$row->id.') == $expected->{id} of ('.$expected->{id}.')';

    is $each->count, $expected->{count},
      'Got $each->count of ('.$each->count.') == $expected->{count} of ('.$expected->{count}.')';

    is $each->index, $expected->{index},
      'Got $each->index of ('.$each->index.') == $expected->{index} of ('.$expected->{index}.')';

    is $each->is_first, $expected->{first},
      'Got $each->first of ('.$each->is_first.') == $expected->{first} of ('.$expected->{first}.')';

    is $each->is_even, $expected->{even},
      'Got $each->even of ('.$each->is_even.') == $expected->{even} of ('.$expected->{even}.')';

    is $each->is_odd, $expected->{odd},
      'Got $each->odd of ('.$each->is_odd.') == $expected->{odd} of ('.$expected->{odd}.')';
  };

  ok $schema
    ->resultset('Person')
    ->each(
      [ $cb, $cb ],
      sub {
        fail 'should not see this';
      },
    );
}

{
  my @expected = (
    { id=>1, count=>1, index=>0, first=>1, even=>0, odd=>1 },
    { id=>2, count=>2, index=>1, first=>0, even=>1, odd=>0 },
    { id=>3, count=>3, index=>2, first=>0, even=>0, odd=>1 },
    { id=>4, count=>4, index=>3, first=>0, even=>1, odd=>0 },
    { id=>5, count=>5, index=>4, first=>0, even=>0, odd=>1 },
  );

  my ($saw_cb1_cnt, $saw_cb2_cnt) = (0,0);

  my $cb1 = sub {
    my ($each, $row) = @_;
    my $expected = shift @expected;

    is $row->id, $expected->{id},
      'Got $row->id of ('.$row->id.') == $expected->{id} of ('.$expected->{id}.')';

    ok $each->is_odd, 'cb1 is getting the odds';

    $saw_cb1_cnt++;
  };

  my $cb2 = sub {
    my ($each, $row) = @_;
    my $expected = shift @expected;

    is $row->id, $expected->{id},
      'Got $row->id of ('.$row->id.') == $expected->{id} of ('.$expected->{id}.')';

    ok $each->is_even, 'cb2 is getting the evens';

    $saw_cb2_cnt++;
  };

  ok $schema
    ->resultset('Person')
    ->each(
      [ $cb1, $cb2 ],
      sub {
        fail 'should not see this';
      },
    )->each(
      [ $cb1, $cb2 ],
      sub {
        pass 'should see this';
      },
    );

  is $saw_cb1_cnt, 3, 'saw first callback correct number of times';
  is $saw_cb2_cnt, 2, 'saw second callback correct number of times';

}

ok $schema
  ->resultset('Person')
  ->once(sub { is shift->id, 1, 'Once got the row expected' })
  ->once(sub { is shift->id, 2, 'Once got the row expected' });

ok $schema
  ->resultset('Person')
  ->tap(sub {
    my ($func, $rs, $arg) = @_;
    is $rs->first->id, $arg, 'Did!';
  },1);

ok $schema
  ->resultset('Person')
  ->times(3, sub {
    my ($func, $rs, $arg) = @_;
    is $rs->first->id, $arg, "Did for $arg";
  },1);

done_testing(147);
