use strict;
use Test::More;
use Class::Accessor::Inherited::XS {
    inherited => [qw/foo/],
    class     => [qw/cfoo/],
};

my $obj = bless {}, __PACKAGE__;
my $bar = \($obj->foo(24));
is($obj->foo, 24);
is($$bar, 24);

$$bar++;
is($obj->foo, 25);

=cut
my $baz = \($obj->foo);
$$baz++;
is($obj->foo, 26);

my $cbar = \(__PACKAGE__->cfoo(24));
$$cbar++;
is(__PACKAGE__->cfoo, 25);

my $cbaz = \(__PACKAGE__->cfoo);
$$cbaz++;
is(__PACKAGE__->cfoo, 26);
=cut

done_testing;