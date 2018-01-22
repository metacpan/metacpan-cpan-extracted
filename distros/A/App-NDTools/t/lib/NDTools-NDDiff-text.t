use strict;
use warnings FATAL => 'all';

use Test::File::Contents;
use Test::More tests => 6;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

use_ok('App::NDTools::NDDiff');

my ($bin, $got, $exp);

$bin = new_ok('App::NDTools::NDDiff') || die "Failed to init module";
$got = $bin->load('text-123.json', 'text-123.json')->diff();
$exp = {};
is_deeply($got, $exp, "Diff same texts") || diag t_ab_cmp($got, $exp);

$bin = App::NDTools::NDDiff->new();
$got = $bin->load('text-123.json', 'text-456.json')->diff();
$exp = {T => [{R => ['1','2','3']},{A => ['4','5','6']}]};
is_deeply($got, $exp, "Diff totally different texts") || diag t_ab_cmp($got, $exp);

$bin = App::NDTools::NDDiff->new();
push @{$bin->{OPTS}->{ignore}}, '{some}{path}';
$got = eval { $bin->load('text-123.json', 'text-456.json')->diff() };
is($@, '', "Check lib avoid attempts to traverse through scalar");
$exp = {T => [{R => ['1','2','3']},{A => ['4','5','6']}]};
is_deeply($got, $exp, "Diff totally different texts") || diag t_ab_cmp($got, $exp);

