use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use Cwd qw(abs_path);
use IPC::Open3;
use Symbol qw(gensym);

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

my $repl = App::AnteREPL->new;
$repl->dispatch('10 say "hi"');
$repl->dispatch('5 say "what is your name?"');
is $repl->listing, "5 say \"what is your name?\";\n10 say \"hi\";\n", 'reported transcript stores explicit terminators';
is capture { $repl->run }, "what is your name?\nhi\n", 'reported two-line program runs in numerical order';
$repl->dispatch('5 say "changed"');
is $repl->listing('5'), "5 say \"changed\";\n", 'replacement also supplies semicolon';
$repl->undo;
is $repl->listing('5'), "5 say \"what is your name?\";\n", 'UNDO restores normalized earlier entry';
$repl->dispatch('5');
is $repl->listing('5'), '', 'number alone still deletes';

for my $case (
    ['say "hi";', 'say "hi";', 'existing semicolon'],
    ['say "hi";  ', 'say "hi";  ', 'existing semicolon with spaces'],
    ['say "hi"  ', 'say "hi";  ', 'preserve trailing whitespace'],
    ['say "hi" # note', 'say "hi"; # note', 'semicolon before comment'],
    ['say "hi"; # note', 'say "hi"; # note', 'existing semicolon before comment'],
    ['# comment', '# comment', 'full-line comment'],
    ['  # comment', '  # comment', 'indented comment'],
    ['   ', '   ', 'whitespace-only entry'],
    ['say "# hi"', 'say "# hi";', 'hash in double-quoted string'],
    [q{say '# hi'}, q{say '# hi';}, 'hash in single-quoted string'],
    ['say "hi;"', 'say "hi;";', 'semicolon inside string is not a terminator'],
    ['say "hi#" # note', 'say "hi#"; # note', 'quoted hash followed by comment'],
    ['say q{# hello}', 'say q{# hello};', 'q literal'],
    ['say q#hello#', 'say q#hello#;', 'hash-delimited q literal'],
    ['my @a = qw(one two)', 'my @a = qw(one two);', 'qw literal'],
    ['my $r = qr/#/', 'my $r = qr/#/;', 'qr literal'],
    ['$x =~ /#/', '$x =~ /#/;', 'bare regex'],
    ['$x =~ s/#/x/g', '$x =~ s/#/x/g;', 'substitution'],
    ['say 12 / 4', 'say 12 / 4;', 'division'],
    ['say $#array', 'say $#array;', 'array last-index sigil'],
    ['say $hash{key}', 'say $hash{key};', 'hash element closing brace'],
    ['$x++', '$x++;', 'postincrement'],
    ['$x--', '$x--;', 'postdecrement'],
    ['my $h = { key => 1 }', 'my $h = { key => 1 };', 'hashref assignment'],
    ['my $f = sub { 1 }', 'my $f = sub { 1 };', 'anonymous sub assignment'],
    ['for my $n (1..3) {', 'for my $n (1..3) {', 'block opener'],
    ['if ($x) { # note', 'if ($x) { # note', 'block opener with comment'],
    ['}', '}', 'block closer'],
    ['} else {', '} else {', 'else bridge'],
    ['if ($x) { say 1 }', 'if ($x) { say 1 }', 'complete control block'],
    ['sub f { return 1 }', 'sub f { return 1 }', 'named sub definition'],
    ['my @a = (', 'my @a = (', 'parenthesized continuation'],
    ['my $a = [', 'my $a = [', 'arrayref continuation'],
    ['1,', '1,', 'comma continuation'],
    ['$x =', '$x =', 'assignment continuation'],
    ['$x +', '$x +', 'operator continuation'],
    ['say "unfinished', 'say "unfinished', 'unclosed quote'],
) {
    my ($input, $expected, $name) = @$case;
    my $subject = App::AnteREPL->new;
    $subject->dispatch("10 $input");
    is $subject->source, "$expected\n", $name;
}

my $block = App::AnteREPL->new;
$block->dispatch($_) for (
    '10 for my $n (1..3) {',
    '20 if ($n == 2) {',
    '30 say "two"',
    '40 } else {',
    '50 say $n',
    '60 }',
    '70 }',
);
is capture { $block->run }, "1\ntwo\n3\n", 'numbered loop and if/else execute without extra terminators';

my $raw = App::AnteREPL->new;
$raw->dispatch($_) for (
    q{10: my $text = <<'TEXT';},
    '20: hello',
    '30:',
    '40: TEXT',
    '50 say $text',
);
is $raw->source, "my \$text = <<'TEXT';\nhello\n\nTEXT\nsay \$text;\n", 'raw numbered lines preserve heredoc body and blank lines';
is capture { $raw->run }, "hello\n\n\n", 'raw multiline heredoc runs';
my $sum = App::AnteREPL->new;
$sum->dispatch($_) for ('10: my $sum = (', '20: 1 +', '30: 2', '40: );', '50 say $sum');
is capture { $sum->run }, "3\n", 'raw multiline expression runs';

my $dir = tempdir(CLEANUP => 1);
my $saved = "$dir/auto.bperl";
$raw->save($saved);
my $loaded = App::AnteREPL->new;
$loaded->load($saved);
is $loaded->listing, $raw->listing, 'SAVE/LOAD preserve both normalized and raw entries';
my $plain = "$dir/raw.pl";
open my $fh, '>', $plain or die $!;
print {$fh} "say \"one\"\n";
close $fh;
$loaded->import_source($plain, 1);
is $loaded->source, "say \"one\"\n", 'IMPORT does not add semicolons';
$loaded->save($saved);
my $literal = App::AnteREPL->new;
$literal->load($saved);
is $literal->source, "say \"one\"\n", 'LOAD does not rewrite old programs';

{
    local $ENV{PERL_ANTE_REPL_SEMI_EXECUTED};
    delete $ENV{PERL_ANTE_REPL_SEMI_EXECUTED};
    my $safe = App::AnteREPL->new;
    $safe->dispatch('10 BEGIN { $ENV{PERL_ANTE_REPL_SEMI_EXECUTED} = 1 }');
    ok !exists $ENV{PERL_ANTE_REPL_SEMI_EXECUTED}, 'normalization never executes BEGIN blocks';
}

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, "-I$FindBin::Bin/../lib", $script, '--quiet');
print {$in} "10 say \"hi\"\n5 say \"what is your name?\"\nLIST\nRUN\nQUIT!\n";
close $in;
my $stdout = do { local $/; <$out> };
my $stderr = do { local $/; <$err> };
waitpid $pid, 0;
is $? >> 8, 0, 'reported CLI session exits successfully';
is $stderr, '', 'reported CLI session has no syntax errors';
is $stdout, "5  say \"what is your name?\";\n10 say \"hi\";\nwhat is your name?\nhi\n\n", 'reported CLI transcript corrected and aligned';

done_testing;
