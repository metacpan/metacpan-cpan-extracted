package MyTest::Plugin::Zoo;
use Moose;
extends 'MyTest::Plugin';
sub priority { return 1; }
no Moose;
1;
