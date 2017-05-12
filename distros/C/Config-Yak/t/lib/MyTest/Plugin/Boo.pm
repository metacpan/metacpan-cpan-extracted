package MyTest::Plugin::Boo;
use Moose;
extends 'MyTest::Plugin';
sub priority { return 0; }
no Moose;
1;
