
use strict;
use warnings;

use FindBin;
use lib qq ($FindBin::Bin/lib);

use Test::More;

use Shared::Example::Context::Singleton (
	qw[ it_should_export ],
);

package Child::Frame;
use Moo;
BEGIN { extends q (Context::Singleton::Frame) }
BEGIN { __PACKAGE__->_generate_frame_class_internals }

package main;

use Context::Singleton;
use Context::Singleton { prefix => q (foo_) };
use Context::Singleton { prefix => q (bar_), frame_class => q (Child::Frame) };

plan tests => 3;

subtest q (use without parameters) => sub {
	plan tests => 10;

	it_should_export q (contrive);
	it_should_export q (current_frame);
	it_should_export q (deduce);
	it_should_export q (frame);
	it_should_export q (is_deduced);
	it_should_export q (load_rules);
	it_should_export q (proclaim);
	it_should_export q (trigger);
	it_should_export q (try_deduce);

	is ref current_frame, q (Context::Singleton::Frame), q (it should use default frame class);
};

subtest q (use with prefix) => sub {
	plan tests => 11;

	it_should_export q (foo_contrive);
	it_should_export q (foo_current_frame);
	it_should_export q (foo_deduce);
	it_should_export q (foo_frame);
	it_should_export q (foo_is_deduced);
	it_should_export q (foo_load_rules);
	it_should_export q (foo_proclaim);
	it_should_export q (foo_trigger);
	it_should_export q (foo_try_deduce);

	is ref foo_current_frame, q (Context::Singleton::Frame), q (it should use default frame class);
	is foo_current_frame, current_frame, q (it should work with same context frame);
};

subtest q (use with alternate frame class) => sub {
	plan tests => 11;

	it_should_export q (bar_contrive);
	it_should_export q (bar_current_frame);
	it_should_export q (bar_deduce);
	it_should_export q (bar_frame);
	it_should_export q (bar_is_deduced);
	it_should_export q (bar_load_rules);
	it_should_export q (bar_proclaim);
	it_should_export q (bar_trigger);
	it_should_export q (bar_try_deduce);

	is ref bar_current_frame, q (Child::Frame), q (it should use given frame class);
	isnt bar_current_frame, current_frame, q (it should work with different context frames);
};


