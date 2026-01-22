use strict;
use warnings;
use Test::More;
use Test::Requires { 'Types::Standard' => '1.000000' };

BEGIN {
	package Local::Foo;
	use Types::Standard 'Int';
	use Class::XSConstructor 'foo';
	use Class::XSReader foo => { reader => 'get_foo', isa => Int, default => sub { 42 } };
};

my $x = Local::Foo->new;
is_deeply( $x, bless({}, 'Local::Foo') );
is( $x->get_foo, 42 );
is_deeply( $x, bless({foo=>42}, 'Local::Foo') );

BEGIN {
	package Local::Foo2;
	use Types::Standard 'Int';
	use Class::XSConstructor 'foo';
	use Class::XSReader foo => { reader => 'get_foo', isa => Int, default => sub { 'Bad' } };
};

my $y = Local::Foo2->new;
is_deeply( $y, bless({}, 'Local::Foo2') );
ok !eval { $y->get_foo; 1 };
is_deeply( $y, bless({}, 'Local::Foo2') );

BEGIN {
	package Local::Foo3;
	use Types::Standard 'HashRef';
	use Class::XSConstructor 'foo';
	use Class::XSReader foo => { reader => 'get_foo', isa => HashRef, clone_on_read => 1 };
};

my $z = Local::Foo3->new( foo => { xyz => 333 } );
my $z1 = $z->get_foo;
my $z2 = $z->get_foo;
my $z3 = $z->get_foo;

$z1->{xyz}++;
$z3->{xyz}--;
is( $z->{foo}{xyz}, 333 );
is( $z1->{xyz}, 334 );
is( $z2->{xyz}, 333 );
is( $z3->{xyz}, 332 );

done_testing;