#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

use Data::Path::XS qw(path_get patha_get path_compile pathc_get);
use autovivification;

# Build large structure with many keys per level
sub build_large_structure {
    my ($keys_per_level, $depth) = @_;

    my $data = {};
    my $current = $data;

    for my $level (1..$depth) {
        # Add many sibling keys at this level
        for my $i (1..$keys_per_level) {
            $current->{"key$i"} = "value_l${level}_k${i}";
        }
        # One key leads deeper
        if ($level < $depth) {
            $current->{target} = {};
            $current = $current->{target};
        } else {
            $current->{target} = "FOUND";
        }
    }

    return $data;
}

print "=" x 70, "\n";
print "Large Structure Benchmark - Many keys per level\n";
print "=" x 70, "\n\n";

for my $keys_per_level (100, 250, 500) {
    for my $depth (3, 5, 7) {
        print "-" x 70, "\n";
        print "Structure: $keys_per_level keys/level, $depth levels deep\n";
        print "-" x 70, "\n";

        my $data = build_large_structure($keys_per_level, $depth);

        # Build path to deepest target
        my $path_str = '/target' x $depth;
        my @path_arr = ('target') x $depth;
        my $path_compiled = path_compile($path_str);

        # Verify all methods work
        my $v1 = path_get($data, $path_str);
        my $v2 = patha_get($data, \@path_arr);
        my $v3 = pathc_get($data, $path_compiled);
        die "Mismatch!" unless $v1 eq 'FOUND' && $v2 eq 'FOUND' && $v3 eq 'FOUND';

        # Build native accessor
        my $native_code = 'sub { no autovivification; $data->' . ('{target}' x $depth) . ' }';
        my $native_sub = eval $native_code;
        die "Eval failed: $@" if $@;

        print "Path: $path_str\n\n";

        cmpthese(-2, {
            'XS str'  => sub { path_get($data, $path_str) },
            'XS arr'  => sub { patha_get($data, \@path_arr) },
            'XS comp' => sub { pathc_get($data, $path_compiled) },
            'Native'  => $native_sub,
        });
        print "\n";
    }
}

# Also test with mixed array/hash structure
print "=" x 70, "\n";
print "Mixed Hash/Array Structure - 200 keys + 50 array elements per level\n";
print "=" x 70, "\n\n";

sub build_mixed_structure {
    my ($depth) = @_;

    my $data = {};
    my $current = $data;

    for my $level (1..$depth) {
        # Add many hash keys
        for my $i (1..200) {
            $current->{"hash$i"} = "hval_$level";
        }
        # Add array with many elements
        $current->{arr} = [ map { "aval_${level}_$_" } 1..50 ];

        if ($level < $depth) {
            $current->{arr}[25] = {};  # Middle of array leads deeper
            $current = $current->{arr}[25];
        } else {
            $current->{arr}[25] = "FOUND";
        }
    }

    return $data;
}

for my $depth (3, 5) {
    print "-" x 70, "\n";
    print "Mixed structure: $depth levels deep\n";
    print "-" x 70, "\n";

    my $data = build_mixed_structure($depth);

    # Path alternates hash->array access
    my $path_str = join('', map { '/arr/25' } 1..$depth);
    my @path_arr = map { ('arr', 25) } 1..$depth;
    my $path_compiled = path_compile($path_str);

    my $v1 = path_get($data, $path_str);
    die "Not found: got '$v1'" unless $v1 eq 'FOUND';

    print "Path: $path_str\n\n";

    cmpthese(-2, {
        'XS str'  => sub { path_get($data, $path_str) },
        'XS arr'  => sub { patha_get($data, \@path_arr) },
        'XS comp' => sub { pathc_get($data, $path_compiled) },
    });
    print "\n";
}

# Test missing key in large structure
print "=" x 70, "\n";
print "Missing Key Lookup in Large Structure (500 keys/level, 5 deep)\n";
print "=" x 70, "\n\n";

my $large = build_large_structure(500, 5);
my $missing_str = '/target/target/NOTFOUND/x/y';
my @missing_arr = qw(target target NOTFOUND x y);
my $missing_compiled = path_compile($missing_str);

cmpthese(-2, {
    'XS str'  => sub { path_get($large, $missing_str) },
    'XS arr'  => sub { patha_get($large, \@missing_arr) },
    'XS comp' => sub { pathc_get($large, $missing_compiled) },
    'Native'  => sub { no autovivification; $large->{target}{target}{NOTFOUND}{x}{y} },
});
print "\n";
