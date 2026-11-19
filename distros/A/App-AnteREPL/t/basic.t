use 5.016;
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;
use Cwd qw(abs_path);
use IPC::Open3;
use Symbol qw(gensym);

use lib "$FindBin::Bin/../lib";
use App::AnteREPL;
my $script = abs_path("$FindBin::Bin/../script/anterepl");
my $dir = tempdir(CLEANUP => 1);

sub capture (&) {
    my ($code) = @_;
    my $output = '';
    open my $fh, '>', \$output or die $!;
    local *STDOUT = $fh;
    $code->();
    return $output;
}

sub fails (&) {
    my ($code) = @_;
    local $@;
    eval { $code->(); 1 };
    return $@;
}

sub put {
    my ($path, $bytes) = @_;
    open my $fh, '>:raw', $path or die $!;
    print {$fh} $bytes or die $!;
    close $fh or die $!;
}

sub cli {
    my ($input, @args) = @_;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $^X, "-I$FindBin::Bin/../lib", $script, '--quiet', @args);
    print {$in} $input;
    close $in;
    local $/;
    my $stdout = <$out>;
    my $stderr = <$err>;
    waitpid $pid, 0;
    return ($stdout, $stderr, $? >> 8);
}

my $repl = App::AnteREPL->new;
ok !$repl->dirty, 'new program is clean';
$repl->set_line(90, 'say $x;');
$repl->set_line(10, '$x += 2;');
is $repl->listing, "10 \$x += 2;\n90 say \$x;\n", 'LIST sorts numerically';
is $repl->listing('11-'), "90 say \$x;\n", 'open-ended range';
is $repl->listing('-10'), "10 \$x += 2;\n", 'range to a number';
is $repl->listing('90'), "90 say \$x;\n", 'one line';
like fails { $repl->listing('90-10') }, qr/starts after/, 'reject reversed range';
ok $repl->dirty, 'insertion is unsaved';
is $repl->evaluate('$x = 40;', 0), 40, 'immediate assignment';
is capture { $repl->run }, "42\n", 'RUN uses immediate workspace';
is $repl->evaluate('$x', 0), 42, 'RUN result state visible at prompt';
$repl->evaluate('our @items = (1,2); our %data = (a => 3); sub twice { 2 * $_[0] }', 0);
is $repl->evaluate('twice($items[1] + $data{a})', 0), 10, 'arrays, hashes and functions persist';
$repl->evaluate('my $private = 99;', 0);
ok !defined $repl->evaluate('$private', 0), 'my remains local to one evaluation';
like fails { $repl->evaluate('die "deliberate\n";', 0) }, qr/deliberate/, 'exceptions reported';
is $repl->evaluate('$x', 0), 42, 'exceptions leave workspace usable';
my $other = App::AnteREPL->new;
ok !defined $other->evaluate('$x', 0), 'independent sessions have separate variables';
$repl->reset_workspace;
ok !defined $repl->evaluate('$x', 0), 'RESET starts fresh variable namespace';
is_deeply [$repl->numbers], [10, 90], 'RESET keeps program';

$repl->set_line(10, '$x = 100;');
like $repl->listing, qr/^10 \$x = 100;/, 'replace existing line';
$repl->set_line(90, undef);
is $repl->listing, "10 \$x = 100;\n", 'number alone deletes';
$repl->undo;
is $repl->listing('90'), "90 say \$x;\n", 'UNDO restores deleted line';
$repl->renumber(100, 25);
is $repl->listing, "100 \$x = 100;\n125 say \$x;\n", 'custom renumbering';
$repl->undo;
like $repl->listing, qr/^10 /, 'UNDO restores original numbers';
my $before = $repl->listing;
like fails { $repl->renumber(999999999, 1) }, qr/exceed/, 'renumber overflow rejected';
is $repl->listing, $before, 'overflow is atomic';
for my $invalid (0, -1, '2.5', 'x', 1000000000) {
    like fails { $repl->set_line($invalid, '1;') }, qr/Line numbers/, "reject line $invalid";
}
$repl->delete_range('10-90');
is $repl->source, '', 'DEL range removes all matching lines';
$repl->undo;
is $repl->listing, $before, 'range delete is one undo step';

my $saved = "$dir/saved program.bperl";
is $repl->save($saved), $saved, 'save with a space in filename';
ok !$repl->dirty, 'saved program is clean';
$repl->set_line(50, '# changed');
$repl->save;
ok !$repl->dirty, 'SAVE remembers filename';
$repl->undo;
ok $repl->dirty, 'UNDO after SAVE makes program dirty';
like fails { $repl->load($saved) }, qr/Unsaved program/, 'LOAD protects unsaved source';
$repl->load($saved, 1);
ok !$repl->dirty, 'forced LOAD is clean';
like $repl->listing, qr/^50 # changed$/m, 'save and load preserve numbering';
my $saved_before = App::AnteREPL::_read_text($saved);
my $target_dir = "$dir/not-a-file";
mkdir $target_dir or die $!;
like fails { $repl->save($target_dir) }, qr/Cannot replace/, 'failed write is reported';
is App::AnteREPL::_read_text($saved), $saved_before, 'failed write preserves earlier saved file';
is $repl->{filename}, $saved, 'failed write does not alter filename';

