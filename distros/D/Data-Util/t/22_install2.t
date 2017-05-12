#!perl -w

use strict;
use Test::More tests => 8;
use Test::Exception;

use Data::Util qw(:all);

install_subroutine(__PACKAGE__, { foo => sub{ 42 } });

lives_ok{
	is __PACKAGE__->foo(), 42;
};

uninstall_subroutine(__PACKAGE__, { foo => \&ok });

lives_ok{
	is __PACKAGE__->foo(), 42;
};

uninstall_subroutine(__PACKAGE__, { foo => undef });

throws_ok{
	__PACKAGE__->foo();
} qr/Can't locate object method "foo" via package "main"/;

install_subroutine(__PACKAGE__, { foo => sub{ 3.14 } });

lives_ok{
	is __PACKAGE__->foo(), 3.14;
};

uninstall_subroutine(__PACKAGE__, { foo => __PACKAGE__->can('foo') });

throws_ok{
	__PACKAGE__->foo();
} qr/Can't locate object method "foo" via package "main"/;
