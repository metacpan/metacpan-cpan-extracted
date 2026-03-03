#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese timethese);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

use Data::Path::XS qw(path_get path_set path_exists path_delete
                      patha_get patha_set patha_exists patha_delete
                      path_compile pathc_get pathc_set pathc_exists pathc_delete);
use Data::Path::XS ':keywords';
use autovivification;

# Pure Perl implementation for comparison
sub pp_path_get {
    my ($data, $path) = @_;
    return $data if $path eq '';
    die "Invalid path" unless $path =~ s{^/}{};
    for my $p (split m{/}, $path, -1) {
        return undef unless ref $data;
        if (ref $data eq 'HASH') {
            return undef unless exists $data->{$p};
            $data = $data->{$p};
        } elsif (ref $data eq 'ARRAY') {
            return undef unless $p =~ /^\d+$/ && exists $data->[$p];
            $data = $data->[$p];
        } else {
            return undef;
        }
    }
    $data;
}

sub pp_path_exists {
    my ($data, $path) = @_;
    return 1 if $path eq '';
    die "Invalid path" unless $path =~ s{^/}{};
    for my $p (split m{/}, $path, -1) {
        return 0 unless ref $data;
        if (ref $data eq 'HASH') {
            return 0 unless exists $data->{$p};
            $data = $data->{$p};
        } elsif (ref $data eq 'ARRAY') {
            return 0 unless $p =~ /^\d+$/ && exists $data->[$p];
            $data = $data->[$p];
        } else {
            return 0;
        }
    }
    1;
}

sub pp_path_set {
    my ($data, $path, $value) = @_;
    die "Cannot set root" if $path eq '';
    die "Invalid path" unless $path =~ s{^/}{};
    my @parts = split m{/}, $path, -1;
    my $last = pop @parts;
    for my $p (@parts) {
        if (ref $data eq 'HASH') {
            $data->{$p} //= {};
            $data = $data->{$p};
        } elsif (ref $data eq 'ARRAY') {
            $data->[$p] //= {};
            $data = $data->[$p];
        }
    }
    if (ref $data eq 'HASH') {
        $data->{$last} = $value;
    } elsif (ref $data eq 'ARRAY') {
        $data->[$last] = $value;
    }
    $value;
}

# Test data
my $deep = {
    level1 => {
        level2 => {
            level3 => {
                level4 => {
                    level5 => { value => 'deep' }
                }
            }
        }
    },
    arr => [0, [1, [2, [3, [4, 'nested']]]]],
};

my $shallow = { foo => 'bar', num => 42 };

print "=" x 70, "\n";
print "Data::Path::XS Benchmark (XS vs Pure Perl vs Native expressions)\n";
print "=" x 70, "\n\n";

print "--- Shallow get: /foo ---\n";
cmpthese(-2, {
    'XS'     => sub { path_get($shallow, '/foo') },
    'Perl'   => sub { pp_path_get($shallow, '/foo') },
    'Native' => sub { no autovivification; $shallow->{foo} },
});

print "\n--- Deep get: /level1/level2/level3/level4/level5/value ---\n";
cmpthese(-2, {
    'XS'     => sub { path_get($deep, '/level1/level2/level3/level4/level5/value') },
    'Perl'   => sub { pp_path_get($deep, '/level1/level2/level3/level4/level5/value') },
    'Native' => sub { no autovivification; $deep->{level1}{level2}{level3}{level4}{level5}{value} },
});

print "\n--- Array get: /arr/1/1/1/1/1 ---\n";
cmpthese(-2, {
    'XS'     => sub { path_get($deep, '/arr/1/1/1/1/1') },
    'Perl'   => sub { pp_path_get($deep, '/arr/1/1/1/1/1') },
    'Native' => sub { no autovivification; $deep->{arr}[1][1][1][1][1] },
});

