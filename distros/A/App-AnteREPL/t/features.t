use 5.016;
use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Open3;
use Symbol qw(gensym);
use lib "$FindBin::Bin/../lib";
use App::AnteREPL;

my $dir = tempdir(CLEANUP => 1);
sub capture (&) {
    my ($code) = @_;
    my $output = '';
    open my $fh, '>', \$output or die $!;
    local *STDOUT = $fh;
    $code->();
    return $output;
}
sub fails (&) { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@; }
sub put { App::AnteREPL::_write_text(@_) }

my $repl = App::AnteREPL->new;
my $source = "# source comment\n\$value = 42;\n\nsay \$value;\n";
my $path = "$dir/source file.pl";
put($path, $source);
is capture { $repl->dispatch(qq{LOAD "$path"}) }, "Loaded 4 lines.\n", 'LOAD accepts ordinary Perl';
is $repl->source, $source, 'LOAD preserves comments and blank lines';
ok !$repl->dirty, 'loaded source starts clean';
ok !defined $repl->evaluate('$value', 0), 'loading never executes source';
is capture { $repl->run }, "42\n", 'loaded source can run';
$repl->set_line(50, '# appended');
$repl->save;
is App::AnteREPL::_read_text($path), $source . "# appended\n", 'SAVE to loaded .pl retains plain source';
put("$dir/extensionless", "say 9;\n");
$repl->load("$dir/extensionless");
$repl->set_line(20, 'say 10;');
$repl->save;
is App::AnteREPL::_read_text("$dir/extensionless"), "say 9;\nsay 10;\n", 'extensionless source retains its format';
$repl->save("$dir/numbered.bperl");
like App::AnteREPL::_read_text("$dir/numbered.bperl"), qr/\A# PERL ANTE REPL V0.1\n10 say 9;/, 'SAVE .bperl selects numbered format';
$repl->load("$dir/numbered.bperl");
is_deeply [$repl->numbers], [10,20], 'LOAD retains native numbering';
$repl->set_line(99, 'say 99;');
like fails { $repl->load($path) }, qr/LOAD!/, 'plain LOAD protects unsaved program';
$repl->load($path, 1);
is $repl->source, $source . "# appended\n", 'forced plain LOAD replaces program';
put("$dir/bad.pl", "# PERL ANTE REPL V0.1\n10 bad\n10 duplicate\n");
my $before = $repl->source;
like fails { $repl->load("$dir/bad.pl") }, qr/Duplicate/, 'native header takes priority over extension';
is $repl->source, $before, 'malformed native input leaves program unchanged';

for my $name ('PERL ANTE REPL', 'BASIC PERL') {
    my $native = App::AnteREPL->new;
    my $file = "$dir/$name.pl";
    put($file, "# $name V0.1\n5 say 5;\n90 say 90;\n");
    is $native->load($file), 2, "$name header identifies numbered source even in .pl";
    is_deeply [$native->numbers], [5, 90], "$name header preserves editing numbers";
    $native->save("$dir/$name.bperl");
    is App::AnteREPL::_read_text("$dir/$name.bperl"),
        "# PERL ANTE REPL V0.1\n5 say 5;\n90 say 90;\n",
        "$name source saves with the current header";
    put($file, "# $name V0.1\n5 say 5;\n5 say 90;\n");
    like fails { $native->load($file) }, qr/Duplicate/, "$name header validates numbered records";
    is_deeply [$native->numbers], [5, 90], "$name invalid file leaves program intact";
    put($file, "# $name V999\n5 say 5;\n");
    like fails { $native->load($file) }, qr/Not a PERL ANTE REPL V0\.1 file/,
        "$name unsupported version is rejected as native";
}

