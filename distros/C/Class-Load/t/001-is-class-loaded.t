use strict;
use warnings;
use Test::More 0.88;

use version;

use lib 't/lib';
use Test::Class::Load 'is_class_loaded';

# basic {{{
ok(is_class_loaded('Class::Load'), "Class::Load is loaded");
ok(!is_class_loaded('Class::Load::NONEXISTENT'), "nonexistent class is NOT loaded");
# }}}

# @ISA (yes) {{{
do {
    package Class::Load::WithISA;
    our @ISA = 'Class::Load';
};
ok(is_class_loaded('Class::Load::WithISA'), "class that defines \@ISA is loaded");
# }}}
# $ISA (no) {{{
do {
    package Class::Load::WithScalarISA;
    our $ISA = 'Class::Load';
};
ok(!is_class_loaded('Class::Load::WithScalarISA'), "class that defines \$ISA is not loaded");
# }}}
# $VERSION (yes) {{{
do {
    package Class::Load::WithVERSION;
    our $VERSION = '1.0';
};
ok(is_class_loaded('Class::Load::WithVERSION'), "class that defines \$VERSION is loaded");
# }}}
# $VERSION is a version object (yes) {{{
do {
    package Class::Load::WithVersionObject;
    our $VERSION = version->new(1);
};
ok(is_class_loaded('Class::Load::WithVersionObject'), 'when $VERSION contains a version object, we still return true');
# }}}
# method (yes) {{{
do {
    package Class::Load::WithMethod;
    sub foo { }
};
ok(is_class_loaded('Class::Load::WithMethod'), "class that defines any method is loaded");
# }}}
# global scalar (no) {{{
do {
    package Class::Load::WithScalar;
    our $FOO = 1;
};
ok(!is_class_loaded('Class::Load::WithScalar'), "class that defines just a scalar is not loaded");
# }}}
# subpackage (no) {{{
do {
    package Class::Load::Foo::Bar;
    sub bar {}
};
ok(!is_class_loaded('Class::Load::Foo'), "even if Foo::Bar is loaded, Foo is not");
# }}}
# superstring (no) {{{
do {
    package Class::Load::Quuxquux;
    sub quux {}
};
ok(!is_class_loaded('Class::Load::Quux'), "Quuxquux does not imply the existence of Quux");
# }}}
# use constant (yes) {{{
do {
    package Class::Load::WithConstant;
    use constant PI => 3;
};
ok(is_class_loaded('Class::Load::WithConstant'), "defining a constant means the class is loaded");
# }}}
# use constant with reference (yes) {{{
do {
    package Class::Load::WithRefConstant;
    use constant PI => \3;
};
ok(is_class_loaded('Class::Load::WithRefConstant'), "defining a constant as a reference means the class is loaded");
# }}}
# stub (yes) {{{
do {
    package Class::Load::WithStub;
    sub foo;
};
ok(is_class_loaded('Class::Load::WithStub'), "defining a stub means the class is loaded");
# }}}
# stub with prototype (yes) {{{
do {
    package Class::Load::WithPrototypedStub;
    sub foo (&);
};
ok(is_class_loaded('Class::Load::WithPrototypedStub'), "defining a stub with a prototype means the class is loaded");
# }}}

ok(!is_class_loaded('Class::Load::VersionCheck'), 'Class::Load::VersionCheck has not been loaded yet');
require Class::Load::VersionCheck;
ok(is_class_loaded('Class::Load::VersionCheck'), 'Class::Load::VersionCheck has been loaded');
ok(!is_class_loaded('Class::Load::VersionCheck', {-version => 43}),
   'Class::Load::VersionCheck has been loaded but the version check failed');
ok(is_class_loaded('Class::Load::VersionCheck', {-version => 41}),
   'Class::Load::VersionCheck has been loaded and the version check passed');

done_testing;
