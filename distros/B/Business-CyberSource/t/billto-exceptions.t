use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Module::Runtime 'use_module';

my $billto_c = use_module('Business::CyberSource::RequestPart::BillTo');

my $exception0
	= exception { $billto_c->new({
		first_name     => 'Caleb',
		last_name      => 'Cushing',
		street         => 'somewhere',
		city           => 'Houston',
		state          => 'TX',
		zip            => '77064',
		country        => 'blerg',
		email          => 'xenoterracide@gmail.com',
	})
};

like $exception0, qr/Attribute \(country\)/, 'country invalid';

my $exception1
	= exception { $billto_c->new({
		first_name     => 'Caleb',
		last_name      => 'Cushing',
		street         => 'somewhere',
		city           => 'Houston',
		state          => 'TX',
		country        => 'US',
		email          => 'xenoterracide@gmail.com',
	});
};
isa_ok $exception1, 'Moose::Exception::AttributeIsRequired';
like $exception1, qr/postal_code/, 'us/ca require a postal_code';
like $exception1, qr/US or Canada/, 'us/ca require a postal_code';

my $exception2
	= exception { $billto_c->new({
		first_name     => 'Caleb',
		last_name      => 'Cushing',
		street         => 'somewhere',
		city           => 'Houston',
		country        => 'US',
		postal_code    => '77064',
		email          => 'xenoterracide@gmail.com',
	});
};

isa_ok $exception2, 'Moose::Exception::AttributeIsRequired';
like $exception2, qr/state/, 'us/ca require a state';
like $exception2, qr/US or Canada/, 'us/ca require a state';

done_testing;
