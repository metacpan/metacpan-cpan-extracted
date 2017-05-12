#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 5;
use_ok('Class::AutoGenerate');

package My::ClassLoader;
use Class::AutoGenerate -base;

requiring '**' => generates {};

package main;

my $class_loader1 = My::ClassLoader->new( match_only => 'Prefix1::**' );
my $class_loader2 = My::ClassLoader->new( match_only => 'Prefix2::**' );

require_ok('Prefix1::Thing');
is($INC{'Prefix1/Thing.pm'}, $class_loader1);

require_ok('Prefix2::Thing');
is($INC{'Prefix2/Thing.pm'}, $class_loader2);