my $auto = App::AnteREPL->new;
like capture { $auto->dispatch('AUTO') }, qr/AUTO 5, step 5/, 'AUTO starts at 5';
is capture { $auto->dispatch('$x = 2') }, '', 'AUTO stores without echo by default';
is $auto->listing('5'), "5 \$x = 2;\n", 'quiet AUTO still supplies a semicolon';
ok !defined $auto->evaluate('$x',0), 'AUTO does not execute input';
capture { $auto->dispatch('say $x'); $auto->dispatch('AUTO OFF'); };
is_deeply [$auto->numbers], [5,10], 'AUTO increments by 5';
ok !$auto->{auto}, 'AUTO OFF ends entry';
$auto->dispatch('$x = 7');
is $auto->evaluate('$x',0), 7, 'input executes again after AUTO OFF';
is capture { $auto->run }, "2\n", 'stored AUTO program runs';
like capture { $auto->dispatch('AUTO') }, qr/AUTO 15/, 'AUTO appends after highest existing line';
capture { $auto->dispatch('AUTO 5 5'); $auto->dispatch('say "gap"'); };
is $auto->listing('5'), "5 \$x = 2;\n", 'AUTO skips occupied numbers instead of overwriting';
is $auto->listing('15'), "15 say \"gap\";\n", 'AUTO finds next free number';
my $unchanged = $auto->listing;
$auto->dispatch('');
is $auto->listing, $unchanged, 'blank entry does not store or delete a line';
ok $auto->{auto}, 'blank entry does not end AUTO';
like capture { $auto->dispatch('LIST') }, qr/5  \$x = 2;/, 'commands remain available during AUTO';
capture { $auto->dispatch('EVAL $x = 77'); };
is $auto->evaluate('$x',0),77,'EVAL executes explicitly during AUTO';
capture { $auto->dispatch(': say "literal"'); };
is $auto->listing('20'), "20 say \"literal\"\n", 'colon stores exact source during AUTO';
ok !$auto->input_needs_more(': my $x = ['), 'literal AUTO lines do not trigger continuation';
capture { $auto->dispatch("\$data = {\n    one => 1,\n};"); };
is $auto->listing('25-35'), "25 \$data = {\n30     one => 1,\n35 };\n", 'multiline AUTO preserves internal syntax';
$auto->undo;
is $auto->listing('25-35'), '', 'multiline AUTO is a single undo operation';
capture { $auto->dispatch('AUTO 999999999 5'); };
$before = $auto->listing;
like fails { capture { $auto->dispatch("say 1;\nsay 2;") } }, qr/nothing stored/, 'AUTO rejects multiline overflow';
is $auto->listing, $before, 'AUTO overflow is atomic';
capture { $auto->dispatch('say "last"'); };
ok !$auto->{auto}, 'AUTO stops at numeric limit';
like fails { $auto->dispatch('AUTO 0') }, qr/Line numbers/, 'AUTO rejects zero start';
like fails { $auto->dispatch('AUTO 1 0') }, qr/Line numbers/, 'AUTO rejects zero step';

my $echo = App::AnteREPL->new;
is capture { $echo->dispatch('AUTO ECHO ON') }, "AUTO echo on.\n", 'echo setting is explicit';
ok !$echo->{auto}, 'echo setting does not start AUTO';
capture { $echo->dispatch('AUTO') };
is capture { $echo->dispatch('say 1') }, "5 say 1;\n", 'optional echo shows assigned source';
capture { $echo->dispatch('AUTO OFF'); $echo->dispatch('AUTO') };
is capture { $echo->dispatch("\$data = {\na => 1,\n};") }, "10 \$data = {\n15 a => 1,\n20 };\n", 'echo persists and handles complete multiline entries';
capture { $echo->dispatch('AUTO ECHO OFF') };
is capture { $echo->dispatch('say 2') }, '', 'echo can be disabled during AUTO';
is $echo->listing('25'), "25 say 2;\n", 'echo toggle retains AUTO position';
like fails { $echo->dispatch('AUTO ECHO maybe') }, qr/Usage: AUTO ECHO/, 'invalid echo setting rejected';

