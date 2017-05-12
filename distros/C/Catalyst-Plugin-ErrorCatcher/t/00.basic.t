#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok 'Catalyst::Plugin::ErrorCatcher';
};

can_ok(
    'Catalyst::Plugin::ErrorCatcher',
    qw<
        finalize_error
        my_finalize_error
        setup

        _cleaned_error_message
        _emit_message
        _keep_frames
        _prepare_message
        _print_context
        _require_and_emit
    >
);
