#!/usr/bin/perl

# MIT License
#
# Copyright (c) 2017 Lari Taskula  <lari@taskula.fi>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use strict;
use warnings;

use Test::More tests => 1;
use Test::Warn;
use Data::Dumper;
use Binance::API::Logger;
use Binance::API::Request;

subtest '_init() tests' => sub {
    plan tests => 2;

    subtest 'recvWindow only for signed requests' => sub {
        plan tests => 6;

        my $recv = Binance::API::Request->new(
            recvWindow => 12345,
            secretKey => 'test',
            logger => Binance::API::Logger->new()
        );

        # Mixed
        my ($ret, %data) = $recv->_init('/test', {
            query => { q_param => 'query' },
            body => { b_param => 'body' },
            signed => 0
        } );
        unlike($ret, qr/recvWindow/, 'No recvWindow unsigned mixed req');
        ($ret, %data) = $recv->_init('/test', {
            query => { q_param => 'query' },
            body => { b_param => 'body' },
            signed => 1
        } );
        like($ret, qr/recvWindow=12345/, 'recvWindow signed mixed req');

        # Query only
        ($ret, %data) = $recv->_init('/test',
            { query => { test => 'test' }, signed => 0 }
        );
        unlike($ret, qr/recvWindow/, 'No recvWindow unsigned query');
        ($ret, %data) = $recv->_init('/test',
            { query => { test => 'test' }, signed => 1 }
        );
        like($ret, qr/recvWindow=12345/, 'recvWindow signed query');

        # Body only
        ($ret, %data) = $recv->_init('/test',
            { body => { test => 'test' }, signed => 0 }
        );
        unlike($data{'Content'}, qr/recvWindow/, 'No recvWindow unsigned body');
        ($ret, %data) = $recv->_init('/test',
            { body => { test => 'test' }, signed => 1 }
        );
        like($data{'Content'}, qr/recvWindow=12345/, 'recvWindow signed body');

    };

    subtest 'Verify signatures' => sub {
        plan tests => 1;

        my ($mix_signature, $b_signature, $q_signature);
        my $recv = Binance::API::Request->new(
            recvWindow => 12345,
            secretKey => 'test',
            logger => Binance::API::Logger->new()
        );

        # Mixed
        my ($ret, %data) = $recv->_init('/test', {
            query => {
                symbol => 'LTCBTC', side => 'BUY', type => 'LIMIT',
                timeInForce => 'GTC'
            },
            body => {
                quantity => 1, price => 0.1, recvWindow => 5000
            },
            signed => 1,
            timestamp => 1499827319559,
        } );
        $mix_signature = $data{'Content'};

        # Query only
        ($ret, %data) = $recv->_init('/test', {
            query => {
                quantity => 1, price => 0.1, recvWindow => 5000,
                symbol => 'LTCBTC', side => 'BUY', type => 'LIMIT',
                timeInForce => 'GTC'
            },
            signed => 1,
            timestamp => 1499827319559,
        } );
        $q_signature = $1 if $ret =~ /signature=(\w+)$/;

        # Body only
        ($ret, %data) = $recv->_init('/test', {
            body => {
                quantity => 1, price => 0.1, recvWindow => 5000,
                symbol => 'LTCBTC', side => 'BUY', type => 'LIMIT',
                timeInForce => 'GTC'
            },
            signed => 1,
            timestamp => 1499827319559,
        }  );
        $b_signature = $1 if $data{'Content'} =~ /signature=(\w+)$/;

        is($b_signature, $q_signature, 'Body only and query only signatures match');
    };
}

