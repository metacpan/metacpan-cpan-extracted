#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More tests => 2;
use Test::Exception;
use Bio::Chado::Schema::Test;

my $schema = Bio::Chado::Schema::Test->init_schema();

my $syn_table = $schema->resultset('Sequence::Synonym');
isa_ok( $syn_table, 'DBIx::Class::ResultSet' );

$schema->txn_do(sub{
    # insert a feature with some sequence
    my $cvterm = $schema->resultset('Cv::Cvterm')
                 ->create_with({
                     name => 'tester',
                     cv   => 'testing cv',
                     db   => 'fake db',
                     dbxref => 'fake accession',
                 });
    my $synonym = $syn_table->create({
        name => 'foo',
        type => $cvterm,
        synonym_sgml => 'foo',
    });

    is( scalar( $synonym->features ), 0, 'feature mm works, returns 0' );

    $schema->txn_rollback;

});
