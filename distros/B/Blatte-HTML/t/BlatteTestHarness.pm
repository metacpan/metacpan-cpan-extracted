use Blatte qw(Parse traverse unwrapws);
use Blatte::HTML;

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
        use Blatte::HTML;

        $result = eval $parsed;
      }

      my $output;
      &Blatte::HTML::render($result, sub { $output .= shift });
      $result = $output;
    }

    ++$fail unless &ok($result, $expected);
  }
}

1;
