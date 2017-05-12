#!/usr/local/bin/perl -w
use strict;
use warnings;

use Test::More;

eval 'use XML::Twig;';
plan( skip_all => 'XML::Twig not installed; skipping' ) if $@;


plan tests => 3;

use AnyData;

my $table =
  adTie( 'CSV',
    ["word,number\none,1\ntwo,2\nthree,3\nunknown\nunknowncomma,\nzero,0"] );

ok( 6 == adRows($table), "Failed rows" );

adExport( $table, "XML", 't/xml.out' );
ok( open( my $fh, '<', 't/xml.out' ), 'open file' );
local $\ = '';
my $result = <$fh>;

#print STDERR "\n---\n";
#print STDERR "$result";
#print STDERR "\n---\n";

ok(
    $result eq
'<table><row><word>one</word><number>1</number></row><row><word>two</word><number>2</number></row><row><word>three</word><number>3</number></row><row><word>unknown</word></row><row><word>unknowncomma</word></row><row><word>zero</word><number>0</number></row></table>',
    'xml export ok'
);

__END__
