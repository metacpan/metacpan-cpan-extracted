#!perl

use 5.006_000;
BEGIN {
    push @INC, 'inc';
}
use My::Builder;

my $build = My::Builder->new(
    module_name => 'Data::Dump::Streamer',
    dist_author => 'Yves Orton <yves@cpan.org>, Joshua ben Jore <jjore@cpan.org>',
    license => 'perl',
    configure_requires => {
        'perl' => '5.006',

        # Core 5.009_004+
        'Module::Build'     => 0,

        # CPAN
        'ExtUtils::Depends' => 0,
    },
    build_requires => {
        # Core modules
        'B::Deparse'         => 0,
        'Carp'               => 0,
        'Config'             => 0,
        'Data::Dumper'       => 0,
        'Devel::Peek'        => 0,
        'ExtUtils::CBuilder' => 0,
        'Symbol'             => 0,
        'Test::More'         => 0,
        'Text::Abbrev'       => 0,
        'base'               => 0,
        'overload'           => 0,
        'strict'             => 0,
        'utf8'               => 0,
        'vars'               => 0,
        'warnings'           => 0,
        $] >= 5.012
            ? ( 're' => 0 )
            : (),
    },
    requires => {
        'B'              => 0,
        'B::Deparse'     => 0,
        'B::Utils'       => 0,
        'Data::Dumper'   => 0,
        'DynaLoader'     => 0,
        'Exporter'       => 0,
        'IO::File'       => 0,
        'Symbol'         => 0,
        'Text::Abbrev'   => 0,
        'Text::Balanced' => 0,
        'overload'       => 0,
        'strict'         => 0,
        'vars'           => 0,
        'warnings'       => 0,
        'warnings::register' => 0,
        $] >= 5.009_004
            ? ( 're' => 0 )
            : (),
        $] >= 5.008
            ? ( 'Hash::Util' => 0 )
            : (),

        # CPAN
        'B::Utils' => 0,
    },
    recommends => {
        # Core 5.007_003+
        'MIME::Base64' => 0,

        # Core 5.009_003+
        'Compress::Zlib' => 0,

        # CPAN
        'Algorithm::Diff' => 0,
        'PadWalker'       => '0.99',

        # optional for testing
        'JSON::XS'           => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/demerphq/Data-Dump-Streamer'
        }
    },
);
$build->create_build_script();
