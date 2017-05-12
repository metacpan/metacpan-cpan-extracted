package Acme::Lambda::Expr::Util;

use strict;
use warnings;

use Moose::Util::TypeConstraints;
use Data::Util;
use Acme::Lambda::Expr::Value;

use Exporter 'import';
our @EXPORT_OK = qw(is_lambda_expr as_lambda_expr);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub is_lambda_expr{
	return Data::Util::is_instance($_[0], 'Acme::Lambda::Expr::Term');
}

sub as_lambda_expr{
	return Data::Util::is_instance($_[0], 'Acme::Lambda::Expr::Term')
		? $_[0]
		: Acme::Lambda::Expr::Value->new(value => $_[0]);
}

coerce 'Acme::Lambda::Expr::Term'
	=> from 'Any'
		=> \&as_lambda_expr;

1;
