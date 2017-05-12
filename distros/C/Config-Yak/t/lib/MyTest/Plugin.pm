package MyTest::Plugin;
use Moose;
sub priority { return 0; }
no Moose;
1;
