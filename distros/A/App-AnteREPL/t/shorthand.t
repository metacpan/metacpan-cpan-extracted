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
sub fails (&) { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@; }
my $r = App::AnteREPL->new;

is capture { $r->dispatch('E s triple return 3 * shift') }, '', 'function shorthand defines silently';
is capture { $r->dispatch('say triple 14') }, "42\n", 'shorthand function is callable by normal Perl';
is_deeply [$r->numbers], [], 'immediate definition does not enter source';
my @warnings;
{ local $SIG{__WARN__} = sub { push @warnings, @_ };
  $r->dispatch('E! s triple return 4 * shift'); }
like join('', @warnings), qr/Subroutine triple redefined/, 'redefinition retains the normal warning';
is capture { $r->dispatch('say triple 3') }, "12\n", 'redefinition installs the replacement';
$r->dispatch('E s factorial return $_[0] < 2 ? 1 : $_[0] * factorial($_[0] - 1)');
is $r->evaluate('factorial 5', 0), 120, 'function body retains recursive Perl calls';
$r->dispatch("E s commented return 7 # comment\n");
is $r->evaluate('commented', 0), 7, 'closing function brace is safe from a trailing comment';
$r->dispatch("E s block {\n return 8;\n}");
is $r->evaluate('block', 0), 8, 'multiline braced function body works';

$r->dispatch('a one, two, threee');
is_deeply $r->evaluate('\@a', 0), [qw(one two threee)], 'implicit words are strings with original spelling';
$r->dispatch('colors red, blue');
is_deeply $r->evaluate('\@colors', 0), [qw(red blue)], 'the leading word names the persistent array';
$r->dispatch('settings color => blue, count => 3');
is_deeply $r->evaluate('\%settings', 0), {color=>'blue',count=>3}, 'arrows select a named hash';
$r->dispatch('E a names Ada, "Grace Hopper", \'Linus\',');
is_deeply $r->evaluate('\@names', 0), ['Ada','Grace Hopper','Linus'], 'quoted words and trailing comma work';
$r->dispatch('E ar numbers -1, 2.5, 3e2, .5, undef');
is_deeply $r->evaluate('$numbers', 0), [-1,2.5,300,.5,undef], 'array references accept decimal numbers and undef';
$r->dispatch('E h options color => blue, tags => [one, two], child => {x => 1}');
is_deeply $r->evaluate('\%options', 0), {color=>'blue',tags=>[qw(one two)],child=>{x=>1}}, 'nested arrays and hashes use the same literal grammar';
$r->dispatch('E hr data name => Ada, flags => ["q", "s"], text => "], => are text"');
is_deeply $r->evaluate('$data', 0), {name=>'Ada', flags=>[qw(q s)],text=>'], => are text'}, 'quote-like words and delimiters inside strings are literal';
$r->dispatch('$count = 0');
$r->dispatch('E a expr (do { ++$count; 1..3 }), (q{x,y}), $count');
is_deeply $r->evaluate('\@expr', 0), [1,2,3,'x,y',1], 'parenthesized expressions use list context and execute once';
is $r->evaluate('$count', 0), 1, 'classification never executes expressions';
$r->dispatch('E a interpolation "value:$count", \'$count\';');
is_deeply $r->evaluate('\@interpolation', 0), ['value:1','$count'], 'quotes retain Perl interpolation and one terminator is allowed';
$r->dispatch('terminator one, "two;";');
is_deeply $r->evaluate('\@terminator', 0), ['one','two;'], 'terminator stripping preserves semicolons inside strings';
@warnings = ();
{ local $SIG{__WARN__} = sub { push @warnings, @_ };
  $r->dispatch('E h contexts total => (1,2,3), count => $count'); }
is_deeply $r->evaluate('\%contexts', 0), {total=>3,count=>1}, 'each hash value uses scalar context';
like join('', @warnings), qr/Useless use/, 'explicit Perl expressions retain their normal warnings';
$r->dispatch('E a empty;');
$r->dispatch('E ar empty_ref');
$r->dispatch('E h empty_hash');
$r->dispatch('E hr empty_hash_ref');
is_deeply $r->evaluate('[\@empty,$empty_ref,\%empty_hash,$empty_hash_ref]', 0), [[],[],{},{}], 'all four empty container definitions are explicit';

for my $bad ('E s', 'E s triple', 'E s $triple return 1', 'E s say return 1',
             'E a $wrong one', 'E a names one,,two', 'E ar names 042',
             'E a names red-blue', 'E a names two words', 'E a names 1+2',
             'E h names a =>', 'E hr names a => 1, b', 'E h names a => b => c',
             'E a names [one}', 'E ar names "unclosed', 'E a names (1) + 2',
             'E a names one; die "bad"', 'E h names [a] => b', 'E a names one;;') {
    like fails { $r->dispatch($bad) }, qr/\AAmbiguous shorthand: .*Try EVAL/s, "$bad gets a friendly explanation";
}
is_deeply $r->evaluate('\@names', 0), ['Ada','Grace Hopper','Linus'], 'rejected definitions leave prior values intact';
for my $case (
    ['E ar values one, [two,', 1], ['E ar values one, [two,three]', 0],
    ['E hr values x => ["two]', 1], ['E hr values x => ["two"]', 0],
    ['E ar values [one}', 0], ['E a words "q", "s"', 0], ['colors "q", "s"', 0],
    ['E s example {', 1], ['E s example { return 1 }', 0],
) {
    is !!$r->input_needs_more($case->[0]), !!$case->[1], "continuation for $case->[0]";
}

# E reserves spaced tags for definitions; EVAL always accepts literal Perl.
$r->dispatch('$_ = "red"');
$r->dispatch('E s/red/blue/');
is $r->evaluate('$_', 0), 'blue', 'unspaced substitution remains Perl under E';
$r->dispatch('EVAL s /blue/green/');
is $r->evaluate('$_', 0), 'green', 'EVAL executes spaced substitution';
like fails { $r->dispatch('E s /green/red/') }, qr/Ambiguous shorthand:.*Try EVAL/,
    'spaced substitution under a reserved E tag gives the literal Perl spelling';
is capture { $r->dispatch('say "one", "two"') }, "onetwo\n", 'Perl keywords are never implicit destination names';
$r->dispatch('EVAL sub colors { say join q{:}, @_ }');
is capture { $r->dispatch('colors "red", "blue"') }, "red:blue\n", 'existing functions take precedence over implicit lists';
$r->dispatch('E! a colors green');
is_deeply $r->evaluate('\@colors', 0), ['green'], 'explicit type resolves a destination/function collision';
$r->dispatch('EVAL sub ar { say $_[0] }');
is capture { $r->dispatch('EVAL ar "literal"') }, "literal\n", 'literal EVAL bypasses shorthand tags';
$r->dispatch('EVAL sub proto ($) { 2 * $_[0] }');
is $r->evaluate('proto 21', 0), 42, 'literal definitions retain native prototype parsing';

capture { $r->dispatch('A') };
$r->dispatch('E a live one, two');
is_deeply $r->evaluate('\@live', 0), [qw(one two)], 'explicit shorthand executes during AUTO';
ok $r->{auto}, 'immediate shorthand leaves AUTO active';
like fails { $r->dispatch('other one, two') }, qr/List shorthand is immediate input/, 'implicit shorthand cannot quietly become invalid stored source';
is_deeply [$r->numbers], [], 'shorthand never adds source rows during AUTO';
$r->dispatch('10 a one, two');
is $r->source, "a one, two;\n", 'numbered source stays literal Perl';
capture { $r->dispatch('A0') };
done_testing;
