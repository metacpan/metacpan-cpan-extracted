#!perl

use strict;
use warnings;
use Test::More;

use Crypt::PBE::CLI;

sub cmd {

    my (@arguments) = @_;

    my $output;

    open( my $output_handle, '>', \$output ) or die "Can't open handle file: $!";
    my $original_handle = select $output_handle;

    Crypt::PBE::CLI->run( \@arguments );
    chomp $output;

    select $original_handle;

    return $output;
}

my $input     = 'secret';
my $password  = 'mypassword';
my $algorithm = 'PBEWithHmacSHA1AndAES_128';

my $encrypted = cmd( '--algorithm', $algorithm, '--password', $password, '--input', $input,     '--encrypt' );
my $decrypted = cmd( '--algorithm', $algorithm, '--password', $password, '--input', $encrypted, '--decrypt' );

ok( $encrypted, 'Encrypt' );
ok( $decrypted, 'Decrypt' );

is( $decrypted, $input, 'Test input' );

# ------------------------------------------------------------------------------

$ENV{PASSWORD} = $password;
$ENV{INPUT}    = $input;

my $env_enc_1 = cmd( '--algorithm', $algorithm, '--password', 'env:PASSWORD', '--input', $input,     '--encrypt' );
my $env_dec_1 = cmd( '--algorithm', $algorithm, '--password', 'env:PASSWORD', '--input', $env_enc_1, '--decrypt' );

my $env_enc_2 = cmd( '--algorithm', $algorithm, '--password', 'env:PASSWORD', '--input', 'env:INPUT', '--encrypt' );
my $env_dec_2 = cmd( '--algorithm', $algorithm, '--password', 'env:PASSWORD', '--input', $env_enc_2,  '--decrypt' );

my $env_enc_3 = cmd( '--algorithm', $algorithm, '--password', $password, '--input', 'env:INPUT', '--encrypt' );
my $env_dec_3 = cmd( '--algorithm', $algorithm, '--password', $password, '--input', $env_enc_3,  '--decrypt' );

my $env_enc_4 = cmd( '--algorithm', $algorithm, '--password', $password, '--input', 'env:INPUT', '--hex', '--encrypt' );
my $env_dec_4 = cmd( '--algorithm', $algorithm, '--password', $password, '--input', $env_enc_4,  '--hex', '--decrypt' );

ok( $env_enc_1, 'Encrypt (env password)' );
ok( $env_dec_1, 'Decrypt (env password)' );

ok( $env_enc_2, 'Encrypt (env password + input)' );
ok( $env_dec_2, 'Decrypt (env password + input)' );

ok( $env_enc_3, 'Encrypt (env input)' );
ok( $env_dec_3, 'Decrypt (env input)' );

ok( $env_enc_4, 'Encrypt (env input) in HEX' );
ok( $env_dec_4, 'Decrypt (env input) in HEX' );

# ------------------------------------------------------------------------------

like( cmd('--list-algorithms'), '/PBEWithMD5AndDES/', 'List algorithms' );
like( cmd('--version'),         '/Crypt::PBE/',       'Show version' );

done_testing();
