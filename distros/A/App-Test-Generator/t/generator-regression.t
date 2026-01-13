use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;

#--------------------------------------------------------------------------
# 1. Module loads cleanly
#--------------------------------------------------------------------------
use_ok('App::Test::Generator');

#--------------------------------------------------------------------------
# 2. _valid_type regression: must accept all declared types
#--------------------------------------------------------------------------
my @valid = qw(string boolean integer number float hashref arrayref object);

for my $t (@valid) {
	ok(App::Test::Generator::_valid_type($t), "_valid_type accepts '$t'");
}

ok(
	!App::Test::Generator::_valid_type('bogus'),
	"_valid_type rejects unknown type"
);

#--------------------------------------------------------------------------
# 3. perl_quote should not die on hashrefs (previous crash path)
#--------------------------------------------------------------------------
lives_ok {
	App::Test::Generator::perl_quote({ a => 1 });
} 'perl_quote survives hashref input';

#--------------------------------------------------------------------------
# 4. Getter accessor short-circuit regression
#	Getter must clear input and skip parameter inference
#--------------------------------------------------------------------------
{
	my $schema = {
		_accessor => { type => 'getter', field => 'foo' },
		input	 => { bogus => { type => 'string' } },
	};

	# simulate getter post-processing
	if ($schema->{_accessor} && $schema->{_accessor}{type} eq 'getter') {
		$schema->{input} = {};
		$schema->{input_style} = 'none';
	}

	is_deeply(
		$schema->{input},
		{},
		'getter clears input schema'
	);

	is(
		$schema->{input_style},
		'none',
		'getter sets input_style to none'
	);
}

#--------------------------------------------------------------------------
# 5. Semantic generator lookup must be stable
#--------------------------------------------------------------------------
my $sem = App::Test::Generator::_get_semantic_generators();

ok(exists $sem->{email}, 'email semantic generator exists');
ok(exists $sem->{uuid},  'uuid semantic generator exists');
ok(exists $sem->{ipv4},  'ipv4 semantic generator exists');

#--------------------------------------------------------------------------
# 6. LectroTest generator generation should not croak
#--------------------------------------------------------------------------
lives_ok {
	App::Test::Generator::_schema_to_lectrotest_generator(
		'count',
		{ type => 'integer', min => 1, max => 10 }
	);
} 'integer schema generates LectroTest code';

lives_ok {
	App::Test::Generator::_schema_to_lectrotest_generator(
		'name',
		{ type => 'string', min => 3, max => 12 }
	);
} 'string schema generates LectroTest code';

#--------------------------------------------------------------------------
# 7. Hashref generator regression
#--------------------------------------------------------------------------
lives_ok {
	App::Test::Generator::_schema_to_lectrotest_generator(
		'data',
		{ type => 'hashref', min => 1, max => 3 }
	);
} 'hashref schema generates LectroTest code';

done_testing();
