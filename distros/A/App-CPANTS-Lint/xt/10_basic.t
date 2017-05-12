use strict;
use warnings;
use FindBin;
use File::Path;
use Test::More;
use App::CPANTS::Lint;

eval {
  require WorePAN;
  WorePAN->import("0.09");
  1;
} or plan skip_all => "requires WorePAN 0.09 to test";

my @dists = (
  # should pass as of Module::CPANTS::Analyse 0.92
  'NEILB/Exporter-Lite-0.05.tar.gz',

  # should fail
  'ISHIGAKI/Acme-CPANAuthors-0.23.tar.gz',
);

my $testdir = "$FindBin::Bin/worepan";
mkpath $testdir unless -d $testdir;

for my $experimental (0..1) {
  my $app = App::CPANTS::Lint->new(experimental => $experimental);

  for my $dist (@dists) {
    test($app, $dist);
  }
}

rmtree $testdir if -d $testdir;

done_testing;

sub test {
  my ($app, $dist) = @_;
  my $worepan = WorePAN->new(
    root => $testdir,
    files => [$dist],
    use_backpan => 1,
    no_network => 0,
    cleanup => 1,
    no_indices => 1,
    verbose => 0,
  );
  my $file = $worepan->file($dist);
  ok -f $file;

  my $got = $app->lint($file);
  if ($got) {
    diag "Lint ok: $dist";
    like $app->report => qr/Congratulations/;
    note $app->report;
  } else {
    diag "Lint fail: $dist";
    like $app->report => qr/Failed (?:core|extra) Kwalitee metrics/;
    note $app->report;
  }
}
