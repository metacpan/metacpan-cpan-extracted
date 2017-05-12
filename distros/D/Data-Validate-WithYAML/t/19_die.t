#!perl 

use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new(
    $FindBin::Bin . '/test_die.yml',
);

throws_ok { $validator->check( 'test_sub', 3 ) }
    qr/\ACan't use user defined sub unless it is allowed/, 'No subs allowed';

throws_ok { $validator->check( 'test_data', 3 ) }
    qr/\AUnknown datatype negative_datatype/, 'negative_datatype';

throws_ok { $validator->check( 'test_plugin', 3 ) }
    qr/\ACan't check with Data::Validate::WithYAML::Plugin::TESTNONEXISTANTPLUGIN/, 'plugin';

done_testing();
