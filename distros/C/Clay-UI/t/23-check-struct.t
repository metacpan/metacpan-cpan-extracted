use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# check_struct walks a value against a struct schema without a Clay
# context or frame. It accepts what parse mode accepts, and is strict about
# unknown keys, array lengths and references used as booleans.
# -----------------------------------------------------------------------------

sub check_error ($type, $value, $root = undef) {
	my $error = dies { check_struct($type, $value, $root) };
	return $error;
}

my $SCHEMAS = Clay::XS::_struct_schemas();

sub field_names ($type) {
	return map { $_->{name} } @{ $SCHEMAS->{$type} };
}

subtest 'valid values pass' => sub {
	my @valid = (
		[ Clay_Color             => [ 1, 2, 3, 4 ] ],
		[ Clay_Color             => { r => 1, a => 255 } ],
		[ Clay_Vector2           => [ 1.5, -2 ] ],
		[ Clay_Dimensions        => { width => 10, height => 20 } ],
		[ Clay_CornerRadius      => 4 ],
		[ Clay_Padding           => padding_all(65535) ],
		[ Clay_SizingAxis        => sizing_fit(0, 9**9**9) ],
		[ Clay_SizingAxis        => sizing_percent(0.5) ],
		[ Clay_FloatingElementConfig => { zIndex => -32768, parentId => Clay_GetElementId('p') } ],
		[ Clay_TextElementConfig => { fontSize => 16, wrapMode => CLAY_TEXT_WRAP_NONE } ],
		[ Clay_ElementDeclaration => {
			layout => { sizing => { width => sizing_grow() }, childGap => 4 },
			backgroundColor => [ 0, 0, 0, 255 ],
			clip => { vertical => 1, childOffset => [ 0, -10 ] },
			transition => { duration => 0.2, enter => { hasSetInitial => 1 } },
		} ],
		[ Clay_TransitionCallbackArguments => {
			transitionState => CLAY_TRANSITION_STATE_EXITING, elapsedTime => 0.1, duration => 0.2,
			current => { backgroundColor => [ 1, 2, 3, 4 ] },
		} ],
		[ Clay_Padding => undef ],
	);
	for my $case (@valid) {
		ok( lives { check_struct(@$case) }, "$case->[0] accepts a valid value" ) or note $@;
	}
};

subtest 'range and type errors name the field' => sub {
	my @cases = (
		[ Clay_Padding => { left => -5 }, qr/^Clay_Padding\.left: expected an integer in 0\.\.65535, got '-5'/ ],
		[ Clay_LayoutConfig => { childGap => 70000 }, qr/^Clay_LayoutConfig\.childGap: expected an integer in 0\.\.65535/ ],
		[ Clay_LayoutConfig => { layoutDirection => 4 }, qr/layoutDirection: expected an integer in 0\.\.3/ ],
		[ Clay_FloatingElementConfig => { zIndex => 40000 }, qr/zIndex: expected an integer in -32768\.\.32767/ ],
		[ Clay_Color => { r => 'red' }, qr/^Clay_Color\.r: expected a number in 0\.\.255, got 'red'/ ],
		[ Clay_Color => [300, 0, 0, 255], qr/^Clay_Color\.r: expected a number in 0\.\.255, got '300'/ ],
		[ Clay_CornerRadius => { topLeft => -4 }, qr/^Clay_CornerRadius\.topLeft: expected a number >= 0, got '-4'/ ],
		[ Clay_CornerRadius => -4, qr/^Clay_CornerRadius: expected a number >= 0, got '-4'/ ],
		[ Clay_SizingAxis => { type => CLAY__SIZING_TYPE_PERCENT, percent => 1.5 }, qr/percent: expected a number in 0\.\.1, got '1.5'/ ],
		[ Clay_SizingAxis => { min => 0, max => -9**9**9 }, qr/max: expected a finite number or \+Inf/ ],
		[ Clay_LayoutConfig => { padding => { top => 1.5 } }, qr/^Clay_LayoutConfig\.padding\.top: expected an integer/ ],
		[ Clay_TransitionCallbackArguments => { elapsedTime => -0.5 },
			qr/^Clay_TransitionCallbackArguments\.elapsedTime: expected a number >= 0, got '-0\.5'/ ],
	);
	for my $case (@cases) {
		my ($type, $value, $message) = @$case;
		like( check_error($type, $value), $message, "$type: $message" );
	}
};

