#!perl -w

use strict;
use Data::Util qw(neat);

sub say{ print @_, "\n" }

say neat "foo";
say neat "here is a very long string";
say neat \"bar";
say neat 3.14;
say neat 42;
say neat \0xFF;
say neat *foo;
say neat \*foo;
say neat \&foo;
say neat [];
say neat { foo => "bar" };
say neat { "foo\n" => "bar\n" };
say neat bless {} => 'Foo';
say neat undef;

