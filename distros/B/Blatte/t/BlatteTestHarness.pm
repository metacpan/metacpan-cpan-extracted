use Blatte qw(Parse flatten unwrapws);

use Test;

sub blatte_test {
  my $num = @_;
  &plan(tests => $num);
  my $fail = 0;
  foreach my $test (@_) {
    my($expected, @test) = @$test;
    my $result;
    while (@test) {
      my $parsed = &Parse(shift @test);
      print STDERR "$parsed\n\n" if $ENV{TEST_VERBOSE};

      {
        package BlatteTest;

        use Blatte::Builtins;

        $result = eval $parsed;
      }

      $result = &flatten($result, '');
    }

    ++$fail unless &ok($result, $expected);
  }
}

1;
