use Test::More;
use lib 't/lib';
use Foo;
use Bar;
use Bang;

{
	package Boom;

	use base 'Foo';

	sub again {
		return 'thing';
	}

	1;
}

{
	package Zoom;

	sub new { bless {}, $_[0] }

	sub again {
		return 'thing';
	}

	1;
}

use Blessed::Merge;
my $merge = Blessed::Merge->new( same => 0 );

my $self = $merge->merge(Foo->new, Bar->new, Bang->new);
my $sself = $merge->merge(Boom->new, Foo->new, Bar->new, Bang->new, Zoom->new);

is ($self->test, 'okay');
is ($self->another, 'next');
is( eval {
	$self->again	
}, undef);
is($self->isa('Foo'), 1);
is($self->isa('Bar'), 1);
is($self->isa('Bang'), 1);

is ($sself->test, 'okay');
is ($sself->another, 'next');
is( eval {
	$sself->again	
}, 'thing');
is($sself->isa('Foo'), 1);
is($sself->isa('Bar'), 1);
is($sself->isa('Bang'), 1);
is($sself->isa('Boom'), 1);

done_testing;
