#!perl -T
use strict;
use warnings FATAL => 'all';
use DBIx::XHTML_Table;
use Test::More tests => 6;

my $attr = { no_indent => 1 };
my @data = (
    [ qw(h1 h2) ],
    [ qw(foo 1) ],
    [ qw(foo 2) ],
);

my $table = new_ok 'DBIx::XHTML_Table', [ \@data ];

is $table->output( $attr ),
    '<table><thead><tr><th>H1</th><th>H2</th></tr></thead><tbody><tr><td>foo</td><td>1</td></tr><tr><td>foo</td><td>2</td></tr></tbody></table>',
    'vanilla output',
;

$table->map_head( sub{ $_[0] =~s/h(\d)/'z' . ($1+1)/e; $_[0] }, 'h1' );
is $table->output( $attr ),
    '<table><thead><tr><th>z2</th><th>H2</th></tr></thead><tbody><tr><td>foo</td><td>1</td></tr><tr><td>foo</td><td>2</td></tr></tbody></table>',
    'alter heading',
;

$table->set_group( 'h1', 1 );
is $table->output( $attr ),
    '<table><thead><tr><th>z2</th><th>H2</th></tr></thead><tbody><tr><td>foo</td><td>1</td></tr><tr><td>&nbsp;</td><td>2</td></tr></tbody></table>',
    'group by heading',
;

$table->calc_totals( 'h2' );
is $table->output( $attr ),
    '<table><thead><tr><th>z2</th><th>H2</th></tr></thead><tfoot><tr><th>&nbsp;</th><th>3</th></tr></tfoot><tbody><tr><td>foo</td><td>1</td></tr><tr><td>&nbsp;</td><td>2</td></tr></tbody></table>',
    'calc totals',
;

$table->modify( td => { style => {background => ['#d0d0d0','#f0f0f0']} }, 'body' );
is $table->output( $attr ),
    '<table><thead><tr><th>z2</th><th>H2</th></tr></thead><tfoot><tr><th>&nbsp;</th><th>3</th></tr></tfoot><tbody><tr><td style="background: #d0d0d0;">foo</td><td style="background: #f0f0f0;">1</td></tr><tr><td style="background: #d0d0d0;">&nbsp;</td><td style="background: #f0f0f0;">2</td></tr></tbody></table>',
    'color cells',
;
