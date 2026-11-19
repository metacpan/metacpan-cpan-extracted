use 5.016;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
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
    package ConfirmRepl;
    our @ISA = ('App::AnteREPL');
    sub _confirmation_answer {
        my ($self, @prompt) = @_;
        push @{$self->{asked}}, \@prompt;
        return shift @{$self->{answers} || []};
    }
    sub _edit_text { ++$_[0]{editor_calls}; return $_[0]{editor_result}; }
    package ConfirmScreen;
    our @ISA = ('App::AnteREPL::Screen');
    sub render { }
    package ConfirmTie;
    sub TIESCALAR { bless {fetch=>0, store=>0}, shift }
    sub FETCH { ++$_[0]{fetch}; return 'old' }
    sub STORE { ++$_[0]{store} }
    package InterruptPrompt;
    sub TIEHANDLE { bless {}, shift }
    sub PRINT { $SIG{INT}->(); return 1 }
}
{
    my $prompt = App::AnteREPL->new;
    $prompt->{interactive} = 1;
    my $error;
    {
        local $SIG{INT} = sub { die "Unhandled prompt interrupt.\n" };
        local *STDOUT;
        tie *STDOUT, 'InterruptPrompt';
        $error = fails { $prompt->_confirmation_answer('Discard source', 'N!') };
    }
    is $error, "Interrupted.\n", 'Ctrl-C is handled as soon as the confirmation becomes visible';
}
my $dir = tempdir(CLEANUP=>1);
my $r = ConfirmRepl->new;
sub asked { scalar @{$_[0]{asked} || []} }
sub yes { $_[0]{answers} = ["yes\n"] }
$r->dispatch('10 say "original"');
my $source = $r->source;
my $undo = scalar @{$r->{undo}};
for my $reply (undef, '', "\n", "n\n", "yes please\n", "y; RUN\n") {
    $r->{answers} = [$reply];
    is fails { $r->dispatch('D1 10') }, "Cancelled.\n", 'only an explicit y/yes approves deletion';
    is $r->source, $source, 'declined deletion retains source';
    is scalar @{$r->{undo}}, $undo, 'declined deletion retains undo history';
}
is $r->{asked}[-1][1], 'D1!', 'confirmation identifies its forced shortcut';
yes $r;
is fails { $r->dispatch('D1 10') }, '', 'yes permits deletion';
is $r->source, '', 'approved deletion takes effect';
my $calls = asked $r;
is fails { $r->dispatch('U') }, "Cancelled.\n", 'undo replacement also needs approval';
is $r->source, '', 'declining undo keeps the current source';
capture { $r->dispatch('U!') };
is $r->source, $source, 'U! restores source without asking again';
is asked($r), $calls+1, 'force does not ask a second time';
$calls = asked $r;
$r->dispatch('D1 999');
like fails { $r->dispatch('D1 nonsense') }, qr/line number or a range/, 'invalid deletion is rejected before confirmation';
is asked($r), $calls, 'no-op and invalid deletion do not prompt';
is fails { $r->dispatch('R1 20 20') }, "Cancelled.\n", 'renumbering protects original line addresses';
is_deeply [$r->numbers], [10], 'cancelled renumbering retains numbers';
capture { $r->dispatch('R1! 20 20') };
is_deeply [$r->numbers], [20], 'R1! renumbers without confirmation';
capture { $r->dispatch(qq{S "$dir/kept.pl"}) };
my $filename = $r->{filename};
is fails { $r->dispatch('N') }, "Cancelled.\n", 'clearing even saved source needs approval';
is $r->{filename}, $filename, 'cancelled clear keeps the filename';
is $r->source, $source, 'cancelled clear keeps the source';
yes $r; $calls = asked $r;
$r->dispatch('N');
is $r->source, '', 'approved clear takes effect';
is asked($r), $calls+1, 'clear asks only once across source and metadata changes';

$r->dispatch('5 say "unsaved"');
my $dirty_source = $r->source;
App::AnteREPL::_write_text("$dir/input.pl", "say \"loaded\";\n");
$calls = asked $r;
like fails { $r->dispatch(qq{L1 "$dir/missing.pl"}) }, qr/Cannot open/, 'load validates the file before asking';
is asked($r), $calls, 'invalid load asks nothing';
is fails { $r->dispatch(qq{L1 "$dir/input.pl"}) }, "Cancelled.\n", 'load replacement defaults to No';
is $r->source, $dirty_source, 'declined load preserves unsaved source';
ok !defined $r->{filename}, 'declined load does not adopt a filename';
yes $r; $calls = asked $r;
capture { $r->dispatch(qq{L1 "$dir/input.pl"}) };
is $r->source, "say \"loaded\";\n", 'approved load replaces unsaved source';
is asked($r), $calls+1, 'approved load asks once';
ok !$r->dirty, 'approved load updates saved state';
is fails { $r->dispatch(qq{I "$dir/kept.pl"}) }, "Cancelled.\n", 'import also confirms replacing saved source';
capture { $r->dispatch(qq{I! "$dir/kept.pl"}) };
ok $r->dirty && !defined $r->{filename}, 'forced import keeps ordinary import semantics';

