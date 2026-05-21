#!perl
#
# Test every online App::cpan2arch component and their combination to ensure correct
# behavior. App::cpan2arch must run as documented in its POD (and its wrapper POD).
#
# NOTE:
#   Requires internet access since it relies on the MetaCPAN and Arch Linux
#   (Official repositories web interface + Aurweb RPC interface) APIs and will
#   likely break and need fixing whenever packages change.

use v5.42.0;

use strict;
use warnings;

use Test2::V1 -utf8, qw<
    T
    fail
    is
    note
    number
    number_gt
    pass
    skip_all
    subtest
    todo
>;

skip_all('Set RELEASE_TESTING=1 to run online tests')
  unless $ENV{RELEASE_TESTING};

use lib 't/lib';
use TestData qw< expected_data test_diff >;

use App::cpan2arch;
use Capture::Tiny 0.50 qw< capture capture_stderr >;
use Path::Tiny 0.150;

my $has_cache_mods = do {
    try {
        require Mojo::UserAgent::Cached;
        Mojo::UserAgent::Cached->VERSION('1.25');

        require CHI;
        CHI->VERSION('0.61');
    }
    catch ($e) {
        undef;
    }
};

my $expected = expected_data();

# Defaults
my %DEFS = (
    class => 'App::cpan2arch',
    ver   => $App::cpan2arch::VERSION,
);

