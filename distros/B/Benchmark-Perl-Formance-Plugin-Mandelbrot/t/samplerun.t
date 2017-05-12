use Test::More;
use Benchmark::Perl::Formance::Plugin::Mandelbrot;

diag "\nSample run. May take some seconds...";
my $result = Benchmark::Perl::Formance::Plugin::Mandelbrot::main
 ({subtests => [],
   verbose  => 1,
   fastmode => 1,
  });

diag "withmce : "    .$result->{withmce}{Benchmark}[0]     if $result->{withmce};
diag "withthreads : ".$result->{withthreads}{Benchmark}[0] if $result->{withthreads};

is($result->{withmce}{goal}, 400, "sample run in fast mode");

done_testing();
