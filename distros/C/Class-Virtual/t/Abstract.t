#!/usr/bin/perl -w

use strict;
use Test::More tests => 18;

BEGIN { use_ok 'Class::Virtually::Abstract'; }


my @vmeths = qw(new foo bar this that);
my $ok;

package Foo::Virtual;
use base qw(Class::Virtually::Abstract);
__PACKAGE__->virtual_methods(@vmeths);

::is_deeply([sort __PACKAGE__->virtual_methods], [sort @vmeths],
    'Declaring virtual methods' );

eval {
    __PACKAGE__->virtual_methods(qw(this wont work));
};
$ok = $@ =~ /^Attempt to reset virtual methods/;
::ok( $ok,        "Disallow reseting by virtual class" );


package Foo::This;
use base qw(Foo::Virtual);

::is_deeply( [sort __PACKAGE__->virtual_methods], [sort @vmeths],
    'Subclass listing virtual methods');
::is_deeply( [sort __PACKAGE__->missing_methods], [sort @vmeths],
    'Subclass listing missing methods');

*foo = sub { 42 };
*bar = sub { 23 };

::ok( defined &foo && defined &bar );

::is_deeply([sort __PACKAGE__->missing_methods], [sort qw(new this that)],
      'Subclass handling some methods');

eval {
    __PACKAGE__->virtual_methods(qw(this wont work));
};
::like $@, qr/^Attempt to reset virtual methods/,  
       "Disallow reseting by subclass";


package Foo::Virtual::Again;
use base qw(Class::Virtually::Abstract);
__PACKAGE__->virtual_methods('bing');

package Foo::Again;
use base qw(Foo::Virtual::Again);
::is_deeply([sort __PACKAGE__->virtual_methods], [sort qw(bing)],
      'Virtual classes not interfering' );
::is_deeply([sort __PACKAGE__->missing_methods], [sort qw(bing)],
      'Missing methods not interfering' );

::is_deeply([sort Foo::This->virtual_methods], [sort @vmeths],
      'Not overwriting virtual methods');
::is_deeply([sort Foo::This->missing_methods], [sort qw(new this that)],
      'Not overwriting missing methods');

eval {
    Foo::This->new;
};
::like( $@, qr/^Foo::This forgot to implement new\(\) at/,
        'virtual method unimplemented, ok');

eval {
    Foo::This->bing;
};
::like( $@, qr/^Can't locate object method "bing" via package "Foo::This"/,
        'virtual methods not leaking');   #')


eval {
    Foo::Again->import;
};
::like( $@, qr/^Class Foo::Again must define bing for class Foo::Virtual::Again/ );

package Foo::More;
use Test::More import => [qw($TODO)];
use base qw(Foo::Again);
sub import { 42 }

{
    local $TODO = 'defeated by import() routine';
    eval {
        Foo::More->import;
    };
    ::like( $@, qr/^Class Foo::More must define bing for class Foo::Virtual::Again/ );
}


package Foo::Yet::Again;
use base qw(Class::Virtually::Abstract);
__PACKAGE__->virtual_methods('foo');

sub import {
    $Foo::Yet::Again = 42;
}


package Foo::Yet;
use base qw(Foo::Yet::Again);

sub foo { 23 }

eval {
    Foo::Yet->import;
};
::is( $@, '' );
::is( $Foo::Yet::Again, 42 );
