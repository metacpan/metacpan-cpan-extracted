#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra');

# --- set_title updates stored value ---
# Note: set_title calls webview_set_title which needs initialized webview for
# the actual window, but the XS also updates self->wv.title stored string.
# Without init, webview_set_title may be a no-op or crash, so we skip the
# actual set_title call and test only what we can without a window.

# --- _set_callback basic ---
{
    my $app = Chandra->new();
    my $called = 0;
    
    # _set_callback should not die
    eval { $app->_set_callback(sub { $called = 1 }) };
    is($@, '', '_set_callback does not die');
}

# --- _set_callback replacement ---
{
    my $app = Chandra->new();
    my ($called_a, $called_b) = (0, 0);
    
    $app->_set_callback(sub { $called_a = 1 });
    $app->_set_callback(sub { $called_b = 1 });
    # Should not crash replacing callback
    ok(1, 'replacing callback does not crash');
}

# --- constructor with callback param ---
{
    my @received;
    my $app = Chandra->new(
        callback => sub { push @received, @_ },
    );
    ok($app, 'new with callback');
}

# --- DESTROY does not segfault ---
{
    my $app = Chandra->new(title => 'destroy test');
    undef $app;
    ok(1, 'DESTROY on non-initialized app does not crash');
}

# --- DESTROY with callback cleans up ---
{
    my $app = Chandra->new(
        callback => sub { 1 },
    );
    undef $app;
    ok(1, 'DESTROY with callback does not crash');
}

# --- multiple creates and destroys ---
{
    for my $i (1..5) {
        my $app = Chandra->new(title => "test $i");
    }
    ok(1, 'multiple create/destroy cycles work');
}

done_testing();