subtest 'shape errors carry the schema hint' => sub {
	my $error = check_error('Clay_LayoutConfig', { padding => 8 }, 'layout');
	like( "$error", qr/^layout\.padding: expected a hash reference, got '8' \(padding_all\(N\) builds one\)/,
		'hint appended to the message' );
	is( $error->hint, 'padding_all(N) builds one', 'hint reader' );

	like( check_error('Clay_Sizing', { width => 100 }),
		qr/width: expected a hash reference, got '100' \(sizing_fit, sizing_grow, sizing_fixed or sizing_percent build one\)/,
		'sizing axis hint' );
	like( check_error('Clay_ElementDeclaration', { backgroundColor => 'red' }),
		qr/backgroundColor: expected a hash or array reference, got 'red' at /,
		'no hint where the schema has none' );
};

subtest 'unknown keys are rejected at every level' => sub {
	my @known = field_names('Clay_LayoutConfig');
	my $error = check_error('Clay_LayoutConfig', { childGapp => 1, zz => 2 });
	like( "$error", qr/^Clay_LayoutConfig: expected only the keys \Q${\join(', ', @known)}\E, got the unknown keys 'childGapp', 'zz'/,
		'unknown keys listed, sorted' );
	is( $error->unknown_keys, [ 'childGapp', 'zz' ], 'unknown_keys reader' );
	is( $error->known_keys, \@known, 'known_keys reader lists the schema fields in order' );

	like( check_error('Clay_ElementDeclaration', { border => { width => { lft => 1 } } }),
		qr/^Clay_ElementDeclaration\.border\.width: expected only the keys left, right, top, bottom, betweenChildren, got the unknown key 'lft'/,
		'nested unknown key' );
	like( check_error('Clay_TransitionElementConfig', { exit => { hasSetInitial => 1 } }),
		qr/exit: expected only the keys trigger, siblingOrdering, hasSetFinal/,
		'anonymous transition structs know their keys' );
};

subtest 'sizing axis keys follow the axis type' => sub {
	like( check_error('Clay_SizingAxis', { type => CLAY__SIZING_TYPE_PERCENT, min => 1 }),
		qr/expected only the keys type, percent, got the unknown key 'min'/, 'percent axis has no min' );
	like( check_error('Clay_SizingAxis', { type => CLAY__SIZING_TYPE_FIXED, percent => 1 }),
		qr/expected only the keys min, max, type, got the unknown key 'percent'/, 'fixed axis has no percent' );
};

subtest 'arrays need one element per field' => sub {
	like( check_error('Clay_Color', [ 1, 2, 3 ]), qr/^Clay_Color: expected an array of 4 numbers, got an array of 3 elements/,
		'short colour' );
	like( check_error('Clay_Vector2', [ 1, 2, 3 ]), qr/expected an array of 2 numbers, got an array of 3 elements/,
		'long vector' );
};

subtest 'booleans must be plain values' => sub {
	like( check_error('Clay_ClipElementConfig', { vertical => {} }),
		qr/^Clay_ClipElementConfig\.vertical: expected a plain boolean value, got a HASH reference/, 'reference rejected' );
	ok( lives { check_struct('Clay_ClipElementConfig', { vertical => 'yes', horizontal => 0 }) }, 'plain values accepted' );
};

