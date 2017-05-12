#!/usr/bin/env perl
use strict;
use warnings;

## 12-versioning.t
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::ES::OAEP;

plan tests => 2;

eval { my $oaep = new Crypt::RSA::ES::OAEP ( Version => '75.8' ); };
like($@, qr/version/i, "Dies if version number is too high");

my $oaep2 = new Crypt::RSA::ES::OAEP ( Version => '1.14' );
is( $oaep2->{P}, "Crypt::RSA", "Version 1.14 makes a P variable." );
