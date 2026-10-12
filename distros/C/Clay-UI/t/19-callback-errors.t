use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Scalar::Util ();

use lib "t/lib";
use Clay::Test::ChildPerl qw(child_perl);

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# Callbacks are stored by value and validated at install time. An exception
# thrown by a callback while Clay runs is re-thrown by the Clay::XS call
# that invoked Clay, once Clay has returned.
# -----------------------------------------------------------------------------

sub fresh_context (%args) {
	my $ctx = Clay_Initialize(Clay_MinMemorySize(), { width => 300, height => 100 },
		$args{error_handler}, $args{error_userdata});
	Clay_SetMeasureTextFunction($args{measure} // sub ($text, $config, $userdata) {
		return { width => length($text), height => 10 };
	});
	return $ctx;
}

sub box ($name, %decl) {
	Clay__OpenElementWithId(Clay_GetElementId($name));
	Clay__ConfigureOpenElement({
		layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(100) } },
		%decl,
	});
}

subtest 'hover callbacks are stored by value' => sub {
	my $ctx = fresh_context();
	my @fired;
	my $build = sub {
		my $handler;
		Clay_BeginLayout();
		for my $name (qw(first second third)) {
			box($name);
			$handler = sub { push @fired, $name };
			Clay_OnHover($handler);
			Clay__CloseElement();
		}
		Clay_EndLayout();
	};
	$build->();
	Clay_SetPointerState([10, 10], 0);
	is( \@fired, ['first'], 'a reused variable still dispatches to the handler of each element' );
};

subtest 'reassigning the caller variables after install has no effect' => sub {
	my $seen;
	my $payload = 'original';
	my $measure = sub ($text, $config, $userdata) { $seen = $userdata; return { width => 1, height => 1 } };
	my $ctx = fresh_context(measure => $measure);
	Clay_SetMeasureTextFunction($measure, $payload);
	$payload = 'mutated-after-install';
	$measure = undef;
	Clay_BeginLayout();
	Clay__OpenTextElement('a', {});
	Clay_EndLayout();
	is( $seen, 'original', 'callback and userdata are private copies' );
};

subtest 'callbacks must be CODE references' => sub {
	my $ctx = fresh_context();
	like( dies { Clay_SetMeasureTextFunction('x') }, qr/expected a CODE reference or undef, got 'x'/,
		'measure function' );
	like( dies { Clay_SetTransitionHandlers(undef, 'x') }, qr/setInitialState: expected a CODE reference/,
		'transition handler' );
	like( dies { Clay_SetQueryScrollOffsetFunction([]) }, qr/expected a CODE reference or undef, got an ARRAY/,
		'query scroll offset function' );
	Clay_BeginLayout();
	box('hoverable');
	like( dies { Clay_OnHover('x') }, qr/Clay_OnHover: callback: expected a CODE reference, got 'x'/,
		'hover callback' );
	like( dies { Clay_OnHover(undef) }, qr/expected a CODE reference, got undef/, 'undef hover callback' );
	Clay__CloseElement();
	Clay_EndLayout();
};

subtest 'a dying error handler propagates out of Clay_EndLayout' => sub {
	my @args;
	my $ctx = fresh_context(
		error_handler  => sub ($error, $userdata) { push @args, [ $error, $userdata ]; die "Clay error: $error->{errorText}\n" },
		error_userdata => 'handler-payload',
	);
	Clay_BeginLayout();
	for (1 .. 2) { box('dup'); Clay__CloseElement() }
	like( dies { Clay_EndLayout() }, qr/^Clay error: An element with this ID was already previously declared/,
		'the handler exception is re-thrown' );
	is( $args[0][0]{errorType}, CLAY_ERROR_TYPE_DUPLICATE_ID, 'handler receives errorType' );
	is( $args[0][1], 'handler-payload', 'handler receives its userdata' );

	Clay_BeginLayout();
	box('single');
	Clay__CloseElement();
	ok( lives { Clay_EndLayout() }, 'the next frame is clean' );
};

