#!/usr/bin/env perl -w
use strict;
use File::Spec;
use Test::More tests => 6;

sub check_dependency {
    my $class = shift;
    eval "require $class; 1";
    if ($@) {
        return;
    }
    1;
}

my ( $noindex, $noabseq, $nogene, $noseq, $noseqindex );

BEGIN {
    diag(
"\n\nTest indexers (Bio::ASN1::EntrezGene::Indexer, Bio::ASN1::Sequence::Indexer)\nIndexing and retrieval:\n"
    );
    check_dependency('Bio::ASN1::EntrezGene')          || $nogene++;
    check_dependency('Bio::Index::AbstractSeq')        || $noabseq++;
    check_dependency('Bio::ASN1::EntrezGene::Indexer') || $noindex++;
    check_dependency('Bio::ASN1::Sequence')            || $noseq++;
    check_dependency('Bio::ASN1::Sequence::Indexer')   || $noseqindex++;
}
diag("\n\nFirst testing gene indexer:\n");
SKIP: {
    if ( !$nogene ) {
        skip( "BioPerl not installed, skipping", 3 ) if $noabseq;

        # test indexer
        if ( !$noabseq ) {
            if ( !$noindex ) {
                my $inx = Bio::ASN1::EntrezGene::Indexer->new(
                    -filename   => File::Spec->catfile('t','testgene.idx'),
                    -write_flag => 'WRITE'
                );
                isa_ok( $inx, 'Bio::ASN1::EntrezGene::Indexer' );
                $inx->make_index( File::Spec->catfile('t','input.asn'), File::Spec->catfile('t','input1.asn' ));

#      cmp_ok($inx->count_records, '==', 4, 'total number of indexed gene records');
                my $value = $inx->fetch_hash(3);
                isa_ok( $value, 'ARRAY' );
                cmp_ok( $value->[0]{'track-info'}[0]{geneid},
                    '==', 3, 'correct gene record retrieved' );
            }
            else {
                diag(
"\nThere's some problem with the installation of Bio::ASN1::EntrezGene::Indexer!\nTry install again using:\n\tperl Makefile.PL\n\tmake\nQuitting now"
                );
            }
        }
    }
    else {
        diag(
"\nThere's some problem with the installation of Bio::ASN1::EntrezGene!\nTry install again using:\n\tperl Makefile.PL\n\tmake\nQuitting now"
        );
    }
    diag("\n\nNow testing sequence indexer:\n");
}

SKIP: {
    if ( !$noseq ) {
        skip( "BioPerl not installed, skipping", 3 ) if $noabseq;

        # test indexer
        if ( !$noabseq ) {
            if ( !$noseqindex ) {
                my $inx = Bio::ASN1::Sequence::Indexer->new(
                    -filename   => File::Spec->catfile('t','testseq.idx'),
                    -write_flag => 'WRITE'
                );
                isa_ok( $inx, 'Bio::ASN1::Sequence::Indexer' );
                $inx->make_index(File::Spec->catfile('t','seq.asn'));

#      cmp_ok($inx->count_records, '==', 2, 'total number of sequence ids in index');
                my $value = $inx->fetch_hash('AF093062');
                isa_ok( $value, 'ARRAY' );
                cmp_ok(
                    $value->[0]{'seq-set'}[0]{seq}[0]{id}[0]{genbank}[0]
                      {accession},
                    'eq', 'AF093062', 'correct sequence record retrieved'
                );
            }
            else {
                diag(
"\nThere's some problem with the installation of Bio::ASN1::Sequence::Indexer!\nTry install again using:\n\tperl Makefile.PL\n\tmake\nQuitting now"
                );
            }
        }
    }
    else {
        diag(
"\nThere's some problem with the installation of Bio::ASN1::Sequence!\nTry install again using:\n\tperl Makefile.PL\n\tmake\nQuitting now"
        );
    }
}
