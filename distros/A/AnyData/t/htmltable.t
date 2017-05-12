#!/usr/local/bin/perl -w
use strict;
use warnings;

use Test::More;
plan tests => 3;

use AnyData;

my $table =
  adTie( 'CSV',
    ["word,number\none,1\ntwo,2\nthree,3\nunknown\nunknowncomma,\nzero,0"] );

ok( 6 == adRows($table), "Failed rows" );

adExport( $table, "HTMLtable", 't/htmltable.out' );
ok( open( my $fh, '<', 't/htmltable.out' ), 'open file' );
local $\ = '';
my $result = <$fh>;

#print STDERR "\n---\n";
#print STDERR "$result";
#print STDERR "\n---\n";

ok(
    $result eq
'<table>t/htmltable.out <tr bgcolor="#c0c0c0"><th>word</th> <th>number</th></tr> <tr><td>one</td> <td>1</td></tr> <tr><td>two</td> <td>2</td></tr> <tr><td>three</td> <td>3</td></tr> <tr><td>unknown</td></tr> <tr><td>unknowncomma</td> <td>&nbsp;</td></tr> <tr><td>zero</td> <td>&nbsp;</td></tr></table>',
    'xml export ok'
);

__END__
