#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );

use Test::More tests => 1;
use lib 't/MyApp/lib';
use lib 't';

use Catalyst::Test 'MyApp';

my $content = get('/test.css');

#diag( $content );

like( $content, qr/some css/, "get test.css" );

1;
