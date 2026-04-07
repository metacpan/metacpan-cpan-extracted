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

# ---- Odd number of args croaks ----
{
    eval { Chandra::Splash->new('orphan') };
    like($@, qr/key => value/, 'odd args croak');
}

# ---- close before show ----
{
    my $s = Chandra::Splash->new;
    eval { $s->close };
    is($@, '', 'close before show does not croak');
    is($s->{_wid}, -1, 'wid still -1');
}

# ---- update_status before show ----
{
    my $s = Chandra::Splash->new;
    my $ret = eval { $s->update_status('test') };
    is($@, '', 'update_status before show does not croak');
    is($ret, $s, 'returns self');
}

# ---- update_progress before show ----
{
    my $s = Chandra::Splash->new;
    my $ret = eval { $s->update_progress(50) };
    is($@, '', 'update_progress before show does not croak');
    is($ret, $s, 'returns self');
}

# ---- Progress clamping: below 0 ----
{
    my $s = Chandra::Splash->new(progress => 1);
    $s->show;
    my $ret = eval { $s->update_progress(-10) };
    is($@, '', 'negative progress does not croak');
    is($ret, $s, 'returns self');
    $s->close;
}

# ---- Progress clamping: above 100 ----
{
    my $s = Chandra::Splash->new(progress => 1);
    $s->show;
    my $ret = eval { $s->update_progress(999) };
    is($@, '', 'over-100 progress does not croak');
    is($ret, $s, 'returns self');
    $s->close;
}

# ---- Empty content ----
{
    my $s = Chandra::Splash->new(content => '');
    $s->show;
    ok($s->is_open, 'empty content splash opens');
    $s->close;
}

# ---- Status text with special characters (JS injection prevention) ----
{
    my $s = Chandra::Splash->new(progress => 1);
    $s->show;
    eval {
        $s->update_status("it's a \"test\" with <html> & \\ chars");
    };
    is($@, '', 'special chars in status do not croak');
    ok($s->is_open, 'still open after special-char status');
    $s->close;
}

# ---- Status with newlines ----
{
    my $s = Chandra::Splash->new(progress => 1);
    $s->show;
    eval { $s->update_status("line1\nline2\rline3") };
    is($@, '', 'newlines in status do not croak');
    $s->close;
}

# ---- Rapid progress updates ----
{
    my $s = Chandra::Splash->new(progress => 1);
    $s->show;
    eval {
        for my $i (0..100) {
            $s->update_progress($i);
        }
    };
    is($@, '', 'rapid progress updates do not croak');
    $s->close;
}

# ---- eval_js before show ----
{
    my $s = Chandra::Splash->new;
    eval { $s->eval_js('1+1') };
    is($@, '', 'eval_js before show does not croak');
}

# ---- close_if_expired before show ----
{
    my $s = Chandra::Splash->new(timeout => 1);
    my $ret = $s->close_if_expired;
    is($ret, 0, 'close_if_expired before show returns 0');
}

# ---- wid before show ----
{
    my $s = Chandra::Splash->new;
    is($s->wid, -1, 'wid is -1 before show');
}

# ---- is_open before show ----
{
    my $s = Chandra::Splash->new;
    ok(!$s->is_open, 'is_open returns false before show');
}

# ---- Double close ----
{
    my $s = Chandra::Splash->new;
    $s->show;
    $s->close;
    eval { $s->close };
    is($@, '', 'double close does not croak');
}

# ---- Image with .jpg extension ----
{
    # Create minimal JFIF file (not valid image, but enough for the read path)
    my $jpg_data = "\xff\xd8\xff\xe0" . ("\x00" x 20) . "\xff\xd9";
    my $img = "$TMPDIR/splash.jpg";
    open my $fh, '>', $img or die "open: $!";
    binmode $fh;
    print $fh $jpg_data;
    close $fh;

    my $s = Chandra::Splash->new(image => $img);
    $s->show;
    ok($s->is_open, 'jpg image splash opens');
    $s->close;
}

# ---- Large content ----
{
    my $big = '<p>' . ('x' x 50000) . '</p>';
    my $s = Chandra::Splash->new(content => $big);
    $s->show;
    ok($s->is_open, 'large content splash opens');
    $s->close;
}

# ---- Zero timeout means no auto-close ----
{
    my $s = Chandra::Splash->new(timeout => 0);
    $s->show;
    select(undef, undef, undef, 0.05);
    my $closed = $s->close_if_expired;
    is($closed, 0, 'zero timeout never expires');
    $s->close;
}

# ---- Show after close (re-show) ----
{
    my $s = Chandra::Splash->new;
    $s->show;
    my $wid1 = $s->wid;
    $s->close;
    ok(!$s->is_open, 'closed');

    $s->show;
    ok($s->is_open, 're-shown');
    ok($s->wid != $wid1, 'new wid on re-show');
    $s->close;
}

# ---- $app->splash() convenience ----
SKIP: {
    eval { require Chandra::App };
    skip 'Chandra::App not available', 2 if $@;

    my $app = eval { Chandra::App->new(title => 'Splash Test') };
    skip 'cannot create app', 2 unless $app;

    my $init_called = 0;
    my $ret = $app->splash(
        progress => 1,
        timeout  => 0,
        init     => sub {
            my ($s) = @_;
            $init_called = 1;
            isa_ok($s, 'Chandra::Splash', 'init receives splash object');
        },
    );
    ok($init_called, 'init callback was called');
}

done_testing;