my $immediate = App::AnteREPL->new;
my $block = "do {\nmy \$total = 0;\nfor my \$n (1..3) { \$total += \$n; }\nif (\$total) { say \$total; }\n};";
is capture { $immediate->dispatch($block) }, "6\n", 'multiple immediate blocks share a lexical scope';
is $immediate->source, '', 'immediate multiline code is not stored';
capture { $immediate->dispatch('AUTO') };
ok $immediate->input_needs_more('EVAL do {'), 'EVAL supports continuation during AUTO';
is capture { $immediate->dispatch("EVAL $block") }, "6\n", 'EVAL multiline code executes during AUTO';
is_deeply $immediate->{auto}, {next=>5, step=>5}, 'EVAL does not consume AUTO numbers';
is $immediate->source, '', 'EVAL leaves VRAM untouched';
$immediate->dispatch('10 sub twice { return 2 * shift }');
like fails { $immediate->dispatch('EVAL say twice(21)') }, qr/Undefined subroutine/, 'stored subroutine is not live before RUN';
$immediate->dispatch('RUN');
is capture { $immediate->dispatch('EVAL say twice(21)') }, "42\n", 'RUN-defined function is callable from immediate input';
capture { $immediate->dispatch('AUTO OFF') };
$immediate->dispatch("sub plus_one {\nreturn 1 + shift;\n}");
is capture { $immediate->dispatch('say plus_one(41)') }, "42\n", 'immediate multiline function persists';
is_deeply [$immediate->numbers], [10], 'immediate definition does not enter stored program';

