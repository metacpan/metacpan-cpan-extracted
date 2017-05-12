#!perl -T
use strict;
use warnings FATAL => 'all';
use DBIx::XHTML_Table;
use Test::More tests => 2;

my $attr = { no_indent => 1 };
my @data = (
    [ qw(h1 h2) ],
    [ '<input type="text" name="a1" />', '<input type="text" name="a2" />' ],
    [ '<input type="text" name="b1" />', '<input type="text" name="b2" />' ],
);

my $table = DBIx::XHTML_Table->new( \@data );
is $table->output( $attr ),
    '<table><thead><tr><th>H1</th><th>H2</th></tr></thead><tbody><tr><td><input type="text" name="a1" /></td><td><input type="text" name="a2" /></td></tr><tr><td><input type="text" name="b1" /></td><td><input type="text" name="b2" /></td></tr></tbody></table>',
    'table cells not HTML encoded by default',
;

$table->{encode_cells} = 1;
is $table->output( $attr ),
    '<table><thead><tr><th>H1</th><th>H2</th></tr></thead><tbody><tr><td>&lt;input type=&quot;text&quot; name=&quot;a1&quot; /&gt;</td><td>&lt;input type=&quot;text&quot; name=&quot;a2&quot; /&gt;</td></tr><tr><td>&lt;input type=&quot;text&quot; name=&quot;b1&quot; /&gt;</td><td>&lt;input type=&quot;text&quot; name=&quot;b2&quot; /&gt;</td></tr></tbody></table>',
    'table cells HTML encoded by request',
;
