#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use File::Spec;

use lib (File::Spec->catdir($FindBin::Bin, 'lib'));

use Test::More tests => 6;

use Catalyst::Test 'TestApp';
use Test::Excel::Template::Plus qw(cmp_excel_files);

BEGIN {
    use_ok('Catalyst::View::Excel::Template::Plus');
}

{
    my $response = request('http://localhost/test_one');
    
    ok(defined $response, '... got the response successfully');
    ok($response->is_success, '... response is a success');
    is($response->code, 200, '... response code is 200');
    is_deeply(
    [ $response->content_type ], 
    [ 'application/x-msexcel' ], 
    '... the response content type is application/x-msexcel');
    
    my $excel = $response->content;
    
    open my $fh_foo, '>', 'temp.xls' || die "Could not write temp file for testing : $!";
    print $fh_foo $excel;
    close $fh_foo;   
    
    cmp_excel_files("temp.xls", "t/xls/001_basic.xls", '... the generated excel file was correct');

    #`open temp.xls`;
    unlink 'temp.xls';
}