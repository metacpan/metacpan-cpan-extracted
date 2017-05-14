#!/usr/bin/env perl

package SessionTestApp;
use Catalyst qw/Session Session::Store::Dummy Session::State::Cookie Authentication/;

use strict;
use warnings;

__PACKAGE__->config('Plugin::Session' => {
        # needed for live_verify_user_agent.t; should be harmless for other tests
        verify_user_agent => 1,
        verify_address => 1,
    },

    'Plugin::Authentication' => {
        default => {
            credential => {
                class => 'Password',
                password_field => 'password',
                password_type => 'clear'
            },
            store => {
                class => 'Minimal',
                users => {
                    bob => {
                        password => "s00p3r",
                    },
                    william => {
                        password => "s3cr3t",
                    },
                },
            },
        },
    },
);

__PACKAGE__->setup;

__PACKAGE__;

