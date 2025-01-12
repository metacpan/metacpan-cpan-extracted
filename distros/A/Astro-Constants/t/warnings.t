use Test2::V0;

use Astro::Constants qw( HUBBLE_TIME );
#use Astro::Constants qw( :deprecated );

#imported_ok('HUBBLE_TIME');
#not_imported_ok('HUBBLE_TIME2');

ok warns { HUBBLE_TIME }, 'Deprecated constant emits a warning';
like(
    warning { HUBBLE_TIME },
    qr/^HUBBLE_TIME deprecated at/,
    'Got expected warning'
);

done_testing();
