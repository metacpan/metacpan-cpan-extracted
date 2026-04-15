#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib $Bin;

package MultiParentTest;

use ParentDB;
use ParentFile;

use Class;
extends qw/ParentDB ParentFile/;

our @build_log;
sub BUILD { push @build_log, 'MultiParentTest' }

package main;

use Test::More;

my $obj = MultiParentTest->new;
ok($obj->can('to_db'));
ok($obj->can('to_file'));
is($obj->to_db . $obj->to_file, "DB saved\nFile saved\n");

# BUILD hook order according to C3 lineariisation (ancestor-first)
my @linear = @{mro::get_linear_isa('MultiParentTest')};
my @expected_build_order = grep {
    my $f;
    {
        no strict 'refs';
        $f = *{"${_}::BUILD"}{CODE};
    }
    $f;
} grep { $_ ne 'UNIVERSAL' } reverse @linear;

is_deeply([@build_log], \@expected_build_order);

done_testing;
