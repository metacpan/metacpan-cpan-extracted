#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix cmp_store);

my $item_class = 'Bio::MUST::Core::Tree';
my $class = $item_class . '::Forest';

{
    my $infile = file('test', 'forest');
    my $forest = $class->load($infile);
    cmp_ok $forest->count_trees, '==', 10,
        'read expected number of items from forest...';
    ok( (List::AllUtils::all { ref($_) eq $item_class } $forest->all_trees ),
        "... and all were indeed $item_class objects!");

    cmp_store(
        obj => $forest, method => 'store',
        file => 'forest',
        test => 'wrote expected forest file',
    );

    my $idmfile = file('test', 'forest.idm');
    my $mapper = Bio::MUST::Core::IdMapper->load($idmfile);
    $forest->restore_ids($mapper);

    cmp_store(
        obj => $forest, method => 'store',
        file => 'forest-ids',
        test => 'wrote expected forest file after restoring ids',
    );
}

done_testing;
