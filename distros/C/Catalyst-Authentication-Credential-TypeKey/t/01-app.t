#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::MockObject::Extends;
use Test::MockObject;
use Test::Exception;
use Scalar::Util qw/blessed/;

use Catalyst::Plugin::Authentication::User::Hash;

my $m;
BEGIN { use_ok( $m = "Catalyst::Authentication::Credential::TypeKey" ) }

done_testing();