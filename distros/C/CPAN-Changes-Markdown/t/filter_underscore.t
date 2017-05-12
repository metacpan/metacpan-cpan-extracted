use strict;
use warnings;

use Test::More tests => 8;

use CPAN::Changes::Markdown::Filter;
use CPAN::Changes::Markdown::Filter::RuleUtil qw( :all );

my $filter = CPAN::Changes::Markdown::Filter->new( rules => [rule_UnderscoredToCode] );

is( $filter->process("this is a test\n"),           "this is a test\n",             "no packages == no highlights" );
is( $filter->process("hell _SMART world\n"),        "hell `_SMART` world\n",        "_ as a prefix highlights" );
is( $filter->process("hell Bar_ world\n"),          "hell `Bar_` world\n",          "Suffix_ highlights" );
is( $filter->process("hell Baz_Quux world\n"),      "hell `Baz_Quux` world\n",      "infix _ highlights" );
is( $filter->process("hell quux_doo world\n"),      "hell `quux_doo` world\n",      "infix _ on lc tokens highlights" );
is( $filter->process("hell quux_doo_asfd world\n"), "hell `quux_doo_asfd` world\n", "Extended tokens == extended highlighting" );
is( $filter->process("hell _quux_doo_asfd world\n"), "hell `_quux_doo_asfd` world\n",
  "Extended prefix == extended highlighting" );
is( $filter->process("hell quux_doo_asfd_ world\n"), "hell `quux_doo_asfd_` world\n",
  "Extended suffix == extended highlighting" );