for my $case (
    ['duplicate', "# PERL ANTE REPL V0.1\n10 1;\n10 2;\n", qr/Duplicate/],
    ['malformed', "# PERL ANTE REPL V0.1\ninvalid\n", qr/Invalid numbered/],
    ['plain', "say 1;\n", qr/ordinary Perl source/],
    ['zero', "# PERL ANTE REPL V0.1\n0 1;\n", qr/Line numbers/],
) {
    my ($name, $content, $error) = @$case;
    my $path = "$dir/$name.bperl";
    put($path, $content);
    my $snapshot = $repl->listing;
    like fails { $repl->load($path, 1) }, $error, "$name input rejected";
    is $repl->listing, $snapshot, "$name input preserves program";
}

my $raw = "$dir/source.pl";
put($raw, "my \$x = 5;\n\nsay \$x;\n");
$repl->import_source($raw, 1);
is $repl->listing, "10 my \$x = 5;\n20 \n30 say \$x;\n", 'IMPORT preserves blank lines';
is capture { $repl->run }, "5\n", 'lexicals span the complete RUN';
$repl->save($saved);
$other->load($saved, 1);
is $other->source, $repl->source, 'blank lines round trip through numbered format';

put($raw, "my \$message = <<'END_TEXT';\nhello\n\nworld\nEND_TEXT\nsay \$message;\n");
$repl->import_source($raw, 1);
is capture { $repl->run }, "hello\n\nworld\n\n", 'RUN preserves heredoc content and blank lines';
$repl->set_line(100, 'die "oops";');
like fails { capture { $repl->run } }, qr/at stored line 100 \(source line 7\)/, 'runtime error maps back to stored number';
$repl->set_line(100, 'my $broken = ;');
like fails { $repl->run }, qr/at stored line 100/, 'syntax error maps to stored number';

my $editor = "$dir/fake editor.pl";
put($editor, <<'EDITOR');
use strict;
use warnings;
my ($mode, $path) = @ARGV;
die "wrong number of arguments" unless @ARGV == 2;
die "expected .pl temporary file" unless $path =~ /program\.pl$/;
open my $in, '<:raw', $path or die $!;
local $/;
my $before = <$in>;
close $in;
die "unexpected numbered source" if $before =~ /^\d+ /m;
exit 0 if $mode eq 'unchanged';
if ($mode eq 'missing') { unlink $path or die $!; exit 0; }
open my $out, '>:raw', $path or die $!;
if ($mode eq 'change' || $mode eq 'failure') { print {$out} "my \$answer = 6 * 7;\n\nsay \$answer;\n"; }
elsif ($mode eq 'invalid') { print {$out} "\xff\xfe"; }
elsif ($mode eq 'nul') { print {$out} "say 1;\0\n"; }
elsif ($mode eq 'empty') { }
elsif ($mode eq 'crlf') { print {$out} "say 'first';\r\n\r\nsay 'last';\r\n"; }
elsif ($mode eq 'unfinished') { print {$out} "BEGIN { \$ENV{PERL_ANTE_REPL_TEST_BEGIN} = 1 }\nmy \$unfinished =\n"; }
else { die "unknown mode $mode"; }
close $out or die $!;
exit($mode eq 'failure' ? 17 : 0);
EDITOR

my $edit = App::AnteREPL->new;
$edit->set_line(7, 'say "old";');
$edit->set_line(103, '# old last line');
my $original = $edit->listing;
{
    local $ENV{EDITOR} = qq{"$^X" "$editor" unchanged};
    is $edit->edit, 0, 'unchanged editor reports no change';
    is $edit->listing, $original, 'unchanged editor preserves sparse numbering';
}
{
    local $ENV{EDITOR} = qq{"$^X" "$editor" change};
    ok $edit->edit, 'editor round trip succeeds with executable arguments and spaced path';
    is $edit->listing, "10 my \$answer = 6 * 7;\n20 \n30 say \$answer;\n", 'edited source renumbered; blank line retained';
    is capture { $edit->run }, "42\n", 'edited program runs';
    $edit->undo;
    is $edit->listing, $original, 'UNDO restores whole edit and original numbering';
}
for my $mode ('failure', 'missing', 'invalid', 'nul') {
    local $ENV{EDITOR} = qq{"$^X" "$editor" $mode};
    ok length(fails { $edit->edit }), "editor $mode reports failure";
    is $edit->listing, $original, "editor $mode preserves original program";
}
{
    local $ENV{EDITOR} = '"unclosed';
    like fails { $edit->edit }, qr/unmatched quotes/, 'bad editor configuration rejected';
    is $edit->listing, $original, 'bad editor configuration preserves program';
}
{
    local $ENV{EDITOR} = '';
    local $ENV{VISUAL} = qq{"$^X" "$editor" change};
    ok $edit->edit, 'VISUAL used when EDITOR is empty';
    $edit->undo;
}
{
    local $ENV{EDITOR} = qq{"$^X" "$editor" unchanged};
    local $ENV{VISUAL} = qq{"$^X" "$editor" change};
    is $edit->edit, 0, 'EDITOR takes precedence over VISUAL';
}
{
    local $ENV{EDITOR} = qq{"$^X" "$editor" empty};
    ok $edit->edit, 'empty edited file is accepted';
    is $edit->source, '', 'empty file clears program';
    $edit->undo;
    is $edit->listing, $original, 'empty edit is undoable';
}
{
    local $ENV{EDITOR} = qq{"$^X" "$editor" crlf};
    ok $edit->edit, 'CRLF editor output accepted';
    is $edit->source, "say 'first';\n\nsay 'last';\n", 'CRLF normalized';
    $edit->undo;
}
{
    local $ENV{EDITOR} = qq{"$^X" "$editor" unfinished};
    local $ENV{PERL_ANTE_REPL_TEST_BEGIN};
    delete $ENV{PERL_ANTE_REPL_TEST_BEGIN};
    ok $edit->edit, 'unfinished Perl accepted by EDIT';
    ok !exists $ENV{PERL_ANTE_REPL_TEST_BEGIN}, 'EDIT never executes BEGIN blocks';
    $edit->undo;
}

