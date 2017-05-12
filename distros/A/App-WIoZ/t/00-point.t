#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test to fix point syntaxe.

=cut

use Test::More tests => 3;

use_ok('App::WIoZ::Point');


my $center = App::WIoZ::Point->new( x => 10, y => 20 );
is($center->x,10,'x set to 10');
is($center->y,20,'y set to 20');

