# vi:sw=2
use strictures 2;

use Test::More;
use Test::Deep;

use lib 't/lib';

BEGIN {
  use loader qw(build_schema);
  build_schema();
}

use common qw(Schema);

use_ok 'DBIx::Class::Sims';
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
);

foreach my $test ( @tests ) {
  cmp_deeply( $sub->( Schema, $test->{start} ), $test->{expected} );
}

done_testing;
