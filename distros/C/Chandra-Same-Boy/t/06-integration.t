#!perl
# Integration: real Same::Boy through the widget, no webview. Exercises the
# full video pipeline (pixels_rgba -> base64 -> blit payload), input-map
# validity against the emulator, and battery persistence determinism.
use 5.008003;
use strict;
use warnings;
use File::Temp ();
use MIME::Base64 qw(decode_base64);
use Test::More;
use Chandra::Same::Boy;

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
    sub toast         { 'id0' }
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

sub last_blit {
    my ($app) = @_;
    for my $e (reverse @{ $app->{evals} }) {
        return $1 if $e =~ /SB\.blit\('([^']*)'\)/;
    }
    return undef;
}

# ---- input map is complete and valid against the emulator ---------------
{
    my $app = StubApp->new;
    my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom(),
                                      sample_rate => 0);
    $gb->mount;

    my ($map) = $app->{content} =~ /var MAP=\{(.*?)\}/s;
    ok($map, 'key MAP found in page');
    my %map;
    while ($map =~ /(\w+):'(\w+)'/g) { $map{$1} = $2 }
    cmp_ok(scalar keys %map, '>=', 12, 'key map has the expected entries');

    # Every mapped button name is one the emulator accepts (press must not die).
    my (%buttons, $bad);
    for my $code (sort keys %map) {
        my $btn = $map{$code};
        $buttons{$btn} = 1;
        eval { $gb->press($btn); $gb->release($btn); 1 }
            or do { $bad = "$code=>$btn: $@"; last };
    }
    ok(!$bad, 'every mapped code drives a valid emulator button') or diag($bad);
    is_deeply([sort keys %buttons],
              [sort qw(a b down left right select start up)],
              'all eight Game Boy buttons are reachable');

    # Action map is complete.
    my ($act) = $app->{content} =~ /var ACT=\{(.*?)\}/s;
    my %act;
    while ($act =~ /(\w+):'(\w+)'/g) { $act{$1} = $2 }
    is_deeply([sort values %act],
              [sort qw(load_state pause reset save_state)],
              'action map covers save/load/pause/reset');
    like($app->{content}, qr/e\.code==='Tab'/, 'Tab wired for fast-forward');
}

SKIP: {
    skip 'Same::Boy pixels_rgba not available', 4
        unless Same::Boy->can('pixels_rgba');

    # ---- blit payload is exactly base64(pixels_rgba) --------------------
    {
        my $app = StubApp->new;
        my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom(),
                                          sample_rate => 0);
        $gb->mount;
        $gb->_next(0); $app->{tick}->();

        my $b64 = last_blit($app);
        ok(defined $b64, 'a blit payload was dispatched');
        my $decoded = decode_base64($b64);
        is($decoded, $gb->boy->pixels_rgba,
            'blit payload decodes to the current frame pixels_rgba');
        my ($w, $h) = $gb->dimensions;
        is(length($decoded), $w * $h * 4, 'decoded frame is w*h*4 bytes');
    }

    # ---- frames actually change as the boot animation runs --------------
    {
        my $app = StubApp->new;
        my $gb  = Chandra::Same::Boy->new(app => $app, rom => \minimal_rom(),
                                          sample_rate => 0);
        $gb->mount;
        $gb->_next(0); $app->{tick}->();
        my $first = last_blit($app);
        for (1 .. 120) { $gb->_next(0); $app->{tick}->() }
        my $latest = last_blit($app);
        isnt($first, $latest, 'blit payload changes as frames advance');
    }
}

# ---- battery persistence determinism through the widget -----------------
{
    my $rom   = minimal_rom(mbc => 0x1B, ram => 0x02);   # MBC5+RAM+BATTERY, 8KB
    my $known = join('', map { chr($_ % 256) } 1 .. 8192);
    my $tmp   = File::Temp->new(SUFFIX => '.sav');

    my $gbA = Chandra::Same::Boy->new(app => StubApp->new, rom => \$rom,
                                      sample_rate => 0, sav => "$tmp");
    $gbA->boy->load_battery(\$known);
    $gbA->save_battery("$tmp");
    ok(-s "$tmp", 'widget wrote the battery file');

    # A fresh widget loads <rom>.sav at construction.
    my $gbB = Chandra::Same::Boy->new(app => StubApp->new, rom => \$rom,
                                      sample_rate => 0, sav => "$tmp");
    is($gbB->boy->save_battery, $known,
        'battery round-trips: save in one widget, reload in another');
}

done_testing;
