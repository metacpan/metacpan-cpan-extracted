#!perl -T

use Test::More;

use Clang;

my $index = Clang::Index -> new(0);
my $tunit = $index -> parse('t/fragments/test.c');
my $cursr = $tunit -> cursor;

is($cursr -> type -> kind -> spelling, 'Invalid');

my $cursors = $cursr -> children;

my @spellings = map { $_ -> type -> kind -> spelling } @$cursors;
my @expected  = qw(
	FunctionProto
	FunctionProto
);

is_deeply(\@spellings, \@expected);

done_testing;
