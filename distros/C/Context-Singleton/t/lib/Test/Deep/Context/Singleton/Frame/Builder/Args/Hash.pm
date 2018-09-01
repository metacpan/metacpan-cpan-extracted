
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
    my $self = shift;

    $self->{cmp_this} = shift if @_ % 2;
    $self->{cmp_val}  = { @_ };
}

sub descend {
    my ($self, $got) = @_;

    my @got_val = @$got;
    my $got_this = shift @got_val if @got_val % 2;

    my ($ok, $stack) = (1);
    ($ok, $stack) = Test::Deep::descend ($got_this, $self->{cmp_this})
        if exists $self->{cmp_this};

    my $hash_got = { @got_val };
    ($ok, $stack) = Test::Deep::descend ($hash_got, $self->{cmp_val})
        if $ok;

    $self->{cmp_diag} = Test::Deep::deep_diag ($stack)
        if $stack;

    $ok;
}

1;

