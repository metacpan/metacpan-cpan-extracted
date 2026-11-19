use 5.016;
use strict;
use warnings;
use Test::More;
use FindBin;
use Cwd qw(abs_path);
use lib "$FindBin::Bin/../lib";
use App::AnteREPL;
my $script = abs_path("$FindBin::Bin/../script/anterepl");

sub capture (&) {
    my ($code) = @_;
    my $output = '';
    open my $fh, '>', \$output or die $!;
    local *STDOUT = $fh;
    $code->();
    return $output;
}

{
    package TestScreen;
    our @ISA = ('App::AnteREPL::Screen');
    sub key { shift @{ $_[0]{keys} } || 'EOF' }
    sub feed { my ($self, @keys) = @_; $self->{keys} = \@keys; return $self->read_entry; }
}
sub typing { map { ['TEXT', $_] } split //, $_[0] }

my $repl = App::AnteREPL->new;
$repl->dispatch('$FOO={bar=>1};');
my $dump = capture { $repl->dispatch('DUMP $FOO') };
like $dump, qr/\$VAR1 = \{/, 'dump uses Data::Dumper output';
like $dump, qr/'bar' => 1/, 'dump sees current workspace';
{
    local %ENV = (PERL_ANTE_REPL_TEST => 'visible');
    like capture { $repl->dispatch('DUMP \%ENV') }, qr/'PERL_ANTE_REPL_TEST' => 'visible'/, 'dump accepts an environment reference';
}
like capture { $repl->dispatch('DUMP [1, 2];') }, qr/1,\s+2/s, 'dump accepts expressions, optional semicolon';
my $peek = capture { $repl->dispatch('PEEK $FOO') };
like $peek, qr/SV = /, 'peek uses Devel::Peek';
like $peek, qr/FLAGS = \(ROK\)/, 'peek sees a reference scalar';
like $peek, qr/PVHV/, 'peek follows the hash reference';
like $peek, qr/Elt "bar"/, 'peek inspects actual contents';
like $peek, qr/REFCNT = 1/, 'peek does not add an artificial reference to the named scalar';
like capture { $repl->dispatch('PEEK $FOO, 10;') }, qr/IV = 1/, 'peek accepts the optional depth/element limit';
my $failed = eval { $repl->dispatch('PEEK my $x = ;'); 1 };
ok !$failed, 'peek syntax errors are reported';
like capture { $repl->dispatch('say "still works"') }, qr/still works/, 'stdout restored after failed peek';

for my $code ('$FOO = {', '$FOO = {bar => [1,', 'say "open', 'say q{open', '($x +') {
    ok App::AnteREPL::needs_more($code), "continue incomplete input: $code";
}
for my $code ('$FOO = {bar=>[1,2]}', 'say "{[()]"', 'say q{nested {braces}}',
    '$FOO = { # } ignored', '10 if (1) {', '10: my $x = [', 'EDIT', '! echo "{"',
    'say $#array', '$FOO = {bar => 1}; # [', 'say 12 / 4', '$x =~ /[{}]/') {
    if ($code eq '$FOO = { # } ignored') { ok App::AnteREPL::needs_more($code), 'comments do not close a data structure'; }
    else { ok !App::AnteREPL::needs_more($code), "complete/special input: $code"; }
}
ok !App::AnteREPL::needs_more('$x = {]'), 'mismatched delimiters are handed to Perl for an error';

my $screen = TestScreen->new;
my $line = $screen->feed(typing('10 say "first"'), 'ENTER');
is $line, '10 say "first"', 'screen submits typed row without a prompt';
$repl->dispatch($line);
$screen->append($repl->listing);
is $screen->{rows}[1]{text}, '10 say "first";', 'LIST output is part of editable screen memory';
$line = $screen->feed('UP', 'END', ('LEFT') x 3, ['TEXT','!'], 'ENTER');
is $line, '10 say "firs!t";', 'moving up inserts into the actual displayed output row by default';
is capture { $repl->run }, "first\n", 'editing the screen alone does not update stored source';
$repl->dispatch($line);
is capture { $repl->run }, "firs!t\n", 'Enter resubmission changes stored source';

my $multi = TestScreen->new;
my $definition = $multi->feed(typing('$FOO = {'), 'ENTER', typing('bar => 2,'), 'ENTER',
    typing('names => [qw(Alice Bob)],'), 'ENTER', typing('};'), 'ENTER');
is $definition, "\$FOO = {\nbar => 2,\nnames => [qw(Alice Bob)],\n};", 'open delimiters join consecutive screen rows';
$repl->dispatch($definition);
is $repl->evaluate('$FOO->{bar}', 0), 2, 'complete multiline definition evaluates';
is $repl->evaluate('$FOO->{names}[1]', 0), 'Bob', 'nested data structure preserved';
my $again = $multi->feed('UP', 'UP', 'UP', 'HOME', ('RIGHT') x 7, ['TEXT','3'], 'ENTER');
like $again, qr/bar => 32,/, 'an earlier multiline entry inserts text without overwriting';
$repl->dispatch($again);
is $repl->evaluate('$FOO->{bar}', 0), 32, 'resubmission evaluates the whole earlier entry';

my $paste = TestScreen->new;
{
    my $typed = TestScreen->new;
    my $r = App::AnteREPL->new;
    $typed->{repl} = $r;
    for my $case (
        ['$_ = "red"', ''],
        ['EVAL s /red/blue/', ''],
        ['say $_', "blue\n"],
        ['E sub ar ($) { say $_[0] }', ''],
        ['EVAL ar "ordinary call"', "ordinary call\n"],
        ['say join q{:}, qw(one two)', "one:two\n"],
        ['E sub twice ($) { 2 * $_[0] }', ''],
        ['say twice 21', "42\n"],
        ['CLS', ''],
    ) {
        my ($code, $expected) = @$case;
        my $entry = $typed->feed(typing($code), 'ENTER');
        is $entry, $code, "single Enter submits QA entry: $code";
        next unless defined $entry;
        is capture { $r->dispatch($entry) }, $expected, "QA entry result: $code";
    }
}
{
    my $typed = TestScreen->new;
    my $r = App::AnteREPL->new;
    $typed->{repl} = $r;
    my $entry = $typed->feed(typing('EVAL sub triple {'), 'ENTER',
        typing('    return 3 * shift;'), 'ENTER', typing('}'), 'ENTER');
    is $entry, "EVAL sub triple {\n    return 3 * shift;\n}",
        'ordinary Enter on a closing subroutine brace completes the typed EVAL';
    is capture { $r->dispatch($entry) }, '', 'successful subroutine definition is silent';
    my $call = $typed->feed(typing('say triple(14)'), 'ENTER');
    is $call, 'say triple(14)', 'next typed command is outside the EVAL group';
    is capture { $r->dispatch($call) }, "42\n", 'the typed subroutine is callable immediately';
    is $r->source, '', 'session function definition and call leave VRAM empty';

    capture { $r->dispatch('AUTO') };
    $entry = $typed->feed(typing('EVAL sub from_auto {'), 'ENTER',
        typing('    return 7 * shift;'), 'ENTER', typing('}'), 'ENTER');
    capture { $r->dispatch($entry) };
    ok $r->{auto}, 'closing EVAL does not leave AUTO';
    $call = $typed->feed(typing('say from_auto(6)'), 'ENTER');
    is capture { $r->dispatch($call) }, '', 'ordinary call after EVAL is stored quietly during AUTO';
    is $r->listing('5'), "5 say from_auto(6);\n", 'quiet input was stored outside the completed EVAL block';
    capture { $r->dispatch($typed->feed(typing('AUTO OFF'), 'ENTER')) };
    is capture { $r->dispatch($typed->feed(typing('say from_auto(6)'), 'ENTER')) }, "42\n",
        'AUTO OFF makes the same function call execute immediately';
}
my $pasted = $paste->feed(['PASTE', "\$FOO = {\nbar => 8,\n};"], 'ENTER');
is $pasted, "\$FOO = {\nbar => 8,\n};", 'multiline paste waits for Enter and remains a single entry';
my $editing = TestScreen->new;
$editing->feed(typing('abc'), 'HOME', ['TEXT','x'], 'DELETE', 'END', 'BACKSPACE', 'ENTER');
is $editing->{rows}[0]{text}, 'xb', 'insert, delete and backspace edit displayed text';
$editing->append("one\r\ntwo\r\n");
is $editing->{rows}[-2]{text}, 'two', 'CRLF output remains visible';
$editing->append("line $_\n") for 1 .. 30;
is $editing->{rows}[-2]{text}, 'line 30', 'new output advances display rows';
$editing->{height} = 6;
$editing->edit_key('PAGEUP');
is $editing->{rows}[ $editing->{row} ]{text}, 'line 26', 'PageUp navigates screen rows rather than command history';
$editing->edit_key('BOTTOM');
is $editing->{rows}[ $editing->{row} ]{text}, '', 'bottom returns to a blank row';

{
    my $left = TestScreen->new;
    $left->append("first\n\nthird\n");
    my @before = map { $_->{text} } @{ $left->{rows} };
    $left->edit_key('LEFT');
    is_deeply [@{$left}{qw(row col)}], [2, 5], 'Left from a fresh row reaches the end of the preceding text';
    $left->edit_key('HOME');
    $left->edit_key('LEFT');
    is_deeply [@{$left}{qw(row col)}], [1, 0], 'Left visits an empty preceding row without skipping it';
    $left->edit_key('LEFT');
    is_deeply [@{$left}{qw(row col)}], [0, 5], 'another Left crosses the empty row to the earlier text end';
    $left->edit_key('LEFT');
    is_deeply [@{$left}{qw(row col)}], [0, 4], 'Left within a row still moves one character';
    $left->edit_key('HOME');
    $left->edit_key('LEFT') for 1 .. 3;
    is_deeply [@{$left}{qw(row col)}], [0, 0], 'Left stops at the first retained row';
    is_deeply [map { $_->{text} } @{ $left->{rows} }], \@before, 'Left navigation never edits or joins rows';

    my $block = $left->feed('BOTTOM', ['PASTE', "EVAL do {\nsay 1;\n}"],
        'HOME', 'LEFT', typing(' say 2;'), 'ENTER');
    is $block, "EVAL do {\nsay 1; say 2;\n}", 'Left crosses a multiline entry boundary and editing retains the whole group';
    is capture { $repl->dispatch($block) }, "1\n2\n", 'the edited multiline entry remains executable';
}

my $cancel = TestScreen->new;
$cancel->feed(typing('$bad = {'), 'ENTER', 'EOF');
$cancel->fresh;
my $next = $cancel->feed(typing('say 7'), 'ENTER');
is $next, 'say 7', 'cancelled continuation cannot absorb the next entry';

{
    package ByteScreen;
    our @ISA = ('App::AnteREPL::Screen');
    sub byte { return shift @{ $_[0]{bytes} }; }
}
my $keyboard = ByteScreen->new;
for my $sequence ("\e[13;2u", "\e[13;2:1u", "\e[13;2:2u", "\e[27;2;13~", "\x0e") {
    $keyboard->{bytes} = [split //, $sequence];
    is $keyboard->key, 'NEWLINE', 'modified Enter / Ctrl-N decodes as newline';
}
$keyboard->{bytes} = [split //, "\e[13;2:3u"];
is $keyboard->key, 'IGNORE', 'Shift+Enter key release does not insert a second newline';
$keyboard->{bytes} = ["\r"];
is $keyboard->key, 'ENTER', 'ordinary Enter remains submit';
$keyboard->{bytes} = ["\x04"];
is $keyboard->key, 'ENDINPUT', 'Ctrl-D is distinct from terminal disconnect';
$keyboard->{bytes} = [];
is $keyboard->key, 'EOF', 'terminal disconnect remains EOF';

my $split = TestScreen->new;
my $block = $split->feed(typing('EVAL do { say 1; };'), 'HOME', ('RIGHT') x 10,
    'NEWLINE', typing('say 2; '), 'ENTER');
is $block, "EVAL do { \nsay 2; say 1; };", 'insert newline splits a complete entry without submitting';
is capture { $repl->dispatch($block) }, "2\n1\n", 'split entry executes together';
my $mid = $split->feed('UP', 'HOME', 'NEWLINE', 'ENTER');
is $mid, "EVAL do { \n\nsay 2; say 1; };", 'inserting a blank row retains the entire earlier group';
is capture { $repl->dispatch($mid) }, "2\n1\n", 'submission from the middle evaluates the complete group';

my $auto_end = TestScreen->new;
my $auto_repl = App::AnteREPL->new;
$auto_end->{repl} = $auto_repl;
capture { $auto_repl->dispatch('AUTO') };
$auto_repl->dispatch('say "kept"');
my $stop = $auto_end->feed(typing('$unfinished = {'), 'ENTER', 'ENDINPUT');
is $stop, 'AUTO OFF', 'Ctrl-D cancels incomplete AUTO input by ending AUTO';
capture { $auto_repl->dispatch($stop) };
ok !$auto_repl->{auto}, 'Ctrl-D leaves AUTO';
is $auto_repl->source, "say \"kept\";\n", 'Ctrl-D preserves completed source and drops unfinished input';
is $auto_end->feed(typing('say "immediate"'), 'ENTER'), 'say "immediate"', 'fresh entry after Ctrl-D does not join cancelled group';
is $auto_end->feed('ENDINPUT'), undef, 'Ctrl-D outside AUTO retains normal exit behavior';

{
    local %ENV = (ANTEREPL_CLS => 'retained');
    my $r = App::AnteREPL->new;
    $r->dispatch('10 say "retained program"');
    $r->dispatch('$value = 42');
    $r->{filename} = 'retained.pl';
    capture { $r->dispatch('AUTO 15') };
    my $s = TestScreen->new;
    $r->{screen} = $s;
    $s->append("old output\n" x 40);
    $s->{left} = 10;
    $s->{top} = 30;
    is capture { $r->dispatch('CLS') }, '', 'CLS clears without a message';
    is_deeply $s->{rows}, [{text=>''}], 'CLS removes retained display rows';
    is_deeply [@{$s}{qw(row col top left)}], [0, 0, 0, 0], 'CLS returns to top left';
    $s->edit_key('TOP');
    is $s->{rows}[$s->{row}]{text}, '', 'old display text cannot be revisited';
    is capture { $r->dispatch('RUN') }, "retained program\n", 'CLS retains runnable VRAM';
    is $r->evaluate('$value', 0), 42, 'CLS retains live Perl variables';
    is $ENV{ANTEREPL_CLS}, 'retained', 'CLS retains environment';
    is $r->{filename}, 'retained.pl', 'CLS retains save filename';
    ok $r->dirty, 'CLS retains unsaved status';
    is_deeply $r->{auto}, {next=>15, step=>5}, 'CLS retains AUTO position';
    $r->dispatch('say "next line"');
    is $r->{lines}{15}, 'say "next line";', 'AUTO continues after CLS';
    $r->undo;
    $r->undo;
    is $r->source, '', 'CLS preserves earlier source undo without adding an edit';
    for my $bad ('CLS extra', 'CLS!') {
        ok !eval { $r->dispatch($bad); 1 }, "$bad is rejected";
    }
    ok !App::AnteREPL::needs_more('CLS {'), 'CLS errors do not start Perl continuation';
    delete $r->{screen};
    is capture { $r->dispatch('CLS') }, '', 'CLS emits no escapes to redirected output';
}

sub screen_run {
    my ($screen, $repl, @keys) = @_;
    $screen->{repl} = $repl;
    my $entry = $screen->feed(@keys);
    {
        local *STDOUT;
        local *STDERR;
        local *STDIN;
        tie *STDOUT, 'App::AnteREPL::ScreenOutput', $screen;
        tie *STDERR, 'App::AnteREPL::ScreenOutput', $screen;
        tie *STDIN, 'App::AnteREPL::ScreenInput', $screen;
        eval { $repl->dispatch($entry); 1 } or print STDERR $@;
    }
    $screen->fresh;
    return $entry;
}
sub screen_rows { [map { $_->{text} } @{ $_[0]{rows} }] }

{
    my $s = TestScreen->new;
    my $r = App::AnteREPL->new;
    $r->dispatch('EVAL sub triple { 3 * shift }');
    screen_run($s, $r, typing('say triple(14)'), 'ENTER');
    is_deeply screen_rows($s), ['say triple(14)', '42', ''], 'result sits directly below its input';
    screen_run($s, $r, 'UP', 'UP', 'END', 'LEFT', 'BACKSPACE', 'BACKSPACE', typing('3'), 'ENTER');
    is_deeply screen_rows($s), ['say triple(3)', '9', ''], 'editing and rerunning replaces the prior result';
    screen_run($s, $r, 'UP', 'UP', 'ENTER') for 1 .. 3;
    is_deeply screen_rows($s), ['say triple(3)', '9', ''], 'repeated Enter does not accumulate results or blank rows';
    screen_run($s, $r, typing('say "later"'), 'ENTER');
    screen_run($s, $r, 'TOP', 'END', 'LEFT', 'BACKSPACE', typing('7'), 'ENTER');
    is_deeply screen_rows($s), ['say triple(7)', '21', 'say "later"', 'later', ''],
        'replacing an earlier result preserves subsequent input and output without a spacer';
    is_deeply [@{$s}{qw(row col)}], [2, 0], 'cursor follows the result onto the intact next command';
    $s->edit_key('BOTTOM');
    is $s->{row}, 4, 'Ctrl-End still reaches the bottom after an earlier resubmission';
    is $r->source, '', 'screen replacement does not store or erase program source';

    my $toggle = TestScreen->new;
    is $toggle->feed(typing('abc'), 'HOME', 'INSERT', typing('X'), 'INSERT', typing('Y'), 'ENTER'),
        'XYbc', 'Insert toggles overwrite on and back to insertion';
}

{
    my $s = TestScreen->new;
    my $r = App::AnteREPL->new;
    $r->dispatch('$n = 3');
    my $code = "EVAL do {\nsay for 1 .. \$n;\n}";
    screen_run($s, $r, ['PASTE', $code], 'ENTER');
    screen_run($s, $r, typing('say "keep"'), 'ENTER');
    $r->dispatch('$n = 1');
    screen_run($s, $r, 'TOP', 'DOWN', 'ENTER');
    is_deeply screen_rows($s), ['EVAL do {', 'say for 1 .. $n;', '}', '1', 'say "keep"', 'keep', ''],
        'resubmitting from the middle of a block replaces all of its longer old output';
    $r->dispatch('$n = 0');
    screen_run($s, $r, 'TOP', 'ENTER');
    is_deeply screen_rows($s), ['EVAL do {', 'say for 1 .. $n;', '}', 'say "keep"', 'keep', ''],
        'a silent rerun removes obsolete results without removing later entries';
    screen_run($s, $r, 'TOP', 'END', 'NEWLINE', typing('say "added";'), 'ENTER');
    is_deeply screen_rows($s), ['EVAL do {', 'say "added";', 'say for 1 .. $n;', '}', 'added', 'say "keep"', 'keep', ''],
        'splitting a previously submitted entry retains its output association';
}

{
    my $s = TestScreen->new;
    my $r = App::AnteREPL->new;
    my $code = q{die "failed\n" if $fail; print "prefix"; print $suffix};
    $r->dispatch(q{$suffix = 'long'});
    screen_run($s, $r, typing($code), 'ENTER');
    is_deeply screen_rows($s), [$code, 'prefixlong', ''], 'partial writes share a result row without a final newline';
    screen_run($s, $r, typing('say "keep"'), 'ENTER');
    $r->dispatch(q{$suffix = 'x'});
    screen_run($s, $r, 'TOP', 'ENTER');
    is_deeply screen_rows($s), [$code, 'prefixx', 'say "keep"', 'keep', ''],
        'shorter output clears the old line suffix';
    $r->dispatch('$fail = 1');
    screen_run($s, $r, 'TOP', 'ENTER');
    is_deeply screen_rows($s), [$code, 'failed', 'say "keep"', 'keep', ''],
        'errors replace prior results at the same position';
    $r->dispatch('$fail = 0');
    screen_run($s, $r, 'TOP', 'ENTER');
    is $s->{rows}[1]{text}, 'prefixx', 'successful rerun replaces the old error';
}

{
    my $s = TestScreen->new;
    my $r = App::AnteREPL->new;
    my $code = q{print "Name: "; chomp($name = <STDIN>); say "Hi $name"};
    screen_run($s, $r, typing($code), 'ENTER', typing('Alice'), 'ENTER');
    screen_run($s, $r, typing('say "keep"'), 'ENTER');
    screen_run($s, $r, 'TOP', 'ENTER', 'LEFT', typing('Bob'), 'ENTER');
    is_deeply screen_rows($s), [$code, 'Name: Bob', 'Hi Bob', 'say "keep"', 'keep', ''],
        'program STDIN and prompts stay beside a rerun entry with later rows present';
}

{
    my $s = TestScreen->new;
    my $r = App::AnteREPL->new;
    $r->{screen} = $s;
    $r->dispatch('5     say "indented"');
    $r->dispatch('10 say "other"');
    screen_run($s, $r, typing('LIST'), 'ENTER');
    screen_run($s, $r, typing('say "keep"'), 'ENTER');
    screen_run($s, $r, 'TOP', 'ENTER');
    is_deeply screen_rows($s), ['LIST', '5      say "indented";', '10 say "other";', 'say "keep"', 'keep', ''],
        'LIST resubmission replaces its listing while retaining later entries';
    my $source = $r->source;
    screen_run($s, $r, 'UP', 'UP', 'ENTER');
    is $r->source, $source, 'LIST padding metadata survives output replacement';
    screen_run($s, $r, 'BOTTOM', typing('CLS'), 'ENTER');
    is_deeply screen_rows($s), [''], 'CLS clears output associations as well as screen rows';

    $s->append("LIST 5\n" x 40);
    screen_run($s, $r, 'TOP', 'ENTER');
    cmp_ok scalar @{ $s->{rows} }, '<=', $s->{height}, 'rerunning at the screen edge keeps only visible rows';
    is $s->{rows}[$s->{row} - 1]{text}, '5     say "indented";',
        'the newest listing row remains immediately above the cursor at the retention limit';
    ok !$s->{rows}[-1]{list_width}, 'retention trimming does not attach LIST padding to an unrelated tail row';
}

{
    my $s = TestScreen->new;
    my $r = App::AnteREPL->new;
    $r->dispatch('EVAL sub triple { 3 * shift }');
    screen_run($s, $r, typing('say triple(14)'), 'ENTER');
    screen_run($s, $r, typing('say "keep this line below"'), 'ENTER');
    screen_run($s, $r, 'TOP', 'END', 'LEFT', 'BACKSPACE', typing('3'), 'ENTER');
    my $expected = ['say triple(13)', '39', 'say "keep this line below"', 'keep this line below', ''];
    is_deeply screen_rows($s), $expected, 'changing 14 to 13 does not insert a blank before the following command';
    screen_run($s, $r, 'TOP', 'ENTER') for 1 .. 3;
    is_deeply screen_rows($s), $expected, 'repeated reruns keep the following command adjacent';
    is_deeply [@{$s}{qw(row col)}], [2, 0], 'cursor rests at the start of the preserved following command';
    screen_run($s, $r, 'ENTER');
    is_deeply screen_rows($s), $expected, 'following command remains executable with its original output association';
}

{
    my $s = TestScreen->new;
    my $r = App::AnteREPL->new;
    $r->dispatch(q{$out = "one\n\n"});
    screen_run($s, $r, typing('print $out'), 'ENTER');
    screen_run($s, $r, typing('say "keep"'), 'ENTER');
    screen_run($s, $r, 'TOP', 'ENTER');
    is_deeply screen_rows($s), ['print $out', 'one', '', 'say "keep"', 'keep', ''],
        'a blank line deliberately printed by the program is retained';
    $r->dispatch(q{$out = ''});
    screen_run($s, $r, 'TOP', 'ENTER');
    is_deeply screen_rows($s), ['print $out', 'say "keep"', 'keep', ''],
        'empty output removes old results without inserting a replacement spacer';
}

{
    my $s = TestScreen->new;
    my $r = App::AnteREPL->new;
    screen_run($s, $r, typing('say "first"'), 'ENTER');
    screen_run($s, $r, ['PASTE', "EVAL do {\nsay q(second);\n}"], 'ENTER');
    screen_run($s, $r, 'TOP', 'ENTER');
    is_deeply screen_rows($s), ['say "first"', 'first', 'EVAL do {', 'say q(second);', '}', 'second', ''],
        'a following multiline entry is preserved without a spacer';
    is screen_run($s, $r, 'DOWN', 'ENTER'), "EVAL do {\nsay q(second);\n}",
        'cursor reuse does not break the following entry grouping';
}

done_testing;
