
use strict;
use warnings;

use FindBin;
use lib map "${FindBin::Bin}/$_", qw[ ../lib lib sample ];

use Test::Spec::Util;

use Examples::Context::Singleton::Frame::Builder;

use Context::Singleton::Frame::Builder::Value;

class_under_test 'Context::Singleton::Frame::Builder::Value';

describe "build" => as {
	context "with defined value" => as {
		build_instance [
			value => 'xyz',
		];

		expect_required   expect => [ ];
		expect_unresolved expect => [ ];
		expect_build      expect => 'xyz';
	};

	context "with undefined value" => as {
		build_instance [
			value => undef,
		];

		expect_required   expect => [ ];
		expect_unresolved expect => [ ];
		expect_build      expect => undef;
	};
};

done_testing;