print "\n--- Deep get (missing key): /level1/level2/nope/x ---\n";
cmpthese(-2, {
    'XS'     => sub { path_get($deep, '/level1/level2/nope/x') },
    'Perl'   => sub { pp_path_get($deep, '/level1/level2/nope/x') },
    'Native' => sub { no autovivification; $deep->{level1}{level2}{nope}{x} },
});

print "\n--- Shallow set: /foo ---\n";
cmpthese(-2, {
    'XS'     => sub { path_set($shallow, '/foo', 'baz') },
    'Perl'   => sub { pp_path_set($shallow, '/foo', 'baz') },
    'Native' => sub { $shallow->{foo} = 'baz' },
});

print "\n--- Deep set (existing path): /level1/level2/level3/level4/level5/value ---\n";
cmpthese(-2, {
    'XS'     => sub { path_set($deep, '/level1/level2/level3/level4/level5/value', 42) },
    'Perl'   => sub { pp_path_set($deep, '/level1/level2/level3/level4/level5/value', 42) },
    'Native' => sub { $deep->{level1}{level2}{level3}{level4}{level5}{value} = 42 },
});

print "\n--- Deep set (create path): /a/b/c/d/e ---\n";
cmpthese(-2, {
    'XS'     => sub { my $d = {}; path_set($d, '/a/b/c/d/e', 1) },
    'Perl'   => sub { my $d = {}; pp_path_set($d, '/a/b/c/d/e', 1) },
    'Native' => sub { my $d = {}; $d->{a}{b}{c}{d}{e} = 1 },
});

# Pre-built path arrays for array-based API benchmarks
my @shallow_path = ('foo');
my @deep_path = qw(level1 level2 level3 level4 level5 value);
my @arr_path = ('arr', 1, 1, 1, 1, 1);
my @missing_path = qw(level1 level2 nope x);
my @create_path = qw(a b c d e);

print "\n", "=" x 70, "\n";
print "Array-based API (patha_*) - zero parsing overhead\n";
print "=" x 70, "\n\n";

print "--- Shallow get: ['foo'] ---\n";
cmpthese(-2, {
    'XS str'  => sub { path_get($shallow, '/foo') },
    'XS arr'  => sub { patha_get($shallow, \@shallow_path) },
    'Native'  => sub { no autovivification; $shallow->{foo} },
});

print "\n--- Deep get: [qw(level1 level2 level3 level4 level5 value)] ---\n";
cmpthese(-2, {
    'XS str'  => sub { path_get($deep, '/level1/level2/level3/level4/level5/value') },
    'XS arr'  => sub { patha_get($deep, \@deep_path) },
    'Native'  => sub { no autovivification; $deep->{level1}{level2}{level3}{level4}{level5}{value} },
});

print "\n--- Array get: ['arr', 1, 1, 1, 1, 1] ---\n";
cmpthese(-2, {
    'XS str'  => sub { path_get($deep, '/arr/1/1/1/1/1') },
    'XS arr'  => sub { patha_get($deep, \@arr_path) },
    'Native'  => sub { no autovivification; $deep->{arr}[1][1][1][1][1] },
});

print "\n--- Deep get (missing): [qw(level1 level2 nope x)] ---\n";
cmpthese(-2, {
    'XS str'  => sub { path_get($deep, '/level1/level2/nope/x') },
    'XS arr'  => sub { patha_get($deep, \@missing_path) },
    'Native'  => sub { no autovivification; $deep->{level1}{level2}{nope}{x} },
});

print "\n--- Deep set (create): [qw(a b c d e)] ---\n";
cmpthese(-2, {
    'XS str'  => sub { my $d = {}; path_set($d, '/a/b/c/d/e', 1) },
    'XS arr'  => sub { my $d = {}; patha_set($d, \@create_path, 1) },
    'Native'  => sub { my $d = {}; $d->{a}{b}{c}{d}{e} = 1 },
});

