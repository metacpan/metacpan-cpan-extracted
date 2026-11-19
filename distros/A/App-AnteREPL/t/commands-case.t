use 5.016;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use App::AnteREPL;

sub capture (&) {
    my ($code) = @_;
    my $output = '';
    open my $fh, '>', \$output or die $!;
    local *STDOUT = $fh;
    $code->();
    return $output;
}
sub fails (&) { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@; }

# Observe routing without running Perl's dump keyword, file commands, or editors.
{
    package CaseRoute;
    our @ISA = ('App::AnteREPL');
    sub evaluate { $_[0]{evaluated} = [$_[1], $_[2]]; return 1; }
    sub _edit_text { die "Unexpected editor invocation\n"; }
}
{
    local %ENV = (case_test => 'value');
    for my $word (qw(AUTO ENV LIST RUN EDIT DEL DELETE RENUM REORDER UNDO SAVE LOAD
                     IMPORT EXPORT NEW CLEAR CLS RECOVER RESET FUNCTIONS STATUS HELP QUIT EXIT EVAL DUMP PEEK CD CHDIR),
                  'LIST10-50', 'NEW!', 'QUIT!') {
        for my $input (lc($word), ucfirst(lc($word))) {
            my $r = CaseRoute->new;
            my $error = fails { capture { $r->dispatch($input) } };
            is $error, '', "$input passes to Perl without command side effects";
            is_deeply $r->{evaluated}, [$input, 0], "$input is immediate Perl";
        }
    }
    my $r = CaseRoute->new;
    capture { $r->dispatch('AUTO') };
    for my $input ('list', 'Run', 'auto off', 'Dump $value', 'peek $value', 'eval { 1 }') {
        my @before = $r->numbers;
        capture { $r->dispatch($input) };
        ok $r->{auto}, "$input does not end AUTO";
        ok !exists $r->{evaluated}, "$input is not executed during AUTO";
        my @after = $r->numbers;
        is scalar(@after), scalar(@before) + 1, "$input becomes stored Perl";
    }
}

my $r = App::AnteREPL->new;
capture { $r->dispatch('AUTO 5 5') };
for my $bad ('AUTO off', 'AUTO Off', 'AUTO echo ON', 'AUTO Echo ON',
             'AUTO ECHO on', 'AUTO ECHO Off') {
    my %before = %{$r->{auto}};
    ok length(fails { capture { $r->dispatch($bad) } }), "$bad is rejected";
    is_deeply $r->{auto}, \%before, "$bad keeps AUTO settings";
    ok !$r->{auto_echo}, "$bad does not enable echo";
}
capture { $r->dispatch('AUTO ECHO ON'); $r->dispatch('AUTO OFF') };
ok $r->{auto_echo} && !$r->{auto}, 'uppercase AUTO subcommands work';

$r->dispatch('10 say "stored"');
for my $bad ('LIST slow', 'LIST Pause', 'LIST10-50 slow', 'EDIT env', 'EDIT Env') {
    ok length(fails { capture { $r->dispatch($bad) } }), "$bad is rejected";
    is $r->source, "say \"stored\";\n", "$bad preserves stored source";
}
is capture { $r->dispatch('LIST SLOW') }, "10 say \"stored\";\n", 'uppercase LIST modifier works';

{
    local %ENV = (set => 'lowercase name', GREETING => 'unchanged');
    my $env = CaseRoute->new;
    is capture { $env->dispatch('ENV set') }, "set=\"lowercase name\"\n",
        'environment variable names retain their case';
    for my $bad ('ENV set GREETING bad', 'ENV Set GREETING bad', 'ENV unset GREETING',
                 'ENV Unset GREETING', 'ENV edit', 'ENV Edit', 'ENV reset', 'ENV Reset',
                 'ENV save file', 'ENV Save file', 'ENV load file', 'ENV Load file',
                 'ENV reload file', 'ENV Reload file') {
        ok length(fails { capture { $env->dispatch($bad) } }), "$bad is not an ENV subcommand";
        is_deeply \%ENV, {set=>'lowercase name', GREETING=>'unchanged'}, "$bad keeps environment";
    }
    $env->dispatch('ENV SET MixedName MixedValue');
    is $ENV{MixedName}, 'MixedValue', 'uppercase SET preserves argument case';
    $env->dispatch('ENV UNSET MixedName');
    ok !exists $ENV{MixedName}, 'uppercase UNSET works';
}

my $perl = App::AnteREPL->new;
$perl->dispatch('EVAL sub list { say $_[0] }');
ok App::AnteREPL::needs_more('list ('), 'lowercase function calls can continue across rows';
ok App::AnteREPL::needs_more('List ('), 'mixed-case function calls can continue across rows';
ok !App::AnteREPL::needs_more('LIST ('), 'uppercase command retains its own input grammar';
is capture { $perl->dispatch("list (\n'Perl function'\n)") }, "Perl function\n",
    'a lowercase function name is available to ordinary Perl';
is capture { $perl->dispatch(q{eval { die "caught\n" }; say $@}) }, "caught\n\n",
    'lowercase Perl eval retains exception handling';
like App::AnteREPL::help(), qr/All REPL commands and subcommands must be uppercase/,
    'HELP states the command case rule';

for my $input ('cls', 'Cls', 'cLs', 'list', 'List', 'help', 'status', 'cd', 'Chdir', '  cls;') {
    my $r = App::AnteREPL->new;
    my @warnings;
    my $error;
    { local $SIG{__WARN__} = sub { push @warnings, @_ }; $error = fails { $r->dispatch($input) }; }
    my ($word) = $input =~ /([A-Za-z]+)/;
    is $error, 'REPL commands must be uppercase; try, "' . uc($word) . "\".\n", "$input gets a clear spelling hint";
    is_deeply \@warnings, [], "$input emits no interpreter warnings";
}
like fails { $perl->dispatch('clss') }, qr/Bareword "clss"/, 'unknown words retain Perl diagnostics';
my $eval_error = fails { $perl->dispatch('eval )') };
like $eval_error, qr/syntax error/, 'invalid Perl eval retains its syntax error';
unlike $eval_error, qr/REPL commands/, 'Perl eval errors are not command hints';
like fails { $perl->dispatch('delete $value') }, qr/delete argument/, 'Perl delete keeps its own diagnostic';
like fails { $perl->dispatch('EVAL cls') }, qr/Bareword "cls"/, 'explicit EVAL keeps Perl diagnostics';
my $stored = App::AnteREPL->new;
$stored->dispatch('10 cls');
like fails { $stored->run }, qr/Bareword "cls".*stored line 10/s, 'stored source retains numbered Perl diagnostics';
my $user = App::AnteREPL->new;
$user->dispatch('EVAL sub cls () { say "user cls" }');
is capture { $user->dispatch('cls') }, "user cls\n", 'valid bare function matching a command still executes';
my $arity = App::AnteREPL->new;
$arity->dispatch('EVAL sub cls ($) { $_[0] }');
like fails { $arity->dispatch('cls') }, qr/Not enough arguments/, 'prototype errors for a real function remain Perl errors';
done_testing;
