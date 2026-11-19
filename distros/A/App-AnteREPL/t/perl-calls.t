use 5.016;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use App::AnteREPL;

sub capture (&) {
    my ($code) = @_;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    local *STDOUT = $fh;
    $code->();
    return $out;
}
my $r = App::AnteREPL->new;

# Completion must understand declaration prototypes before interpreting sigils
# as variables. In particular, the closing ')' in ($) is not part of $).
for my $prototype ('$', '@', '%', '$$', '&@', '\\$', '\\[$@]', '*;_', '+', '') {
    for my $header ("sub named ($prototype)", "sub ($prototype)",
        "sub named :prototype($prototype)") {
        ok !$r->input_needs_more("EVAL $header { 42 }"), "complete declaration: $header";
        ok $r->input_needs_more("EVAL $header {"), "open body: $header";
    }
}
ok $r->input_needs_more('E sub pending ($'), 'unfinished prototype continues';
ok !$r->input_needs_more("E sub pending (\$\n) { 42 }"), 'prototype can span rows';
ok !$r->input_needs_more("E sub # declaration\n pending # name\n (\$) { 42 }"),
    'comments between declaration tokens are ignored';
ok !$r->input_needs_more('E sub Other::named ($) { 42 }'), 'qualified subroutine name';
ok !$r->input_needs_more('E sub named ($) :lvalue { $value }'), 'attribute after prototype';
for my $source ('EVAL do { say $) }', 'EVAL do { say $( }',
    'say($))', 'say($( )', '$x = "sub named ($) {"', '$x = q|sub named ($) {|') {
    ok !$r->input_needs_more($source), "ordinary variables and quotes remain complete: $source";
}
ok $r->input_needs_more('EVAL do { say $)'), 'special variable does not close an open body';
ok $r->input_needs_more('say($)'), 'special variable does not close its enclosing call';

$r->dispatch('EVAL sub triple { 3 * shift }');
is capture { $r->dispatch('say triple 14') }, "42\n", 'ordinary subroutine call needs no parentheses';
is capture { $r->dispatch('say triple(14)') }, "42\n", 'parenthesized calls remain supported';
$r->dispatch('EVAL sub scalar_arg ($) { 3 * $_[0] }');
is capture { $r->dispatch('say scalar_arg 14') }, "42\n", 'scalar prototype accepts bare argument';
$r->dispatch('EVAL sub answer () { 42 }');
is capture { $r->dispatch('say answer') }, "42\n", 'nullary prototype accepts bare call';
$r->dispatch('EVAL sub total (@) { my $n = 0; $n += $_ for @_; $n }');
is capture { $r->dispatch('say total 1, 2, 3') }, "6\n", 'list prototype consumes the argument list';
$r->dispatch('EVAL sub apply (&@) { my $code = shift; map { $code->($_) } @_ }');
is capture { $r->dispatch('say join q{,}, apply { $_[0] * 2 } 1, 2, 3') }, "2,4,6\n",
    'block-and-list prototype preserves Perl block-call syntax';
$r->dispatch('EVAL sub increment (\$) { ++${$_[0]} }');
$r->dispatch('$value = 4');
$r->dispatch('increment $value');
is $r->evaluate('$value', 0), 5, 'reference prototype receives a scalar alias';
$r->dispatch('EVAL sub cls ($) { say $_[0] }');
is capture { $r->dispatch('cls 17') }, "17\n", 'prototype call matching a lowercase command is still Perl';
$r->dispatch('10 sub from_run ($) { 2 * $_[0] }');
$r->dispatch('RUN');
is capture { $r->dispatch('say from_run 21') }, "42\n", 'RUN-defined prototypes are visible to later entries';
is capture { $r->dispatch(q{eval { die "caught\n" }; print $@}) }, "caught\n",
    'lowercase eval retains its block and exception semantics';

# Prototypes influence parsing; verify the same result as Perl itself rather
# than imposing a new precedence rule on the input.
my $expected = eval 'sub reference_scalar ($) { 3 * $_[0] } reference_scalar 1 + 2';
die $@ if $@;
is $r->evaluate('scalar_arg 1 + 2', 0), $expected, 'scalar-prototype precedence stays native';
$expected = eval 'sub reference_list { 3 * $_[0] } reference_list 1 + 2';
die $@ if $@;
is $r->evaluate('triple 1 + 2', 0), $expected, 'ordinary list-operator precedence stays native';
done_testing;
