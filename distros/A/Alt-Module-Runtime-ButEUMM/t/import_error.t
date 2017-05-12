use warnings;
use strict;

use Test::More tests => 3;

eval q{#line 11 "test_eval"
	use Module::Runtime qw(foo);
};
$@ =~ s/\(eval [0-9]+\) line 2/test_eval line 11/ if "$]" < 5.006001;
like $@, qr/\A
	\"foo\"\ is\ not\ exported\ by\ the\ Module::Runtime\ module\n
	Can't\ continue\ after\ import\ errors\ at\ test_eval\ line\ 11.\n
/x;

eval q{#line 22 "test_eval"
	use Module::Runtime qw(require_module.1);
};
$@ =~ s/\(eval [0-9]+\) line 2/test_eval line 22/ if "$]" < 5.006001;
like $@, qr/\A
	\"require_module.1\"\ is\ not\ exported
	\ by\ the\ Module::Runtime\ module\n
	Can't\ continue\ after\ import\ errors\ at\ test_eval\ line\ 22.\n
/x;

eval q{#line 33 "test_eval"
	use Module::Runtime qw(foo require_module bar);
};
$@ =~ s/\(eval [0-9]+\) line 2/test_eval line 33/ if "$]" < 5.006001;
like $@, qr/\A
	\"foo\"\ is\ not\ exported\ by\ the\ Module::Runtime\ module\n
	\"bar\"\ is\ not\ exported\ by\ the\ Module::Runtime\ module\n
	Can't\ continue\ after\ import\ errors\ at\ test_eval\ line\ 33.\n
/x;

1;
