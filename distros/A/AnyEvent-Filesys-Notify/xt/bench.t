#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Cwd qw/abs_path/;
use AnyEvent::Filesys::Notify;
use Test::More;

use Benchmark qw(:all);
use File::Find::Rule;
use Path::Iterator::Rule;
use Path::Class::Rule;

diag "This isn't a test, it was a benchmark of file search tools";

cmpthese(
    10_000,
    {
        'Path-Iterator-Rule' => sub { path_iterator_rule('t/data'); },
        'File-Find-Rule'     => sub { file_find_rule('t/data'); },
        'Path-Class-Rule'    => sub { path_class_rule('t/data'); },
    } );

ok(1);
done_testing;


sub file_find_rule {
    my (@args) = @_;

    # Accept either an array of dirs or a array ref of dirs
    my @paths = ref $args[0] eq 'ARRAY' ? @{ $args[0] } : @args;

    my $fs_stats = {};

    for my $file ( File::Find::Rule->in(@paths) ) {
        my $stat = _stat($file)
          or next; # Skip files that we can't stat (ie, broken symlinks on ext4)
        $fs_stats->{ abs_path($file) } = $stat;
    }

    return $fs_stats;
}

sub path_iterator_rule {
    my (@args) = @_;

    # Accept either an array of dirs or a array ref of dirs
    my @paths = ref $args[0] eq 'ARRAY' ? @{ $args[0] } : @args;

    my $fs_stats = {};

    my $rule = Path::Iterator::Rule->new;
    my $next = $rule->iter(@paths);
    while ( my $file = $next->() ) {
        my $stat = _stat($file)
          or next; # Skip files that we can't stat (ie, broken symlinks on ext4)
        $fs_stats->{ abs_path($file) } = $stat;
    }

    return $fs_stats;
}

sub path_class_rule {
    my (@args) = @_;

    # Accept either an array of dirs or a array ref of dirs
    my @paths = ref $args[0] eq 'ARRAY' ? @{ $args[0] } : @args;

    my $fs_stats = {};

    my $rule = Path::Class::Rule->new;
    my $next = $rule->iter(@paths);
    while ( my $file = $next->() ) {
        my $stat = _stat($file)
          or next; # Skip files that we can't stat (ie, broken symlinks on ext4)
        $fs_stats->{ abs_path($file) } = $stat;
    }

    return $fs_stats;
}

sub _stat {
    AnyEvent::Filesys::Notify->_stat(@_);
}
