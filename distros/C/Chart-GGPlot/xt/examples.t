#!perl

use FindBin;
use Path::Tiny;
use Capture::Tiny qw(:all);
use Chart::Kaleido::Plotly;

use Test2::V0;

eval { Chart::Kaleido::Plotly::kaleido_available(); };
plan skip_all("needs kaleido to run") if $@;

my $script = "$FindBin::RealBin/../utils/run_all_examples.pl";

my $tempdir = Path::Tiny->tempdir;

my @cmd = ( $^X, $script, "--save-to-dir=$tempdir" );
my ( $out, $err, $exit ) = tee { system(@cmd) };

ok( $exit == 0, "run_all_examples.pl has no errors" );
#ok( length($err) == 0, 'no warnings emitted' );

done_testing;
