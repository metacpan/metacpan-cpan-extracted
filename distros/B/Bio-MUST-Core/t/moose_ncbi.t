#!/usr/bin/env perl

use Test::Most;
use Test::Deep;

use autodie;
use feature qw(say);

# use Data::Structure::Util qw(unbless);
use Path::Class qw(dir file);
use Storable;

use Bio::MUST::Core;
use Bio::MUST::Core::Taxonomy::MooseNCBI;

my $class = 'Bio::MUST::Core::Taxonomy::MooseNCBI';

my $tax_dir = dir('test', 'taxdump')->stringify;

SKIP: {
  skip 'due to NCBI Taxonomy database not installed', 3
    unless -e file($tax_dir, 'names.dmp');

    # build Taxonomy object
    # Note: when names and nodes are plain files (not GLOBs) as here, their removal
    # in the pack method is useless (but does not harm)
    my $tax = $class->new(
        names => file($tax_dir, 'names.dmp'),
        nodes => file($tax_dir, 'nodes.dmp'),
    );
    isa_ok $tax, $class;

    # pack and store Taxonomy
    my $pack = $tax->pack;
    my $binfile = file($tax_dir, 'moose_ncbi.bin');
    unlink $binfile if -e $binfile;
    Storable::nstore($pack, $binfile);

    # load and unpack Taxonomy
    my $load = Storable::retrieve($binfile);
    unlink $binfile;
    my $tax_unpack = $class->unpack($load);
    isa_ok $tax_unpack, $class;

    # check that packed Taxonomy is identical to original object
    cmp_deeply(
        $tax_unpack,
        methods(
            [ 'get_taxid_from_name', 'Homo sapiens' ] => 9606,
            [ 'get_level_from_name', 'Homo sapiens' ] => 'species',
            [ 'get_term_at_level', 9606, 'species'  ] => 'Homo sapiens',
        ),
        'apparently freezed and thawed NCBI Taxonomy as expected'
    );
}

done_testing;