# Pre-compiled paths for compiled API benchmarks
my $cp_shallow = path_compile('/foo');
my $cp_deep = path_compile('/level1/level2/level3/level4/level5/value');
my $cp_arr = path_compile('/arr/1/1/1/1/1');
my $cp_missing = path_compile('/level1/level2/nope/x');
my $cp_create = path_compile('/a/b/c/d/e');

print "\n", "=" x 70, "\n";
print "Compiled path API (pathc_*) - pre-parsed, maximum speed\n";
print "=" x 70, "\n\n";

print "--- Shallow get (compiled) ---\n";
cmpthese(-2, {
    'XS str'  => sub { path_get($shallow, '/foo') },
    'XS comp' => sub { pathc_get($shallow, $cp_shallow) },
    'Native'  => sub { no autovivification; $shallow->{foo} },
});

print "\n--- Deep get (compiled) ---\n";
cmpthese(-2, {
    'XS str'  => sub { path_get($deep, '/level1/level2/level3/level4/level5/value') },
    'XS comp' => sub { pathc_get($deep, $cp_deep) },
    'Native'  => sub { no autovivification; $deep->{level1}{level2}{level3}{level4}{level5}{value} },
});

print "\n--- Array get (compiled) ---\n";
cmpthese(-2, {
    'XS str'  => sub { path_get($deep, '/arr/1/1/1/1/1') },
    'XS comp' => sub { pathc_get($deep, $cp_arr) },
    'Native'  => sub { no autovivification; $deep->{arr}[1][1][1][1][1] },
});

print "\n--- Deep get missing (compiled) ---\n";
cmpthese(-2, {
    'XS str'  => sub { path_get($deep, '/level1/level2/nope/x') },
    'XS comp' => sub { pathc_get($deep, $cp_missing) },
    'Native'  => sub { no autovivification; $deep->{level1}{level2}{nope}{x} },
});

print "\n--- Deep set create (compiled) ---\n";
cmpthese(-2, {
    'XS str'  => sub { my $d = {}; path_set($d, '/a/b/c/d/e', 1) },
    'XS comp' => sub { my $d = {}; pathc_set($d, $cp_create, 1) },
    'Native'  => sub { my $d = {}; $d->{a}{b}{c}{d}{e} = 1 },
});

print "\n", "=" x 70, "\n";
print "EXISTS benchmarks\n";
print "=" x 70, "\n\n";

print "--- Shallow exists: /foo ---\n";
cmpthese(-2, {
    'XS'     => sub { path_exists($shallow, '/foo') },
    'Perl'   => sub { pp_path_exists($shallow, '/foo') },
    'Native' => sub { no autovivification; exists $shallow->{foo} },
});

print "\n--- Deep exists: /level1/level2/level3/level4/level5/value ---\n";
cmpthese(-2, {
    'XS'     => sub { path_exists($deep, '/level1/level2/level3/level4/level5/value') },
    'Perl'   => sub { pp_path_exists($deep, '/level1/level2/level3/level4/level5/value') },
    'Native' => sub { no autovivification; exists $deep->{level1}{level2}{level3}{level4}{level5}{value} },
});

print "\n--- Deep exists (missing): /level1/level2/nope/x ---\n";
cmpthese(-2, {
    'XS'     => sub { path_exists($deep, '/level1/level2/nope/x') },
    'Perl'   => sub { pp_path_exists($deep, '/level1/level2/nope/x') },
    'Native' => sub { no autovivification; exists $deep->{level1}{level2}{nope}{x} },
});

print "\n--- Exists (compiled) ---\n";
cmpthese(-2, {
    'XS str'  => sub { path_exists($deep, '/level1/level2/level3/level4/level5/value') },
    'XS comp' => sub { pathc_exists($deep, $cp_deep) },
    'Native'  => sub { no autovivification; exists $deep->{level1}{level2}{level3}{level4}{level5}{value} },
});