my $unicode = App::AnteREPL->new;
$unicode->set_line(10, 'say "café";');
$unicode->save($saved);
$other->load($saved, 1);
is $other->source, $unicode->source, 'UTF-8 numbered source round trip';
is capture { $other->run }, "café\n", 'Unicode source runs';

is capture { $edit->dispatch('? 2 + 3') }, "5\n", '? displays expression result';
is capture { $edit->dispatch('LIST 7') }, "7 say \"old\";\n", 'uppercase LIST command';
is capture { $edit->dispatch('EVAL say 123;') }, "123\n", 'EVAL bypasses dispatcher';
like fails { $edit->dispatch('QUIT') }, qr/Unsaved/, 'QUIT protects dirty buffer';
is $edit->dispatch('QUIT!'), 0, 'QUIT! allows explicit discard';
like fails { $edit->dispatch('NEW') }, qr/Unsaved/, 'NEW protects dirty buffer';
$edit->dispatch('NEW!');
is $edit->source, '', 'NEW! clears program';
$edit->undo;
is $edit->listing, $original, 'NEW! is undoable';
like fails { $edit->dispatch('RUN!') }, qr/suffix/, 'reject unsupported force suffix';
like fails { $edit->dispatch('SAVE "unfinished') }, qr/Usage/, 'unmatched filename quotes rejected';

my ($out, $err, $status) = cli("\$x = 6;\n20 say \$x;\n10 \$x *= 7;\nRUN\n? \$x\nQUIT!\n");
is $out, "42\n42\n\n", 'CLI immediate + stored evaluation';
is $err, '', 'CLI no spurious warnings';
is $status, 0, 'CLI success status';
($out, $err, $status) = cli("die \"oops\\n\";\nsay 7;\nQUIT\n");
is $out, "7\n\n", 'CLI continues after exception';
like $err, qr/oops/, 'CLI error is visible';
is $status, 1, 'batch reports command failures';
for my $command ('QUIT', 'QUIT!', 'EXIT', 'EXIT!') {
    ($out, $err, $status) = cli("print q{last output};\n$command\n");
    is $out, "last output\n", "$command ends output on a fresh line";
    is $err, '', "$command has no exit warning";
    is $status, 0, "$command exits successfully";
}
($out, $err, $status) = cli("Q!\n", '--plain');
is $err, '', 'plain Q! is a command, not a Perl bareword';
is $status, 0, 'plain Q! exits successfully';
($out, $err, $status) = cli("Q\nQ!\n", '--plain');
like $err, qr/Confirmation required: Exit the REPL/, 'batch plain Q reaches its confirmation guard';
unlike $err, qr/Bareword|syntax error/, 'plain Q and Q! never reach the Perl parser';
($out, $err, $status) = cli("10 say 1;\n");
like $err, qr/Unsaved/, 'EOF reports dirty batch';
is $status, 1, 'dirty batch exits nonzero';
($out, $err, $status) = cli("AUTO\nsay 1\n");
like $err, qr/Unsaved/, 'batch EOF during AUTO still reports unsaved source';
is $status, 1, 'batch EOF during AUTO exits instead of waiting for more input';

my $export = "$dir/export.pl";
my $standalone = App::AnteREPL->new;
$standalone->set_line(10, '$x = 21;');
$standalone->set_line(20, 'say $x * 2;');
$standalone->export_source($export);
my $pid = open3(my $input, my $output, my $error = gensym, $^X, $export);
close $input;
my $export_output = do { local $/; <$output> };
my $export_error = do { local $/; <$error> };
waitpid $pid, 0;
is $export_output, "42\n", 'EXPORT runs with ordinary perl';
is $export_error, '', 'EXPORT prelude supports default workspace semantics';
is $? >> 8, 0, 'standalone export exits successfully';
ok $standalone->dirty, 'EXPORT does not mark numbered program saved';

done_testing;
