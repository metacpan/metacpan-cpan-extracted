
use strict;
use warnings;

use Test::More;

use Catalyst::Plugin::ExternalURI; 

my $tests = {
    'http://static.example.com/mystatic' => {
         host => 'static.example.com',
         path => '/mystatic',
         scheme => 'http'
   },
   'http://css.example.com' => {
         scheme => 'http',
         host => 'css.example.com'
   },
   'https://www.example.com' => {
         scheme => 'https',
         host => 'www.example.com'
   },
   'js.example.com:99' => {
       host => 'js.example.com',
       port => 99

   },
   'content.example.com' => {
       host => 'content.example.com'
   },
   'https://' =>  {
       scheme => 'https'
   },
   'http://' =>  {
       scheme => 'http'
   },
   'http://www.example.com/?testparam=1' => {
       scheme => 'http',
       host => 'www.example.com',
       query => 'testparam=1',
   },
   '://another.example.com' => {
       host => 'another.example.com'
   }
};

foreach my $test_name (keys %$tests){
  my $changes = eval { Catalyst::Plugin::ExternalURI->_get_changes_for_uri($test_name) };

  if ($@){
    ok (0, "_get_changes_for_uri $test_name failed with $@")
  } else {
    is_deeply(
     $changes,
     $tests->{ $test_name },
     "Got correct changes for $test_name"
     );
  }
}

done_testing;
