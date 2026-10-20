use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;
use Config;
use POSIX ();

use lib "t/lib";
use Clay::Test::Guards qw(call_guarded guarded_names);

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# Context ownership, lifetime and validation: every Perl handle to a context
# shares one referent, copies and forgeries are rejected, Clay-touching calls
# croak without a usable context (the wrapper guard table's context, frame
# and counts columns, every row), and Clay_Initialize / the capacity setters
# validate their input before anything is allocated.
# -----------------------------------------------------------------------------

sub build_frame ($label) {
	Clay_BeginLayout();
	Clay__OpenElementWithId(Clay_GetElementId('root'));
	Clay__ConfigureOpenElement({
		layout          => { sizing => { width => sizing_fixed(50), height => sizing_fixed(20) } },
		backgroundColor => [1, 2, 3, 255],
	});
	Clay__OpenTextElement($label, { fontSize => 10 });
	Clay__CloseElement();
	return Clay_EndLayout();
}

sub new_context () {
	my $ctx = Clay_Initialize(Clay_MinMemorySize(), { width => 100, height => 100 });
	Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
		return { width => length($text), height => 10 };
	});
	return $ctx;
}

sub text_of ($cmds) {
	my ($text) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @$cmds;
	return $text->{renderData}{stringContents};
}

# The wrapper guard table (Clay::XS::_wrapper_guards) drives the guard
# tests: every row of a column is called with as many undef arguments as it
# needs (call_guarded), so only its guard can refuse the call.
subtest 'the context guard: current rows need a current context' => sub {
	is( Clay_GetCurrentContext(), undef, 'no current context' );
	my @current = guarded_names(sub ($guard) { $guard->{context} eq 'current' });
	ok( scalar @current, 'the table lists functions that need a context' );
	for my $name (@current) {
		like( dies { call_guarded($name) }, qr/^\Q$name\E: no current Clay context/, "$name croaks" );
	}
	for my $name (guarded_names(sub ($guard) { $guard->{context} ne 'current' })) {
		my $error = dies { call_guarded($name) };
		unlike( $error // '', qr/no current Clay context/, "$name needs no context" );
	}
	is( Clay_GetCurrentContext(), undef, 'the calls left no current context' );
};

subtest 'the frame guard: in_frame, open_element and complete_layout rows' => sub {
	my $ctx = new_context();
	my %rows = map { my $frame = $_; ($frame => [ guarded_names(sub ($guard) { $guard->{frame} eq $frame }) ]) }
		qw(in_frame open_element complete_layout);
	ok( scalar @{ $rows{$_} }, "the table lists $_ functions" ) for sort keys %rows;

	for my $name (@{ $rows{in_frame} }) {
		like( dies { call_guarded($name) }, qr/^\Q$name\E: called outside Clay_BeginLayout\/Clay_EndLayout/,
			"$name croaks outside a frame" );
	}
	Clay_BeginLayout();
	for my $name (@{ $rows{open_element} }) {
		like( dies { call_guarded($name) }, qr/^\Q$name\E: no element is open/, "$name croaks with nothing open" );
	}
	for my $name (@{ $rows{complete_layout} }) {
		like( dies { call_guarded($name) }, qr/^\Q$name\E: cannot be called between Clay_BeginLayout and Clay_EndLayout/,
			"$name croaks inside a frame" );
	}
	ok( lives { Clay_EndLayout(0) }, 'the frame still ends' );
	is( text_of(build_frame('after the guards')), 'after the guards', 'and the next one renders' );
};

subtest 'the counts guard: rows with counts croak once a count changed' => sub {
	my $ctx = new_context();
	Clay_SetMaxElementCount(16384);
	my @counted = guarded_names(sub ($guard) { $guard->{counts} });
	ok( scalar @counted, 'the table lists functions that need the initial counts' );
	for my $name (@counted) {
		like( dies { call_guarded($name) }, qr/^\Q$name\E: element\/word counts changed since Clay_Initialize/,
			"$name croaks" );
	}
	for my $name (guarded_names(sub ($guard) { !$guard->{counts} })) {
		my $error = dies { call_guarded($name) };
		unlike( $error // '', qr/counts changed/, "$name does not check the counts" );
	}
	Clay_SetMaxElementCount(8192);
	is( text_of(build_frame('counts restored')), 'counts restored', 'restoring the count lets the calls through again' );
};

subtest 'an alias from Clay_GetCurrentContext shares the context' => sub {
	my $ctx = new_context();
	{
		my $alias = Clay_GetCurrentContext();
		isa_ok( $alias, ['Clay::XS::Context'], 'alias is a context object' );
		is( $$alias, $$ctx, 'alias shares the referent' );
	}
	Clay_SetCurrentContext($ctx);
	is( text_of(build_frame('still alive')), 'still alive', 'original renders after the alias is gone' );
};

subtest 'explicit DESTROY then scope exit frees once, silently' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	{
		my $ctx = new_context();
		$ctx->DESTROY;
		like( dies { Clay_SetCurrentContext($ctx) }, qr/not a live Clay::XS::Context/,
			'a destroyed context croaks on use' );
	}
	is( \@warnings, [], 'no warnings from the second DESTROY' );
	is( Clay_GetCurrentContext(), undef, 'no current context after DESTROY' );
};

subtest 'contexts keep their own state' => sub {
	my $first  = new_context();
	my $second = new_context();
	Clay_SetCurrentContext($first);
	is( text_of(build_frame('first')), 'first', 'the first context renders' );
	Clay_SetCurrentContext($second);
	is( text_of(build_frame('second')), 'second', 'the second context renders' );
	Clay_SetMeasureTextFunction(undef);
	Clay_SetCurrentContext($first);
	is( text_of(build_frame('first again')), 'first again',
		'the first context still has its own measure function' );
};

subtest 'a new context after DESTROY works' => sub {
	my $old = new_context();
	build_frame('old');
	$old->DESTROY;
	my $new = new_context();
	is( text_of(build_frame('new')), 'new', 'Clay_Initialize after DESTROY of the current context' );
};

subtest 'a Storable copy is rejected and destroyed silently' => sub {
	skip_all 'Storable not installed' unless eval { require Storable; 1 };
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $ctx = new_context();
	{
		my $copy = Storable::dclone($ctx);
		like( dies { Clay_SetCurrentContext($copy) }, qr/not a live Clay::XS::Context/,
			'the copy croaks on use' );
	}
	is( \@warnings, [], 'no warnings when the copy goes out of scope' );
	Clay_SetCurrentContext($ctx);
	is( text_of(build_frame('original')), 'original', 'the original still renders' );
};

subtest 'a forged context object croaks' => sub {
	my $forged = bless \(my $x = 1), 'Clay::XS::Context';
	like( dies { Clay_SetCurrentContext($forged) }, qr/not a live Clay::XS::Context/,
		'forged object rejected' );
};

subtest 'threads do not inherit contexts' => sub {
	skip_all 'perl built without ithreads' unless $Config{useithreads};
	require threads;
	my $ctx = new_context();

	threads->create(sub { return 1 })->join;
	Clay_SetCurrentContext($ctx);
	is( text_of(build_frame('after join')), 'after join', 'original renders after a thread joined' );

	my $error = threads->create(sub {
		my $ok = eval { Clay_BeginLayout(); 1 };
		return $ok ? 'no error' : "$@";
	})->join;
	like( $error, qr/different interpreter\/thread/, 'a thread using the inherited context croaks' );
	is( text_of(build_frame('still fine')), 'still fine', 'the parent context is intact' );

	# Clay has one current context, so a thread makes its own while none is.
	$ctx->DESTROY;
	my $text = threads->create(sub {
		my $own = new_context();
		return text_of(build_frame('measured in a thread'));
	})->join;
	is( $text, 'measured in a thread', 'a thread lays out text with a context of its own, callbacks included' );
};

subtest 'Clay_Initialize validates capacity before allocating' => sub {
	my $min = Clay_MinMemorySize();
	like( dies { Clay_Initialize(-1, [10, 10]) },   qr/non-negative integer/, '-1 croaks' );
	like( dies { Clay_Initialize(0, [10, 10]) },    qr/below Clay_MinMemorySize\(\) = $min/, '0 croaks' );
	like( dies { Clay_Initialize(1, [10, 10]) },    qr/below Clay_MinMemorySize/, '1 croaks' );
	like( dies { Clay_Initialize(1024, [10, 10]) }, qr/below Clay_MinMemorySize/, '1024 croaks' );
	like( dies { Clay_Initialize('abc', [10, 10]) }, qr/non-negative integer/, "'abc' croaks" );
	like( dies { Clay_Initialize(1.5, [10, 10]) },  qr/non-negative integer/, '1.5 croaks' );
	like( dies { Clay_Initialize($min, [10, 10], 'not code') }, qr/error handler: expected a CODE reference/,
		'non-code error handler croaks' );
};

subtest 'a failing Clay_Initialize does not leak its arena' => sub {
	open my $statm, '<', '/proc/self/statm' or skip_all 'no /proc/self/statm';
	my $page_kb = POSIX::sysconf(POSIX::_SC_PAGESIZE()) / 1024;
	my $vm_pages = sub { seek $statm, 0, 0; my ($size) = split ' ', scalar <$statm>; $size };
	my $min = Clay_MinMemorySize();
	eval { Clay_Initialize($min, 'bad') } for 1 .. 5;
	my $before = $vm_pages->();
	eval { Clay_Initialize($min, 'bad') } for 1 .. 200;
	my $grown_kb = ($vm_pages->() - $before) * $page_kb;
	ok( $grown_kb < 20_000, "200 failed Clay_Initialize calls grew VmSize by $grown_kb kB" );
};

subtest 'capacity setters validate their argument' => sub {
	my $ctx = new_context();
	like( dies { Clay_SetMaxElementCount(0) },          qr/expected an integer in 1\.\.2147483647/, 'element count 0' );
	like( dies { Clay_SetMaxElementCount(-5) },         qr/expected an integer in 1\.\./, 'negative element count' );
	like( dies { Clay_SetMaxElementCount(4294967297) }, qr/expected an integer in 1\.\./, 'element count above INT32_MAX' );
	like( dies { Clay_SetMaxElementCount(1.5) },        qr/expected an integer/, 'fractional element count' );
	like( dies { Clay_SetMaxElementCount(2**31 - 1) },  qr/limited to 4 GiB/, 'element count whose arena overflows' );
	like( dies { Clay_SetMaxMeasureTextCacheWordCount(31) }, qr/expected an integer in 32\.\./, 'word count below 32' );
	is( Clay_GetMaxElementCount(), 8192, 'rejected values leave the count unchanged' );
	like( dies { Clay_Initialize(2**64, { width => 10, height => 10 }) },
		qr/Clay_Initialize: capacity must be a non-negative integer/, 'a capacity beyond size_t' );
};

subtest 'Clay_Initialize refuses a measure cache below 32 words' => sub {
	my $ctx = new_context();
	$ctx->DESTROY;
	Clay_SetMaxElementCount(15);
	like( dies { Clay_Initialize(Clay_MinMemorySize(), { width => 10, height => 10 }) },
		qr/30 measure-cache words are below the minimum of 32/, 'the word count Clay derived from 15 elements' );
	Clay_SetMaxMeasureTextCacheWordCount(32);
	is( Clay_GetMaxElementCount(), 15, 'the element getter reports the process-wide default without a context' );
	is( Clay_GetMaxMeasureTextCacheWordCount(), 32, 'so does the word getter' );
	ok( lives { new_context() }, 'setting the word count afterwards fixes it' );
	is( Clay_GetCurrentContext(), undef, 'that context is gone again' );
	Clay_SetMaxElementCount(8192);   # back to Clay's defaults (and 2 x 8192 words)
};

subtest 'counts whose arena exceeds 4 GiB are rejected' => sub {
	my $ctx = new_context();
	like( dies { Clay_SetMaxElementCount(6_500_000) }, qr/limited to 4 GiB/, 'with a current context' );
	$ctx->DESTROY;
	is( Clay_GetCurrentContext(), undef, 'no current context' );
	like( dies { Clay_SetMaxElementCount(5_912_000) }, qr/limited to 4 GiB/, 'before Clay_Initialize' );
	ok( Clay_MinMemorySize() >= 65536, 'Clay_MinMemorySize still reports the default size' );
	ok( lives { new_context() }, 'Clay_Initialize still works' );
};

subtest 'Clay_MinMemorySize sizes explicit counts by the count rules' => sub {
	my $ctx = new_context();
	is( Clay_MinMemorySize({ maxElementCount => 8192, maxMeasureTextCacheWordCount => 16384 }), Clay_MinMemorySize(),
		'the counts of the current context need what Clay_MinMemorySize() reports' );
	is( Clay_MinMemorySize(undef), Clay_MinMemorySize(), 'undef stands for the configured counts' );
	is( Clay_MinMemorySize({ maxElementCount => 1000 }), Clay_MinMemorySize({ maxElementCount => 1000, maxMeasureTextCacheWordCount => 2000 }),
		'the word count defaults to twice the elements' );
	is( Clay_MinMemorySize({ maxElementCount => 10 }), Clay_MinMemorySize({ maxElementCount => 10, maxMeasureTextCacheWordCount => 32 }),
		'and to at least 32 words' );
	ok( Clay_MinMemorySize({ maxElementCount => 2000 }) > Clay_MinMemorySize({ maxElementCount => 1000 }),
		'more elements need more memory' );

	like( dies { Clay_MinMemorySize({ maxElementCount => 100, maxMeasureTextCacheWordCount => 31 }) },
		qr/^Clay_MinMemorySize: counts: maxMeasureTextCacheWordCount: expected an integer in 32\.\.2147483647, got '31'/,
		'fewer than 32 words croak' );
	ok( lives { Clay_MinMemorySize({ maxElementCount => 10, maxMeasureTextCacheWordCount => 351 }) },
		'32 words per element or fewer fit' );
	like( dies { Clay_MinMemorySize({ maxElementCount => 10, maxMeasureTextCacheWordCount => 352 }) },
		qr/^Clay_MinMemorySize: 352 measure-cache words need 11 hash buckets but only 10 elements are configured/,
		'more croak: Clay would index its measure cache past its elements' );
	like( dies { Clay_MinMemorySize({ maxElementCount => 6_500_000 }) }, qr/^Clay_MinMemorySize: .*limited to 4 GiB/,
		'counts whose arena exceeds 4 GiB croak' );
	like( dies { Clay_MinMemorySize({ maxElementCount => 2**30 }) }, qr/would overflow the default measure-cache word count/,
		'so do elements whose default word count overflows' );

	like( dies { Clay_MinMemorySize({ maxElementCount => 0 }) },
		qr/^Clay_MinMemorySize: counts: maxElementCount: expected an integer in 1\.\.2147483647, got '0'/, 'no elements croak' );
	like( dies { Clay_MinMemorySize({ maxMeasureTextCacheWordCount => 64 }) },
		qr/^Clay_MinMemorySize: counts: maxElementCount is required/, 'the element count is required' );
	like( dies { Clay_MinMemorySize({ maxElementCount => 10, maxElements => 10 }) },
		qr/^Clay_MinMemorySize: counts: unknown key 'maxElements'; the keys are maxElementCount and maxMeasureTextCacheWordCount/,
		'unknown keys croak' );
	like( dies { Clay_MinMemorySize(10) }, qr/^Clay_MinMemorySize: counts: expected a hash reference or undef, got '10'/,
		'counts must be a hash' );
	is( [ Clay_GetMaxElementCount(), Clay_GetMaxMeasureTextCacheWordCount() ], [ 8192, 16384 ],
		'the current context keeps its counts' );
};

subtest 'Clay_Initialize with counts changes no other counts' => sub {
	my %counts = (maxElementCount => 100, maxMeasureTextCacheWordCount => 64);
	my $ctx = new_context();
	like( dies { Clay_Initialize(Clay_MinMemorySize(\%counts) - 1, [10, 10], undef, undef, \%counts) },
		qr/^Clay_Initialize: capacity \d+ is below Clay_MinMemorySize\(\) = \d+ bytes for 100 elements and 64 measure-cache words/,
		'the capacity must fit the given counts' );
	ok( Clay_GetCurrentContext() == $ctx, 'a refused call leaves the previous context current' );

	my $small = Clay_Initialize(Clay_MinMemorySize(\%counts), [100, 100], undef, undef, \%counts);
	Clay_SetMeasureTextFunction(sub { return { width => 1, height => 1 } });
	ok( Clay_GetCurrentContext() == $small, 'the new context is current' );
	is( [ Clay_GetMaxElementCount(), Clay_GetMaxMeasureTextCacheWordCount() ], [ 100, 64 ], 'with exactly the counts' );
	is( text_of(build_frame('small')), 'small', 'and renders' );

	Clay_SetCurrentContext($ctx);
	is( [ Clay_GetMaxElementCount(), Clay_GetMaxMeasureTextCacheWordCount() ], [ 8192, 16384 ],
		'the previous context keeps its counts' );
	is( text_of(build_frame('previous')), 'previous', 'and still renders' );

	undef $ctx;
	undef $small;
	is( Clay_GetCurrentContext(), undef, 'no context is current' );
	my $alone = Clay_Initialize(Clay_MinMemorySize(\%counts), [10, 10], undef, undef, \%counts);
	is( Clay_GetMaxElementCount(), 100, 'without a current context the counts still reach the new context' );
	undef $alone;
	is( [ Clay_GetMaxElementCount(), Clay_GetMaxMeasureTextCacheWordCount() ], [ 8192, 16384 ],
		"Clay's process-wide defaults are unchanged" );
};

subtest 'changing a count requires a new Clay_Initialize' => sub {
	my $ctx = new_context();
	Clay_SetMaxElementCount(16384);
	is( Clay_GetMaxElementCount(), 16384, 'the getter reports the new count' );

	my $bigger = Clay_Initialize(Clay_MinMemorySize(), { width => 100, height => 100 });
	Clay_SetMeasureTextFunction(sub { return { width => 1, height => 1 } });
	is( Clay_GetMaxElementCount(), 16384, 're-Initialize adopts the new count' );
	is( text_of(build_frame('bigger')), 'bigger', 'and renders' );
};

done_testing;
