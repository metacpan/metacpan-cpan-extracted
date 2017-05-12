
package MyImplCalc;

use strict;
use warnings;

use Error;

use base qw(Calculator);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	return $self;
}

sub Add {
	my $self = shift;
	my ($var1, $var2) = @_;

	my $res = $var1 + $var2;
	print __PACKAGE__,"::Add $var1 + $var2 -> $res\n";
	return $res;
}

sub Sub {
	my $self = shift;
	my ($var1, $var2) = @_;

	my $res = $var1 - $var2;
	print __PACKAGE__,"::Sub\n";
	return $res;
}

sub Mul {
	my $self = shift;
	my ($var1, $var2) = @_;

	my $res = $var1 * $var2;
	print __PACKAGE__,"::Mul\n";
	return $res;
}

sub Div {
	my $self = shift;
	my ($var1, $var2) = @_;
	print __PACKAGE__,"::Div\n";

	if ($var2 == 0) {
		throw Calculator::DivisionByZero(
				_repos_id => "IDL:Calculator/DivisionByZero:1.0",
		);
	} else {
		my $res = $var1 / $var2;
		return $res;
	}
}

1;