for my $command ('S', 'E2') {
    App::AnteREPL::_write_text("$dir/existing.pl", "keep me\n");
    is fails { $r->dispatch(qq{$command "$dir/existing.pl"}) }, "Cancelled.\n", "$command protects an existing file";
    is App::AnteREPL::_read_text("$dir/existing.pl"), "keep me\n", "$command cancellation leaves file bytes intact";
    capture { $r->dispatch(qq{$command! "$dir/existing.pl"}) };
    like App::AnteREPL::_read_text("$dir/existing.pl"), qr/say "original"/, "$command! overwrites deliberately";
}
$r->{editor_result} = "say \"edited\";\n";
is fails { capture { $r->dispatch('E1') } }, "Cancelled.\n", 'editor changes need approval before applying';
is $r->{editor_calls}, 1, 'the editor result is prepared before approval';
is $r->source, $source, 'declined editor replacement keeps program';
capture { $r->dispatch('E1!') };
is $r->source, $r->{editor_result}, 'E1! applies editor changes';
$calls = asked $r;
capture { $r->dispatch('E1') };
is asked($r), $calls, 'unchanged editor result does not ask';

my $screen = ConfirmScreen->new;
$r->{screen} = $screen;
$screen->{rows} = [{text=>'keep display'}];
is fails { $r->dispatch('C') }, "Cancelled.\n", 'clearing screen defaults to No';
is $screen->{rows}[0]{text}, 'keep display', 'cancel preserves visible rows';
$r->dispatch('C!');
is $screen->{rows}[0]{text}, '', 'C! clears the screen';
$calls = asked $r;
like fails { $r->dispatch('R3') }, qr/No saved screen/, 'invalid recovery reports its problem first';
is asked($r), $calls, 'unavailable recovery does not ask';
$screen->{resize_bank} = {width=>20,height=>2,row=>0,col=>0,rows=>[{text=>'banked'}]};
$screen->{rows} = [{text=>'current'}];
is fails { $r->dispatch('R3') }, "Cancelled.\n", 'recovery confirms replacing active display';
is $screen->{rows}[0]{text}, 'current', 'declined recovery keeps active display';
ok $screen->{resize_bank}, 'declined recovery retains bank';
$r->dispatch('R3!');
is $screen->{rows}[0]{text}, 'banked', 'R3! restores bank';
delete $r->{screen};
$r->dispatch('E s live return 9');
my $workspace = $r->{workspace};
is fails { $r->dispatch('R2') }, "Cancelled.\n", 'workspace reset confirms';
is $r->{workspace}, $workspace, 'declined reset keeps live package';
is $r->evaluate('live',0), 9, 'live function still works';
capture { $r->dispatch('R2!') };
isnt $r->{workspace}, $workspace, 'R2! resets live workspace';
is fails { $r->dispatch('Q') }, "Cancelled.\n", 'Q requires confirmation';
yes $r;
is $r->dispatch('Q'), 0, 'approved Q can discard unsaved source and exit';
$calls = asked $r;
is $r->dispatch('Q!'), 0, 'Q! exits immediately';
is asked($r), $calls, 'Q! does not ask';

