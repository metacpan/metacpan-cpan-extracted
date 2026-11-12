#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp qw(tempdir);
use Data::Shared;

my $root = Data::Shared->new(tempdir(CLEANUP => 1));
# Composite budgets come from the mount spec; stats has no max_children field.
my %child_limit = ('/tenants' => 3);
$root->mount('jobs', 'queue:int', undef, 8);
$root->mount('cache', 'hashmap:ss', undef, 16, 0, 0, 0, 4096);
$root->set("/cache/$_", 'x' x 200) for 1 .. 13;
$root->mount('tenants', ['hashmap:ss', 4, ['queue:int', 8],
    { max_children => $child_limit{'/tenants'}, cache_size => 1 }]);
$root->push('/jobs', $_) for 1 .. 7;
$root->push('/tenants/acme', $_) for 1 .. 7;
$root->push('/tenants/beta', $_) for 1 .. 2;
$root->push('/tenants/gamma', 1);

sub usage {
    my ($path, $label, $used, $capacity) = @_;
    my $percent = 100 * $used / $capacity;
    printf "%s %s: %d/%d (%.0f%%)%s\n", $path, $label, $used, $capacity,
        $percent, $percent >= 80 ? ' nearly full' : '';
}

sub report {
    my ($node, $stats) = @_;
    if (($stats->{class} // '') eq 'Data::Shared::Composite') {
        printf "%s: %d registered children, %d cached\n",
            $node->path, $stats->{children}, $stats->{open};
        usage($node->path, 'children', $stats->{children}, $child_limit{$node->path})
            if $child_limit{$node->path};
        # child_stats covers cached children; enumerate to include evicted ones.
        for my $address ($node->children) {
            my $child = $node->node([$address]);
            my $handle = $child->handle;
            my $s = $handle->isa('Data::Shared::Node') ? $handle->call('stats')
                : $handle->can('stats') ? $handle->stats : {};
            report($child, $s);
        }
    } else {
        my $reported = 0;
        # HashMap can grow its slot table; arena_used is a high-water mark.
        for my $resource (['slots', 'size', 'capacity'], ['arena bytes', 'arena_used', 'arena_cap']) {
            my ($label, $used, $cap) = @$resource;
            next unless defined $stats->{$used} && $stats->{$cap};
            usage($node->path, $label, $stats->{$used}, $stats->{$cap});
            $reported++;
        }
        print $node->path, ": capacity unavailable\n" unless $reported;
    }
}

my $stats = $root->stats;
print "cached tenant stats: ", join(', ', sort keys %{ $stats->{tenants}{child_stats} }), "\n";
report($root->node($_), $stats->{$_}) for sort keys %$stats;
