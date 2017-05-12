package Dwarf::Validator::Constraint;
use Dwarf::Pragma;
#use Dwarf::Validator;

sub import {
	strict->import;
	warnings->import;

	no strict 'refs';
	my $pkg = caller(0);
	*{"$pkg\::rule"}      = \&rule;
	*{"$pkg\::file_rule"} = \&file_rule;
	*{"$pkg\::filter"}    = \&filter;
	*{"$pkg\::alias"}     = \&alias;
	*{"$pkg\::delsp"}     = \&delsp;
}

sub rule {
	my ($name, $code) = @_;
	$Dwarf::Validator::Rules->{$name} = $code;
}

sub file_rule {
	my ($name, $code) = @_;
	$Dwarf::Validator::FileRules->{$name} = $code;
}

sub filter {
	my ($name, $code) = @_;
	$Dwarf::Validator::Filters->{$name} = $code;
	$Dwarf::Validator::Rules->{$name} = sub {
		my ($opts) = @_;
		return $Dwarf::Validator::Rules->{FILTER}->($name, $opts);
	};
}

sub alias {
	my ($from, $to) = @_;
	$Dwarf::Validator::Rules->{$to} = $Dwarf::Validator::Rules->{$from};
}

sub delsp {
	my $x = $_;
	$x =~ s/\s//g;
	return $x;
}

1;