{
    local %ENV = (ORIGINAL=>'old');
    my $v = ConfirmRepl->new;
    $v->dispatch('V1 NEW value');
    is asked($v), 0, 'new environment value needs no confirmation';
    is fails { $v->dispatch('V1 ORIGINAL replacement') }, "Cancelled.\n", 'environment overwrite confirms';
    is $ENV{ORIGINAL}, 'old', 'declined overwrite keeps value';
    $v->dispatch('V1! ORIGINAL replacement');
    is $ENV{ORIGINAL}, 'replacement', 'V1! overwrites';
    is fails { $v->dispatch('V2 ORIGINAL') }, "Cancelled.\n", 'unset confirms';
    ok exists $ENV{ORIGINAL}, 'declined unset keeps variable';
    $v->dispatch('V2! ORIGINAL');
    ok !exists $ENV{ORIGINAL}, 'V2! unsets';
    $v->dispatch('V1 ORIGINAL restored');
    App::AnteREPL::_write_text("$dir/vars.env", "LOADED=yes\n");
    for my $command ('V5', 'V6') {
        is fails { $v->dispatch(qq{$command "$dir/vars.env"}) }, "Cancelled.\n", "$command protects live environment";
        is_deeply \%ENV, {ORIGINAL=>'restored',NEW=>'value'}, "$command cancellation keeps all entries";
        ok !defined $v->{env_filename}, "$command cancellation keeps remembered file";
    }
    $v->{editor_result} = "EDITED=yes\n";
    is fails { $v->dispatch('V3') }, "Cancelled.\n", 'environment editor confirms prepared replacement';
    ok exists $ENV{ORIGINAL}, 'declining editor keeps live environment';
    is fails { $v->dispatch('V0') }, "Cancelled.\n", 'startup environment reset confirms';
    is fails { $v->dispatch('V SET ORIGINAL no') }, "Cancelled.\n", 'generic V also protects destructive subcommands';
    $v->dispatch('V! SET ORIGINAL forced');
    is $ENV{ORIGINAL}, 'forced', 'generic V! bypasses confirmation';
    is fails { $v->dispatch(qq{V4 "$dir/vars.env"}) }, "Cancelled.\n", 'environment save protects existing file';
    is App::AnteREPL::_read_text("$dir/vars.env"), "LOADED=yes\n", 'declining environment save keeps file';
    capture { $v->dispatch(qq{V4! "$dir/vars.env"}) };
    like App::AnteREPL::_read_text("$dir/vars.env"), qr/ORIGINAL=forced/, 'V4! overwrites file';
    capture { $v->dispatch('V0!') };
    is_deeply \%ENV, {ORIGINAL=>'old'}, 'V0! restores initial environment';
}

my $d = ConfirmRepl->new;
$d->dispatch('E s triple return 3 * shift');
is asked($d), 0, 'new function needs no confirmation';
is fails { $d->dispatch('E s triple return 4 * shift') }, "Cancelled.\n", 'function shorthand redefinition confirms';
is $d->evaluate('triple 14',0), 42, 'declining retains old function';
my @warnings;
{ local $SIG{__WARN__} = sub { push @warnings, @_ };
  $d->dispatch('E! s triple return 4 * shift'); }
like join('', @warnings), qr/Subroutine triple redefined/, 'force bypasses confirmation but retains Perl warning';
is $d->evaluate('triple 14',0), 56, 'forced function replaces old definition';
$d->dispatch('$effects = 0');
for my $case (
    ['a','items','\@items'], ['h','items','\%items'], ['ar','items','$items'], ['hr','record','$record'],
) {
    my ($type,$name,$expression) = @$case;
    my $values = $type =~ /^h/ ? 'key => old' : 'old';
    my $replacement = $type =~ /^h/ ? 'key => (do { ++$effects; "new" })' : '(do { ++$effects; "new" })';
    $d->dispatch("E $type $name $values");
    my $before = capture { $d->dispatch("D $expression") };
    is fails { $d->dispatch("E $type $name $replacement") }, "Cancelled.\n", "$type replacement confirms";
    is capture { $d->dispatch("D $expression") }, $before, "$type cancellation preserves destination";
    is $d->evaluate('$effects',0), 0, "$type cancellation runs no value expression";
}
$d->dispatch('words one, two');
is fails { $d->dispatch('words three, four') }, "Cancelled.\n", 'implicit destination replacement confirms';
$d->dispatch('words! three, four');
is_deeply $d->evaluate('\@words',0), [qw(three four)], 'name! forces implicit replacement';
ok $d->input_needs_more('E! ar nested [one,'), 'forced explicit shorthand still continues';
ok $d->input_needs_more('words! one, [two,'), 'forced implicit shorthand still continues';
my $tied = $d->evaluate('tie $tied_destination, "ConfirmTie"', 0);
is fails { $d->dispatch('E ar tied_destination new') }, "Cancelled.\n", 'tied destination also confirms';
is_deeply $tied, {fetch=>0,store=>0}, 'declining invokes neither FETCH nor STORE';

my $batch = App::AnteREPL->new;
$batch->dispatch('10 say "kept"');
my $answer = "yes\n";
open my $in, '<', \$answer or die $!;
{ local *STDIN = $in;
  like fails { $batch->dispatch('N') }, qr/Confirmation required:.*Try N!/,
      'batch refuses destructive shorthand without force';
  is scalar <STDIN>, "yes\n", 'batch refusal does not consume a line as approval';
}
is $batch->source, "say \"kept\";\n", 'batch refusal preserves source';
$batch->dispatch('N!');
is $batch->source, '', 'forced batch command works';
done_testing;