subtest 'a bad transition handler result croaks from Clay_EndLayout' => sub {
	my $ctx = fresh_context();
	Clay_SetTransitionHandlers(sub ($args, $userdata) {
		$args->{current} = { boundingBox => [1, 2, 3, 4] };
		return 0;
	});
	my $frame = sub ($colour) {
		Clay_BeginLayout();
		box('fading', backgroundColor => $colour,
			transition => { duration => 1, properties => CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR });
		Clay__CloseElement();
		return Clay_EndLayout(0.1);
	};
	$frame->([255, 0, 0, 255]);
	like( dies { $frame->([0, 0, 255, 255]) },
		qr/transition handler args\.current\.boundingBox: expected a hash reference, got an ARRAY reference/,
		'the malformed result is reported' );
	Clay_SetTransitionHandlers();
};

subtest 'a dying hover callback propagates out of Clay_SetPointerState' => sub {
	my $ctx = fresh_context();
	Clay_BeginLayout();
	box('trap');
	Clay_OnHover(sub { die "hover exploded\n" });
	Clay__CloseElement();
	Clay_EndLayout();
	like( dies { Clay_SetPointerState([10, 10], 0) }, qr/^hover exploded$/, 'hover exception re-thrown' );
};

subtest 'a failing measurer is called once per frame' => sub {
	my $calls = 0;
	my $ctx = fresh_context(measure => sub { $calls++; die "no font\n" });
	Clay_BeginLayout();
	Clay__OpenTextElement("many words in this text $_", {}) for 1 .. 20;
	like( dies { Clay_EndLayout() }, qr/^no font$/, 'one exception for the frame' );
	is( $calls, 1, 'the measurer ran once' );
};

subtest 'later callback errors of the same call are counted' => sub {
	my $ctx = fresh_context();
	Clay_BeginLayout();
	box('outer');
	Clay_OnHover(sub { die "outer hover\n" });
	box('inner');
	Clay_OnHover(sub { die "inner hover\n" });
	Clay__CloseElement();
	Clay__CloseElement();
	Clay_EndLayout();
	like( dies { Clay_SetPointerState([10, 10], 0) },
		qr/^outer hover \(and 1 more callback error this frame\)$/, 'first error re-thrown, second counted' );
};

subtest 'a context without a measure function reports measured text' => sub {
	my $a = fresh_context();
	my $b = Clay_Initialize(Clay_MinMemorySize(), { width => 100, height => 100 });
	Clay_BeginLayout();
	Clay__OpenTextElement('hello', {});
	like( dies { Clay_EndLayout() },
		qr/text measured but no measure_text function is installed for this context/,
		'second context without a measurer croaks' );
};

subtest 'an error left by an unfinished frame is raised by the next Clay_BeginLayout' => sub {
	my $ctx = fresh_context(measure => sub { die "measure failed\n" });
	Clay_BeginLayout();
	Clay__OpenTextElement('abandoned', {});
	like( dies { Clay_BeginLayout() }, qr/^measure failed \(from the previous unfinished frame\)$/,
		'the leftover error names its origin' );
	Clay_SetMeasureTextFunction(sub { return { width => 1, height => 1 } });
	Clay_BeginLayout();
	Clay__OpenTextElement('fine', {});
	ok( lives { Clay_EndLayout() }, 'the following frame works' );
};

subtest 'a query in the middle of a frame leaves the held error for Clay_EndLayout' => sub {
	my $ctx = fresh_context(measure => sub { die "measure failed\n" });
	Clay_BeginLayout();
	box('outer');
	Clay__OpenTextElement('unmeasurable', {});
	ok( lives { Clay_PointerOver(Clay_GetElementId('outer')) }, 'Clay_PointerOver returns normally' );
	is( Clay::XS::_context_stats($ctx)->{open_depth}, 1, 'and the element stays open' );
	Clay__CloseElement();
	like( dies { Clay_EndLayout() }, qr/^measure failed$/, 'Clay_EndLayout re-throws the error' );
	is( Clay::XS::_context_stats($ctx), hash { field layout_state => 'complete'; field open_depth => 0; etc },
		'with nothing left open' );
};