print "\n", "=" x 70, "\n";
print "KEYWORDS API (pathget, pathset, pathdelete, pathexists)\n";
print "=" x 70, "\n\n";

# For keywords, we compare constant paths vs dynamic paths vs native
my $kw_path_deep = '/level1/level2/level3/level4/level5/value';
my $kw_path_shallow = '/foo';
my $kw_path_create = '/a/b/c/d/e';
my $l1 = 'level1'; my $l2 = 'level2'; my $l3 = 'level3';
my $l4 = 'level4'; my $l5 = 'level5'; my $lv = 'value';

print "--- pathget shallow (constant path) ---\n";
cmpthese(-2, {
    'kw const'  => sub { pathget $shallow, "/foo" },
    'kw dyn'    => sub { pathget $shallow, $kw_path_shallow },
    'XS func'   => sub { path_get($shallow, '/foo') },
    'Native'    => sub { no autovivification; $shallow->{foo} },
});

print "\n--- pathget deep (constant vs dynamic vs native) ---\n";
cmpthese(-2, {
    'kw const'  => sub { pathget $deep, "/level1/level2/level3/level4/level5/value" },
    'kw dyn'    => sub { pathget $deep, $kw_path_deep },
    'dyn native'=> sub { no autovivification; $deep->{$l1}{$l2}{$l3}{$l4}{$l5}{$lv} },
    'Native'    => sub { no autovivification; $deep->{level1}{level2}{level3}{level4}{level5}{value} },
});

print "\n--- pathset shallow (constant path) ---\n";
cmpthese(-2, {
    'kw const'  => sub { pathset $shallow, "/foo", 'x' },
    'kw dyn'    => sub { pathset $shallow, $kw_path_shallow, 'x' },
    'XS func'   => sub { path_set($shallow, '/foo', 'x') },
    'Native'    => sub { $shallow->{foo} = 'x' },
});

print "\n--- pathset deep create (constant vs dynamic) ---\n";
cmpthese(-2, {
    'kw const'  => sub { my $d = {}; pathset $d, "/a/b/c/d/e", 1 },
    'kw dyn'    => sub { my $d = {}; pathset $d, $kw_path_create, 1 },
    'XS func'   => sub { my $d = {}; path_set($d, '/a/b/c/d/e', 1) },
    'Native'    => sub { my $d = {}; $d->{a}{b}{c}{d}{e} = 1 },
});

print "\n--- pathexists deep (constant vs dynamic) ---\n";
cmpthese(-2, {
    'kw const'  => sub { pathexists $deep, "/level1/level2/level3/level4/level5/value" },
    'kw dyn'    => sub { pathexists $deep, $kw_path_deep },
    'dyn native'=> sub { no autovivification; exists $deep->{$l1}{$l2}{$l3}{$l4}{$l5}{$lv} },
    'Native'    => sub { no autovivification; exists $deep->{level1}{level2}{level3}{level4}{level5}{value} },
});

print "\n--- pathexists missing ---\n";
my $kw_path_missing = '/level1/level2/nope/x';
cmpthese(-2, {
    'kw const'  => sub { pathexists $deep, "/level1/level2/nope/x" },
    'kw dyn'    => sub { pathexists $deep, $kw_path_missing },
    'XS func'   => sub { path_exists($deep, '/level1/level2/nope/x') },
    'Native'    => sub { no autovivification; exists $deep->{level1}{level2}{nope}{x} },
});

print "\n--- pathdelete (constant vs dynamic) ---\n";
cmpthese(-2, {
    'kw const'  => sub { my $d = {a=>{b=>1}}; pathdelete $d, "/a/b" },
    'kw dyn'    => sub { my $d = {a=>{b=>1}}; my $p = "/a/b"; pathdelete $d, $p },
    'XS func'   => sub { my $d = {a=>{b=>1}}; path_delete($d, '/a/b') },
    'Native'    => sub { my $d = {a=>{b=>1}}; delete $d->{a}{b} },
});

print "\n";
