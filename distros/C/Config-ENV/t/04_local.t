{
	package MyConfig;
	use strict;

	use Config::ENV 'FOO_ENV';

	common +{
		name => 'foobar',
	};

	config development => +{
		dsn_user => 'dbi:mysql:dbname=user;host=localhost',
	};

	config test => +{
		dsn_user => 'dbi:mysql:dbname=user;host=localhost',
	};

	config production => +{
		dsn_user => 'dbi:mysql:dbname=user;host=127.0.0.254',
	};

	config production_bot => +{
		parent('production'),
		bot => 1,
	};
};

BEGIN { MyConfig->import };
sub config { 'MyConfig' }

use Test::More;
use Test::Fatal;
use Test::Name::FromLine;

{
	my $guard = config->local(name => 'localized');
	is config->param('name'), 'localized', 'unmerged...';
};

is config->param('name'), 'foobar';

{
	my $guard = config->local(name => 'localized');
	is config->param('name'), 'localized', 'merged';

	my $guard2 = config->local(name => 'localized2');
	is config->param('name'), 'localized2';

	undef $guard2;

	is config->param('name'), 'localized';

	{
		my $guard3 = config->local(name => 'localized3');
		is config->param('name'), 'localized3';
	};

	is config->param('name'), 'localized';
};

like exception { config->local(name => 'localized'); undef }, qr/local returns guard object; Can't use in void context/;

done_testing;
