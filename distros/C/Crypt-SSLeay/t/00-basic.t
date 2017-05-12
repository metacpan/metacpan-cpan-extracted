# 00-basic.t

use Test::More;

BEGIN {
    use_ok( 'Crypt::SSLeay' );
    use_ok( 'Crypt::SSLeay::CTX' );
    use_ok( 'Crypt::SSLeay::Conn' );
    use_ok( 'Crypt::SSLeay::Err' );
    use_ok( 'Crypt::SSLeay::MainContext', 'main_ctx' );
    use_ok( 'Crypt::SSLeay::X509' );
    use_ok(
        'Crypt::SSLeay::Version',
        qw(
            openssl_built_on
            openssl_cflags
            openssl_dir
            openssl_platform
            openssl_version
            openssl_version_number
        ),
    );
    use_ok( 'Net::SSL' );
}

SKIP: {
    skip( 'Test::Pod not installed on this system', 2 )
        unless do {
            eval "use Test::Pod";
            $@ ? 0 : 1;
        };

    pod_file_ok( 'SSLeay.pm' );
    pod_file_ok( 'lib/Net/SSL.pm' );
}

SKIP: {
    my @modules = qw(Crypt::SSLeay Crypt::SSLeay::Version Net::SSL);

    eval "use Test::Pod::Coverage; 1" or skip(
        'Test::Pod::Coverage not installed on this system',
        scalar @modules
    );

    pod_coverage_ok($_, "$_ POD coverage") for @modules;
}

{
    my $ctx = main_ctx();
    isa_ok($ctx, 'Crypt::SSLeay::CTX', 'main context');
}

done_testing();
