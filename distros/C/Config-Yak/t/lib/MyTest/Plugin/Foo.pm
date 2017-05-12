package MyTest::Plugin::Foo;
use Moose;
extends 'MyTest::Plugin';
sub priority { return 20; }
no Moose;
1;
