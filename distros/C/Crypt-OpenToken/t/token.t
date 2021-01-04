#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use POSIX qw(strftime);
use Test::More tests => 16;
use Crypt::OpenToken::Token;

###############################################################################
# TEST: instantiation
instantiation: {
    my $token = Crypt::OpenToken::Token->new(version => 1);
    isa_ok $token, 'Crypt::OpenToken::Token';
}

###############################################################################
# TEST: invalid token; before "not-before"
invalid_not_before: {
    my $tomorrow = DateTime->now()->add(days => 1);
    my $date_str = _make_iso8601_date($tomorrow->epoch);

    my $token = Crypt::OpenToken::Token->new( {
        data => { 'not-before' => $date_str },
    } );
    isa_ok $token, 'Crypt::OpenToken::Token';
    ok !$token->is_valid, '... which is invalid; not-before';
}

###############################################################################
# TEST: invalid token; after "not-on-or-after"
invalid_not_on_or_after: {
    my $yesterday = DateTime->now()->subtract(days => 1);
    my $date_str  = _make_iso8601_date($yesterday->epoch);

    my $token = Crypt::OpenToken::Token->new( {
        data => { 'not-on-or-after' => $date_str },
    } );
    isa_ok $token, 'Crypt::OpenToken::Token';
    ok !$token->is_valid, '... which is invalid; not-on-or-after';
}

###############################################################################
# TEST: valid token
valid: {
    my $yesterday = DateTime->now()->subtract(days => 1);
    my $tomorrow  = DateTime->now()->add(days => 1);
    my $token = Crypt::OpenToken::Token->new( {
        data => {
            'not-before'      => _make_iso8601_date($yesterday->epoch),
            'not-on-or-after' => _make_iso8601_date($tomorrow->epoch),
        },
    } );
    isa_ok $token, 'Crypt::OpenToken::Token';
    ok $token->is_valid, '... which is valid';
}

###############################################################################
# TEST: token needs renewal
needs_renewal: {
    my $yesterday = DateTime->now()->subtract(days => 1);
    my $token = Crypt::OpenToken::Token->new( {
        data => {
            'renew-until' => _make_iso8601_date($yesterday->epoch),
        },
    } );
    isa_ok $token, 'Crypt::OpenToken::Token';
    ok $token->requires_renewal, '... which requires renewal';
}

###############################################################################
# TEST: token not in need of renewal; off in future
no_renewal_in_future: {
    my $tomorrow  = DateTime->now()->add(days => 1);
    my $token = Crypt::OpenToken::Token->new( {
        data => {
            'renew-until' => _make_iso8601_date($tomorrow->epoch),
        },
    } );
    isa_ok $token, 'Crypt::OpenToken::Token';
    ok !$token->requires_renewal, '... which does not require renewal';
}

###############################################################################
# TEST: token not in need of renewal; not specified
no_renewal_not_specified: {
    my $yesterday = DateTime->now()->subtract(days => 1);
    my $tomorrow  = DateTime->now()->add(days => 1);
    my $token = Crypt::OpenToken::Token->new( {
        data => {
            'not-before'      => _make_iso8601_date($yesterday->epoch),
            'not-on-or-after' => _make_iso8601_date($tomorrow->epoch),
        },
    } );
    isa_ok $token, 'Crypt::OpenToken::Token';
    ok !$token->requires_renewal, '... which does not require renewal';
}

###############################################################################
# TEST: clock skew
clock_skew: {
    my $before = DateTime->now()->subtract(seconds => 10);
    my $after  = DateTime->now()->add(seconds =>  10);
    my $token = Crypt::OpenToken::Token->new( {
        data => {
            'not-before'      => _make_iso8601_date($after->epoch),
            'not-on-or-after' => _make_iso8601_date($before->epoch),
        },
    } );
    isa_ok $token, 'Crypt::OpenToken::Token';
    ok !$token->is_valid(clock_skew => 1),  '... invalid w/small allowed skew';
    ok  $token->is_valid(clock_skew => 30), '... valid w/larger allowed skew';
}


sub _make_iso8601_date {
    my $time_t = shift;
    return strftime('%Y-%m-%dT%H:%M:%SGMT', gmtime($time_t));
}
