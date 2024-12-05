use Test2::V0 -no_srand => 1;
use 5.020;
use Test::Script qw( script_compiles script_runs );
use Path::Tiny qw( path );
use IO::Socket::INET;
use lib 't/lib';

my $path = path(__FILE__)->parent(2)->child('examples');

foreach my $script (sort { $a->basename cmp $b->basename } $path->children)
{
  next unless $script->basename =~ /\.pl\z/;
  subtest "$script" => sub {
    script_compiles "$script";
    script_runs     "$script", { stdout => \my $out, stderr => \my $err };
    note "[out]\n$out" if $out ne '';
    note "[err]\n$err" if $err ne '';
  };
}

done_testing;

