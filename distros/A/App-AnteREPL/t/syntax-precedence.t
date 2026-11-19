use 5.016;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use App::AnteREPL;

sub capture (&) {
    my ($code) = @_;
    my $text = '';
    open my $fh, '>', \$text or die $!;
    local *STDOUT = $fh;
    $code->();
    return $text;
}

# E reserves spaced definition tags; bare Perl and EVAL keep Perl's meaning.
# In particular, Perl's s operator permits alphabetic delimiters.
for my $prefix ('', 'EVAL ') {
    my $r = App::AnteREPL->new;
    $r->dispatch('$_ = "riple re"');
    $r->dispatch($prefix . 's triple return 3 * shift');
    is $r->evaluate('$_',0), 'urn 3 * shif', "$prefix preserves the alphabetic-delimiter substitution";
    is_deeply [$r->function_names], [], 'real substitution did not install a function';
    $r->dispatch($prefix . 's /urn 3/changed/');
    is $r->evaluate('$_',0), 'changed * shif', 'spaced punctuation delimiter remains Perl';
    is capture { $r->dispatch($prefix . 'say q{one,two}, qq{ three}, join q{:}, qw(four five)') },
        "one,two threefour:five\n", 'ordinary quote operators run without changing modes';
    $r->dispatch('sub ar ($) { say $_[0] }');
    is capture { $r->dispatch($prefix . 'ar "real function"') }, "real function\n", 'a shorthand tag can be a normal prototype-based function';
    $r->dispatch('sub a { say join q{:}, @_ }');
    is capture { $r->dispatch($prefix . 'a "one", "two"') }, "one:two\n", 'existing function takes precedence over a named list';
    $r->dispatch($prefix . '$result = { a => "one", ar => q{two} }');
    is_deeply $r->evaluate('$result',0), {a=>'one', ar=>'two'}, 'hash syntax and bareword keys stay Perl';
    is capture { $r->dispatch($prefix . 'say "E s fake return 1; a one, two"') },
        "E s fake return 1; a one, two\n", 'shorthand inside strings remains text';
}

for my $source ('q => 1, s => 2', 'name => 1, other => 2',
                "=pod\nwords, here\n=cut", 'E =pod', 'EVAL s triple return 3 * shift',
                'E = s triple return 3 * shift', '= words one, two') {
    ok !defined App::AnteREPL::Shorthand->explicit($source), "explicit parser ignores $source";
    ok !defined App::AnteREPL::Shorthand->implicit($source), "list parser ignores $source";
}

my $r = App::AnteREPL->new;
$r->dispatch('$_ = "riple re"');
$r->dispatch('E s triple return 3 * shift');
is $r->evaluate('triple 14',0), 42, 'the requested E s spelling defines a function';
is $r->evaluate('$_',0), 'riple re', 'E s did not execute a substitution';
$r->dispatch('EVAL s triple return 3 * shift');
is $r->evaluate('$_',0), 'urn 3 * shif', 'EVAL retains the literal substitution';
is capture { $r->dispatch('E say triple 14') }, "42\n", 'E still evaluates ordinary Perl outside its reserved tags';
$r->dispatch('$count = 2; $q = 7');
$r->dispatch('E a quoted q{one,two}, qq{value:$count}, qw(red blue), $q, "q", "s"');
is_deeply $r->evaluate('\@quoted',0), ['one,two','value:2','red','blue',7,'q','s'], 'real quoting and implicit words coexist in the same array grammar';
$r->dispatch('named one, q/two,three/, qq{four:$count}, qw(five six)');
is_deeply $r->evaluate('\@named',0), ['one','two,three','four:2','five','six'], 'named lists have the same native quoting rules';
$r->dispatch('E hr nested text => q{=>,[]}, values => [qw(one two), {quote => qq{hello:$count}}], regex => qr/a,b/');
my $nested = $r->evaluate('$nested',0);
is $nested->{text}, '=>,[]', 'quoted separators are opaque inside a hash';
is_deeply $nested->{values}, ['one','two',{quote=>'hello:2'}], 'quoting works recursively';
like 'a,b', $nested->{regex}, 'regex quote operator produces a real regex';
$r->dispatch('E a unusual q,comma delimited,, q XalphabeticX, q!bang!');
is_deeply $r->evaluate('\@unusual',0), ['comma delimited','alphabetic','bang'], 'Perl punctuation and alphabetic quote delimiters work';
$r->dispatch('$_ = "old"');
$r->dispatch('E a effects s/old/new/, tr/n/N/');
is_deeply $r->evaluate('\@effects',0), [1,1], 'substitution/transliteration keep normal value semantics';
is $r->evaluate('$_',0), 'New', 'accepted quote operators execute normally';
for my $source ('E q{one,', 'E a words q{one,', 'words q{one,') {
    ok $r->input_needs_more($source), "continuation respects real quotes: $source";
    ok !$r->input_needs_more($source . 'two}'), 'closing quote completes entry';
}
our $classified = 0;
ok !$r->input_needs_more('BEGIN { ++$main::classified } say "ready"'), 'complete Perl block is classified';
is $classified, 0, 'classification did not execute BEGIN';
capture { $r->dispatch('BEGIN { ++$main::classified } say "ready"') };
is $classified, 1, 'Perl executes BEGIN exactly once';
for my $bad ('E s', 'E ar $name one', 'words one,,two', 'words one, two words') {
    my $error;
    { local $@; eval { $r->dispatch($bad); 1 } or $error = $@; }
    like $error, qr/^Ambiguous shorthand:/, "$bad gets a shorthand explanation";
}

# Defined function calls, Perl keywords, and numbered entries remain source.
$r->dispatch('EVAL sub future { say @_ }');
capture { $r->dispatch('A') };
$r->dispatch('future "one", "two"');
$r->dispatch('s triple return 3 * shift');
$r->dispatch('q{one,two}');
like $r->source, qr/future "one", "two";\ns triple return 3 \* shift;\nq\{one,two\};\n/, 'AUTO stores unmarked syntax verbatim apart from the usual semicolon';
$r->dispatch('100 E a words one, two');
like $r->source, qr/\nE a words one, two;\n/, 'numbered source is never rewritten even when it resembles shorthand';
capture { $r->dispatch('A0') };
done_testing;
