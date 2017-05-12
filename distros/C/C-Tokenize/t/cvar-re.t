use warnings;
# Test the matching of $cvar_re against various expressions.

use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use C::Tokenize '$cvar_re';

like ('fix->nix', qr/^$cvar_re$/,
      "member of struct reference is a c variable");

like ('trigrams[i].values', qr/^$cvar_re$/,
      "array of structs is a c variable");

like ('trigrams[bigrams].values[j]', qr/^$cvar_re$/,
      "array of structs with array members is a c variable");

TODO: {
    local $TODO = 'nested arrays';
    like ('trigrams[bigrams[i]].values[j]', qr/^$cvar_re$/,
	  "array of structs is a c variable");
};
done_testing ();
