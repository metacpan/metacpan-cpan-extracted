#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use File::Spec;

use lib (File::Spec->catdir($FindBin::Bin, 'lib'));

use Test::More tests => 5;

use Catalyst::Test 'TestApp';
use Test::Excel::Template::Plus qw(cmp_excel_files);

BEGIN {
    use_ok('Catalyst::View::Excel::Template::Plus');
}

{
    my $response = request('http://localhost/test_two');

    ok(defined $response, '... got the response successfully');
    ok($response->is_success, '... response is a success');
    is($response->code, 200, '... response code is 200');
    is_deeply(
    [ $response->header('Content-Disposition') ],
    [ 'attachment; filename="test.xls"' ],
    '... the response content disposition is correct and sets the filename');
}
