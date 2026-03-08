use Test2::V0;

use Text::ZTemplate;

subtest 'simple substitution with default html escaping' => sub {
	my $tmpl = Text::ZTemplate->new(
		string => 'Name: {{ product/name }}',
		escape => 'html',
	);

	my $out = $tmpl->process({
		product => { name => 'A & B' },
	});

	is( $out, 'Name: A &amp; B', 'html escaped output' );
};

subtest 'block loops over node sets' => sub {
	my $tmpl = Text::ZTemplate->new(
		string => "{{# /items/* }}<p>{{ name }}</p>{{/ /items/* }}",
		escape => 'raw',
	);

	my $out = $tmpl->process({
		items => [
			{ name => 'One' },
			{ name => 'Two' },
		],
	});

	is( $out, '<p>One</p><p>Two</p>', 'renders each selected node' );
};

subtest 'block can be used as a test without changing context' => sub {
	my $tmpl = Text::ZTemplate->new(
		string => '{{# count(result/*) == 1 }}{{ count(result/*) }} result{{/ count(result/*) == 1 }}',
		escape => 'raw',
	);

	my $one = $tmpl->process({ result => [ { }, ] });
	is( $one, '1 result', 'truthy non-node expression renders once' );

	my $two = $tmpl->process({ result => [ { }, { } ] });
	is( $two, q{}, 'false expression does not render' );
};

subtest 'per-tag escape override with :: html and :: raw' => sub {
	my $tmpl = Text::ZTemplate->new(
		string => '{{ product/name :: raw }}|{{ product/name :: html }}',
		escape => 'raw',
	);

	my $out = $tmpl->process({
		product => { name => 'A & B' },
	});

	is( $out, 'A & B|A &amp; B', 'override works for both modes' );
};

subtest 'expressions are compiled once and reused across process calls' => sub {
	my $tmpl = Text::ZTemplate->new(
		string => '{{ product/name }}',
		escape => 'raw',
	);

	is( $tmpl->process({ product => { name => 'Alpha' } }), 'Alpha', 'first process' );
	is( $tmpl->process({ product => { name => 'Beta' } }), 'Beta', 'second process reuses compiled expression' );
};

subtest 'template can be loaded from file' => sub {
	my $tmpl = Text::ZTemplate->new(
		file => 't/integration/ztemplate/sample.tmpl',
		escape => 'raw',
	);

	is( $tmpl->process({ product => { price => '9.99' } }), "Price: 9.99\n", 'reads template from file' );
};


subtest 'template include paths are relative to including file' => sub {
	my $tmpl = Text::ZTemplate->new(
		file => 't/integration/ztemplate/include-main.tmpl',
		escape => 'raw',
	);

	my $out = $tmpl->process({
		product => {
			name => 'Widget',
			price => '9.99',
		},
	});

	is(
		$out,
		"Header
Child: Widget
Grandchild: 9.99


Footer
",
		'include and nested include render from local directories',
	);
};


subtest 'shorthand close tag {{/}} closes last open block' => sub {
	my $tmpl = Text::ZTemplate->new(
		string => '{{# product }}{{# features/* }}[{{ . }}]{{/}}{{/}}',
		escape => 'raw',
	);

	my $out = $tmpl->process({
		product => {
			features => [ 'A', 'B' ],
		},
	});

	is( $out, '[A][B]', 'each shorthand close matches the nearest open block' );
};

subtest 'includes => 0 disables include tags' => sub {
	like(
		dies {
			Text::ZTemplate->new(
				string => '{{> part.tmpl }}',
				escape => 'raw',
				includes => 0,
			);
		},
		qr/Template includes are disabled/,
		'include tag fails when includes are disabled',
	);
};

subtest 'includes => 0 does not affect regular expressions or blocks' => sub {
	my $tmpl = Text::ZTemplate->new(
		string => '{{# product }}{{ name }}{{/}}',
		escape => 'raw',
		includes => 0,
	);

	is( $tmpl->process({ product => { name => 'Widget' } }), 'Widget',
		'normal rendering still works when includes are disabled' );
};

subtest 'circular includes are rejected' => sub {
	like(
		dies {
			Text::ZTemplate->new(
				file => 't/integration/ztemplate/cycle-a.tmpl',
				escape => 'raw',
			);
		},
		qr/Circular include detected/,
		'circular include reports a clear error',
	);
};

done_testing;
