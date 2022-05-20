use Test::More;

use Anonymous::Object;


ok(my $ok = Anonymous::Object->new(
	build_object_name => sub { 'Not::Kaput' },
	build_type_map => sub {
		my ($self, $params) = @_;
		$params->{default} = 'Str';
		return $params;
	}
));

eval {
	my $not_ok = Anonymous::Object->new(
		build_type_map => sub {
			my ($self, $params) = @_;
			$params->{default} = 'Str';
			return undef;
		}
	);
};

like("$@", qr/type_map accessor is required/);

is($ok->object_name, 'Not::Kaput', 'Not::Kaput');

eval {
	$ok->object_name({ go => "kaput" });
};

like("$@", qr/Str: invalid value/);

eval {
	$ok->default("go kaput");
};

like("$@", qr/HashRef: invalid value/);

eval {
	$ok->types("go kaput");
};

like("$@", qr/HashRef: invalid value/);

eval {
	$ok->type_library({ go => "kaput" });
};

like("$@", qr/Str: invalid value/);

eval {
	$ok->types("go kaput");
};

like("$@", qr/HashRef: invalid value/);


eval {
	$ok->type_map("go kaput");
};

like("$@", qr/HashRef: invalid value/);

eval {
	$ok->hash_to_object(undef);
};

like("$@", qr/HashRef: invalid value undef/);

eval {
	$ok->hash_to_nested_object(undef);
};

like("$@", qr/HashRef: invalid value undef/);

eval {
	$ok->hash_to_nested_object('string');
};

like("$@", qr/HashRef: invalid value string/);

eval {
	$ok->array_to_nested_object(undef);
};

like("$@", qr/ArrayRef: invalid value undef/);



eval {
	$ok->array_to_nested_object('string');
};

like("$@", qr/ArrayRef: invalid value string/);


ok($ok->array_to_nested_object([
	[
		{
			one => 123,
			two => 345
		}
	]
]));

eval {
	$ok->add_new(undef)
};

like("$@", qr/HashRef: invalid value undef/);

eval {
	$ok->add_new('string')
};

like("$@", qr/HashRef: invalid value string/);

eval {
	$ok->add_methods(undef)
};

like("$@", qr/ArrayRef: invalid value undef/);

eval {
	$ok->add_methods('string')
};

like("$@", qr/ArrayRef: invalid value string/);

ok($ok->add_methods([{ name => 'string'}]));

eval {
	$ok->add_method(undef)
};

like("$@", qr/HashRef: invalid value undef/);

eval {
	$ok->add_method('string')
};

like("$@", qr/HashRef: invalid value string/);

eval {
	$ok->add_method({ name => undef })
};

like("$@", qr/Str: invalid value undef/);

eval {
	$ok->add_method({ name => [] })
};

like("$@", qr/Str: invalid value/);

ok($ok->add_method({ name => 123, code => qq|return \$_[0]->{123}| }));

eval { $ok->build() };

like("$@", qr/Illegal declaration of anonymous subroutine/);

is($ok->stringify_struct(), 'undefined');

eval {
	$ok->add_type(undef);
};

like("$@", qr/Str: invalid value/);

eval {
	$ok->add_type({});
};

like("$@", qr/Str: invalid value/);

is($ok->identify_type(undef), 'Str');

is($ok->identify_type('test'), 'Str');

is($ok->identify_type(0.11), 'Num');

is($ok->identify_type(' '), 'Str');

done_testing;
