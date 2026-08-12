
use strict;
use warnings;

use FindBin;
use lib map qq (${FindBin::Bin}/$_), qw[ ../lib lib sample ];

use Test::Spec::Util;

use Examples::Context::Singleton::Frame::Builder;

use Context::Singleton::Frame::Builder::Value;

class_under_test q (Context::Singleton::Frame::Builder::Value);

describe q (build) => as {
	context q (with defined value) => as {
		build_instance [
			value => q (xyz),
		];

		expect_required   expect => [ ];
		expect_unresolved expect => [ ];
		expect_build      expect => q (xyz);
	};

	context q (with undefined value) => as {
		build_instance [
			value => undef,
		];

		expect_required   expect => [ ];
		expect_unresolved expect => [ ];
		expect_build      expect => undef;
	};
};

done_testing;
