use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd abs_path);
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
{
    package ShortcutEditor;
    our @ISA = ('App::AnteREPL');
    sub _edit_text { $_[0]{edited_name} = $_[2]; return $_[0]{edited_text}; }
    package ShortcutScreen;
    sub clear_display { ++$_[0]{cleared} }
    sub recover_display { ++$_[0]{recovered} }
    sub list_rows { $_[0]{listed} = [@_[1..$#_]] }
    package ShortcutPeek;
    our @ISA = ('App::AnteREPL');
    sub inspect_value { $_[0]{peek} = [$_[1], $_[2]] }
}

my $dir = tempdir(CLEANUP=>1);
my $r = ShortcutEditor->new;
$r->dispatch('E sub triple { 3 * shift }');
is capture { $r->dispatch('E say triple 14') }, "42\n", 'E evaluates ordinary Perl';
is capture { $r->dispatch('F') }, "triple\n", 'F lists workspace functions';
like capture { $r->dispatch('A 5 5') }, qr/AUTO 5, step 5/, 'A starts AUTO';
capture { $r->dispatch('A1') };
ok $r->{auto_echo}, 'A1 enables numbered echo';
is capture { $r->dispatch('say "one"') }, "5 say \"one\";\n", 'AUTO echo preference takes effect';
capture { $r->dispatch('A2') };
is capture { $r->dispatch('say "two"') }, '', 'A2 disables numbered echo';
is capture { $r->dispatch('E say "immediate"') }, "immediate\n", 'E bypasses AUTO storage';
is_deeply [$r->numbers], [5,10], 'E leaves source intact';
capture { $r->dispatch('A0') };
ok !$r->{auto}, 'A0 ends AUTO';
like capture { $r->dispatch('S1') }, qr/2 lines; unsaved changes/, 'S1 reports status';
is capture { $r->dispatch('R') }, "one\ntwo\n", 'R runs stored source';
is capture { $r->dispatch('L 5') }, "5 say \"one\";\n", 'L accepts a separated line number';
my $screen = bless {}, 'ShortcutScreen';
$r->{screen} = $screen;
$r->dispatch('L2 5-10');
is_deeply $screen->{listed}, [['5  say "one";', '10 say "two";'],2,'slow'], 'L2 puts its range before SLOW';
$r->dispatch('L3 10-');
is_deeply $screen->{listed}, [['10 say "two";'],2,'pause'], 'L3 preserves open-ended ranges and PAUSE';
$r->dispatch('C!'); $r->dispatch('R3!');
is $screen->{cleared}, 1, 'C clears the screen';
is $screen->{recovered}, 1, 'R3 requests screen recovery';
$r->dispatch('H');
is $screen->{listed}[2], 'pause', 'H retains paged HELP';
is $screen->{listed}[3], 'HELP', 'H keeps the HELP listing label';
delete $r->{screen};
capture { $r->dispatch('R1! 20 20') };
is_deeply [$r->numbers], [20,40], 'R1 renumbers with supplied start and step';
$r->dispatch('D1! 20');
is_deeply [$r->numbers], [40], 'D1 deletes source';
capture { $r->dispatch('U!') };
is_deeply [$r->numbers], [20,40], 'U restores the prior source edit';
capture { $r->dispatch(qq{S "$dir/test file.pl"}) };
ok !$r->dirty, 'S saves and marks source clean';
$r->dispatch('N!');
is_deeply [$r->numbers], [], 'N clears saved source';
capture { $r->dispatch(qq{L1 "$dir/test file.pl"}) };
is capture { $r->dispatch('R') }, "one\ntwo\n", 'L1 loads a quoted path';
$r->dispatch('50 say "dirty"');
for my $input ('N', 'Q', qq{L1 "$dir/test file.pl"}, qq{I "$dir/test file.pl"}) {
    like fails { $r->dispatch($input) }, qr/Confirmation required/, "$input retains its unsaved-source guard";
}
capture { $r->dispatch(qq{L1! "$dir/test file.pl"}) };
ok !$r->dirty, 'L1! deliberately replaces unsaved source';
capture { $r->dispatch(qq{I! "$dir/test file.pl"}) };
ok !defined $r->{filename} && $r->dirty, 'I! imports an unsaved copy without a save destination';
capture { $r->dispatch(qq{E2 "$dir/export.pl"}) };
like App::AnteREPL::_read_text("$dir/export.pl"), qr/use strict;.*say "one"/s, 'E2 exports standalone Perl';
$r->{edited_text} = "say \"editor\";\n";
capture { $r->dispatch('E1!') };
is $r->{edited_name}, 'program.pl', 'E1 opens the program editor';
is $r->source, "say \"editor\";\n", 'E1 replaces source with editor result';
is capture { $r->dispatch('D [1,2]') }, "\$VAR1 = [\n          1,\n          2\n        ];\n", 'D inspects a Perl expression';
my $peek = ShortcutPeek->new;
$peek->dispatch('P $value, 10');
is_deeply $peek->{peek}, ['PEEK','$value, 10'], 'P keeps the expression and traversal limit';
capture { $r->dispatch('R2!') };
is_deeply [$r->function_names], [], 'R2 clears the live workspace';
is $r->source, "say \"editor\";\n", 'R2 keeps source';
is $r->dispatch('Q!'), 0, 'Q! deliberately exits with unsaved source';
$r->dispatch('N!');
like fails { $r->dispatch('Q') }, qr/Confirmation required/, 'Q confirms even when source is clean';
for my $bad ('R!', 'C1!', 'E!', 'A0!', 'D!', 'P!', 'L!', 'F!', 'H!', 'S1!') {
    like fails { $r->dispatch($bad) }, qr/suffix/, "$bad does not acquire a force behavior";
}

{
    local %ENV = (START=>'original', S=>'variable named S');
    my $v = ShortcutEditor->new;
    is capture { $v->dispatch('V S') }, "S=\"variable named S\"\n", 'V does not reserve short subcommand names as environment keys';
    $v->dispatch('V1 Mixed "hello world"');
    is $ENV{Mixed}, 'hello world', 'V1 retains literal value quoting and case';
    like capture { $v->dispatch('V') }, qr/Mixed="hello world"/, 'V lists the environment';
    capture { $v->dispatch(qq{V4 "$dir/test.env"}) };
    $v->dispatch('V2! Mixed');
    ok !exists $ENV{Mixed}, 'V2 removes the variable';
    capture { $v->dispatch(qq{V5 "$dir/test.env"}) };
    is $ENV{Mixed}, 'hello world', 'V5 loads a snapshot';
    $v->dispatch('V1! Mixed changed');
    capture { $v->dispatch('V6!') };
    is $ENV{Mixed}, 'hello world', 'V6 reloads the remembered snapshot';
    $v->{edited_text} = "ONLY=edited\n";
    capture { $v->dispatch('V3!') };
    is $v->{edited_name}, 'environment.env', 'V3 opens the environment editor';
    is_deeply \%ENV, {ONLY=>'edited'}, 'V3 replaces the environment from editor text';
    capture { $v->dispatch('V0!') };
    is_deeply \%ENV, {START=>'original',S=>'variable named S'}, 'V0 restores the startup environment';
}

my $original = getcwd;
END { chdir $original if defined $original }
$r->dispatch(qq{C1 "$dir"});
is getcwd(), abs_path($dir), 'C1 changes the actual working directory';
chdir $original or die $!;
ok !$r->input_needs_more('C1 "unfinished'), 'directory shortcut retains command argument grammar';
ok $r->input_needs_more('E do {'), 'E supports normal multiline Perl';
ok !$r->input_needs_more('L1 path['), 'file shortcut does not enter Perl continuation';
like fails { $r->dispatch('L10') }, qr/Bareword/, 'L10 is not interpreted as LOAD or LIST 10';
is fails { $r->dispatch('e1') }, "REPL commands must be uppercase; try, \"E1\".\n", 'lowercase shortcut receives quoted uppercase hint';
$r->dispatch('EVAL sub e { say "ordinary function" }');
is capture { $r->dispatch('e') }, "ordinary function\n", 'lowercase function e is still Perl';
done_testing;