subtest 'a call refused inside a callback evaluates none of its arguments' => sub {
	package Recording::Bool { our $calls = 0; use overload 'bool' => sub { $calls++; 1 }, fallback => 1 }
	my $flag = bless {}, 'Recording::Bool';
	my %calls = (
		Clay_SetPointerState                  => [ [0, 0], $flag ],
		Clay_UpdateScrollContainers           => [ $flag, [0, 0], 0 ],
		Clay_SetExternalScrollHandlingEnabled => [ $flag ],
		Clay_SetDebugModeEnabled              => [ $flag ],
		Clay_SetCullingEnabled                => [ $flag ],
	);
	my %refused;
	my $ctx = fresh_context(measure => sub ($text, $config, $userdata) {
		for my $name (sort keys %calls) {
			eval { Clay::XS->can($name)->(@{ $calls{$name} }); 1 }
				or $refused{$name} = $@ =~ /^\Q$name\E: cannot be called from inside a Clay callback/ ? 1 : $@;
		}
		return { width => 1, height => 1 };
	});
	text_frame();
	is( \%refused, { map { $_ => 1 } keys %calls }, 'every call is refused' );
	is( $Recording::Bool::calls, 0, 'before its boolean argument is read' );
};

subtest 'loop control in a callback cannot leave the callback' => sub {
	my $ctx = fresh_context();
	Clay_BeginLayout();
	box('looping');
	Clay_OnHover(sub { no warnings 'exiting'; last FRAME });
	Clay__CloseElement();
	Clay_EndLayout();
	my @errors;
	FRAME: for my $iteration (1 .. 2) {
		eval { Clay_SetPointerState([10, 10], 0); 1 } or push @errors, $@;
	}
	is( scalar @errors, 2, 'the loop around the call runs every iteration' );
	like( $errors[0], qr/^Label not found for "last FRAME"/, 'Clay_SetPointerState re-throws the error last died with' );
	is( Clay::XS::_context_stats($ctx)->{callback_depth}, 0, 'no callback is left running' );
	ok( lives { Clay_BeginLayout(); Clay_EndLayout() }, 'the next frame works' );
	is( warnings { undef $ctx }, [], 'and the context goes away silently' );
};

# Runs Perl code in a child perl; returns its output (STDOUT and STDERR)
# and exit status.
sub run_child ($code) {
	my $redirect = qq{BEGIN { open STDERR, '>&', \\*STDOUT or die "cannot redirect STDERR: \$!" }\n};
	open my $child, '-|', child_perl($redirect . $code) or die "cannot run $^X: $!";
	my $output = do { local $/; <$child> };
	close $child;
	return ($output, $? >> 8);
}

subtest 'exit in a callback takes effect once Clay has returned' => sub {
	my $preamble = <<'PERL';
use Clay::XS qw(:all);
our $ctx = Clay_Initialize(Clay_MinMemorySize(), [300, 100]);
END {
	Clay_SetMeasureTextFunction(sub { [1, 1] });
	print eval { Clay_BeginLayout(); Clay_EndLayout(); 1 } ? "END: frame ok\n" : "END: died: $@";
}
PERL
	my %exits = (
		'a hover callback' => <<'PERL',
Clay_BeginLayout();
Clay__OpenElementWithId(Clay_GetElementId('quit'));
Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(100) } } });
Clay_OnHover(sub { exit 3 });
Clay__CloseElement();
Clay_EndLayout();
Clay_SetPointerState([10, 10], 1);
print "not reached\n";
PERL
		'a measure callback' => <<'PERL',
