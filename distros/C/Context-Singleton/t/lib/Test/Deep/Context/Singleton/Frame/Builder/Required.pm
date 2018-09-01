
use strict;
use warnings;

package Test::Deep::Context::Singleton::Frame::Builder::Required;

use Scalar::Util;

use parent 'Test::Deep::Cmp';

sub is_test_deep_cmp {
	my ($what) = @_;

	Scalar::Util::blessed ($what) and $what->isa ('Test::Deep::Cmp');
}

sub init {
    my ($self, @expected) = @_;

    $self->{expect_required} =
		@expected == 1 && is_test_deep_cmp ($expected[0])
		? $expected[0]
		: Test::Deep::bag (@expected)
		;
}

sub descend {
    my ($self, $got) = @_;

	my @got_required = $got->required;

    my ($ok, $stack) = Test::Deep::descend (\@got_required, $self->{expect_required});

    $self->{cmp_diag} = Test::Deep::deep_diag ($stack)
        if $stack;

    $ok;
}

1;

