#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;

ThisTest->runtests;

package Blog::Entry::List;
use base qw/DBIx::MoCo::List/;

sub size_test {
    shift->size;
}

package ThisTest;
use base qw/Test::Class/;
use Test::More;
use Blog::Entry;

sub startup : Test(startup) {
    Blog::Entry->list_class('Blog::Entry::List');
}

sub list_class : Tests {
    my $entries = Blog::Entry->search(limit => 3);
    isa_ok $entries, 'DBIx::MoCo::List';
    isa_ok $entries, 'Blog::Entry::List';
    is $entries->size_test, 3;
}
