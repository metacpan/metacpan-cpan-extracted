use warnings;
use strict;
use Test::More tests => 9;
use Test::Exception;
use File::Spec;
use App::SpamcupNG qw(read_config);

dies_ok { read_config('foobar') } 'dies with no existing configuration file';
like $@, qr/Can't\sopen/, 'got the expected error message';
dies_ok { read_config( File::Spec->catfile( 't', 'after_login.html' ) ) }
'dies with non YAML file';
like $@, qr/Can't\sopen/, 'got the expected error message';
my $sample = File::Spec->catfile( ( 't', 'config' ), 'sample.yaml' );
dies_ok { read_config( $sample, 'foo' ) }
'dies with invalid configuration refence';
like $@, qr/hash\sreference/, 'got the expected error message';
my $config_ref   = {};
my $accounts_ref = read_config( $sample, $config_ref );
is( ref($accounts_ref), 'HASH', 'read_config returns a hash reference' );
my $expected_cfg_ref = {
    'V'          => 'INFO',
    'all'        => 1,
    'alt_code'   => 0,
    'alt_user'   => 0,
    'check_only' => 0,
    'database'   => {
        enabled => 1,
        path    => '/var/spamcupng/reports.db'
    },
    'stupid' => 1
};
is_deeply( $config_ref, $expected_cfg_ref,
    'command line options were updated as expected' );
my $expected_accounts_ref = {
    'Gmail' => {
        'e-mail'   => 'account@provider2.com.br',
        'password' => 'FOOBAR'
    },
    'Yahoo!' => {
        'e-mail'   => 'account@provider1.com.br',
        'password' => 'FOOBAR'
    }
};
is_deeply( $accounts_ref, $expected_accounts_ref,
    'the expected accounts configuration is returned' );

# vim: filetype=perl
