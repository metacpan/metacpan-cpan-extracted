#!/usr/bin/env perl
use strict;
use warnings;

no warnings 'redefine';

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 
use Test::Output;
use Catalyst::Test 'TestApp';

my $get    = sub { get(join '/', '/errors/signature_error_on_foo', @_) };
my $subget = sub { get(join '/', '/sub_errors/signature_error_on_foo', @_) };
my $modget = sub { get(join '/', '/sub_errors/signature_error_on_foo_modify', @_) };


local *TestApp::debug = sub { 0 };

stderr_like {

    like $get->('bar'),     qr/come back later/i, 'normal handling of method validation error';

} qr/Validation failed/, 'method error throws validation error to error log';

stderr_like {

    like $subget->('bar'),  qr/come back later/i, 'normal handling of method validation error (child)';

} qr/Validation failed/, 'method error throws validation error to error log (child)';

stderr_like {

    like $modget->('bar'),  qr/come back later/i, 'normal handling of method validation error (modified)';

} qr/Validation failed/, 'method error throws validation error to error log (modified)';

is $get->('baz'),       'FOO BAR', 'make sure all works without any errors happening';
is $subget->('baz'),    'FOO BAR', 'make sure all works without any errors happening (child)';
is $modget->('baz'),    'FOO_MODIFY BAR', 'make sure all works without any errors happening (child)';


local *TestApp::debug = sub { 1 };

stderr_unlike {

    is $get->('baz'), 'FOO BAR', 'make sure all works without any errors happening in debug mode';

} qr/\[error\]/i, 'no errors in output';

stderr_unlike {

    is $subget->('baz'), 'FOO BAR', 'make sure all works without any errors happening in debug mode (child)';

} qr/\[error\]/i, 'no errors in output (child)';

stderr_unlike {

    is $modget->('baz'), 'FOO_MODIFY BAR', 'make sure all works without any errors happening in debug mode (modified)';

} qr/\[error\]/i, 'no errors in output (modified)';


done_testing;
