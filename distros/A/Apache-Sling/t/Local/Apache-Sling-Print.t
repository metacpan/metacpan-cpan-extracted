#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;
use File::Temp;
BEGIN { use_ok( 'Apache::Sling' ); }
BEGIN { use_ok( 'Apache::Sling::Content' ); }
BEGIN { use_ok( 'Apache::Sling::Print' ); }

ok( Apache::Sling::Print::print_lock('Check print_lock function'), 'Check print_lock function' );
ok( Apache::Sling::Print::print_with_lock('Check print_with_lock function'), 'Check print_with_lock function' );
my ( $tmp_print_file_handle, $tmp_print_file_name ) = File::Temp::tempfile();
ok( Apache::Sling::Print::print_with_lock('Check print_with_lock function',$tmp_print_file_name), 'Check print_with_lock function to file' );
ok( Apache::Sling::Print::print_file_lock('Check print_file_lock function',$tmp_print_file_name), 'Check print_file_lock function' );
my $file;
throws_ok{ Apache::Sling::Print::print_with_lock('Check print_with_lock function',\$file); } qr%%, 'Check print_with_lock function to in memory file fails';
close $tmp_print_file_handle;
unlink($tmp_print_file_name);
ok( Apache::Sling::Print::date_time('Check date_time function'), 'Check date_time function' );
ok( Apache::Sling::Print::date_string(1, 1, 100, 1, 1, 1, 1), 'Check date_string function single figure units' );
ok( Apache::Sling::Print::date_string(1, 1, 100, 1, 1, 30, 30), 'Check date_string function double figure units' );

# sling object:
my $sling = Apache::Sling->new();
isa_ok $sling, 'Apache::Sling', 'sling';
my $authn   = new Apache::Sling::Authn(\$sling);
my $content = new Apache::Sling::Content(\$authn,'1');
my $res = HTTP::Response->new( '200' );
$content->{'Response'} = \$res;

ok( Apache::Sling::Print::print_result($content), 'Check print_result function' );
$content->{'Verbose'} = 3;
ok( Apache::Sling::Print::print_result($content), 'Check print_result function with extra verbosity' );
