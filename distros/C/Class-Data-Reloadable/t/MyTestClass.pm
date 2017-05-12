package MyTestClass;
use base 'Class::Data::Reloadable';
$| = 1;
__PACKAGE__->mk_classdata( 'foo' );
warn "loading MyTestClass\n" if __PACKAGE__->_debug;
1;