Clay_SetMeasureTextFunction(sub { exit 3 });
Clay_BeginLayout();
Clay__OpenTextElement('quit', {});
print "not reached\n";
PERL
	);
	for my $where (sort keys %exits) {
		my ($output, $status) = run_child($preamble . $exits{$where});
		is( [ $output, $status ], [ "END: frame ok\n", 3 ],
			"exit 3 in $where: END blocks can use Clay, the status is 3, nothing else is printed" );
	}
};

subtest 'a query inside a hover callback leaves the held error alone' => sub {
	my $ctx = fresh_context();
	my ($calls, $query_error) = (0, undef);
	my $hover = sub {
		die "first hover\n" if $calls++ == 0;
		eval { Clay_GetPointerState(); 1 } or $query_error = $@;
	};
	Clay_BeginLayout();
	box('outer');
	Clay_OnHover($hover);
	box('inner');
	Clay_OnHover($hover);
	Clay__CloseElement();
	Clay__CloseElement();
	Clay_EndLayout();
	like( dies { Clay_SetPointerState([10, 10], 0) }, qr/^first hover$/,
		'Clay_SetPointerState re-throws the first error' );
	is( $calls, 2, 'both hover callbacks ran' );
	is( $query_error, undef, 'the query in the second callback did not take it' );
};

subtest 'a query inside a transition handler leaves the held error alone' => sub {
	my $ctx = fresh_context(measure => sub ($text, $config, $userdata) {
		die "measure failed\n" if $text eq 'bad';
		return { width => 1, height => 1 };
	});
	my ($handled, $query_error) = (0, undef);
	Clay_SetTransitionHandlers(sub ($args, $userdata) {
		$handled++;
		eval { Clay_GetPointerState(); 1 } or $query_error = $@;
		return 1;
	});
	my $frame = sub ($colour, $text) {
		Clay_BeginLayout();
		box('fading', backgroundColor => $colour,
			transition => { duration => 1, properties => CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR });
		Clay__OpenTextElement($text, {});
		Clay__CloseElement();
		return Clay_EndLayout(0.1);
	};
	$frame->([255, 0, 0, 255], 'good');
	like( dies { $frame->([0, 0, 255, 255], 'bad') }, qr/^measure failed$/,
		'Clay_EndLayout re-throws the measure error' );
	ok( $handled, 'the transition handler ran' );
	is( $query_error, undef, 'the query in the handler did not take it' );
	Clay_SetTransitionHandlers();
};

# -----------------------------------------------------------------------------
# A callback runs in the middle of a Clay function: it cannot free the
# context Clay is using, and calls that change Clay's state croak (the croak
# is re-thrown by the call that invoked Clay).
# -----------------------------------------------------------------------------

sub text_frame ($text = 'hello') {
	Clay_BeginLayout();
	Clay__OpenTextElement($text, {});
	return Clay_EndLayout();
}

subtest 'a callback dropping the last reference does not free the running context' => sub {
	my $ctx = fresh_context();
	Clay_BeginLayout();
	box('drop');
	Clay_OnHover(sub { undef $ctx });
	Clay__CloseElement();
	Clay_EndLayout();
	ok( lives { Clay_SetPointerState([10, 10], 0) }, 'Clay_SetPointerState completes' );
	is( $ctx, undef, 'the callback dropped the reference' );
	like( dies { Clay_BeginLayout() }, qr/no current Clay context/, 'the context is freed afterwards' );

	my $measured;
	$measured = fresh_context(measure => sub ($text, $config, $userdata) {
		undef $measured;
		return { width => 1, height => 1 };
	});
	Clay_BeginLayout();
	ok( lives { Clay__OpenTextElement('hello', {}) }, 'the call that ran the dropping measurer completes' );
	like( dies { Clay_EndLayout() }, qr/no current Clay context/, 'and that context is freed afterwards' );
};

