use ExtUtils::MakeMaker;
use Config;

if ($Config{ivsize} < 8) {
    warn "OS unsupported: ClickHouse::Encoder requires a 64-bit Perl ",
         "(\$Config{ivsize}=$Config{ivsize}, need >= 8). ",
         "The XS code uses 64-bit integer arithmetic for varint, ",
         "Decimal64, DateTime64, etc., and will fail to compile on a ",
         "32-bit perl with #error.\n";
    exit 0;
}

WriteMakefile(
    NAME         => 'ClickHouse::Encoder',
    VERSION_FROM => 'lib/ClickHouse/Encoder.pm',
    ABSTRACT     => 'Encode data to ClickHouse native format',
    AUTHOR       => 'vividsnow',
    LICENSE      => 'perl_5',
    PREREQ_PM    => {
        XSLoader => 0,
        # All four below are core in any supported Perl; listed for
        # honesty about what the lazy-require sites pull in.
        'HTTP::Tiny'   => 0,  # for_table(via=>'http'), insert_http, etc.
        'Time::HiRes'  => 0,  # bulk_inserter retry backoff
        'Math::BigInt' => 0,  # decimal128_str / decimal256_str
    },
    TEST_REQUIRES => {
        'Test::More'      => 0,
        'File::Temp'      => 0,
        'IO::Socket::INET' => 0,
        'Digest::SHA'     => 0,   # t/stress.t, t/concurrency.t,
                                  # t/concurrency-json.t, t/cross-version.t
    },
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-clickhouse-encoder.git',
                web  => 'https://github.com/vividsnow/perl5-clickhouse-encoder',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-clickhouse-encoder/issues',
            },
        },
        prereqs => {
            runtime => {
                recommends => {
                    # Needed by compress_native_block(mode=>'lz4'|'auto')
                    # and decompress_native_block on LZ4-framed blocks -
                    # the default mode for select_blocks(decompress=>1),
                    # bulk_inserter(compress=>'lz4'), and TCP pack_data
                    # with negotiated compression.
                    'Compress::LZ4'      => 0,
                    # compress_native_block(mode=>'zstd'),
                    # compressed_writer('zstd', ...), and
                    # bulk_inserter(compress=>'zstd').
                    'Compress::Zstd'     => 0,
                    # compressed_writer('gzip', ...) /
                    # bulk_inserter(compress=>'gzip'). Core since 5.10
                    # but listed for explicitness.
                    'IO::Compress::Gzip' => 0,
                },
            },
        },
    },
    OBJECT       => 'Encoder$(OBJ_EXT) '
                  . 'buffer$(OBJ_EXT) '
                  . 'decimal$(OBJ_EXT) '
                  . 'scalar_kind$(OBJ_EXT) '
                  . 'datetime$(OBJ_EXT) '
                  . 'types$(OBJ_EXT) '
                  . 'json_kind$(OBJ_EXT) '
                  . 'encode$(OBJ_EXT) '
                  . 'decode$(OBJ_EXT) '
                  . 'runtime$(OBJ_EXT) '
                  . 'cityhash$(OBJ_EXT)',
    DEFINE       => '',
    INC          => '',
);
