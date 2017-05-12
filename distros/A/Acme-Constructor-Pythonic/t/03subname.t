use strict;
use warnings;
use Test::More;

BEGIN {
	eval { require Sub::Identify }
		or plan skip_all => 'need Sub::Identify';
	plan tests => 3;
}

BEGIN {
	package Local::Enterprise::Constructor;
	use Acme::Constructor::Pythonic ();
	our @ISA = qw( Acme::Constructor::Pythonic );
	$INC{'Local/Enterprise/Constructor.pm'} = __FILE__;
}

{
	package Local::Foo;
	sub new {
		require Carp;
		Carp::croak("DIED");
	}
}

#line 27 "03subname.t"
use Local::Enterprise::Constructor { no_require => 1 }, qw( Local::Foo );

is(
	Sub::Identify::stash_name( \&Foo ),
	'Local::Enterprise::Constructor',
	'stash name is correct for exported subs',
);

is(
	Sub::Identify::sub_name( \&Foo ),
	'__ANON__',
	'sub name is correct for exported subs',
);

# Catch exception
my $e = do {
	local $@;
#line 45 "03subname.t"
	eval { Foo(); 1 } ? undef : $@;
};

like(
	$e,
	qr{\ADIED at 03subname.t line 4[456]}, # allow a small margin of error
	'file name and line number reported correctly in exceptions',
);
