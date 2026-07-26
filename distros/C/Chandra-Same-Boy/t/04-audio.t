#!perl
use 5.008003;
use strict;
use warnings;
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

# ---- Web Audio sink is injected -----------------------------------------
{
    my $app = StubApp->new;
    my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom());
    $gb->mount;
    my $html = $app->{content};
    like($html, qr/window\.SBA\s*=/,        'SBA audio sink injected');
    like($html, qr/AudioContext/,           'uses AudioContext');
    like($html, qr/createBuffer\(2,/,       'builds stereo AudioBuffer');
    like($html, qr/SBA\.resume\(\)/,        'resumes audio on first keydown');
}

# ---- volume / mute dispatch setVolume -----------------------------------
{
    my $app = StubApp->new;
    my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom());
    $gb->mount;

    $gb->set_volume(0.5);
    like($app->{evals}[-1], qr/SBA\.setVolume\(0\.5\)/, 'set_volume dispatches');

    $gb->mute;
    like($app->{evals}[-1], qr/SBA\.setVolume\(0\)/, 'mute -> volume 0');
    ok($gb->is_muted, 'is_muted true');

    $gb->mute;
    like($app->{evals}[-1], qr/SBA\.setVolume\(0\.5\)/, 'unmute restores 0.5');
    ok(!$gb->is_muted, 'is_muted false');

    $gb->set_volume(2);   # clamped
    like($app->{evals}[-1], qr/SBA\.setVolume\(1\)/, 'volume clamped to 1');
}

SKIP: {
    skip 'Same::Boy >= 0.03 (pixels_rgba) not available', 4
        unless Same::Boy->can('pixels_rgba');

    # ---- tick pumps audio when sample_rate is set -----------------------
    {
        my $app = StubApp->new;
        my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom(),
                                          sample_rate => 44100);
        $gb->mount;
        $gb->_next(0); $app->{tick}->();
        my $joined = join "\n", @{ $app->{evals} };
        like($joined, qr/SBA\.push\('[A-Za-z0-9+\/=]+',44100\)/,
            'tick pumps audio via SBA.push with rate');
    }

    # ---- no audio pumped when sample_rate is 0 --------------------------
    {
        my $app = StubApp->new;
        my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom(),
                                          sample_rate => 0);
        $gb->mount;
        $gb->_next(0); $app->{tick}->();
        my $joined = join "\n", @{ $app->{evals} };
        unlike($joined, qr/SBA\.push/, 'no audio pumped with sample_rate=0');
    }

    # ---- fast-forward mutes the audio dispatch --------------------------
    {
        my $app = StubApp->new;
        my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom(),
                                          sample_rate => 44100);
        $gb->mount;
        $app->{binds}{__sb_action}->('ff', 1);   # fast-forward on
        my $before = @{ $app->{evals} };
        $gb->_next(0); $app->{tick}->();
        my $after = grep { /SBA\.push/ } @{ $app->{evals} };
        is($after, 0, 'no SBA.push while fast-forwarding');

        $app->{binds}{__sb_action}->('ff', 0);   # fast-forward off
        $gb->_next(0); $app->{tick}->();
        my $now = grep { /SBA\.push/ } @{ $app->{evals} };
        cmp_ok($now, '>', 0, 'audio resumes after fast-forward');
    }
}

done_testing;
