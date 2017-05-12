#!/usr/bin/perl -w

use strict;
use Test::More tests => 15;

BEGIN { use_ok 'Class::Virtual'; }


my @vmeths = qw(new foo bar this that);
my $ok;

package Test::Virtual;
use base qw(Class::Virtual);
__PACKAGE__->virtual_methods(@vmeths);

::is_deeply([sort __PACKAGE__->virtual_methods], [sort @vmeths],
    'Declaring virtual methods' );

eval {
    __PACKAGE__->virtual_methods(qw(this wont work));
};
::like($@, qr/^Attempt to reset virtual methods/,
       "Disallow reseting by virtual class" );


package Test::This;
use base qw(Test::Virtual);

::is_deeply([sort __PACKAGE__->virtual_methods], [sort @vmeths],
    'Subclass listing virtual methods');
::is_deeply([sort __PACKAGE__->missing_methods], [sort @vmeths],
    'Subclass listing missing methods');

*foo = sub { 42 };
*bar = sub { 23 };

::ok( defined &foo && defined &bar );

::is_deeply([sort __PACKAGE__->missing_methods], [sort qw(new this that)],
      'Subclass handling some methods');

eval {
    __PACKAGE__->virtual_methods(qw(this wont work));
};
::like($@, qr/^Attempt to reset virtual methods/,
       "Disallow reseting by subclass" );


package Test::Virtual::Again;
use base qw(Class::Virtual);
__PACKAGE__->virtual_methods('bing');

package Test::Again;
use base qw(Test::Virtual::Again);
::is_deeply([sort __PACKAGE__->virtual_methods], [sort qw(bing)],
      'Virtual classes not interfering' );
::is_deeply([sort __PACKAGE__->missing_methods], [sort qw(bing)],
      'Missing methods not interfering' );

::is_deeply([sort Test::This->virtual_methods], [sort @vmeths],
      'Not overwriting virtual methods');
::is_deeply([sort Test::This->missing_methods], [sort qw(new this that)],
      'Not overwriting missing methods');

eval {
    Test::This->new;
};
::like( $@, qr/^Test::This forgot to implement new\(\) at/,
      'virtual method unimplemented, ok');

eval {
    Test::This->bing;
};
::like( $@, qr/^Can't locate object method "bing" via package "Test::This"/,
      'virtual methods not leaking');



###  This test doesn't work and probably never will.
###
package Test::That;
use Test::More import => [qw($TODO)];
use base qw(Test::Virtual);

# Let's see how things work with an autoloader.
use vars qw($AUTOLOAD);
sub AUTOLOAD {
    if( $AUTOLOAD =~ /(foo|bar)/ ) {
        return "Yay!";
    }
    else {
        die "ARrrrrrrrrrrgh!\n";
    }
}

{
    local $TODO = 'autoloaded methods';
    ::is_deeply([sort __PACKAGE__->missing_methods], [sort qw(new this that)],
                'Autoloaded methods recognized' );
}
