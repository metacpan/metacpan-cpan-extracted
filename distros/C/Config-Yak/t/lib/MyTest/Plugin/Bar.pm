package MyTest::Plugin::Bar;
use Moose;
extends 'MyTest::Plugin';
sub priority { return 10; }
no Moose;
1;