subtest 'parse mode stays lenient' => sub {
	my $ctx = Clay_Initialize(Clay_MinMemorySize(), { width => 100, height => 100 });
	Clay_BeginLayout();
	Clay__OpenElement();
	ok( lives { Clay__ConfigureOpenElement({ layout => { childGapp => 1 }, backgroundColor => [ 1, 2, 3 ] }) },
		'unknown keys and short arrays are ignored by Clay__ConfigureOpenElement' );
	Clay__CloseElement();
	Clay_EndLayout(0);
};

subtest 'the error object' => sub {
	my $error = check_error('Clay_Padding', { left => -5 }, 'padding');
	isa_ok( $error, 'Clay::XS::StructError' );
	is( $error->path, [ 'padding', 'left' ], 'path starts at the root' );
	is( $error->expected, 'an integer in 0..65535', 'expected' );
	is( $error->got, "'-5'", 'got' );
	ok( $error ? 1 : 0, 'true in boolean context' );
	is( $error->message, "padding.left: expected an integer in 0..65535, got '-5'", 'message without location' );
	my $line  = __LINE__; my $located = dies { check_struct('Clay_Padding', 8) };
	is( [ $located->file, $located->line ], [ __FILE__, $line ], 'file and line of the caller' );
	like( "$located", qr/ at \Q${\__FILE__}\E line $line\.\n\z/, 'stringifies with the location' );
	is( check_error('Clay_Padding', { left => -5 })->path, [ 'Clay_Padding', 'left' ], 'default root is the type name' );
};

subtest 'Clay::XS::Structs documents every schema field' => sub {
	my $file = $INC{'Clay/XS.pm'} =~ s/\.pm\z/\/Structs.pod/r;
	open my $fh, '<', $file or die "cannot read $file: $!";
	my $pod = do { local $/; <$fh> };

	# Words of the =head and =item lines, e.g. "sizing.width" gives
	# sizing and width.
	my %headed;
	for my $heading ($pod =~ /^=(?:head\d|item)\s+(.*)$/mg) {
		$headed{$_} = 1 for split /[^\w]+/, $heading =~ s/C<([^>]*)>/$1/gr;
	}

	# The struct table of the QUICK INDEX: a struct name, then its keys,
	# continued on lines indented to the key column.
	my ($index) = $pod =~ /^=head1 QUICK INDEX\n(.*?)^=head1/ms;
	my (%index_keys, $struct);
	for my $line (split /\n/, $index) {
		if ($line =~ /^    (Clay_[\w.]+)\s+(.*)/) {
			$struct = $1;
			$index_keys{$struct} = [ split ' ', $2 ];
		} elsif (defined $struct && $line =~ /^ {20,}(\S.*)/) {
			push @{ $index_keys{$struct} }, split ' ', $1;
		} else {
			undef $struct;
		}
	}

	for my $type (sort keys %$SCHEMAS) {
		my @fields = field_names($type);
		is( [ grep { !$headed{$_} } @fields ], [], "$type: every field has a heading or item" );
		is( $index_keys{$type}, \@fields, "$type: the QUICK INDEX lists its keys in schema order" );
	}
};

subtest 'the check_struct POD lists every named schema' => sub {
	open my $fh, '<', $INC{'Clay/XS.pm'} or die "cannot read Clay/XS.pm: $!";
	my $pod = do { local $/; <$fh> };
	my ($list) = $pod =~ /^=head2 check_struct\n.*?one of:\n\n(.*?)\n\n/ms;
	ok( defined $list, 'the list is found' );
	is( [ sort split ' ', $list // '' ], [ sort grep { !/\./ } keys %$SCHEMAS ],
		'it names exactly the schemas check_struct knows' );
};

subtest 'unknown type names' => sub {
	my $error = check_error('Clay_Nope', {});
	ok( !ref $error, 'plain string' );
	like( $error, qr/^check_struct: unknown struct type 'Clay_Nope'/, 'message' );
};

done_testing;
