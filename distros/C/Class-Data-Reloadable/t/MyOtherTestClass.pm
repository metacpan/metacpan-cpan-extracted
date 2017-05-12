package MyOtherTestClass;
use base 'MyTestClass';
$| = 1;
warn "loading MyOtherTestClass\n" if __PACKAGE__->_debug;
1;
