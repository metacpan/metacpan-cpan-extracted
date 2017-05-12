# vi:sw=2
package # Hide from PAUSE
  t::common;

use strictures 2;

use base 'Exporter';
our @EXPORT_OK = qw(
  test_dateish runner
);

use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Test::Trap;

use Test::DBIx::Class;

{
  my $runner = DBIx::Class::Sims::Runner->new(
    schema       => Schema,
    parent       => undef,
    toposort     => undef,
    initial_spec => undef,
    spec         => undef,
    hooks        => undef,
    reqs         => undef,
  );

  sub runner { $runner }
}

sub test_dateish {
  my ($name, $parser, $type, $addl) = @_;

  my $num_to_run = $ENV{HARNESS_IS_VERBOSE} ? 1 : 1000;

  subtest $type => sub {
    my $sub = DBIx::Class::Sims->sim_type($type);
    ok($sub, "Found the handler for $type") || return;

    my $runner = runner();
    foreach my $i ( 1 .. $num_to_run ) {
      my $value = $sub->({}, { type => $type }, $runner);

      my $dt = eval { $runner->datetime_parser->$parser($value); };
      if ($@) {
        ok(0, "'$value' is NOT a legal $name: $@");
        # Don't run $addl->() because $dt isn't legal, so other tests won't pass.
      }
      else {
        ok(1, "'$value' is a legal $name");
        $addl->($value, $dt);
      }
    }
  };
}

1;
