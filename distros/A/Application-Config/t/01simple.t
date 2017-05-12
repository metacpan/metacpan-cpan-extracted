#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

ok( my $baseconfig = MyPackage->config );
is( $baseconfig->{Final}->{test}, "simple" );
is_deeply( $baseconfig, MyOtherPackage->config );
is_deeply( $baseconfig, Foo->config );
is_deeply( $baseconfig, My::MyPackage->config );

package Final;
main::is( MyPackage->pkgconfig->{test}, "simple" );


## set up packages to test...
package MyPackage;

use Application::Config;

package MyOtherPackage;

use Application::Config 'mypackage.conf';

package MyFooPackage;

use Application::Config 'mypackage.conf', 'Foo';

package My::MyPackage;

use Application::Config;