is capture { $immediate->dispatch(q{eval 'say "string eval"'}) }, "string eval\n", 'lowercase eval uses the Perl keyword';
is capture { $immediate->dispatch(q{eval { die "caught\n" }; say "error:$@"}) }, "error:caught\n\n", 'Perl eval catches exceptions';
like fails { $immediate->dispatch(q{EVAL die "uncaught\n"}) }, qr/uncaught/, 'uppercase EVAL reports exceptions';
$immediate->dispatch(q{sub Eval { say "mixed case function" }});
is capture { $immediate->dispatch(q{Eval ()}) }, "mixed case function\n", 'mixed-case Eval is Perl code';
capture { $immediate->dispatch('AUTO 20') };
$immediate->dispatch(q{eval { $from_stored_eval = 9 }});
like $immediate->listing('20'), qr/^20 eval \{/, 'lowercase eval follows AUTO storage rules';
is capture { $immediate->dispatch(q{EVAL say "immediate"}) }, "immediate\n", 'uppercase EVAL bypasses AUTO';

my $session = App::AnteREPL->new;
$session->dispatch('EVAL sub triple { return 3 * shift }');
{
    no strict 'refs';
    is ref(*{ $session->{workspace} . '::triple' }{CODE}), 'CODE',
        'EVAL installs a callable function in the current workspace symbol table';
}
is $session->source, '', 'session-only function leaves VRAM empty';
ok !$session->dirty, 'session-only definition does not dirty the program';
$session->dispatch('10 say triple(14)');
is capture { $session->dispatch('RUN') }, "42\n", 'RUN can call the session-only function';
$session->save("$dir/session.pl");
is App::AnteREPL::_read_text("$dir/session.pl"), "say triple(14);\n",
    'SAVE contains the stored call, not the session-only function';
$session->dispatch('CLEAR');
is capture { $session->dispatch('say triple(2)') }, "6\n", 'CLEAR retains live functions';
capture { $session->dispatch('RESET') };
like fails { $session->dispatch('say triple(2)') }, qr/Undefined subroutine/,
    'RESET selects a fresh symbol table for subsequent evaluation';
$session->dispatch('EVAL sub STORE { say "ordinary function" }');
is capture { $session->dispatch('STORE "argument"') }, "ordinary function\n",
    'STORE is no longer reserved as a REPL command';

my $functions = App::AnteREPL->new;
is capture { $functions->dispatch('FUNCTIONS') }, "No functions defined in this workspace.\n",
    'FUNCTIONS describes an empty workspace without exposing other sessions';
$functions->dispatch(q{EVAL do { $setups++; sub triple { 3 * shift } }});
$functions->dispatch(q{EVAL $old = \&triple; $value = 1; $callback = sub { 7 }; sub pending;});
$functions->dispatch(q{EVAL use Scalar::Util qw(blessed); *alias = \&triple;});
$functions->dispatch('10 sub from_program { 9 }');
is capture { $functions->dispatch('FUNCTIONS') }, "alias\nblessed\ntriple\n",
    'FUNCTIONS sorts local names and imports, excluding variables, stubs and unrun source';
$functions->dispatch('RUN');
is capture { $functions->dispatch('FUNCTIONS') }, "alias\nblessed\nfrom_program\ntriple\n",
    'RUN-defined functions join the listing';
my $warnings = '';
{
    local $SIG{__WARN__} = sub { $warnings .= join '', @_ };
    $functions->dispatch(q{EVAL sub triple { 4 * shift }});
}
like $warnings, qr/Subroutine triple redefined/, 'redefinition warns without asking for input';
is capture { $functions->dispatch(q{say triple(14), ':', $old->(14), ':', $setups}) }, "56:42:1\n",
    'new calls use the replacement, old references keep the old body, setup ran once';
capture { $functions->dispatch('AUTO') };
my $functions_source = $functions->source;
my %functions_auto = %{ $functions->{auto} };
is capture { $functions->dispatch('FUNCTIONS') }, "alias\nblessed\nfrom_program\ntriple\n",
    'FUNCTIONS is available during AUTO';
is $functions->source, $functions_source, 'FUNCTIONS leaves numbered source unchanged';
is_deeply $functions->{auto}, \%functions_auto, 'FUNCTIONS leaves AUTO numbering unchanged';
like fails { $functions->dispatch('FUNCTIONS extra') }, qr/Usage: FUNCTIONS/, 'FUNCTIONS rejects arguments';
like fails { $functions->dispatch('FUNCTIONS!') }, qr/The ! suffix/, 'FUNCTIONS has no force suffix';
capture { $functions->dispatch('RESET') };
is capture { $functions->dispatch('FUNCTIONS') }, "No functions defined in this workspace.\n",
    'FUNCTIONS follows RESET to the fresh workspace despite retained source';
is capture { $session->dispatch('FUNCTIONS') }, "STORE\n", 'another session retains its own functions';

{
    local %ENV = (FIRST => 'startup', EMPTY => '');
    my $env = App::AnteREPL->new;
    is capture { $env->dispatch('ENV') }, "EMPTY=\nFIRST=startup\n", 'ENV displays sorted VAR=value';
    $env->dispatch(q{ENV SET GREETING 'hello world'});
    is $ENV{GREETING}, 'hello world', 'ENV SET preserves quoted spaces';
    $env->dispatch(q{ENV SET EMPTY ""});
    is $ENV{EMPTY}, '', 'ENV SET permits empty values';
    $env->dispatch(q{ENV SET LITERAL '$HOME `echo hi` $(echo hi)'});
    is $ENV{LITERAL}, '$HOME `echo hi` $(echo hi)', 'ENV SET does not expand shell syntax';
    is $env->evaluate('$ENV{GREETING}',0), 'hello world', 'Perl observes changed environment';
    $env->dispatch(q{$ENV{DIRECT} = 'perl'});
    is capture { $env->dispatch('ENV DIRECT') }, "DIRECT=perl\n", 'ENV sees direct Perl changes';
    $env->dispatch('ENV UNSET FIRST');
    ok !exists $ENV{FIRST}, 'ENV UNSET removes variable';
    $ENV{COMPLEX} = " quote\" slash\\ newline\n tab\t carriage\r hash# dollar\$ ";
    $ENV{UTF8_BYTES} = "caf\xc3\xa9";
    $ENV{RAW_BYTES} = "\xff\xe9";
    my %expected = %ENV;
    capture { $env->dispatch(qq{ENV SAVE "$dir/vars.env"}); };
    $ENV{EXTRA} = 'remove me';
    capture { $env->dispatch('ENV RELOAD'); };
    is_deeply \%ENV, \%expected, 'environment snapshot round trips all supported escapes';
    like App::AnteREPL::_read_text("$dir/vars.env"), qr/UTF8_BYTES="café"/, 'UTF-8 environment values are readable in editor';
    like App::AnteREPL::_read_text("$dir/vars.env"), qr/RAW_BYTES="\\xFF\\xE9"/, 'non-UTF-8 bytes are escaped';
    put("$dir/unicode.env", "UNICODE=雪\n");
    capture { $env->dispatch(qq{ENV LOAD "$dir/unicode.env"}); };
    is $ENV{UNICODE}, "\xe9\x9b\xaa", 'UTF-8 environment file becomes UTF-8 process bytes';
    $env->dispatch(q{ENV SET UNICODE '雪'});
    is $ENV{UNICODE}, "\xe9\x9b\xaa", 'ENV SET handles Unicode input without wide-character warning';
    put("$dir/vars.env", <<'ENVFILE');
# comment
export FIRST=loaded
SPACES="hello world" # comment
SINGLE='a $HOME value'
LITERAL=$HOME`whoami`$(echo hello)
WINDOWS='C:\Users\brett'
HASH=abc#def # comment
EMPTY= # comment
ENVFILE
    capture { $env->dispatch(qq{ENV RELOAD "$dir/vars.env"}); };
    is $ENV{FIRST}, 'loaded', 'RELOAD reads changed file';
    is $ENV{SPACES}, 'hello world', 'double quotes and trailing comment';
    is $ENV{SINGLE}, 'a $HOME value', 'single quotes keep dollar sign literal';
    is $ENV{LITERAL}, '$HOME`whoami`$(echo hello)', 'file parsing never executes or interpolates';
    is $ENV{WINDOWS}, 'C:\Users\brett', 'single quotes keep Windows paths literal';
    is $ENV{HASH}, 'abc#def', 'inline hash survives unless preceded by whitespace';
    ok !exists $ENV{COMPLEX}, 'ENV LOAD/RELOAD replace entire snapshot';
    my %valid = %ENV;
    for my $bad ("GOOD=yes\ninvalid\n", "A=x\nA=y\n", 'A="unterminated', 'A="\x00"') {
        put("$dir/bad.env", $bad);
        ok length(fails { $env->dispatch(qq{ENV LOAD "$dir/bad.env"}) }), 'bad environment is rejected';
        is_deeply \%ENV, \%valid, 'bad environment leaves live environment intact';
    }
    capture { $env->dispatch('ENV RESET'); };
    is_deeply \%ENV, {FIRST=>'startup',EMPTY=>''}, 'ENV RESET restores original startup snapshot';
    $env->reset_workspace;
    is $ENV{FIRST}, 'startup', 'Perl RESET does not replace process environment';
}

my $editor = "$dir/env-editor.pl";
put($editor, <<'EDITOR');
use strict;
use warnings;
my ($mode, $path) = @ARGV;
die 'wrong temporary file' unless $path =~ /environment\.env$/;
open my $out, '>', $path or die $!;
print {$out} $mode eq 'invalid' ? "BROKEN\n" : "EDITED=from_editor\n";
close $out or die $!;
exit($mode eq 'failure' ? 17 : 0);
EDITOR
{
    local %ENV = %ENV;
    my $env = App::AnteREPL->new;
    for my $mode ('invalid','failure') {
        local $ENV{EDITOR} = qq{"$^X" "$editor" $mode};
        my %before = %ENV;
        ok length(fails { $env->dispatch('EDIT ENV') }), "environment editor $mode reported";
        is_deeply \%ENV, \%before, "environment editor $mode is atomic";
    }
    $ENV{EDITOR} = qq{"$^X" "$editor" change};
    capture { $env->dispatch('EDIT ENV'); };
    is_deeply \%ENV, {EDITED=>'from_editor'}, 'EDIT ENV imports editor file';
    $ENV{EDITOR} = qq{"$^X" "$editor" change};
    capture { $env->dispatch('ENV EDIT'); };
    is_deeply \%ENV, {EDITED=>'from_editor'}, 'ENV EDIT aliases EDIT ENV';
}

my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, "-I$FindBin::Bin/../lib", "$FindBin::Bin/../script/anterepl", '--quiet');
print {$in} "AUTO\n\$FOO = {\nbar => 1,\n};\nAUTO OFF\nRUN\n? \$FOO->{bar}\nQUIT!\n";
close $in;
my ($stdout, $stderr);
{ local $/; $stdout = <$out>; $stderr = <$err>; }
waitpid $pid, 0;
is $? >> 8, 0, 'anterepl CLI accepts AUTO multiline input';
is $stderr, '', 'AUTO CLI has no errors';
like $stdout, qr/AUTO off.\n1\n/, 'quiet AUTO CLI stores then runs multiline code';
unlike $stdout, qr/\$FOO =|bar =>/, 'AUTO CLI does not echo stored source';

done_testing;
