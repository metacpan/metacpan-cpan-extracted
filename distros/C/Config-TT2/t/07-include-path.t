#!perl -T

use Test::More;
use Try::Tiny;

use_ok('Config::TT2');

my $params = {
    INCLUDE_PATH => './t/cfg/',
    ABSOLUTE     => 0,
    RELATIVE     => 0,
};

my ( $ctt2, $error );
{
    undef $error;
    try {
        $ctt2 = Config::TT2->new($params);
    }
    catch { $error = $_ };
    is( $error, undef, "set INCLUDE_PATH, unset ABSOLUTE and RELATIVE" );
}

{
    undef $error;
    try {
        $ctt2 = Config::TT2->new($params);
        $ctt2->process('/tmp/absolute');
    }
    catch { $error = $_ };
    like( $error, qr/absolute .* not allowed/i, "absolute paths are not allowed" );
}

{
    undef $error;
    try {
        $ctt2 = Config::TT2->new($params);
        $ctt2->process('./relative');
    }
    catch { $error = $_ };
    like( $error, qr/relative .* not allowed/i, "relative paths are not allowed" );
}

{
    undef $error;
    my $cfg;
    try {
        $ctt2 = Config::TT2->new($params);
        $cfg = $ctt2->process('one');
    }
    catch { $error = $_ };
    is( $error, undef, "PROCESS cfg file via INCLUDE_PATH" );
    is($cfg->{filename}, 'one', 'got filename via template or component');
}

{
    undef $error;
    my $cfg;
    try {
        $ctt2 = Config::TT2->new($params);
        $cfg = $ctt2->process('two');
    }
    catch { $error = $_ };
    is( $error, undef, "INCLUDE cfg file via INCLUDE_PATH" );
    is($cfg->{filename}, undef, 'local stash, variable not set');
}

{
    undef $error;
    my ($cfg, $output);
    try {
        $ctt2 = Config::TT2->new($params);
        ($cfg, $output) = $ctt2->process('three');
    }
    catch { $error = $_ };
    is( $error, undef, "INSERT cfg file via INCLUDE_PATH" );
    is($cfg->{filename}, undef, 'insert, no variables set');
}

done_testing(10);

