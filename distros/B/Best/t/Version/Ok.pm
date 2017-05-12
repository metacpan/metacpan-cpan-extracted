package Version::Ok;

$VERSION = '2.00';

sub import {
    push @main::loaded, __PACKAGE__;
    push @main::args,   @_;
}
1;
