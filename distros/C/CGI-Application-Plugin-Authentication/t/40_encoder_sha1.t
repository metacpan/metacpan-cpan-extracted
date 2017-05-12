#!/usr/bin/perl
use Test::More;

use strict;
use warnings;

use Digest::SHA;

plan tests => 17;

use_ok('CGI::Application::Plugin::Authentication::Driver::Filter::sha1');
my $class = 'CGI::Application::Plugin::Authentication::Driver::Filter::sha1';

# Test binary
my $binary = Digest::SHA::sha1('123');
is($class->filter('binary', '123'), $binary, "filter");
ok($class->check('binary', '123', $binary), "check passes");
ok(!$class->check('binary', 'xxx', $binary), "check fails");
ok($class->check(undef, '123', $binary), "check passes");
ok(!$class->check(undef, 'xxx', $binary), "check fails");

# Test base64
is($class->filter('base64', '123'), 'QL0AFWMIX8NRZTKeof9cXsvbvu8', "filter");
ok($class->check('base64', '123', 'QL0AFWMIX8NRZTKeof9cXsvbvu8'), "check passes");
ok(!$class->check('base64', 'xxx', 'QL0AFWMIX8NRZTKeof9cXsvbvu8'), "check fails");
ok($class->check(undef, '123', 'QL0AFWMIX8NRZTKeof9cXsvbvu8'), "check passes");
ok(!$class->check(undef, 'xxx', 'QL0AFWMIX8NRZTKeof9cXsvbvu8'), "check fails");

# Test hex
is($class->filter('hex', '123'), '40bd001563085fc35165329ea1ff5c5ecbdbbeef', "filter");
ok($class->check('hex', '123', '40bd001563085fc35165329ea1ff5c5ecbdbbeef'), "check passes");
ok(!$class->check('hex', 'xxx', '40bd001563085fc35165329ea1ff5c5ecbdbbeef'), "check fails");
is($class->filter(undef, '123'), '40bd001563085fc35165329ea1ff5c5ecbdbbeef', "filter");
ok($class->check(undef, '123', '40bd001563085fc35165329ea1ff5c5ecbdbbeef'), "check passes");
ok(!$class->check(undef, 'xxx', '40bd001563085fc35165329ea1ff5c5ecbdbbeef'), "check fails");

