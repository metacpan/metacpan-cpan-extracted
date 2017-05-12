use strict;
use warnings;

use Test::More tests => 15;

use CPAN::Changes::Markdown::Filter;
use CPAN::Changes::Markdown::Filter::RuleUtil qw( :all );

my $filter = CPAN::Changes::Markdown::Filter->new( rules => [rule_PackageNamesToCode] );

is( $filter->process("this is a test\n"),        "this is a test\n",          "no packages == no highlights" );
is( $filter->process("hell Foo world\n"),        "hell Foo world\n",          "Nouns are not magically packages" );
is( $filter->process("hell FooFoo world\n"),     "hell `FooFoo` world\n",     "Nouns with 2 humps are packages" );
is( $filter->process("hell FooFooFoo world\n"),  "hell `FooFooFoo` world\n",  "Nouns with 3 humps are packages" );
is( $filter->process("hell FooFooFFoo world\n"), "hell `FooFooFFoo` world\n", "Nouns with 4 humps are packages" );
is( $filter->process("hell SMART world\n"),      "hell SMART world\n",        "Nouns with all-caps are not packages" );
is( $filter->process("hell ::SMART world\n"),    "hell `::SMART` world\n",    "Nouns with all-caps are and prefix are packages" );
is( $filter->process("hell ShMART world\n"), "hell `ShMART` world\n", "Nouns with all caps except first segment are packages" );
is( $filter->process("hell ::Foo world\n"),  "hell `::Foo` world\n",  "::Prefix highlights" );
is( $filter->process("hell Bar:: world\n"),  "hell `Bar::` world\n",  "Suffix:: highlights" );
is( $filter->process("hell Baz::Quux world\n"), "hell `Baz::Quux` world\n", "infix :: highlights" );
is( $filter->process("hell quux::doo world\n"), "hell `quux::doo` world\n", "infix :: on lc tokens highlights" );
is(
  $filter->process("hell quux::doo::asfd world\n"),
  "hell `quux::doo::asfd` world\n",
  "Extended tokens == extended highlighting"
);
is(
  $filter->process("hell ::quux::doo::asfd world\n"),
  "hell `::quux::doo::asfd` world\n",
  "Extended prefix == extended highlighting"
);
is(
  $filter->process("hell quux::doo::asfd:: world\n"),
  "hell `quux::doo::asfd::` world\n",
  "Extended suffix == extended highlighting"
);
