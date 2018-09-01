
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use Shared::Example::Context::Singleton (
	qw[ it_should_export ],
);

package Child::Frame;

use parent 'Context::Singleton::Frame';

package main;

use Context::Singleton;
use Context::Singleton { prefix => 'foo_' };
use Context::Singleton { prefix => 'bar_', frame_class => 'Child::Frame' };

plan tests => 3;

subtest "use without parameters" => sub {
	plan tests => 10;

	it_should_export 'contrive';
	it_should_export 'current_frame';
	it_should_export 'deduce';
	it_should_export 'frame';
	it_should_export 'is_deduced';
	it_should_export 'load_rules';
	it_should_export 'proclaim';
	it_should_export 'trigger';
	it_should_export 'try_deduce';

	is ref current_frame, 'Context::Singleton::Frame', "it should use default frame class";
};

subtest "use with prefix" => sub {
	plan tests => 11;

	it_should_export 'foo_contrive';
	it_should_export 'foo_current_frame';
	it_should_export 'foo_deduce';
	it_should_export 'foo_frame';
	it_should_export 'foo_is_deduced';
	it_should_export 'foo_load_rules';
	it_should_export 'foo_proclaim';
	it_should_export 'foo_trigger';
	it_should_export 'foo_try_deduce';

	is ref foo_current_frame, 'Context::Singleton::Frame', "it should use default frame class";
	is foo_current_frame, current_frame, "it should work with same context frame";
};

subtest "use with alternate frame class" => sub {
	plan tests => 11;

	it_should_export 'bar_contrive';
	it_should_export 'bar_current_frame';
	it_should_export 'bar_deduce';
	it_should_export 'bar_frame';
	it_should_export 'bar_is_deduced';
	it_should_export 'bar_load_rules';
	it_should_export 'bar_proclaim';
	it_should_export 'bar_trigger';
	it_should_export 'bar_try_deduce';

	is ref bar_current_frame, 'Child::Frame', "it should use given frame class";
	isnt bar_current_frame, current_frame, "it should work with different context frames";
};


