use Modern::Perl;
use lib 't/lib';
use lib 'lib';
use Test2::V0;
use Test2::Tools::Subtest qw/subtest_buffered subtest_streamed/;

use FindBin qw($Bin);

use Plack::Test;
use HTTP::Request::Common;
use JSON::MaybeXS;
use File::Copy qw(copy);

my $test_db_file  = 't/db/test_database.sqlite3';
my $clean_db_file = 't/db/test_database.sqlite3.orig';

# Test needs to start with a fresh database
if ( -f "$test_db_file" ) {
   unlink("$test_db_file");
}
copy $clean_db_file, $test_db_file;

use TestViewCache;

plan(3);

my $test = Plack::Test->create( TestViewCache->to_app );

subtest 'Check keyword generate_guest_url with generated code' => sub {
   plan(4);

   my $res = $test->request( GET '/' );

   ok( $res->is_success, 'Successful request' );
   my $res_code = $res->code;
   is( $res->code, '200', 'HTTP response 200 received' );

   my $content = $res->content;
   like( $content, qr/^https?:\/\//, 'Response has URL beginning with http' );

   my $view_page = $test->request( GET $content);
   like( $view_page->content, qr|<body>Hello world!</body>|, 'Page returned by the URL returns expected content' );

};

subtest_streamed 'Check keyword generate_guest_url with provided code' => sub {
   plan(4);

   my $random1     = int( rand(1000) );
   my $random2     = int( rand(1000) );
   my $custom_code = $random1 . 'abc' . $random2;
   note("Custom code provided to site is $custom_code");

   my $res_with_code = $test->request( GET '/' . $custom_code );
   ok( $res_with_code->is_success, 'Successful request' );
   my $res_code = $res_with_code->code;
   is( $res_with_code->code, '200', 'HTTP response 200 received' );

   my $content = $res_with_code->content;
   like( $content, qr/$custom_code/, 'Response has URL containing the custom code provided by the caller' );

   my $view_with_code = $test->request( GET $content);
   like(
      $view_with_code->content,
      qr|<body>Hello world!</body>|,
      'Page returned by the URL with provided code returns expected content'
   );

};

subtest_streamed 'Database entry deleted when delete_after_view set' => sub {
   plan(5);

   my $del_res = $test->request( GET '/?delete_after_view=1' );
   ok( $del_res->is_success, 'Successful request' );

   my $res_code = $del_res->code;
   is( $del_res->code, '200', 'HTTP response 200 received' );

   my $content    = $del_res->content;
   my $first_view = $test->request( GET $content);
   like(
      $first_view->content,
      qr|<body>Hello world!</body>|,
      'Page returned by the URL returns expected content for the first view'
   );

   my $second_view = $test->request( GET $content);
   is( $second_view->code, '200', 'HTTP response 200 received' );
   like( $second_view->content, qr/Unable to find content to display/, 'Page displays expected error on second view' );

};

END {
   if ( -f "$test_db_file" ) {
      unlink("$test_db_file");
   }
}