use Test::Most;
use lib 't/lib';
use Sample::Schema;
use My::Fixtures;
use aliased 'DBIx::Class::EasyFixture::Definition';
use DateTime;

my $birthday = DateTime->new(
    year  => 1983,
    month => 2,
    day   => 12,
);

my $schema = Sample::Schema->test_schema;

my $fixtures = My::Fixtures->new( { schema => $schema } );
my @names = $fixtures->all_fixture_names;
foreach my $name (@names) {
    lives_ok {
        Definition->new(
            {   name       => $name,
                definition => $fixtures->get_definition($name),
                fixtures   => { map { $_ => 1 } @names },
            }
        );
    }
    "Definition should be valid for '$name'";
}

my $definition = Definition->new(
    {   name       => 'person_with_customer',
        definition => $fixtures->get_definition('person_with_customer'),
        fixtures   => { map { $_ => 1 } @names },
    }
);
is $definition->name, 'person_with_customer',
  'definitions should return the correct name';
is $definition->resultset_class, 'Person',
  '... and the correct resultset_class';
eq_or_diff $definition->constructor_data,
  { name     => 'sally',
    email    => 'person@customer.com',
    birthday => $birthday,
  },
  '... and the correct data definition';
eq_or_diff $definition->next, [qw/basic_customer/],
  '... and the correct next';
ok !defined $definition->requires,
  '... and no requirements if they are not defined';

subtest 'exceptions' => sub {
    subtest 'definition constructor' => sub {
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => { new => 'Foo', using => { foo_id => sub{} } },
                fixtures   => { bob => 1 },
            );
        }
        qr/Unhandled reference type passed for bob.foo_id/,
          'Having a code reference as a requires should fail';
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => { new => 'Foo', using => { foo_id => [qw(foo bar baz)] } },
                fixtures   => { bob => 1 },
            );
        }
        qr/bob.foo_id malformed: foo bar baz/,
          'Having more than 2 elements in requires should fail';
    };
    subtest 'definition group' => sub {
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => [],
                fixtures   => { bob => 1 },
            );
        }
        qr/Fixture 'bob' defines an empty group/,
          'Having an empty group should fail';
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => [qw(larry damian)],
                fixtures   => { bob => 1 },
            );
        }
        qr/Fixture 'bob'.group had unknown fixtures: damian larry/,
          'Having a group using unknown fixtures should fail';
    };
    subtest 'definition class and data' => sub {
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => { new => 'Foo' },
                fixtures   => { bob => 1 },
            );
        }
        qr/Fixture 'bob' had a 'new' without a 'using'/,
          'Having a definition class without constructor data should fail';
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => { using => { name => 'Foo' } },
                fixtures   => { bob => 1 },
            );
        }
        qr/Fixture 'bob' had a 'using' without a 'new'/,
          'Having constructor data without a class should fail';
    };
    subtest 'definition keys' => sub {
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => {},
                fixtures   => { bob => 1 },
            );
        }
        qr/Fixture 'bob' had no keys/,
          'Having a definition data without keys should fail';
        throws_ok {
            Definition->new(
                name       => "bob",
                definition => { foo => 1, bar => 2 },
                fixtures   => { bob => 1 },
            );
        }
        qr/Fixture 'bob' had unknown keys: bar foo/,
          'Having a definition data with unknown keys should fail';
    };
    subtest 'definition next' => sub {
        my %ignore = ( new => 'Foo', using => { bar => 1 } );
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => { %ignore, next => [undef] },
                fixtures   => { this => 1 },
            );
        }
        qr/Fixture 'this' had an undefined element in 'next'/,
          "Undefined elements in 'next' should fail";
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => { %ignore, next => [ {} ] },
                fixtures   => { this => 1 },
            );
        }
        qr/Fixture 'this' had non-string elements in 'next'/,
          "Non-string elements in 'next' should fail";
    };
    subtest 'definition requires' => sub {
        my %ignore = ( new => 'Foo', using => { bar => 1 } );
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => { %ignore, requires => [] },
                fixtures   => { this => 1 },
            );
        }
        qr/this.Foo.requires does not appear to be a hashref/,
          "requires() must be a hashref";
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => {
                    %ignore,
                    requires => {
                        some_other_fixture => {
                            our   => 'foo_id',
                            their => 'foo_id',
                            extra => 'asdf',
                        },
                    },
                },
                fixtures => { this => 1, some_other_fixture => 1 },
            );
        }
        qr/'this.Foo.requires' had bad keys: extra/,
          "Unknown keys in requires should fail";
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => {
                    %ignore,
                    requires => {
                        some_other_fixture => {
                            their => 'foo_id',
                        },
                    },
                },
                fixtures => { this => 1, some_other_fixture => 1 },
            );
        }
        qr/'this.Foo.requires' requires 'our'/,
          "Missing 'our' in requires should fail";
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => {
                    %ignore,
                    requires => {
                        some_other_fixture => {
                            our => 'foo_id',
                        },
                    },
                },
                fixtures => { this => 1, some_other_fixture => 1 },
            );
        }
        qr/'this.Foo.requires' requires 'their'/,
          "Missing 'their' in requires should fail";
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => {
                    %ignore,
                    requires => { unknown_fixture => 'unknown_fixture_id' },
                },
                fixtures => { this => 1, some_other_fixture => 1 },
            );
        }
        qr/Fixture 'this.Foo.requires' requires a non-existent fixture 'unknown_fixture'/,
          "An unknown fixture in 'requires' should fail";
        throws_ok {
            Definition->new(
                name       => 'this',
                definition => {
                    %ignore,
                    next => [ 'unknown_fixture' ],
                },
                fixtures => { this => 1, some_other_fixture => 1 },
            );
        }
        qr/Fixture 'this' lists a non-existent fixture in 'next': 'unknown_fixture'/,
          "An unknown fixture in 'next' should fail";
    };
};

done_testing;
