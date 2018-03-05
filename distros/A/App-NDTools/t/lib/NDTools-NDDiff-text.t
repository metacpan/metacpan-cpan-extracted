use strict;
use warnings FATAL => 'all';

use Test::File::Contents;
use Test::More tests => 6;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

use_ok('App::NDTools::NDDiff');

my ($bin, $got, $exp);

$bin = new_ok('App::NDTools::NDDiff' => ['foo', 'bar']) || die "Failed to init module";
$got = $bin->diff($bin->load('text-123.json'), $bin->load('text-123.json'));
$exp = {};
is_deeply($got, $exp, "Diff same texts") || diag t_ab_cmp($got, $exp);

$bin = App::NDTools::NDDiff->new('foo', 'bar');
$got = $bin->diff($bin->load('text-123.json'), $bin->load('text-456.json'));
$exp = {T => [{R => ['1','2','3']},{A => ['4','5','6']}]};
is_deeply($got, $exp, "Diff totally different texts") || diag t_ab_cmp($got, $exp);

$bin = App::NDTools::NDDiff->new('foo', 'bar');
push @{$bin->{OPTS}->{ignore}}, '{some}{path}';
$got = eval {
    $bin->diff($bin->load('text-123.json'), $bin->load('text-456.json'))
};
is($@, '', "Check lib avoid attempts to traverse through scalar");
$exp = {T => [{R => ['1','2','3']},{A => ['4','5','6']}]};
is_deeply($got, $exp, "Diff totally different texts") || diag t_ab_cmp($got, $exp);

