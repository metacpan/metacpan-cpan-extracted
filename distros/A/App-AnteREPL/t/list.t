use 5.016;
use strict;
use warnings;
use Test::More;
use FindBin;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use lib "$FindBin::Bin/../lib";
use App::AnteREPL;
my $script = abs_path("$FindBin::Bin/../script/anterepl");

sub capture (&) {
    my ($code) = @_;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    local *STDOUT = $fh;
    $code->();
    return $out;
}

my $repl = App::AnteREPL->new;
$repl->dispatch('5 say "hi"');
$repl->dispatch('10 say "there!"');
is capture { $repl->dispatch('LIST') }, "5  say \"hi\";\n10 say \"there!\";\n", 'numbers left aligned and padded on the right';
is $repl->listing, "5 say \"hi\";\n10 say \"there!\";\n", 'canonical source has no display padding';
$repl->dispatch('100 say "last"');
is capture { $repl->dispatch('LIST') }, "5   say \"hi\";\n10  say \"there!\";\n100 say \"last\";\n", 'width follows largest selected line number';
is capture { $repl->dispatch('LIST 5-10') }, "5  say \"hi\";\n10 say \"there!\";\n", 'inclusive range gets its own aligned column';
is capture { $repl->dispatch('LIST5-10') }, capture { $repl->dispatch('LIST 5-10') }, 'compact C64 range syntax';
is capture { $repl->dispatch('LIST 5 - 10') }, capture { $repl->dispatch('LIST 5-10') }, 'spaces around the range separator';
is capture { $repl->dispatch('LIST -10') }, "5  say \"hi\";\n10 say \"there!\";\n", 'range from beginning';
is capture { $repl->dispatch('LIST 10-') }, "10  say \"there!\";\n100 say \"last\";\n", 'range to end';
is capture { $repl->dispatch('LIST 10') }, "10 say \"there!\";\n", 'one line';
is capture { $repl->dispatch('LIST 20-50') }, '', 'empty range';
for my $bad ('LIST 10 20', 'LIST 100-5', 'LIST nonsense', 'LIST 10 FAST') {
    my $ok = eval { capture { $repl->dispatch($bad) }; 1 };
    ok !$ok, "reject invalid syntax: $bad";
}
is capture { $repl->dispatch('LIST 5-10 SLOW') }, capture { $repl->dispatch('LIST 5-10') }, 'plain/batch SLOW does not delay or consume input';
is capture { $repl->dispatch('LIST 5-10 PAUSE') }, capture { $repl->dispatch('LIST 5-10') }, 'plain/batch PAUSE prints complete output';
my $dir = tempdir(CLEANUP => 1);
$repl->save("$dir/list.bperl");
capture { $repl->dispatch('LIST') };
ok !$repl->dirty, 'display formatting cannot dirty a saved program';
like App::AnteREPL::_read_text("$dir/list.bperl"), qr/^5 say "hi";/m, 'SAVE retains canonical unpadded format';

{
    package ListingScreen;
    our @ISA = ('App::AnteREPL::Screen');
    sub render { push @{ $_[0]{seen_status} }, $_[0]{list_status} || ''; }
    sub key {
        my ($self, $timeout) = @_;
        if ($self->{wait_for_pause} && $self->{list_status} !~ /paused/) {
            select undef, undef, undef, $timeout;
            return 'NONE';
        }
        delete $self->{wait_for_pause};
        return shift @{ $self->{test_keys} } || 'EOF';
    }
}
my @rows = map { sprintf('%-2d say %d;', $_, $_) } 1 .. 12;
my $screen = ListingScreen->new;
$screen->{height} = 4;
$screen->{wait_for_pause} = 1;
$screen->{test_keys} = ['ENTER', ['TEXT','s'], ['TEXT',' '], ['TEXT','q']];
$screen->list_rows(\@rows, 2, 'pause');
my @printed = grep { $_->{list_width} } @{ $screen->{rows} };
is scalar @printed, 3, 'stepping a full screen scrolls the oldest listed row away';
is $printed[-1]{text}, '4  say 4;', 'stepped row is the next source line';
ok scalar(grep { /LIST paused/ } @{ $screen->{seen_status} }), 'paused state is displayed';
ok scalar(grep { /LIST slow/ } @{ $screen->{seen_status} }), 'S selects slow speed when resuming';
ok !exists $screen->{list_status}, 'control overlay removed after stopping';

my $slow = ListingScreen->new;
$slow->{test_keys} = [['TEXT',' '], 'ENTER', ['TEXT','q']];
$slow->list_rows(\@rows, 2, 'slow');
is scalar(grep { $_->{list_width} } @{ $slow->{rows} }), 2, 'Space pauses SLOW; Enter steps without resuming continuous output';
my $stop = ListingScreen->new;
$stop->{height} = 4;
$stop->{test_keys} = ['CANCEL'];
eval { $stop->list_rows(\@rows, 2, 'normal') };
is $@, "Interrupted.\n", 'Ctrl-C hands interruption back to the session for exit guidance';
is scalar(grep { $_->{list_width} } @{ $stop->{rows} }), 1, 'stop control ends listing promptly';
my $queued = ListingScreen->new;
$queued->{height} = 4;
$queued->{test_keys} = [['TEXT','R']];
$queued->list_rows(\@rows, 2, 'normal');
is_deeply $queued->{pending_keys}, [['TEXT','R']], 'typing another command interrupts LIST without losing the first key';

my $memory = App::AnteREPL->new;
$memory->set_line(5, '    say "indented";');
$memory->set_line(10, 'say "other";');
my $original = $memory->source;
for (1 .. 2) {
    my $display = ListingScreen->new;
    $memory->{screen} = $display;
    $memory->dispatch('LIST');
    $display->{row} = 0;
    my ($entry) = $display->entry;
    is $entry, '5     say "indented";', 'screen entry removes only number-column padding';
    $memory->dispatch($entry);
    is $memory->source, $original, 'resubmitting an aligned row preserves source indentation';
}
delete $memory->{screen};
is capture { $memory->run }, "indented\nother\n", 'aligned resubmission keeps the program executable';

my $help = ListingScreen->new;
$help->{height} = 4;
$help->{wait_for_pause} = 1;
$help->{test_keys} = [['TEXT', 'q']];
$memory->{screen} = $help;
$memory->dispatch('HELP');
ok scalar(grep { /HELP paused/ } @{$help->{seen_status}}), 'HELP pauses before its first screenful scrolls away';
is $memory->source, "    say \"indented\";\nsay \"other\";\n", 'reading paged HELP does not change source';

done_testing;
