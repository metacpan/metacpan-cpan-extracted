use Test::More;

note 'MyConfig';

{
	package MyConfig;

	use Config::ENV 'FOO_ENV';

	common +{
		test => 'test',
	};
};

{
	package MyConfig_import1;

	BEGIN { MyConfig->import };
};

is_deeply [ @MyConfig_import1::ISA ], [], 'Does not allow inheritance';

{
	package MyConfig_import2;

	# invalid
	BEGIN { MyConfig_import2->import('XXX') };
};

is_deeply [ @Bar::ISA ], [], 'Does not allow inheritance';

note 'MyConfig2';

{
	package MyConfig2;

	use Config::ENV 'FOO_ENV', export => 'config';

	common +{
		test => 'test',
	};
};

{
	package MyConfig2_import;
	use Test::More;
	BEGIN { MyConfig2->import }

	is config(), 'MyConfig2';
	is config->param('test'), 'test';
};

note 'MyConfig3';

{
	package MyConfig3;

	use Config::ENV 'FOO_ENV';

	common +{
		test => 'test',
	};
};

{
	package MyConfig3_import;
	use Test::More;
	BEGIN { MyConfig3->import(export => 'config') }

	is config(), 'MyConfig3';
	is config->param('test'), 'test';
};

done_testing;
