
use strict;
use warnings;

use FindBin;
use lib map qq (${FindBin::Bin}/$_), qw[ ../lib lib sample ];

use Test::Spec::Util;

use Examples::Context::Singleton;
use Sample::Context::Singleton;

describe q (import()) => as {
	it_should_know_about_rule (rule => q (001-foo));
};

describe q (load_rules()) => as {
	it_should_load_rules (
		rules => [ q (002-foo) ],
		loader => as {
			load_rules q (Sample::Context::Singleton::002);
		},
	);
};

describe q (contrive()) => as {
	it_should_load_rules (
		rules => [ q (provides-foo), q (Provides::Foo) ],
		loader => as { contrive q (provides-foo) => class => q (Provides::Foo) },
	);
};

describe q (deduce()) => as {
	context q (value rule) => as {
		frame {
			it_should_resolve_rule (rule => q (constant), expected => q (42));
			frame {
				proclaim constant => 24;
				it_should_resolve_rule (rule => q (constant), expected => q (24));
			};
			it_should_resolve_rule (rule => q (constant), expected => q (42));
		};
	};

	context q (computed rule) => as {
		frame {
			proclaim a => 10;
			proclaim b => 5;

			it_should_resolve_rule (rule => q (sum), expected => q (15));
		};
	};

	context q (unresolvable rule) => as {
		it q (should die) => as { throws_ok { deduce q (un-resolvable) } q (Context::Singleton::Exception::Nondeducible), q () };
	};
};

describe q (try_deduce()) => as {
	context q (unresolvable rule) => as {
		it q (should not die) => as { lives_ok { try_deduce q (un-resolvable) } };
		it q (should return undef) => as { is try_deduce( q (un-resolvable) ), undef };
	};
};

describe q (is_deduced()) => as {
	plan tests => 1;

	context q (known resource) => as {
		frame {
			proclaim a => 10;
			proclaim b => 5;

			it_should_be_resolved (rule => q (a));
			it_should_not_be_resolved (rule => q (sum));

			try_deduce q (sum);

			it_should_be_resolved (rule => q (sum));
		};
	};
};

done_testing;
