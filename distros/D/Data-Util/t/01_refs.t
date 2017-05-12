#!perl -w
use strict;

use Test::More tests => 47;

use Test::Exception;

use Data::Util qw(:check :validate);
use Symbol qw(gensym);

use constant PP_ONLY => exists $INC{'Data/Util/PurePerl.pm'};

diag "Testing ", PP_ONLY ? "PurePerl" : "XS";

sub lval_f :lvalue{
	my $f;
}


ok is_scalar_ref(\''), 'is_scalar_ref';
ok is_scalar_ref(\lval_f()), 'is_scalar_ref (lvalue)';
ok is_scalar_ref(\\''), 'is_scalar_ref (ref)';
ok!is_scalar_ref(bless \do{my$o}), 'is_scalar_ref';
ok!is_scalar_ref({}), 'is_scalar_ref';
ok!is_scalar_ref(undef), 'is_scalar_ref';
ok!is_scalar_ref(*STDOUT{IO}), 'is_scalar_ref';

ok is_array_ref([]), 'is_array_ref';
ok!is_array_ref(bless []), 'is_array_ref';
ok!is_array_ref({}), 'is_array_ref';
ok!is_array_ref(undef), 'is_array_ref';

ok is_hash_ref({}), 'is_hash_ref';
ok!is_hash_ref(bless {}), 'is_hash_ref';
ok!is_hash_ref([]), 'is_hash_ref';
ok!is_hash_ref(undef), 'is_hash_ref';

ok is_code_ref(sub{}), 'is_code_ref';
ok!is_code_ref(bless sub{}), 'is_code_ref';
ok!is_code_ref({}), 'is_code_ref';
ok!is_code_ref(undef), 'is_code_ref';

ok is_glob_ref(gensym()), 'is_glob_ref';
ok!is_glob_ref(bless gensym()), 'is_glob_ref';
ok!is_glob_ref({}), 'is_glob_ref';
ok!is_glob_ref(undef), 'is_glob_ref';

ok is_regex_ref(qr/foo/), 'is_regex_ref';
ok!is_regex_ref({}), 'is_regex_ref';

ok is_rx(qr/foo/), 'is_rx';
ok!is_rx({}),      'is_rx';

SKIP:{
	skip 'in testing perl only', 1 if PP_ONLY;
	ok!is_regex_ref(bless [], 'Regexp'), 'fake regexp';
}

ok scalar_ref(\42), 'scalar_ref';
ok scalar_ref(\\42);

throws_ok{
	scalar_ref([]);
} qr/Validation failed: you must supply a SCALAR reference/;

throws_ok{
	scalar_ref(undef);
} qr/Validation failed/;

throws_ok{
	scalar_ref(42);
} qr/Validation failed/;

throws_ok{
	scalar_ref('SCALAR');
} qr/Validation failed/;
throws_ok{
	scalar_ref(\*ok);
} qr/Validation failed/;

ok array_ref([]), 'array_ref';
throws_ok{
	array_ref({foo => "bar"});
} qr/Validation failed/;

ok hash_ref({}), 'hash_ref';
throws_ok{
	hash_ref([]);
} qr/Validation failed/;


ok code_ref(sub{}), 'code_ref';
throws_ok{
	code_ref([]);
} qr/Validation failed/;

ok glob_ref(gensym()), 'glob_ref';
throws_ok{
	glob_ref('*glob');
} qr/Validation failed/;

ok rx(qr/foo/), 'rx';
throws_ok{
	rx([]);
} qr/Validation failed/;

SKIP:{
	skip 'in testing perl only', 2 if PP_ONLY;
	dies_ok{
		is_scalar_ref();
	} 'not enough arguments';
	dies_ok{
		scalar_ref();
	} 'not enought arguments';
}
