#!perl
# `<:` is recognised while tokenising code, never inside quoted text. This is
# the property a source filter could not give: the lexer path that consults the
# operator hook is not reached during string, heredoc or pattern scanning.
use 5.038;
use strict;
use warnings;
use Test::More;
use Confold;

plan tests => 10;

is "a <: b", 'a <: b', 'double-quoted string is untouched';
is 'a <: b', 'a <: b', 'single-quoted string is untouched';
is q{<:encoding(UTF-8)}, '<:encoding(UTF-8)', 'a PerlIO layer string survives';
is qq{x<:y}, 'x<:y', 'qq{} is untouched';

my $here = <<"END";
inside <: heredoc
END
is $here, "inside <: heredoc\n", 'interpolating heredoc is untouched';

my $here2 = <<'END';
inside <: heredoc
END
is $here2, "inside <: heredoc\n", 'literal heredoc is untouched';

ok "x<:y" =~ /<:/,       'a pattern matches the literal glyph';
ok "x<:y" =~ m{<:},      'an m{} pattern matches it too';
is join(',', split /<:/, "a<:b"), 'a,b', 'split on the glyph works';

# An operator position is left alone entirely, so `<` keeps its meanings.
{
    my ($a, $b) = (1, 2);
    my %r = (
        lt      => ($a < $b ? 1 : 0),
        cmp     => ($b <=> $a),
        shift   => (1 << 4),
    );
    is join(',', map { "$_=$r{$_}" } sort keys %r),
       'cmp=1,lt=1,shift=16',
       'comparison, <=> and left shift are unaffected';
}
