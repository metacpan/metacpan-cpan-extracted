#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
no warnings 'once';

BEGIN {
    plan skip_all => 'CHANDRA_SKIP_WINDOW set' if $ENV{CHANDRA_SKIP_WINDOW};
    if ($^O ne 'darwin' && $^O ne 'MSWin32'
        && !$ENV{DISPLAY} && !$ENV{WAYLAND_DISPLAY}) {
        plan skip_all => 'No display server available';
    }
}

use Chandra;
use Chandra::Splash;

# Check multi-window support
{
    my $splash = eval { Chandra::Splash->new };
    unless ($splash) {
        plan skip_all => 'multi-window not supported on this platform';
    } else {
        $splash->close;
    }
}

my $TMPDIR = tempdir(CLEANUP => 1);

# ---- Constructor defaults ----
{
    my $s = Chandra::Splash->new;
    isa_ok($s, 'Chandra::Splash', 'new() returns blessed object');
    is($s->{title},     'Loading', 'default title');
    is($s->{width},     400,       'default width');
    is($s->{height},    200,       'default height');
    is($s->{frameless}, 0,         'default frameless');
    is($s->{progress},  0,         'default progress');
    is($s->{timeout},   0,         'default timeout');
    is($s->{_wid},      -1,        'wid starts at -1');
    is($s->{_shown},    0,         'not shown yet');
}

# ---- Constructor with all options ----
{
    my $s = Chandra::Splash->new(
        title     => 'My App',
        width     => 600,
        height    => 400,
        frameless => 1,
        progress  => 1,
        timeout   => 5000,
        content   => '<h1>Hello</h1>',
    );
    is($s->{title},     'My App',          'custom title');
    is($s->{width},     600,               'custom width');
    is($s->{height},    400,               'custom height');
    is($s->{frameless}, 1,                 'custom frameless');
    is($s->{progress},  1,                 'custom progress');
    is($s->{timeout},   5000,              'custom timeout');
    is($s->{content},   '<h1>Hello</h1>',  'custom content stored');
}

# ---- show / is_open / wid / close lifecycle ----
{
    my $s = Chandra::Splash->new(title => 'Lifecycle');
    is($s->wid, -1, 'wid is -1 before show');

    my $ret = $s->show;
    is($ret, $s, 'show returns self for chaining');
    ok($s->wid >= 0, 'wid is valid after show');
    ok($s->is_open, 'is_open after show');

    # show again is no-op
    my $wid_before = $s->wid;
    $s->show;
    is($s->wid, $wid_before, 'double show is no-op');

    $s->close;
    is($s->{_shown}, 0, '_shown reset after close');
    is($s->{_wid},  -1, '_wid reset after close');
}

# ---- Custom content ----
{
    my $s = Chandra::Splash->new(
        content => '<div id="test">Custom</div>',
    );
    my $ret = $s->show;
    ok($s->is_open, 'custom content splash is open');
    $s->close;
    ok(!$s->is_open, 'closed');
}

# ---- Progress mode (built-in template) ----
{
    my $s = Chandra::Splash->new(
        title    => 'Loading App',
        progress => 1,
    );
    $s->show;
    ok($s->is_open, 'progress splash is open');

    # update_status returns self
    my $ret = $s->update_status('Step 1...');
    is($ret, $s, 'update_status returns self');

    # update_progress returns self
    $ret = $s->update_progress(50);
    is($ret, $s, 'update_progress returns self');

    $s->update_progress(100);
    $s->close;
    ok(!$s->is_open, 'progress splash closed');
}

# ---- Frameless mode ----
{
    my $s = Chandra::Splash->new(frameless => 1);
    $s->show;
    ok($s->is_open, 'frameless splash is open');
    $s->close;
}

# ---- eval_js escape hatch ----
{
    my $s = Chandra::Splash->new(
        content => '<div id="x">before</div>',
    );
    $s->show;
    $s->eval_js('document.getElementById("x").textContent="after"');
    ok($s->is_open, 'splash still open after eval_js');
    $s->close;
}

# ---- close_if_expired with no timeout ----
{
    my $s = Chandra::Splash->new;
    $s->show;
    my $closed = $s->close_if_expired;
    is($closed, 0, 'close_if_expired returns 0 when no timeout');
    $s->close;
}

# ---- close_if_expired with very short timeout ----
{
    my $s = Chandra::Splash->new(timeout => 1);    # 1ms
    $s->show;
    # Wait a tiny bit to ensure deadline passes
    select(undef, undef, undef, 0.05);
    my $closed = $s->close_if_expired;
    is($closed, 1, 'close_if_expired returns 1 after deadline');
    ok(!$s->is_open, 'window closed by close_if_expired');
}

# ---- close_if_expired with long timeout (not yet expired) ----
{
    my $s = Chandra::Splash->new(timeout => 60000);  # 60s
    $s->show;
    my $closed = $s->close_if_expired;
    is($closed, 0, 'close_if_expired returns 0 before deadline');
    ok($s->is_open, 'window still open');
    $s->close;
}

# ---- Image mode ----
{
    # Create a 1x1 red PNG (minimal valid PNG)
    my $png = pack('H*',
        '89504e470d0a1a0a0000000d49484452000000010000000108020000009001' .
        '2e00000000000c4944415408d76360f8cf00000002000160e7274a00000000' .
        '49454e44ae426082'
    );
    my $img = "$TMPDIR/splash.png";
    open my $fh, '>', $img or die "open: $!";
    binmode $fh;
    print $fh $png;
    close $fh;

    my $s = Chandra::Splash->new(
        image     => $img,
        frameless => 1,
    );
    $s->show;
    ok($s->is_open, 'image splash is open');
    $s->close;
}

# ---- Image mode with missing file ----
{
    my $s = Chandra::Splash->new(
        image => "$TMPDIR/nonexistent.png",
    );
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $s->show;
    ok(grep(/cannot open image/, @warnings), 'warns on missing image');
    $s->close;
}

# ---- DESTROY cleans up native window ----
{
    my $wid;
    {
        my $s = Chandra::Splash->new;
        $s->show;
        $wid = $s->wid;
        ok($wid >= 0, 'wid valid before DESTROY');
    }
    # After scope exit, DESTROY should have closed the window
    # We can't easily check native state, but at least it doesn't crash
    pass('DESTROY did not crash');
}

# ---- Methods exist ----
{
    my $s = Chandra::Splash->new;
    can_ok($s, qw(
        new show close is_open wid
        update_status update_progress
        eval_js close_if_expired
        DESTROY
    ));
}

# ---- Bare splash (no progress, no content) uses default template ----
{
    my $s = Chandra::Splash->new(title => 'Bare');
    $s->show;
    ok($s->is_open, 'bare splash shows');
    $s->close;
}

# ---- Multiple splashes ----
{
    my $s1 = Chandra::Splash->new(title => 'One');
    my $s2 = Chandra::Splash->new(title => 'Two');
    $s1->show;
    $s2->show;
    ok($s1->is_open && $s2->is_open, 'two splashes open');
    ok($s1->wid != $s2->wid, 'different wids');
    $s1->close;
    $s2->close;
}

done_testing;
