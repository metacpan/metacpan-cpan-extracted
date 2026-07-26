#!perl
use 5.008003;
use strict;
use warnings;
use File::Temp ();
use Test::More;
use Chandra::Same::Boy;

# A no-op stand-in for Chandra::App: the Phase 2 API never touches the webview
# (mount is deferred to Phase 3), so an inert object is enough.
{ package FakeApp; sub new { bless {}, shift } }

# Minimal, valid 32KB cartridge (an infinite loop) built in-memory.
sub minimal_rom {
    my %o = @_;
    my $rom = "\x00" x 0x8000;
    substr($rom, 0x100, 4) = "\x00\xC3\x50\x01";
    substr($rom, 0x150, 2) = "\x18\xFE";
    substr($rom, 0x147, 1) = chr($o{mbc} || 0x00);
    substr($rom, 0x149, 1) = chr($o{ram} || 0x00);
    my $x = 0;
    $x = ($x - ord(substr($rom, $_, 1)) - 1) & 0xFF for 0x134 .. 0x14C;
    substr($rom, 0x14D, 1) = chr($x);
    return $rom;
}

plan tests => 19;

my $app = FakeApp->new;

# ---- construction requires app ------------------------------------------
eval { Chandra::Same::Boy->new };
like($@, qr/'app' is required/, 'new croaks without app');

# ---- construct without a ROM, defaults ----------------------------------
{
    my $gb = Chandra::Same::Boy->new(app => $app);
    isa_ok($gb, 'Chandra::Same::Boy');
    is($gb->id, 'gbScreen', 'default id');
    is($gb->scale, 3, 'default scale');
    ok(!defined $gb->boy, 'no boy until a ROM is loaded');
    is_deeply([$gb->dimensions], [160, 144], 'dimensions default before ROM');
}

# ---- events: rom fires on load, with title + crc ------------------------
{
    my $gb = Chandra::Same::Boy->new(app => $app, id => 'screen', scale => 4);
    is($gb->scale, 4, 'scale honoured');

    my @rom;
    $gb->on(rom => sub { my ($w, $title, $crc) = @_; @rom = ($title, $crc) });
    $gb->load_rom(\minimal_rom());

    isa_ok($gb->boy, 'Same::Boy', 'boy created after load_rom');
    is(scalar @rom, 2, 'rom event fired with two args');
    like($rom[1], qr/\A\d+\z/, 'rom event crc is numeric');
    is($gb->rom_title, $rom[0], 'rom_title matches event');
}

# ---- controls (functional without webview) ------------------------------
{
    my $gb = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom());
    ok(!$gb->is_paused, 'not paused initially');
    $gb->pause;  ok($gb->is_paused, 'pause sets flag');
    $gb->toggle_pause; ok(!$gb->is_paused, 'toggle_pause flips');
    isa_ok($gb->resume->reset->set_speed(2)->press('a')->release('a'),
        'Chandra::Same::Boy', 'controls chain');
}

# ---- save state emits save event and round-trips ------------------------
{
    my $gb = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom());
    my @saved;
    $gb->on(save => sub { my ($w, $kind, $path) = @_; push @saved, $kind });

    my $tmp = File::Temp->new(SUFFIX => '.state');
    $gb->save_state("$tmp");
    ok(-s "$tmp", 'save_state writes a file');
    is($saved[0], 'state', 'save event fired with kind=state');
    isa_ok($gb->load_state("$tmp"), 'Chandra::Same::Boy', 'load_state chains');
}

# ---- battery save event on a RAM cartridge ------------------------------
{
    my $gb = Chandra::Same::Boy->new(
        app => $app, rom => \minimal_rom(mbc => 0x1B, ram => 0x02));
    my @kinds;
    $gb->on(save => sub { push @kinds, $_[1] });
    my $tmp = File::Temp->new(SUFFIX => '.sav');
    $gb->save_battery("$tmp");
    is($kinds[0], 'battery', 'save event fired with kind=battery');
}