# Unit test methods not covered in offline tests:
#   get_metadata()
#   merge_prereqs()
#   check_packages()
#
# NOTE:
#   Some errors can only be reproduced realistically when there are internet
#   connection issues or when MetaCPAN/Arch APIs have issues.
#
#   Mocks are out of scope for this test, which only covers the real APIs.
subtest 'Unit test' => sub {
    #skip_all;

    # Tests need to set a proper C2A environment + temporary cache.
    my sub get_env_cache ( $t, $path )
    {
        my $temp       = Path::Tiny->tempdir;
        my $cache_path = $temp->child($path)->stringify;

        my $cache_key =
            $path eq 'mcpan_cache' ? 'cache_mcpan_path'
          : $path eq 'arch_cache'  ? 'cache_arch_path'
          :                          ();

        my %env = (
            user_agent       => "$DEFS{class}/$DEFS{ver}",
            $cache_key       => $cache_path,
            cache_expiration => '1d',
            cache_ignore     => $t =~ /\Ano_cache/ ? true : false,
            #debug            => true,
        );

        return ( \%env, $cache_path );
    }

    subtest 'Metadata' => sub {
        #skip_all;

        subtest 'Get metadata' => sub {
            #skip_all;

            my $MOD       = 'File::KDBX';
            my $DIST      = 'File-KDBX';
            my $VER       = $expected->{$DIST}{version};
            my $BOGUS_END = 'https://bogus/';

            my %TESTS_META = (
                'normal_mod'    => $MOD,
                'normal_dist'   => $DIST,
                'no_cache_mod'  => $MOD,
                'no_cache_dist' => $DIST,
                'bogus_mod'     => 'Bogus::Module',
                'bogus_dist'    => 'Bogus-Dist',
                'bogus_mod_end' => $MOD,
                'bogus_rel_end' => $DIST,
            );

            foreach my ( $t, $name ) (%TESTS_META) {
                next if $t =~ /\Ano_cache/ && !$has_cache_mods;

                subtest "$t ($name)" => sub {
                    my $c2a = App::cpan2arch->new;
                    my $cache_path;

                    if ($has_cache_mods) {
                        ( my $env, $cache_path ) = get_env_cache( $t, 'mcpan_cache' );
                        $c2a->set_env( $env->%* );
                    }

                    my @argv = $name;
                    push @argv, $VER if $t eq 'normal_dist' || $t eq 'no_cache_dist';
                    $c2a->_process_opts( \@argv );

                    # Error
                    if ( $t =~ /\Abogus_/ ) {
                        if ( $t eq 'bogus_mod_end' ) {
                            $c2a->set_mod_endpoint($BOGUS_END);
                        }
                        elsif ( $t eq 'bogus_rel_end' ) {
                            $c2a->set_rel_endpoint($BOGUS_END);
                        }

                        my ( $stderr, @ret ) = capture_stderr {
                            return $c2a->get_metadata;
                        };

                        is(
                            $ret[0], number(1),
                            'return value (error)',
                        );

                        return;
                    }

                    my $ret       = $c2a->get_metadata;
                    my %optionals = $c2a->optionals;
                    my %meta      = $c2a->meta;

                    # Cache
                    if ($has_cache_mods) {
                        if ( $t =~ /\Ano_cache_/ ) {
                            is(
                                !-d $cache_path, T(),
                                'has no cache',
                            );
                        }
                        else {
                            my @caches = path($cache_path)->child('Default')->children;
                            #system( 'tree', '-a', $cache_path );

                            is(
                                scalar @caches, number_gt(0),
                                'has cache',
                            );

                            # Clear cache
                            $c2a->_process_opts( [ qw< --clear >, $DIST ] );
                            $c2a->_get_mua('mcpan');
                            my @cl_caches = path($cache_path)->children;
                            #system( 'tree', '-a', $cache_path );

                            is(
                                scalar @caches, number_gt( scalar @cl_caches ),
                                'has cleared cache',
                            );
                        }
                    }

                    # Module (normal_mod) only fetches the latest release, so it cannot
                    # be tested reliably like the versioned dist.
                    if ( $t eq 'normal_dist' || $t eq 'no_cache_dist' ) {
                        is(
                            %optionals, $expected->{$DIST}{optionals}->%*,
                            'optionals match',
                        );

                        is(
                            %meta, $expected->{$DIST}{meta}->%*,
                            'metadata match',
                        );
                    }

                    is(
                        $ret, number(0),
                        'return value (success)',
                    );
                };
            }
        };

        subtest 'Find files' => sub {
            #skip_all;

            my $DIST = 'Padre';
            my $URL  = 'https://cpan.metacpan.org/authors/id/S/SZ/SZABGAB/Padre-1.02.tar.gz';

            # Expected files
            my %FILES = (
                mi                 => true,
                license            => 'COPYING',
                has_multi_licenses => true,
                xs                 => true,
            );

            my %TESTS_FILES = (
                normal    => $URL,
                bogus_url => 'https://bogus',
                bogus_tar => 'https://ftp.gnu.org/gnu/tar/tar-1.24.tar.xz',
            );

            foreach my ( $t, $name ) (%TESTS_FILES) {
                subtest "$t ($name)" => sub {
                    my $TODO;

                    my $c2a = App::cpan2arch->new;
                    $c2a->_init_mua_mcpan;

                    if ( $t =~ /\Abogus_/ ) {
                        $TODO = todo 'This test fails when IO::Uncompress::UnXz is installed'
                          if $t eq 'bogus_tar';

                        my ( $stderr, @ret ) = capture_stderr {
                            return $c2a->_find_files( $DIST, $name );
                        };

                        is(
                            $ret[0], number(1),
                            'return value (error)',
                        );

                        return;
                    }

                    my $ret = $c2a->_find_files( $DIST, $name );

                    is(
                        $ret, \%FILES,
                        'files match',
                    );
                };
            }
        };
    };

    subtest 'Merge prereqs' => sub {
        #skip_all;

        my $DIST = 'Regexp-Debugger';

        my %TESTS_MERGE = (
            'normal'    => $DIST,
            'no_cache'  => $DIST,
            'bogus_url' => 'https://bogus',
        );

        foreach my ( $t, $name ) (%TESTS_MERGE) {
            next if $t eq 'no_cache' && !$has_cache_mods;

            subtest "$t ($name)" => sub {
                my $c2a = App::cpan2arch->new;
                my $cache_path;

                if ($has_cache_mods) {
                    ( my $env, $cache_path ) = get_env_cache( $t, 'mcpan_cache' );
                    $c2a->set_env( $env->%* );
                }

                $c2a->_init_mua_mcpan;
                $c2a->set_meta( $expected->{$DIST}{meta}->%* );

                if ( $t eq 'bogus_url' ) {
                    $c2a->set_dl_endpoint($name);

                    my ( $stderr, @ret ) = capture_stderr {
                        return $c2a->merge_prereqs;
                    };
                    my @fetch_errors = $c2a->fetch_errors;

                    is(
                        scalar @fetch_errors, number_gt(0),
                        'has error message',
                    );

                    is(
                        $ret[0], number(1),
                        'return value (error)',
                    );

                    return;
                }

                my $ret          = $c2a->merge_prereqs;
                my %cpan_prereqs = $c2a->cpan_prereqs;

                if ($has_cache_mods) {
                    if ( $t eq 'no_cache' ) {
                        is(
                            !-d $cache_path, T(),
                            'has no cache',
                        );
                    }
                    else {
                        my @caches = path($cache_path)->child('Default')->children;

                        is(
                            scalar @caches, number_gt(0),
                            'has cache',
                        );

                        # Clear cache
                        $c2a->_process_opts( [ qw< --clear-mcpan >, $DIST ] );
                        $c2a->_get_mua('mcpan');
                        my @cl_caches = path($cache_path)->children;

                        is(
                            scalar @caches, number_gt( scalar @cl_caches ),
                            'has cleared cache',
                        );
                    }
                }

                is(
                    %cpan_prereqs, $expected->{$DIST}{cpan_prereqs}->%*,
                    'prereqs match',
                );

                is(
                    $ret, number(0),
                    'return value (success)',
                );
            };
        }
    };

    subtest 'Check packages' => sub {
        #skip_all;

        my $DIST = 'Regexp-Debugger';

        subtest 'Get Arch prereqs' => sub {
            #skip_all;

            my %TESTS_PKGS = (
                'normal'   => $DIST,
                'no_cache' => $DIST,
            );

            foreach my ( $t, $name ) (%TESTS_PKGS) {
                next if $t eq 'no_cache' && !$has_cache_mods;

                subtest "$t ($name)" => sub {
                    my $c2a = App::cpan2arch->new;
                    my $cache_path;

                    if ($has_cache_mods) {
                        ( my $env, $cache_path ) = get_env_cache( $t, 'arch_cache' );
                        $c2a->set_env( $env->%* );
                    }

                    $c2a->set_cpan_prereqs( $expected->{$DIST}{cpan_prereqs}->%* );

                    my $ret          = $c2a->check_packages;
                    my %arch_prereqs = $c2a->arch_prereqs;

                    if ($has_cache_mods) {
                        if ( $t eq 'no_cache' ) {
                            is(
                                !-d $cache_path, T(),
                                'has no cache',
                            );
                        }
                        else {
                            my @caches = path($cache_path)->child('Default')->children;

                            is(
                                scalar @caches, number_gt(0),
                                'has cache',
                            );

                            # Clear cache
                            $c2a->_process_opts( [ qw< --clear-arch >, $DIST ] );
                            $c2a->_get_mua('arch');
                            my @cl_caches = path($cache_path)->children;

                            is(
                                scalar @caches, number_gt( scalar @cl_caches ),
                                'has cleared cache',
                            );
                        }
                    }

                    is(
                        %arch_prereqs, $expected->{$DIST}{arch_prereqs}->%*,
                        'prereqs match',
                    );

                    is(
                        $ret, number(0),
                        'return value (success)',
                    );
                };
            }
        };

        subtest 'Get JSON' => sub {
            #skip_all;

            my %env = (
                user_agent   => "$DEFS{class}/$DEFS{ver}",
                cache_ignore => true,
                #debug        => true,
            );

            my %TESTS_JSON = (
                normal           => 'https://archlinux.org/packages/core/x86_64/perl/json/',
                bogus_url        => 'https://bogus',
                bogus_error_code => 'https://httpbin.org/status/500',
                bogus_json       => 'https://httpbin.org/status/200',
            );

            foreach my ( $t, $name ) (%TESTS_JSON) {
                subtest "$t ($name)" => sub {
                    my $c2a = App::cpan2arch->new;
                    $c2a->set_env(%env);
                    $c2a->_init_mua_arch;

                    if ( $t =~ /\Abogus_/ ) {
                        my ( $stderr, @ret ) = capture_stderr {
                            return $c2a->_get_json($name);
                        };

                        is(
                            $ret[0], number(1),
                            'return value (error)',
                        );

                        return;
                    }

                    my $json = $c2a->_get_json($name);

                    is(
                        scalar keys $json->%*, number_gt(0),
                        'has JSON',
                    );
                };
            }
        };

        subtest 'Get Perl core modules list' => sub {
            #skip_all;

            my %TESTS_CORE = (
                'normal'      => 'v5.6.0',
                'newer'       => '999',
                'bogus_ver'   => 'v5.42.x',
                'bogus_newer' => '999',
            );

            foreach my ( $t, $name ) (%TESTS_CORE) {
                $name = 'undef' unless defined $name;

                subtest "$t ($name)" => sub {
                    my $c2a = App::cpan2arch->new;

                    if ( $t =~ /\Abogus_/ ) {
                        local $] = $name;

                        my ( $stderr, @ret ) = capture_stderr {
                            return $c2a->_get_corelist($name);
                        };

                        is(
                            $ret[0], number(1),
                            'return value (error)',
                        );

                        return;
                    }

                    my $corelist = $c2a->_get_corelist($name);

                    is(
                        scalar keys $corelist->%*, number_gt(0),
                        'has corelist',
                    );
                };
            }
        };

    };
};

# Test if App::cpan2arch methods work together correctly.
subtest 'Integration test' => sub {
    #skip_all;

    subtest 'PKGBUILD output (default)' => sub {
        my $TODO = todo 'This test fails whenever Arch packages change';

        foreach my ( $dist, $data ) ( $expected->%* ) {
            subtest $dist => sub {
                my $c2a = App::cpan2arch->new;

                my ( $stdout, $stderr, @ret ) = capture {
                    return $c2a->init( $dist, $data->{version} )->run;
                };

                test_diff( $stdout, $data->{pkgbuild}, 'STDOUT' );

                is(
                    $ret[0], number(0),
                    'return value (success)',
                );
            };
        }
    };
};

T2->done_testing;
