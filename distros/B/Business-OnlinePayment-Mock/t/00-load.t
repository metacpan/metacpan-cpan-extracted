#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 1;

use_ok( 'Business::OnlinePayment::Mock' );

diag( "Testing Business::OnlinePayment::Mock $Business::OnlinePayment::Mock::VERSION, Perl $], $^X" );
