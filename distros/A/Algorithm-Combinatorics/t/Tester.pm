package Tester;

use strict;

use Test::More;

sub __new {
	my ($class, $coderef, $comparator) = @_;
	$comparator = \&Test::More::is_deeply if not $comparator;
	bless { to_test => $coderef, comparator => $comparator }, $class;
}

# Here @rest is mean to be either (@data) or (@data, $k).
sub __test {
	my ($self, $expected, @rest) = @_;

	my @result = ();
	my $iter = $self->{to_test}(@rest);
	while (my $c = $iter->next) {
	    push @result, $c;
	}
	$self->{comparator}($expected, \@result, "");

	@result = $self->{to_test}(@rest);
	$self->{comparator}($expected, \@result, "");

    if (@rest > 1) {
        # as of today this means we've got a $k
        # test we don't assume $k is an IV in XS
        $rest[1] = "$rest[1]";

        @result = ();
        $iter = $self->{to_test}(@rest);
        while (my $c = $iter->next) {
            push @result, $c;
        }
        $self->{comparator}($expected, \@result, "");

        @result = $self->{to_test}(@rest);
        $self->{comparator}($expected, \@result, "");
    }
}

1;
