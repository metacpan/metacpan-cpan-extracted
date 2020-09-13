# vi:sw=2
package # Hide from PAUSE
  types;

use strictures 2;

use base 'Exporter';
our @EXPORT_OK = qw(
  types_test
);

use DDP;
use Test2::V0 qw(
  subtest like cmp_ok
);
#  E item object array bag hash subtest skip_all number is match call field
#  end

use DBIx::Class::Sims::Runner;
use DBIx::Class::Sims::Types;

sub types_test ($$) {
  my ($name, $opts) = @_;
  $opts->{type} //= $name;

  my $sub = DBIx::Class::Sims::Types->can($opts->{type});

  subtest $name => sub {
    my $spec = {};

    my $iters = 100;
    my $tries = 10;

    foreach my $test ( @{$opts->{tests}} ) {
      # q.v. the comment in DBIx::Class::Sims::Column where ::Random is imported
      # for why this test helper creates a fake $column object.
      my $column = bless {
        predictable_values => 0
      }, 'DBIx::Class::Sims::Column';

      $test->[0]{sim} = { type => $opts->{type} };

      for (1 .. $iters) {
        my $v = $sub->($test->[0], $spec, $column);
        next unless like( $v, $test->[1] );
        $spec->{addl_check}->($v) if exists $spec->{addl_check};
      }

      next unless $test->[2];

      my $successes = 0;
      for ( 1.. $tries ) {
        my $v = $sub->($test->[0], $spec, $column);
        $successes += 1 if $v eq $test->[2];
      }
      cmp_ok( $successes, '<', $tries, "if predictable_values is not set, don't get the same value" );

      $column->{predictable_values} = 1;
      for ( 1 .. $tries ) {
        cmp_ok(
          $sub->($test->[0], $spec, $column), 'eq', $test->[2],
          "Test $_ for predictable_values",
        );
      }
    }
  };
}

1;
