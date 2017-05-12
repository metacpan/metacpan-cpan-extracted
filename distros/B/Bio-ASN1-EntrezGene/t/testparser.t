#!/usr/bin/env perl -w
use strict;
use warnings;
use File::Spec;
use Test::More tests => 10;

my ($nogene, $noseq);

BEGIN {
  diag("\n\nTest parsers (Bio::ASN1::EntrezGene, Bio::ASN1::Sequence),\nparsing and method call:\n");
  use_ok('Bio::ASN1::EntrezGene') || $nogene++;
  use_ok('Bio::ASN1::Sequence') || $noseq++;
}
diag("\n\nFirst testing gene parser:\n");
if(!$nogene)
{
  my $parser = Bio::ASN1::EntrezGene->new(file => File::Spec->catfile('t','input.asn'));
  isa_ok($parser, 'Bio::ASN1::EntrezGene');
  my $value = $parser->next_seq;
  isa_ok($value, 'ARRAY');
  like($value->[0]{'track-info'}[0]{geneid}, qr/^\d+$/, 'correct geneid format');
  my $raw = $parser->rawdata;
  like($raw, qr/^Entrezgene ::=/, 'rawdata() call');
}
else
{
  diag("\nThere's some problem with the installation of Bio::ASN1::EntrezGene!\nTry install again using:\n\tperl Makefile.PL\n\tmake\nQuitting now");
}
diag("\n\nNow testing sequence parser:\n");
if(!$noseq)
{
  my $parser = Bio::ASN1::Sequence->new(file => File::Spec->catfile('t','seq.asn'));
  isa_ok($parser, 'Bio::ASN1::Sequence');
  my $value = $parser->next_seq;
  isa_ok($value, 'ARRAY');
  like($value->[0]{'seq-set'}[0]{seq}[0]{id}[0]{genbank}[0]{accession}, qr/^[A-Za-z0-9.]+$/, 'genbank id format test');
  my $raw = $parser->rawdata;
  like($raw, qr/^Seq-entry ::= set/, 'rawdata() call');
}
else
{
  diag("\nThere's some problem with the installation of Bio::ASN1::Sequence!\nTry install again using:\n\tperl Makefile.PL\n\tmake\nQuitting now");
}

