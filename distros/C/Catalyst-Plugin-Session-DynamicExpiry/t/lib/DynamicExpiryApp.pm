#!/usr/bin/perl

package DynamicExpiryApp;

use strict;
use warnings;

use Catalyst qw/
    Session::DynamicExpiry
    Session
    Session::Store::Dummy
    Session::State::Cookie
/;

__PACKAGE__->setup;

__PACKAGE__;

