#!perl
use 5.008003;
use strict;
use warnings;
use File::Temp ();
use Test::More;
use Chandra::Same::Boy;

# Stub app that also records on_close and toast (Phase 6 surface).
{
    package StubApp;
    sub new { bless { content => undef, binds => {}, tick => undef,
                      evals => [], toasts => [], on_close => undef }, shift }
    sub set_content   { $_[0]{content} = $_[1];        $_[0] }
    sub bind          { $_[0]{binds}{$_[1]} = $_[2];   $_[0] }
    sub on_tick       { $_[0]{tick} = $_[1];           $_[0] }
    sub on_close      { $_[0]{on_close} = $_[1];       $_[0] }
    sub dispatch_eval { push @{ $_[0]{evals} }, $_[1]; $_[0] }
    sub eval          { push @{ $_[0]{evals} }, $_[1]; $_[0] }
    sub toast         { push @{ $_[0]{toasts} }, [ $_[1], { @_[2 .. $#_] } ]; 'id0' }
}

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

# ---- toolbar + HUD chrome in the page -----------------------------------
{
    my $app = StubApp->new;
    my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom(),
                                      sample_rate => 0);
    $gb->mount;
    my $h = $app->{content};
    like($h, qr/id="sb-bar"/,               'toolbar present');
    like($h, qr/data-act="pause"/,          'pause button');
    like($h, qr/data-act="save_state"/,     'save button');
    like($h, qr/data-act="load_state"/,     'load button');
    like($h, qr/data-act="mute"/,           'mute button');
    like($h, qr/data-act="open"/,           'open button');
    like($h, qr/id="sb-title"/,             'HUD title');
    like($h, qr/id="sb-fps"/,               'HUD fps');
    like($h, qr/window\.SB_hud\s*=/,        'SB_hud helper');
    like($h, qr/getAttribute\('data-act'\)/, 'toolbar buttons wired to act()');

    # on_close registered for battery flush
    is(ref $app->{on_close}, 'CODE', 'on_close handler registered');
    # HUD seeded on mount
    my $ev = join "\n", @{ $app->{evals} };
    like($ev, qr/SB_hud\('title'/, 'HUD title seeded at mount');
    like($ev, qr/SB_hud\('speed','1x'\)/, 'HUD speed seeded at mount');
}

# ---- toasts on actions --------------------------------------------------
{
    my $app = StubApp->new;
    my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom(),
                                      sample_rate => 0);
    $gb->mount;
    my $fire = $app->{binds}{__sb_action};

    $fire->('pause', 1);
    is($app->{toasts}[-1][0], 'Paused', 'pause toast');
    is($app->{toasts}[-1][1]{type}, 'info', 'pause toast type');

    $fire->('mute', 1);
    is($app->{toasts}[-1][0], 'Muted', 'mute toast');

    my $tmp = File::Temp->new(SUFFIX => '.state');
    $gb->state_path("$tmp");
    $fire->('save_state', 1);
    is($app->{toasts}[-1][0], 'State saved', 'save toast (success)');
    is($app->{toasts}[-1][1]{type}, 'success', 'save toast type');

    # speed HUD on fast-forward
    $fire->('ff', 1);
    like(join("\n", @{ $app->{evals} }), qr/SB_hud\('speed','4x'\)/, 'speed HUD 4x');
}

# ---- battery autosave interval + shutdown flush -------------------------
SKIP: {
    skip 'Same::Boy >= 0.03 (pixels_rgba) not available', 3
        unless Same::Boy->can('pixels_rgba');

    my $app = StubApp->new;
    # RAM cartridge so save_battery writes; short autosave interval
    my $rom = minimal_rom(mbc => 0x1B, ram => 0x02);
    my $tmp = File::Temp->new(SUFFIX => '.sav');
    my $gb  = Chandra::Same::Boy->new(app => $app, rom => \$rom,
                                      sample_rate => 0, autosave => 0.001,
                                      sav => "$tmp");
    $gb->mount;

    # force a tick past the autosave deadline
    $gb->_next(0); $gb->_sav_next(0);
    select(undef, undef, undef, 0.005);   # let wall-clock pass the deadline
    $app->{tick}->();
    ok(-s "$tmp", 'autosave wrote the battery during play');

    unlink "$tmp";
    ok(!-e "$tmp", 'sav removed for shutdown check');
    $gb->shutdown;
    ok(-s "$tmp", 'shutdown flushed the battery');
}

# ---- on_close handler flushes too ---------------------------------------
SKIP: {
    skip 'Same::Boy >= 0.03 not available', 1
        unless Same::Boy->can('pixels_rgba');
    my $app = StubApp->new;
    my $rom = minimal_rom(mbc => 0x1B, ram => 0x02);
    my $tmp = File::Temp->new(SUFFIX => '.sav'); unlink "$tmp";
    my $gb  = Chandra::Same::Boy->new(app => $app, rom => \$rom,
                                      sample_rate => 0, sav => "$tmp");
    $gb->mount;
    $app->{on_close}->();   # simulate window close
    ok(-s "$tmp", 'on_close handler flushed the battery');
}

done_testing;
