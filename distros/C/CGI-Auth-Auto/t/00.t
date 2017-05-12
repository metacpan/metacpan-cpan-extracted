use Test::Simple 'no_plan';
use strict;
use lib './lib';
use CGI::Auth::Auto;
use File::Path;
use Cwd;

$CGI::Auth::Auto::DEBUG = 1;

$CGI::Scriptpaths::DEBUG = 1;

_makefiles();


my $a = new CGI::Auth::Auto;

ok($a,'instanced');



sub _makefiles{
   
   File::Path::rmtree( cwd().'/t/auth' );

   mkdir cwd().'/t/auth';
   mkdir cwd().'/t/auth/sess';

   open(FILE,'>',cwd().'/t/auth/user.dat') or die;
   print FILE "default:PfmFKhUXeqTUwPfo62LcyAuTjA\n";
   close FILE;
   
   return;
}


   File::Path::rmtree( cwd().'/t/auth' );