subtest 'a callback cannot destroy the running context explicitly' => sub {
	my $ctx;
	$ctx = fresh_context(measure => sub ($text, $config, $userdata) {
		$ctx->DESTROY;
		return { width => 1, height => 1 };
	});
	like( dies { text_frame() }, qr/DESTROY: cannot be called from inside a Clay callback/,
		'explicit DESTROY croaks' );
	ok( Clay_GetCurrentContext(), 'the context is still alive' );
};

# The wrapper guard table (Clay::XS::_wrapper_guards) says which functions
# change Clay's state. Arguments are never parsed before the guard refuses
# the call, so a call needs only the right number of them.
my $GUARDS = Clay::XS::_wrapper_guards();
my %ARGC = (
	Clay_Initialize => 2, Clay_SetPointerState => 2, set_scroll_position => 2,
	Clay_UpdateScrollContainers => 3,
	map { $_ => 1 } qw(
		Clay_SetCurrentContext Clay_SetLayoutDimensions Clay__OpenElementWithId
		Clay__ConfigureOpenElement Clay__OpenTextElement Clay_SetMeasureTextFunction
		Clay_OnHover Clay_SetQueryScrollOffsetFunction Clay_SetExternalScrollHandlingEnabled
		Clay_SetDebugModeEnabled Clay_SetCullingEnabled Clay_SetMaxElementCount
		Clay_SetMaxMeasureTextCacheWordCount
	),
);

sub guarded ($predicate) {
	return sort grep { $predicate->($GUARDS->{$_}) } keys %$GUARDS;
}

