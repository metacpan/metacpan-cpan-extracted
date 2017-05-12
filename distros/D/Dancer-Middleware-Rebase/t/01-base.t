# vim: filetype=perl :
use strict;
use warnings;

#use Test::More tests => 1; # last test to print
use Test::More 'no_plan';    # substitute with previous line when done

use Dancer::Middleware::Rebase;

{
   my $app = sub {
      my ($env) = @_;
      is($env->{'psgi.url_scheme'}, 'http',              'scheme is good');
      is($env->{HTTP_HOST},         'polettix.it:12345', 'host is good');
      is($env->{SCRIPT_NAME},       '/whatever',         'prefix is good');
      is($env->{PATH_INFO}, '/whatever/you/want',
         'PATH_INFO did not change');
   };

   Dancer::Middleware::Rebase->wrap($app,
      base => 'http://polettix.it:12345/whatever',)->(
      {
         'psgi.url_scheme' => 'ftp',
         HTTP_HOST         => '127.0.0.1:54321',
         SCRIPT_NAME       => '/path/to/nowhere',
         PATH_INFO         => '/whatever/you/want',
      }
      );
}
{
   my $app = sub {
      my ($env) = @_;
      is($env->{'psgi.url_scheme'}, 'http',              'scheme is good');
      is($env->{HTTP_HOST},         'polettix.it:12345', 'host is good');
      is($env->{SCRIPT_NAME},       '/whatever/',         'prefix is good');
      is($env->{PATH_INFO}, '/whatever/you/want',
         'PATH_INFO did not change');
   };

   Dancer::Middleware::Rebase->wrap($app,
      base => 'http://polettix.it:12345/whatever/',)->(
      {
         'psgi.url_scheme' => 'ftp',
         HTTP_HOST         => '127.0.0.1:54321',
         SCRIPT_NAME       => '/path/to/nowhere',
         PATH_INFO         => '/whatever/you/want',
      }
      );
}
