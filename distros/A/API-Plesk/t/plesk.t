use strict;
use warnings;

use Carp;
use Test::More;
use Data::Dumper;

use lib qw(t lib);
use TestData;

BEGIN {
    plan tests => 8;
}

BEGIN {
    use_ok( 'API::Plesk' );
}

my $api = API::Plesk->new( %TestData::plesk_valid_params );

isa_ok( $api, 'API::Plesk', 'STATIC call new' );

my $yet_another_api = $api->new( %TestData::plesk_valid_params );

isa_ok( $api, 'API::Plesk', 'INSTANCE call new' );
isnt( $api, $yet_another_api, 'object compare' );

# render_xml

is($api->render_xml({
    webspace => {
        add => [
            { gen_setup => [
                { qq => sub { 'ddd' } },
                { name => 'sample.com' },
                { ddd => sub { {lll => 1234567} } },
            ]},
            { hosting => {
                name => '123',
                value => 'erty'
            }}
        ]
    }
}), '<?xml version="1.0" encoding="UTF-8"?><packet version="1.6.3.0"><webspace><add><gen_setup><qq>ddd</qq><name>sample.com</name><ddd><lll>1234567</lll></ddd></gen_setup><hosting><value>erty</value><name>123</name></hosting></add></webspace></packet>', 'render_xml');

is ( $api->render_xml({ prop => [
    {value1 => '0'},
    {value2 => ''},
    {value3 => undef},
]}), '<?xml version="1.0" encoding="UTF-8"?><packet version="1.6.3.0"><prop><value1>0</value1><value2/><value3/></prop></packet>', 'render_xml');
# compoments

$api = API::Plesk->new(
    api_version   => '1.6.3.1',
    username      => 'admin',
    password      => 'qwerty',
    url           => 'https://12.34.56.78',
);
my %pkgs = (
    customer => 'API::Plesk::Customer',
    webspace => 'API::Plesk::Webspace',
);
for my $accessor ( keys %pkgs ) {
    isa_ok($api->$accessor(), $pkgs{$accessor}, "$accessor component");
}
