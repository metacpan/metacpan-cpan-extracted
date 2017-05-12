use strict;
use warnings;

use FindBin qw/$Bin/;
use Test::More tests => 5;
use Test::Differences;
use Path::Class qw(dir);

use_ok('Class::Discover');

# RT #48571 : Random Test Failures due to unexpected array order
# See Also :  RT #48593 : Document Result-Order being arbitrary and not-predictable

sub class_sort {
    my ( $x, $y ) = @_;
    my @m = keys %{ $x };
    my @n = keys %{ $y };
    return $m[0] cmp $n[0];
}

sub c_sort($){
    [ sort { class_sort($a,$b) } @{ $_[0] } ]
}

sub make_paths_native {
    my ( $result_list ) = @_;
    
    for ( @{$result_list} ) {
        my ($result) = values %{$_};
        $result->{file} = dir($result->{file})->stringify;
    }
    
    return;
}

# /RT

my $classes = Class::Discover->discover_classes({
  dir => "$Bin/data/dir1/",
  files => "$Bin/data/dir1/lib/Class1.pm"
});
my $expected = [ { MyClass => { file => "lib/Class1.pm", type => "class", version => "0.03_a" } } ];

make_paths_native($expected);
eq_or_diff( c_sort $classes, c_sort $expected, "Provided files" );

################################################################################

$classes = Class::Discover->discover_classes({ dir => "$Bin/data/dir1" });
$expected = [
    { MyClass => { file => "lib/Class1.pm", type => "class", version => "0.03_a" } },
    { MyClass2 => { file => "lib/Class2.pm", type => "class" } },
];

make_paths_native($expected);
eq_or_diff( c_sort $classes, c_sort $expected, "Found files" );

################################################################################

$classes = Class::Discover->discover_classes({
  dir => "$Bin/data/dir1",
  no_index => {
    file => ["lib/Class1.pm"]
  }
});
$expected = [ { MyClass2 => { file => "lib/Class2.pm", type => "class" } } ];

make_paths_native($expected);
eq_or_diff( c_sort $classes, c_sort $expected, "Found files, no_index" );

################################################################################

$classes = Class::Discover->discover_classes({ dir => "$Bin/data/dir2" });
$expected = [
    { Outer => { file => "lib/Nested.pm", type => "class" } },
    { 'Global::Versioned' => { file => "lib/Nested.pm", type => "class", version => "1" } },
    { 'Outer::Inner::Versioned' => { file => "lib/Nested.pm", type => "class", version => "1" } },
    { 'Outer::Inner::Unversioned' => { file => "lib/Nested.pm", type => "class" } },
    { Global => { file => "lib/Nested.pm", type => "class" } },
    { MyRole => { file => "lib/Nested.pm", type => "role" } },
];

make_paths_native($expected);
eq_or_diff( c_sort $classes, c_sort $expected, "Found files, no_index" );
