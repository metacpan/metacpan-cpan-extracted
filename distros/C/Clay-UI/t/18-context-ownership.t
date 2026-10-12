use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;
use Config;
use POSIX ();

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# Context ownership, lifetime and validation: every Perl handle to a context
# shares one referent, copies and forgeries are rejected, Clay-touching calls
# croak without a usable context, and Clay_Initialize / the capacity setters
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

subtest 'Clay-touching calls croak without a current context' => sub {
	my @calls = (
		[ Clay_SetLayoutDimensions         => sub { Clay_SetLayoutDimensions([10, 10]) } ],
		[ Clay_GetLayoutDimensions         => sub { Clay_GetLayoutDimensions() } ],
		[ Clay_BeginLayout                 => sub { Clay_BeginLayout() } ],
		[ Clay_EndLayout                   => sub { Clay_EndLayout() } ],
		[ Clay__OpenElement                => sub { Clay__OpenElement() } ],
		[ Clay__OpenElementWithId          => sub { Clay__OpenElementWithId({ id => 1 }) } ],
		[ Clay__CloseElement               => sub { Clay__CloseElement() } ],
		[ Clay__ConfigureOpenElement       => sub { Clay__ConfigureOpenElement({}) } ],
		[ Clay__OpenTextElement            => sub { Clay__OpenTextElement('x', {}) } ],
		[ Clay_GetOpenElementId            => sub { Clay_GetOpenElementId() } ],
		[ Clay_GetElementData              => sub { Clay_GetElementData({ id => 1 }) } ],
		[ Clay_SetMeasureTextFunction      => sub { Clay_SetMeasureTextFunction(sub { }) } ],
		[ Clay_ResetMeasureTextCache       => sub { Clay_ResetMeasureTextCache() } ],
		[ Clay_SetPointerState             => sub { Clay_SetPointerState([0, 0], 0) } ],
		[ Clay_GetPointerState             => sub { Clay_GetPointerState() } ],
		[ Clay_Hovered                     => sub { Clay_Hovered() } ],
		[ Clay_OnHover                     => sub { Clay_OnHover(sub { }) } ],
		[ Clay_PointerOver                 => sub { Clay_PointerOver({ id => 1 }) } ],
		[ Clay_GetPointerOverIds           => sub { Clay_GetPointerOverIds() } ],
		[ Clay_UpdateScrollContainers      => sub { Clay_UpdateScrollContainers(0, [0, 0], 0) } ],
		[ Clay_GetScrollOffset             => sub { Clay_GetScrollOffset() } ],
		[ Clay_GetScrollContainerData      => sub { Clay_GetScrollContainerData({ id => 1 }) } ],
		[ Clay_SetQueryScrollOffsetFunction => sub { Clay_SetQueryScrollOffsetFunction(sub { }) } ],
		[ Clay_SetExternalScrollHandlingEnabled => sub { Clay_SetExternalScrollHandlingEnabled(0) } ],
		[ set_scroll_position              => sub { set_scroll_position({ id => 1 }, [0, 0]) } ],
		[ Clay_SetDebugModeEnabled         => sub { Clay_SetDebugModeEnabled(1) } ],
		[ Clay_IsDebugModeEnabled          => sub { Clay_IsDebugModeEnabled() } ],
		[ Clay_SetCullingEnabled           => sub { Clay_SetCullingEnabled(1) } ],
		[ Clay_SetTransitionHandlers       => sub { Clay_SetTransitionHandlers() } ],
	);
	for my $call (@calls) {
		my ($name, $code) = @$call;
		like( dies { $code->() }, qr/\Q$name\E: no current Clay context/, "$name croaks" );
	}

	is( Clay_GetCurrentContext(), undef, 'Clay_GetCurrentContext is undef without a context' );
	ok( lives { Clay_GetElementId('x'); Clay__HashString('x', 3); Clay_EaseOut({}) },
		'pure helpers need no context' );
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

subtest 'changing a count requires a new Clay_Initialize' => sub {
	my $ctx = new_context();
	Clay_SetMaxElementCount(16384);
	is( Clay_GetMaxElementCount(), 16384, 'the getter reports the new count' );
	like( dies { Clay_BeginLayout() }, qr/element\/word counts changed since Clay_Initialize/,
		'Clay_BeginLayout croaks after a count change' );
	like( dies { Clay_SetPointerState([0, 0], 0) }, qr/counts changed/, 'so does every Clay-touching call' );

	my $bigger = Clay_Initialize(Clay_MinMemorySize(), { width => 100, height => 100 });
	Clay_SetMeasureTextFunction(sub { return { width => 1, height => 1 } });
	is( Clay_GetMaxElementCount(), 16384, 're-Initialize adopts the new count' );
	is( text_of(build_frame('bigger')), 'bigger', 'and renders' );
};

done_testing;
