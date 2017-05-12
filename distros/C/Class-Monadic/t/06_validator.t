#!perl -w

use strict;
use Test::More tests => 7;
use Test::Exception;
use Class::Monadic qw(:all);
use Data::Util qw(is_regex_ref);

{
	package T;

	sub new{
		return bless {}, shift;
	}
}

my $t = T->new;

monadic($t)->add_field(
	integer  => qr/^\d+$/,
	symbol   => [qw(true false)],
	checker  => \&is_regex_ref,
);

lives_and{
	$t->set_integer(10);
	is $t->get_integer, 10;
} 'regex';
throws_ok{
	$t->set_integer(3.14);
} qr/Invalid value/;

lives_and{
	$t->set_symbol('true');
	$t->set_symbol('false');
	is $t->get_symbol, 'false';
} 'array of symbols';
throws_ok{
	$t->set_symbol('TRUE');
} qr/Invalid value/;

lives_and{
	$t->set_checker(qr/foo/);
	is $t->get_checker, qr/foo/;
} 'subroutine';
throws_ok{
	$t->set_checker('foo');
} qr/Invalid value/;


throws_ok{
	monadic($t)->add_field(xyz => \*ok);
} qr/not valid/;

