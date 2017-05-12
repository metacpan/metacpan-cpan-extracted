#!perl -w

# get_stash(), is_invocant(), invocant()

use strict;
use warnings FATAL => 'all';
use Test::More tests => 40;
use Test::Exception;

use Tie::Scalar;

use Scalar::Util qw(blessed);
use Data::Util qw(:all);

#diag 'Testing ', $INC{'Data/Util/PurePerl.pm'} ? 'PurePerl' : 'XS';

sub get_stash_pp{
	my($pkg) = @_;
	no strict 'refs';

	if(blessed $pkg){
		$pkg = ref $pkg;
	}

	return \%{$pkg . '::'};
}

foreach my $pkg( qw(main strict Data::Util ::main::Data::Util), bless{}, 'Foo'){
	is get_stash($pkg), get_stash_pp($pkg), sprintf 'get_stash(%s)', neat $pkg;
	ok is_invocant($pkg), 'is_invocant()';
	ok invocant($pkg)->isa('UNIVERSAL'), 'invocant()';
}

foreach my $pkg('not_exists', '', 1, undef, [], *ok){
	ok !defined(get_stash $pkg), 'get_stash for ' . neat($pkg) . '(invalid value)';
	ok !is_invocant($pkg), '!is_invocant()';
	throws_ok{
		invocant($pkg);
	} qr/Validation failed/, 'invocant() throws fatal error';
}

my $x = tie my($ts), 'Tie::StdScalar', 'main';
is get_stash($ts), get_stash_pp('main'), 'for magic variable';
ok is_invocant($ts);
ok invocant($ts);

ok is_invocant($x), 'is_invocant() for an object';
is invocant($x), $x, 'invocant() for an object';

is invocant('::Data::Util'),     'Data::Util';
is invocant('main::Data::Util'), 'Data::Util';

