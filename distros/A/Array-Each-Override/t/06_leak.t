#! /usr/bin/perl

use strict;
use warnings;

use Test::More;

eval 'use Devel::Leak';
plan skip_all => 'Devel::Leak required for testing memory leaks'
    if $@;

use File::Find qw<find>;
use Array::Each::Override qw<:safe>;

my %hash;
find({no_chdir => 1, wanted => sub {
    return if !-f;
    open my $fh, '<', $_
        or return;
    return if -B $fh;
    while (my $line = <$fh>) {
        chomp $line;
        $hash{$line}++;
    }
} }, '.');

sub is_leakproof (&;$) {
    my ($code, $action) = @_;
    my $handle;
    my $count = Devel::Leak::NoteSV($handle);
    $code->();
    my $new_count = Devel::Leak::CheckSV($handle);
    is($new_count, $count, $action ? "$action doesn't leak" : undef);
}

plan tests => 18;

is_leakproof { array_each %hash; 1 }
    'void-context array_each() on a hash';

is_leakproof {
    my @results;
    while (my $k = array_each %hash) {
        push @results, $k;
    }
} 'scalar-context array_each() on a hash';

is_leakproof {
    my @results;
    while (my ($k, $v) = array_each %hash) {
        push @results, [$k, $v];
    }
} 'list-context array_each() on a hash';

for my $function (qw<array_keys array_values>) {
    my $code = do { no strict qw<refs>; \&$function };
    is_leakproof { $code->(\%hash); 1 }
        "void-context $function on a hash";
    is_leakproof { my $n = $code->(\%hash) }
        "scalar-context $function on a hash";
    is_leakproof { my @list = $code->(\%hash) }
        "list-context $function on a hash";
}

TODO: {
    local $TODO = 'memory leaks when working on arrays';

    is_leakproof { my @array = keys %hash; array_each @array; 1 }
        'void-context array_each() on an array';

    is_leakproof {
        my @array = keys %hash;
        my @results;
        while (my $k = array_each @array) {
            push @results, $k;
        }
        1;
    } 'scalar-context array_each() on an array';

    is_leakproof {
        my @array = keys %hash;
        my @results;
        while (my ($k, $v) = array_each @array) {
            push @results, [$k, $v];
        }
        1;
    } 'list-context array_each() on an array';
}

for my $function (qw<array_keys array_values>) {
    my $code = do { no strict qw<refs>; \&$function };
    is_leakproof { my @array = keys %hash; $code->(\@array); 1 }
        "void-context $function on an array";
    is_leakproof { my @array = keys %hash; my $n = $code->(\@array); 1 }
        "scalar-context $function on an array";
    is_leakproof { my @array = keys %hash; my @list = $code->(\@array); 1 }
        "list-context $function on an array";
}
