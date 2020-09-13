# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing is );

use lib 't/lib';

BEGIN {
  use loader qw(build_schema);
  build_schema();
}

use common qw(Schema);

use DBIx::Class::Sims;
my $sub = \&DBIx::Class::Sims::massage_input;

my @tests = (
  {
    start => {},
    expected => {},
  },
  {
    start => { abcd => [] },
    expected => { abcd => [] }
  },
  {
    start => { abcd => [ { a => 'b' } ] },
    expected => { abcd => [ { a => 'b' } ] },
  },
  {
    start => { abcd => [ { 'a.b' => 'c' } ] },
    expected => { abcd => [ { a => { 'b' => 'c' } } ] },
  },
  {
    start => { abcd => [ { 'a.b.c' => 'd' } ] },
    expected => { abcd => [ { a => { 'b' => { 'c' => 'd' } } } ] },
  },
  {
    start => { account => { org => { name => 'Abc' } }, 'account.name' => 'Abc' },
    expected => {
      account => {
        name => 'Abc',
        org => { name => 'Abc' },
      },
    }
  }
);

foreach my $test ( @tests ) {
  is( $sub->( Schema, $test->{start} ), $test->{expected} );
}

done_testing;
