#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

my $content = "key:value\n";

# Verify error messages reference the correct namespace (Colon::Config, not Config::Colon)

like(
    dies { Colon::Config::read( $content, 1, 2 ) },
    qr/Colon::Config::read/,
    "too many arguments error references correct namespace"
);

like(
    dies { Colon::Config::read( $content, -1 ) },
    qr/Colon::Config::read/,
    "negative field error references correct namespace"
);

like(
    dies { Colon::Config::read( $content, "abc" ) },
    qr/Colon::Config::read/,
    "non-integer field error references correct namespace"
);

# Verify error messages do NOT reference the wrong namespace
my $err_too_many = dies { Colon::Config::read( $content, 1, 2 ) };
unlike( $err_too_many, qr/Config::Colon/, "error does not reference wrong namespace Config::Colon" );

done_testing;
