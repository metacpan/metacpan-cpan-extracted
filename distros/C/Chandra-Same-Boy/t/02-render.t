#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Chandra::Same::Boy;

# A stub Chandra::App that records the calls mount() makes, so the render
# wiring can be verified without launching a webview.
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
my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom(), sample_rate => 0,
                                  id => 'gbScreen', scale => 4);

# ---- mount wires up content, input bind, and the tick loop --------------
isa_ok($gb->mount, 'Chandra::Same::Boy', 'mount returns self');

my $html = $app->{content};
ok(defined $html, 'set_content was called');
like($html, qr/<canvas id="gbScreen"/,       'canvas element with id');
like($html, qr/width="640" height="576"/,     'canvas scaled 160x144 * 4');
like($html, qr/window\.SB\s*=\s*\{blit:/,      'SB.blit helper injected');
like($html, qr/NW=160, NH=144/,                'offscreen native size 160x144');
like($html, qr/addEventListener\('keydown'/,   'keydown listener injected');
like($html, qr/addEventListener\('keyup'/,     'keyup listener injected');
like($html, qr/__sb_key/,                      'input bridges to __sb_key');
like($html, qr/image-rendering:\s*pixelated/,  'pixelated rendering');

ok($app->{binds}{__sb_key}, 'bind(__sb_key) registered');
is(ref $app->{tick}, 'CODE', 'on_tick registered a coderef');

# ---- input bridge maps to press/release without throwing ----------------
$app->{binds}{__sb_key}->('a', 1);
$app->{binds}{__sb_key}->('a', 0);
pass('__sb_key handler runs press/release');

# ---- the tick loop advances and blits (needs Same::Boy 0.03) ------------
SKIP: {
    skip 'Same::Boy >= 0.03 (pixels_rgba) not available', 5
        unless Same::Boy->can('pixels_rgba');

    # force the pacing gate open and tick once
    $gb->_next(0);
    $app->{tick}->();
    is($gb->frame, 1, 'one tick advanced one frame');
    ok(@{ $app->{evals} }, 'tick emitted a dispatch_eval');
    like($app->{evals}[-1], qr/SB\.blit\('[A-Za-z0-9+\/=]+'\)/,
        'blit called with a base64 payload');

    # draw_every gating
    my $app2 = StubApp->new;
    my $gb2  = Chandra::Same::Boy->new(app => $app2, rom => \minimal_rom(), sample_rate => 0,
                                       draw_every => 2);
    $gb2->mount;
    for (1 .. 2) { $gb2->_next(0); $app2->{tick}->() }
    is($gb2->frame, 2, 'two frames ran');
    is(scalar(grep { /SB\.blit/ } @{ $app2->{evals} }), 1,
        'draw_every=2 blits once per two frames');
}

# ---- pause gates the loop -----------------------------------------------
{
    my $app3 = StubApp->new;
    my $gb3  = Chandra::Same::Boy->new(app => $app3, rom => \minimal_rom(), sample_rate => 0);
    $gb3->mount;
    $gb3->pause;
    $gb3->_next(0);
    $app3->{tick}->();
    is($gb3->frame, 0, 'paused tick does not advance a frame');
}

done_testing;
