#!perl -T

use Test::More;

use Clang;

my $index = Clang::Index -> new(0);
my $tunit = $index -> parse('t/fragments/test.c');
my $cursr = $tunit -> cursor;
my $kind  = $cursr -> kind;

is($kind -> spelling, 'TranslationUnit');

my $cursors = $cursr -> children;

my @spellings = map { $_ -> kind -> spelling } @$cursors;
my @expected  = qw(
	FunctionDecl
	FunctionDecl
);
is_deeply(\@spellings, \@expected);

done_testing;
