# for the most part it is copy-paste from billto-exceptions.t
# but not totally, as some tests are specific to shipping

use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception dies_ok);

use Module::Runtime 'use_module';

my $shipto_c = use_module('Business::CyberSource::RequestPart::ShipTo');

dies_ok {
    $shipto_c->new(
        {
            first_name  => 'Caleb',
            last_name   => 'Cushing',
            street1     => 'somewhere',
            city        => 'Houston',
            state       => 'TX',
            postal_code => '77064',
        }
    );
}
'no country in request';

my $exception0 = exception {
    $shipto_c->new(
        {
            first_name  => 'Caleb',
            last_name   => 'Cushing',
            street1     => 'somewhere',
            city        => 'Houston',
            state       => 'TX',
            postal_code => '77064',
            country     => 'blerg',
        }
      )
};
like $exception0, qr/Attribute \(country\)/, 'country invalid';

my $exception1 = exception {
    $shipto_c->new(
        {
            first_name => 'Caleb',
            last_name  => 'Cushing',
            street1    => 'somewhere',
            city       => 'Houston',
            state      => 'TX',
            country    => 'US',
        }
    );
};
isa_ok $exception1, 'Moose::Exception::AttributeIsRequired';
like $exception1,   qr/postal_code/, 'us/ca require a postal_code';
like $exception1,   qr/US or Canada/, 'us/ca require a postal_code';

my $exception2 = exception {
    $shipto_c->new(
        {
            first_name  => 'Caleb',
            last_name   => 'Cushing',
            street1     => 'somewhere',
            city        => 'Houston',
            country     => 'US',
            postal_code => '77064',
        }
    );
};

isa_ok $exception2, 'Moose::Exception::AttributeIsRequired';
like $exception2,   qr/state/, 'us/ca require a state';
like $exception2,   qr/US or Canada/, 'us/ca require a state';

my $exception3 = exception {
    $shipto_c->new(
        {
            first_name  => 'Caleb',
            last_name   => 'Cushing',
            street1     => 'somewhere',
            state       => 'TX',
            country     => 'US',
            postal_code => '77064',
        }
    );
};

isa_ok $exception3, 'Moose::Exception::AttributeIsRequired';
like $exception3,   qr/city/, 'us/ca require a city';
like $exception3,   qr/US or Canada/, 'us/ca require a city';

my $exception4 = exception {
    $shipto_c->new(
        {
            first_name      => 'Caleb',
            last_name       => 'Cushing',
            street1         => 'somewhere',
            city            => 'Houston',
            state           => 'TX',
            country         => 'US',
            postal_code     => '77064',
            shipping_method => 'UnknownMethod',
        }
    );
};

like $exception4, qr/Attribute \(shipping_method\) does not pass the type constraint/, 'unknown shipping method';

done_testing;