subtest 'calls that change Clay state croak inside callbacks' => sub {
	for my $name (guarded(sub ($guard) { $guard->{mutates} })) {
		my $call = Clay::XS->can($name);
		my @args = (undef) x ($ARGC{$name} // 0);
		my $ctx = fresh_context(measure => sub ($text, $config, $userdata) {
			$call->(@args);
			return { width => 1, height => 1 };
		});
		like( dies { text_frame() }, qr/^\Q$name\E: cannot be called from inside a Clay callback/,
			"$name from a measure callback" );
		Clay_SetMeasureTextFunction(sub { return { width => 1, height => 1 } });
		ok( lives { text_frame() }, "the next frame after $name works" );
	}

	my $ctx = fresh_context();
	Clay_SetTransitionHandlers(sub ($args, $userdata) { Clay_BeginLayout(); return 1 });
	my $frame = sub ($colour) {
		Clay_BeginLayout();
		box('fading', backgroundColor => $colour,
			transition => { duration => 1, properties => CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR });
		Clay__CloseElement();
		return Clay_EndLayout(0.016);
	};
	$frame->([255, 0, 0, 255]);
	like( dies { $frame->([0, 0, 255, 255]) }, qr/^Clay_BeginLayout: cannot be called from inside a Clay callback/,
		'Clay_BeginLayout from a transition handler' );
	Clay_SetTransitionHandlers(sub ($args, $userdata) { my $other = Clay_Initialize(Clay_MinMemorySize(), [10, 10]); return 1 });
	like( dies { $frame->([0, 255, 0, 255]) }, qr/^Clay_Initialize: cannot be called from inside a Clay callback/,
		'Clay_Initialize from a transition handler' );
	Clay_SetTransitionHandlers();
	ok( lives { $frame->([0, 255, 0, 255]) }, 'the next frame works' );
};

subtest 'read-only queries work inside callbacks' => sub {
	my $id = Clay_GetElementId('somewhere');
	my %args = map { $_ => [$id] } qw(Clay_GetElementData Clay_PointerOver Clay_GetScrollContainerData);
	my @queries = guarded(sub ($guard) { !$guard->{mutates} && $guard->{context} ne 'none' });
	my %failed;
	my $ctx = fresh_context(measure => sub ($text, $config, $userdata) {
		for my $name (@queries) {
			eval { Clay::XS->can($name)->(@{ $args{$name} // [] }); 1 } or $failed{$name} = $@;
		}
		return { width => 1, height => 1 };
	});
	ok( lives { text_frame() }, 'the frame completes' );
	ok( scalar @queries, 'the table lists queries' );
	is( \%failed, {}, 'every query worked' );
};

subtest 'every export has a POD heading and the POD matches the wrapper guard table' => sub {
	open my $fh, '<', $INC{'Clay/XS.pm'} or die "cannot read Clay/XS.pm: $!";
	my $pod = do { local $/; <$fh> };
	my %headed = map { $_ => 1 } $pod =~ /^=(?:head\d|item)\s+(\w+)/mg;
	is( [ grep { !$headed{$_} } @Clay::XS::EXPORT_OK ], [], 'every exported function and constant has its own heading' );

	my @paragraphs = split /\n\s*\n/, $pod;
	my $named = sub ($marker) {
		my ($paragraph) = grep { /\Q$marker\E/ } @paragraphs;
		return sort grep { exists $GUARDS->{$_} } $paragraph =~ /C<(\w+)>/g;
	};

	is( [ $named->('cannot be called from inside a Clay callback') ],
		[ guarded(sub ($guard) { $guard->{mutates} }) ], 'the POD names every mutating function' );
	is( [ $named->('Read-only queries work') ],
		[ guarded(sub ($guard) { !$guard->{mutates} && $guard->{context} ne 'none' }) ],
		'the POD names every query' );
	my %never = map { $_ => 1 } guarded(sub ($guard) { $guard->{rethrow} eq 'never' });
	my @named_never = $named->('These never re-throw a held error');
	is( [ grep { !$never{$_} } @named_never ], [], 'what the POD says never re-throws does not' );
	my %named_never = map { $_ => 1 } @named_never;
	is( [ grep { !$named_never{$_} } guarded(sub ($guard) { $guard->{rethrow} eq 'never' && $guard->{context} ne 'none' }) ],
		[], 'the POD names every function with a context that never re-throws' );
};

subtest 'an exception object with a dying bool overload is re-thrown as is' => sub {
	package My::Exception { use overload 'bool' => sub { die "bool called\n" }, fallback => 1 }
	my $exception = bless {}, 'My::Exception';
	my $ctx = fresh_context(measure => sub { die $exception });
	# Test2's dies() truth-tests the exception, so use a plain eval.
	my $ok    = eval { text_frame(); 1 };
	my $error = $@;
	ok( !defined $ok, 'the frame dies' );
	is( Scalar::Util::refaddr($error), Scalar::Util::refaddr($exception), 'with the same object' );
};

subtest 'a held exception object survives elements left open' => sub {
	my $exception = bless {}, 'My::Exception';
	my $ctx = fresh_context(measure => sub { die $exception });
	Clay_BeginLayout();
	box('left-open');
	Clay__OpenTextElement('hello', {});
	my $ok    = eval { Clay_EndLayout(); 1 };
	my $error = $@;
	ok( !defined $ok, 'Clay_EndLayout dies' );
	is( Scalar::Util::refaddr($error), Scalar::Util::refaddr($exception), 'with the held object' );
	Clay_SetMeasureTextFunction(sub { return { width => 1, height => 1 } });
	ok( lives { text_frame() }, 'the open element was closed' );
};

subtest 'destroying a context with a held error warns' => sub {
	my $ctx = fresh_context(measure => sub { die "measure failed\n" });
	Clay_BeginLayout();
	Clay__OpenTextElement('abandoned', {});
	like( warning { undef $ctx }, qr/^Clay::XS: context destroyed with a held callback error: measure failed$/,
		'the error is not lost' );
};

subtest 'Clay::XS::_dispatch cannot be called directly' => sub {
	like( dies { Clay::XS::_dispatch(1, 0, sub { [1, 2] }) }, qr/_dispatch is internal/, 'outside a callback' );
	my $inner;
	my $ctx = fresh_context(measure => sub ($text, $config, $userdata) {
		$inner = dies { Clay::XS::_dispatch(sub { [1, 2] }) };
		return { width => 1, height => 1 };
	});
	text_frame();
	like( $inner, qr/_dispatch is internal/, 'inside a callback' );
};

subtest 'code that runs while callback arguments are freed cannot re-enter Clay' => sub {
	package Reenter { our @errors; sub DESTROY { eval { Clay::XS::Clay_BeginLayout(); 1 } or push @errors, $@ } }
	my $ctx = fresh_context(measure => sub ($text, $config, $userdata) {
		bless $config, 'Reenter';   # freed with the arguments, after the callback returned
		return { width => length($text), height => 10 };
	});
	my $commands = text_frame('guarded');
	ok( scalar @Reenter::errors, 'the DESTROY ran' );
	like( $Reenter::errors[0], qr/^Clay_BeginLayout: cannot be called from inside a Clay callback/,
		'and its Clay call was refused' );
	is( $commands->[0]{renderData}{stringContents}, 'guarded', 'the frame finished intact' );
};

subtest 'replacing the internal dispatcher does not break callbacks' => sub {
	# In a process of its own: the replacement frees the glob's original.
	my $code = <<'PERL';
use Clay::XS qw(:all);
my $ctx = Clay_Initialize(Clay_MinMemorySize(), [100, 100]);
Clay_SetMeasureTextFunction(sub { [1, 1] });
{ no warnings 'redefine'; *Clay::XS::_dispatch = sub { die "replacement called\n" }; }
Clay_BeginLayout(); Clay__OpenTextElement('measured', {});
print eval { Clay_EndLayout(); 1 } ? "measured\n" : "died: $@";
undef $ctx;
my $later = Clay_Initialize(Clay_MinMemorySize(), [100, 100]);
Clay_SetMeasureTextFunction(sub { [1, 1] });
Clay_BeginLayout(); Clay__OpenTextElement('measured', {});
print eval { Clay_EndLayout(); 1 } ? "measured later\n" : "died: $@";
PERL
	open my $child, '-|', child_perl($code) or die "cannot run $^X: $!";
	my $output = do { local $/; <$child> };
	close $child;
	is( $output, "measured\nmeasured later\n",
		'the trampolines keep calling the original dispatcher, also for a context made after the replacement' );
};

subtest 'a measure function returning undef is an error' => sub {
	my $ctx = fresh_context(measure => sub { return undef });
	like( dies { text_frame() }, qr/measure_text callback result: expected a hash or array reference, got undef/,
		'Clay_EndLayout croaks' );
};

subtest 'a dying warn handler does not keep a destroyed context alive' => sub {
	my $ctx = fresh_context(measure => sub { die "measure failed\n" });
	Clay_BeginLayout();
	Clay__OpenTextElement('abandoned', {});
	{
		local $SIG{__WARN__} = sub { die "warned: $_[0]" };
		like( dies { $ctx->DESTROY }, qr/^warned: Clay::XS: context destroyed with a held callback error/,
			'the warning still reaches the handler' );
	}
	like( dies { Clay::XS::_context_stats($ctx) }, qr/not a live Clay::XS::Context/,
		'the context was freed before it' );

	package Unprintable { use overload '""' => sub { die "cannot print\n" }, fallback => 1 }
	my $other = fresh_context(measure => sub { die bless {}, 'Unprintable' });
	Clay_BeginLayout();
	Clay__OpenTextElement('abandoned', {});
	like( dies { $other->DESTROY }, qr/^cannot print$/, 'an error object that cannot be printed dies in DESTROY' );
	like( dies { Clay::XS::_context_stats($other) }, qr/not a live Clay::XS::Context/,
		'after the context was freed' );
};

subtest 'the caller $@ survives callbacks' => sub {
	my $ctx = fresh_context();
	eval { die "outer error\n" };
	Clay_BeginLayout();
	Clay__OpenTextElement('measured', {});
	Clay_EndLayout();
	is( $@, "outer error\n", '$@ is unchanged' );
};

done_testing;
