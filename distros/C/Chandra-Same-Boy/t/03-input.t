#!perl
use 5.008003;
use strict;
use warnings;
use File::Temp ();
use Test::More;
use Chandra::Same::Boy;

{
    package StubApp;
    sub new { bless { content => undef, binds => {}, tick => undef, evals => [] }, shift }
    sub set_content   { $_[0]{content} = $_[1];        $_[0] }
    sub bind          { $_[0]{binds}{$_[1]} = $_[2];   $_[0] }
    sub on_tick       { $_[0]{tick} = $_[1];           $_[0] }
    sub dispatch_eval { push @{ $_[0]{evals} }, $_[1]; $_[0] }
    sub eval          { push @{ $_[0]{evals} }, $_[1]; $_[0] }
}

sub minimal_rom {
    my $rom = "\x00" x 0x8000;
    substr($rom, 0x100, 4) = "\x00\xC3\x50\x01";
    substr($rom, 0x150, 2) = "\x18\xFE";
    my $x = 0;
    $x = ($x - ord(substr($rom, $_, 1)) - 1) & 0xFF for 0x134 .. 0x14C;
    substr($rom, 0x14D, 1) = chr($x);
    return $rom;
}

my $app = StubApp->new;
my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom());
$gb->mount;

# ---- action keys present in the page JS ---------------------------------
my $html = $app->{content};
like($html, qr/F2:'save_state'/,  'F2 -> save_state');
like($html, qr/F4:'load_state'/,  'F4 -> load_state');
like($html, qr/KeyP:'pause'/,     'P -> pause');
like($html, qr/KeyR:'reset'/,     'R -> reset');
like($html, qr/e\.code==='Tab'/,  'Tab handled for fast-forward');
like($html, qr/__sb_action/,      'actions bridge to __sb_action');
ok($app->{binds}{__sb_action},    'bind(__sb_action) registered');

# collect action events
my @acts;
$gb->on(action => sub { push @acts, $_[1] });
my $fire = $app->{binds}{__sb_action};

# ---- pause / reset -------------------------------------------------------
$fire->('pause', 1);
is($acts[-1], 'paused', 'pause action -> paused');
ok($gb->is_paused, 'widget is paused');
$fire->('pause', 1);
is($acts[-1], 'resumed', 'second pause -> resumed');
ok(!$gb->is_paused, 'widget resumed');

$fire->('reset', 1);
is($acts[-1], 'reset', 'reset action emits reset');

# ---- fast-forward down/up -----------------------------------------------
$fire->('ff', 1);
is($acts[-1], 'fast_forward_on', 'Tab down -> fast_forward_on');
$fire->('ff', 0);
is($acts[-1], 'fast_forward_off', 'Tab up -> fast_forward_off');

# ---- load with no state file is graceful --------------------------------
$fire->('load_state', 1);
is($acts[-1], 'load_state_missing', 'load_state with no file is graceful');

# ---- save_state with a real path ----------------------------------------
{
    my $tmp = File::Temp->new(SUFFIX => '.state');
    $gb->state_path("$tmp");
    $fire->('save_state', 1);
    is($acts[-1], 'save_state', 'save_state action emits save_state');
    ok(-s "$tmp", 'save_state action wrote the file');

    # now load_state finds it
    $fire->('load_state', 1);
    is($acts[-1], 'load_state', 'load_state action loads existing file');
}

# ---- save_state with no path is graceful --------------------------------
{
    my $app2 = StubApp->new;
    my $gb2  = Chandra::Same::Boy->new(app => $app2, rom => \minimal_rom());
    $gb2->mount;
    my @a2; $gb2->on(action => sub { push @a2, $_[1] });
    $app2->{binds}{__sb_action}->('save_state', 1);
    is($a2[-1], 'save_state_no_path', 'save_state with no path is graceful');
}

done_testing;
