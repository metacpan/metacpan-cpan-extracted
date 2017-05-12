#!perl 

use Test::More tests => 2;

use lib 'lib';

{

    package Foo;
    use Class::BuildMethods qw(a), class_data => { class_data => 1 };
    sub new { bless {}, shift(); }

    package Bar;
    use base qw(Foo);
    use Class::BuildMethods qw(b), class_data => { class_data => 1 };
}

my $b = Bar->new();
$b->a(5);
$b->class_data(3);
undef $b;
$b = Bar->new;
ok !defined $b->a,
  'instance data should not retain its value between invocations';
ok defined $b->class_data,
  'class_data() should retain its value between invocations';
