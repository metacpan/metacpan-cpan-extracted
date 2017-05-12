#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;
use Test::MockObject;
use Storable qw/thaw/;

use FindBin qw($Bin);
use lib "$Bin/lib";
use MockCatalyst;
use ok 'TestApp::View::Raw';

my $catalyst = mk_catalyst;
$view = TestApp::View::Raw->COMPONENT($catalyst);

$stash = { unicode => "\x{65e5}\x{672c}\x{8a9e}" };
$view->process;
ok utf8::is_utf8($body), 'output is utf8';
like $content_type, qr/charset=utf-8/, 'is utf8';

$stash = { not_unicode => 'foo bar baz' };
$view->process;
ok !utf8::is_utf8($body), 'output is not utf8';
like $content_type, qr/charset=iso-8859-1/, 'is iso-8859-1';

$view = TestApp::View::Raw->COMPONENT($catalyst,
                                      { CONTENT_TYPE => 'text/plain' }
                                     );
$view->process;
is $content_type, 'text/plain; charset=iso-8859-1', 'is iso-8859-1';
