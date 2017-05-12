#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok('Catalyst::Authentication::Credential::HTTP::Proxy');
    use_ok('Catalyst::Authentication::Credential::HTTP::Proxy::User');
}
