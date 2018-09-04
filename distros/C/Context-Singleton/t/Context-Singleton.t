
use strict;
use warnings;

use FindBin;
use lib map "${FindBin::Bin}/$_", qw[ ../lib lib sample ];

use Test::Spec::Util;

use Examples::Context::Singleton;
use Sample::Context::Singleton;

describe 'import()' => as {
	it_should_know_about_rule (rule => '001-foo');
};

describe 'load_rules()' => as {
	it_should_load_rules (
		rules => [ '002-foo' ],
		loader => as {
			load_rules 'Sample::Context::Singleton::002';
		},
	);
};

describe 'contrive()' => as {
	it_should_load_rules (
		rules => [ 'provides-foo', 'Provides::Foo' ],
		loader => as { contrive 'provides-foo' => class => 'Provides::Foo' },
	);
};

describe 'deduce()' => as {
	context 'value rule' => as {
		frame {
			it_should_resolve_rule (rule => 'constant', expected => '42');
			frame {
				proclaim constant => 24;
				it_should_resolve_rule (rule => 'constant', expected => '24');
			};
			it_should_resolve_rule (rule => 'constant', expected => '42');
		};
	};

	context 'computed rule' => as {
		frame {
			proclaim a => 10;
			proclaim b => 5;

			it_should_resolve_rule (rule => 'sum', expected => '15');
		};
	};

	context 'unresolvable rule' => as {
		it "should die" => as { throws_ok { deduce 'un-resolvable' } 'Context::Singleton::Exception::Nondeducible', '' };
	};
};

describe 'try_deduce()' => as {
	context 'unresolvable rule' => as {
		it "should not die" => as { lives_ok { try_deduce 'un-resolvable' } };
		it "should return undef" => as { is try_deduce( 'un-resolvable' ), undef };
	};
};

describe 'is_deduced()' => as {
	plan tests => 1;

	context 'known resource' => as {
		frame {
			proclaim a => 10;
			proclaim b => 5;

			it_should_be_resolved (rule => 'a');
			it_should_not_be_resolved (rule => 'sum');

			try_deduce 'sum';

			it_should_be_resolved (rule => 'sum');
		};
	};
};

done_testing;
