#!perl
#
# Test every offline App::cpan2arch component to ensure correct behavior.
# App::cpan2arch must run as documented in its POD (and its wrapper POD).
#
# NOTE:
#   The methods bellow are only tested in online tests (t/02-online.t), that also
#   cover the integration tests since they require internet.
#     get_metadata()
#     merge_prereqs()
#     check_packages()

use v5.42.0;

use strict;
use warnings;

use Test2::V1 -utf8, qw<
    fail
    is
    isa_ok
    note
    number
    pass
    skip_all
    subtest
    todo
>;

use lib 't/lib';
use TestData qw< expected_data test_diff >;

use App::cpan2arch;
use builtin qw< is_bool >;
use Capture::Tiny 0.50 qw< capture_stdout capture_stderr >;
use Path::Tiny 0.150;
use Devel::CheckBin 0.04;

no warnings qw< experimental::builtin >;

my $expected = expected_data();

# Defaults
my %DEFS = (
    class    => 'App::cpan2arch',
    ver      => $App::cpan2arch::VERSION,
    packager => 'Your Name <email@domain.tld>',
);

my %FAKE = (
    mod  => 'Foo::Bar',
    dist => 'Foo-Bar',
    ver  => 'v2.0.0',
);

# Unit test each method separately.
subtest 'Unit test' => sub {
    #skip_all;

    subtest 'Construct App::cpan2arch instance' => sub {
        #skip_all;

        my $c2a = App::cpan2arch->new;

        isa_ok(
            $c2a, [ $DEFS{class} ],
            'return value (instance)',
        );
    };

    subtest 'Environment processing' => sub {
        #skip_all;

        my $TODO = todo 'Test fails when parent shell exports the same vars';

        my $ddp = do {
            try {
                require Data::Printer;
            }
            catch ($e) {
                false;
            }
        };

        my %ENV_VARS = (
            packager => {
                var     => 'PACKAGER',
                default => $DEFS{packager},
                custom  => 'Alice <alice@domain.tld>',
            },
            user_agent => {
                var     => 'C2A_USER_AGENT',
                default => "$DEFS{class}/$DEFS{ver}",
                custom  => 'App::Foo/v1.0.0',
            },
            cache_mcpan_path => {
                var     => 'C2A_CACHE_MCPAN_PATH',
                default => '/tmp/mcpan_cache',
                custom  => '/tmp/foo_cache',
            },
            cache_arch_path => {
                var     => 'C2A_CACHE_ARCH_PATH',
                default => '/tmp/arch_cache',
                custom  => '/tmp/bar_cache',
            },
            cache_expiration => {
                var     => 'C2A_CACHE_EXPIRATION',
                default => '1d',
                custom  => '1h',
            },
            cache_ignore => {
                var     => 'C2A_CACHE_IGNORE',
                default => false,
                custom  => true,
            },
            debug => {
                var     => 'C2A_DEBUG',
                default => false,
                custom  => true,
            },
        );

        foreach my ($t) ( qw< default custom > ) {
            subtest $t => sub {
                my $c2a = App::cpan2arch->new;
                my %local_env;

                # Set custom vars locally to not pollute the environment.
                if ( $t eq 'custom' ) {
                    foreach my ( $k, $v ) (%ENV_VARS) {
                        my $var = $v->{var};
                        my $val = $v->{custom};

                        # Skip custom debug test if DDP is not installed.
                        next if $var eq 'C2A_DEBUG' && !$ddp;

                        $local_env{$var} = $val;
                    }
                }
                local %ENV = %local_env if $t eq 'custom';

                my ( $stderr, @ret ) = capture_stderr {
                    return $c2a->_process_env;
                };
                my %env = $c2a->env;

                foreach my ( $k, $v ) (%ENV_VARS) {
                    my $var  = $v->{var};
                    my $val  = $v->{$t};
                    my $name = $val;

                    # Skip custom debug test if DDP is not installed.
                    next if $t eq 'custom' && $var eq 'C2A_DEBUG' && !$ddp;

                    if ( is_bool($val) ) {
                        $name = $val ? 'true' : 'false';
                    }

                    is(
                        $env{$k}, $val,
                        "$var match ($name)",
                    );
                }

                isa_ok(
                    $ret[0], [ $DEFS{class} ],
                    'return value (blessed)',
                );
            }
        }
    };

    # NOTE:
    #   Do not test --help and --version because they must exit() immediately when
    #   invoked via CLI; they are so simple that can be skipped.
    subtest 'Options processing' => sub {
        #skip_all;

        my %TESTS_OPTS = (
            'nothing' => {
                type => 'success',
            },
            'no module' => {
                type => 'error',
                opts => [],
                args => [],
            },
            'perl' => {
                type => 'error',
                opts => [],
                args => [ qw< perl > ],
            },
            'dist + version' => {
                type => 'success',
                opts => [],
                args => [ $FAKE{dist}, $FAKE{ver} ],
            },
            '--bogus' => {
                type => 'error',
                opts => [ qw< --bogus > ],
                args => [ $FAKE{mod} ],
            },
            '-u, --update' => {
                type => 'success',
                opts => [ qw< -u --update > ],
                args => [ $FAKE{mod} ],
                val  => [ update => 1 ],
            },
            '-w, --write' => {
                type => 'success',
                opts => [ qw< -w --write > ],
                args => [ $FAKE{mod} ],
                val  => [ write => 1 ],
            },
            '--force' => {
                type => 'success',
                opts => [ qw< --force > ],
                args => [ $FAKE{mod} ],
                val  => [ force => 1 ],
            },
            'c, --clear' => {
                type => 'success',
                opts => [ qw< -c --clear > ],
                args => [ $FAKE{mod} ],
                val  => [ clear => 1 ],
            },
            '--clear-mcpan' => {
                type => 'success',
                opts => [ qw< --clear-mcpan > ],
                args => [ $FAKE{mod} ],
                val  => [ clear_mcpan => 1 ],
            },
            '--clear-arch' => {
                type => 'success',
                opts => [ qw< --clear-arch > ],
                args => [ $FAKE{mod} ],
                val  => [ clear_arch => 1 ],
            },
        );

        foreach my ( $t, $v ) (%TESTS_OPTS) {
            subtest $t => sub {
                my $c2a = App::cpan2arch->new;

                my @argv;
                @argv = ( $v->{opts}->@*, $v->{args}->@* ) if $t ne 'nothing';

                # Error
                if ( $v->{type} eq 'error' ) {
                    my ( $stderr, @ret ) = capture_stderr {
                        return $c2a->_process_opts( \@argv );
                    };

                    is(
                        $ret[0], number(2),
                        'return value (error)',
                    );

                    return;
                }

                # Success
                is(
                    $c2a->_process_opts( $t eq 'nothing' ? () : \@argv ), number(0),
                    'return value (success)',
                );

                return if $t eq 'nothing';

                # Options
                {
                    my %opts = $c2a->opts;

                    is(
                        $opts{ $v->{val}[0] }, $v->{val}[1],
                        'opts values match',
                    ) if defined $v->{val};
                }

                # Arguments
                {
                    my %args   = $c2a->args;
                    my %t_args = (
                        module  => shift $v->{args}->@*,
                        version => shift $v->{args}->@*,
                    );

                    is(
                        %args, %t_args,
                        'args values match',
                    );
                }
            };
        }
    };

    subtest 'Compare Perl dist versions' => sub {
        #skip_all;

        my %TESTS_VER = (
            bogus_ver => {
                ver_a => 'bogus',
                ver_b => 'v1.0.0',
                op    => '>',
            },
            bogus_op => {
                ver_a => 'v2.0.0',
                ver_b => 'v1.0.0',
                op    => '>>',
            },
            '<' => {
                ver_a => 'v1.0.0',
                ver_b => 'v2.0.0',
                op    => '<',
            },
            '<=' => {
                ver_a => 'v1.0.0',
                ver_b => 'v2.0.0',
                op    => '<=',
            },
            '==' => {
                ver_a => 'v1.0.0',
                ver_b => 'v2.0.0',
                op    => '==',
            },
            '>' => {
                ver_a => 'v2.0.0',
                ver_b => 'v1.0.0',
                op    => '>',
            },
            '>=' => {
                ver_a => 'v2.0.0',
                ver_b => 'v1.0.0',
                op    => '>=',
            },
        );

        foreach my ( $t, $v ) (%TESTS_VER) {
            subtest $t => sub {
                my $c2a = App::cpan2arch->new;

                # Bogus comparison
                if ( $t =~ /\Abogus_/ ) {
                    my ( $stderr, @ret ) = capture_stderr {
                        return $c2a->_comp_vers( $v->{ver_a}, $v->{ver_b}, $v->{op} );
                    };

                    is(
                        $ret[0], number(1),
                        'return value (error)',
                    ) if $t eq 'bogus_ver';

                    is(
                        $ret[0], undef,
                        'return value (undef)',
                    ) if $t eq 'bogus_op';

                    return;
                }

                # Successful comparison
                {
                    my $ret = $c2a->_comp_vers(
                        $v->{ver_a},
                        $t eq '==' ? $v->{ver_a} : $v->{ver_b},
                        $v->{op},
                    );

                    is(
                        $ret, number(0),
                        'return value (success)',
                    );
                }

                # Failed comparison
                {
                    my $ret = $c2a->_comp_vers( $v->{ver_b}, $v->{ver_a}, $v->{op} );

                    is(
                        $ret, undef,
                        'return value (undef)',
                    );
                }
            };
        }
    };

    subtest 'PKGBUILD generation' => sub {
        #skip_all;

        my %env = (
            packager => $DEFS{packager},
            #debug    => true,
        );

        foreach my ( $dist, $data ) ( $expected->%* ) {
            subtest $dist => sub {
                note( $data->{note} );

                my $c2a = App::cpan2arch->new;

                # Fake necessary data for generation.
                $c2a->set_env(%env);
                $c2a->set_meta( $data->{meta}->%* );
                $c2a->set_arch_prereqs( $data->{arch_prereqs}->%* );

                $c2a->generate_pkgbuild;
                my %pkgbuild = $c2a->pkgbuild;

                test_diff(
                    $pkgbuild{output}, $data->{pkgbuild},
                    'generated PKGBUILD',
                );
            }
        }
    };

    # Test output behavior from generated PKGBUILD.
    subtest 'PKGBUILD output' => sub {
        #skip_all;

        my $DIST = 'Regexp-Debugger';

        my %FILES = (
            outfile  => 'PKGBUILD',
            metadata => '.SRCINFO',
        );

        my %TESTS_OUT = (
            '--update' => {
                normal_ver          => 'PKGBUILD + version updated',
                normal_ver_no_pkger => 'PKGBUILD updated + version updated + co-maintainer not preserved',
                normal_bump         => 'PKGBUILD updated + pkgrel bumped',
                normal_comp         => '.SRCINFO != generated metadata',
                normal_epoch        => 'PKGBUILD updated + preserve epoch',

                epoch_add    => 'PKGBUILD updated + add epoch',
                epoch_bump   => 'PKGBUILD updated + bump epoch',
                epoch_vercmp => 'no vercmp',

                no_files => 'no .SRCINFO or PKGBUILD',
                no_vars  => 'no pkgbase/pkgver/pkgrel in .SRCINFO',

                bogus_pkgbase => '.SRCINFO pkgbase != generated pkgbase',
                bogus_pkgver  => '.SRCINFO pkgver is newer than generated pkgver',
                bogus_pkgrel  => '.SRCINFO pkgrel != number',
            },
            '--write' => {
                nothing  => 'no PKGBUILD',
                normal   => '--write',
                no_force => '--write + file exists',
                force    => '--write + --force + file exists',
            },
            'STDOUT' => 'no opts',
        );

        foreach my ( $opt, $info ) (%TESTS_OUT) {
            subtest $opt => sub {
                if ( $opt eq '--update' ) {
                    my $CONTRIBS = <<~'END';
                        # Maintainer: Alice <alice@domain.tld>
                        # Contributor: Bob <bob@domain.tld>
                        END

                    my %env = (
                        packager => $DEFS{packager},
                        #debug    => true,
                    );

                    my %SRCINFO = (
                        default => <<~'END',
                            pkgbase = perl-regexp-debugger
                            	pkgdesc = Visually debug regexes in-place
                            	pkgver = 0.002007
                            	pkgrel = 1
                            	url = https://metacpan.org/dist/Regexp-Debugger
                            	arch = any
                            	license = unknown
                            	makedepends = perl-extutils-makemaker
                            	depends = perl-test-simple
                            	depends = perl-version
                            	depends = perl>=5.10.1
                            	options = !emptydirs
                            	source = https://cpan.metacpan.org/authors/id/D/DC/DCONWAY/Regexp-Debugger-0.002007.tar.gz
                            	sha256sums = db096cf2e0e1e6127dacc40be6fbd526aa5ad41886a5bae00f4fe6a53a6c6ffb

                            pkgname = perl-regexp-debugger
                            END
                    );

                    $SRCINFO{normal_ver} = $SRCINFO{normal_ver_no_pkger} =
                      $SRCINFO{default} =~ s{^\tpkgver = \K[^\n]+$}{0.002006}mr;

                    $SRCINFO{normal_bump} = $SRCINFO{default};

                    $SRCINFO{normal_comp} = $SRCINFO{default} =~ s{^\tpkgdesc = \K[^\n]+$}{Bogus abstract}mr;
                    $SRCINFO{normal_comp} =~ s{^\tpkgrel = \K[^\n]+$}{2}m;
                    $SRCINFO{normal_comp} =~ s{^\tdepends = perl-test-simple\n}{}m;
                    $SRCINFO{normal_comp} =~ s{(?=^\tmakedepends = )}{\tcheckdepends = perl-test-simple\n}m;
                    $SRCINFO{normal_comp}
                      =~ s{(?=^\tdepends = )}{\tdepends = perl-list-compare\n\tdepends = perl-capture-tiny\n}m;
                    $SRCINFO{normal_comp}
                      =~ s{^\tsha256sums = [^\n]+$}{\tmd5sums = 65b0f7984e0c176dcd640973a8fb6581}m;

                    $SRCINFO{normal_epoch} = $SRCINFO{default} =~ s{^\tpkgrel = [^\n]+\n\K}{\tepoch = 1\n}mr;

                    $SRCINFO{epoch_add} = $SRCINFO{epoch_bump} = $SRCINFO{epoch_vercmp} =
                      $SRCINFO{default} =~ s{^\tpkgver = \K[^\n]+$}{0.002006111}mr;

                    $SRCINFO{epoch_bump} =~ s{^\tpkgrel = [^\n]+\n\K}{\tepoch = 1\n}m;

                    $SRCINFO{bogus_pkgbase} = $SRCINFO{default} =~ s{\Apkgbase = \K[^\n]+$}{perl-bogus}mr;
                    $SRCINFO{bogus_pkgver}  = $SRCINFO{default} =~ s{^\tpkgver = \K[^\n]+$}{99999}mr;
                    $SRCINFO{bogus_pkgrel}  = $SRCINFO{default} =~ s{^\tpkgrel = \K[^\n]+$}{bogus}mr;

                    my $PROG = path($0)->basename;

                    # Expected metadata comparison
                    my $comparison = <<~"END";
                        $PROG: .SRCINFO is different than generated metadata

                        Metadata comparison
                        +--------------+-------------------+-------------------+-------------------+
                        | Variable     | .SRCINFO          | Generated         | Status            |
                        +--------------+-------------------+-------------------+-------------------+
                        | sha256sums   | N/A               | -                 | Missing from .SRC |
                        |              |                   |                   | INFO              |
                        |              |                   |                   |                   |
                        | checkdepends | -                 | N/A               | Missing from Gene |
                        |              |                   |                   | rated             |
                        |              |                   |                   |                   |
                        | md5sums      | -                 | N/A               | Missing from Gene |
                        |              |                   |                   | rated             |
                        |              |                   |                   |                   |
                        | checkdepends | perl-test-simple  | -                 | Only in .SRCINFO  |
                        |              |                   |                   |                   |
                        | depends      | perl-capture-tiny | -                 | Only in .SRCINFO  |
                        |              | , perl-list-compa |                   |                   |
                        |              | re                |                   |                   |
                        |              |                   |                   |                   |
                        | md5sums      | 65b0f7984e0c176dc | -                 | Only in .SRCINFO  |
                        |              | d640973a8fb6581   |                   |                   |
                        |              |                   |                   |                   |
                        | depends      | -                 | perl-test-simple  | Only in Generated |
                        |              |                   |                   |                   |
                        | sha256sums   | -                 | db096cf2e0e1e6127 | Only in Generated |
                        |              |                   | dacc40be6fbd526aa |                   |
                        |              |                   | 5ad41886a5bae00f4 |                   |
                        |              |                   | fe6a53a6c6ffb     |                   |
                        |              |                   |                   |                   |
                        | pkgdesc      | Bogus abstract    | Visually debug re | Differs           |
                        |              |                   | gexes in-place    |                   |
                        +--------------+-------------------+-------------------+-------------------+
                        END

                    # Expected updated PKGBUILD
                    my $updated_default;
                    {
                        $updated_default = $expected->{$DIST}{pkgbuild} =~ s{
                            \A
                            \#\ Maintainer:\ [^\n]+\n
                            \K
                        }
                        {$CONTRIBS}xr;
                    }

                    foreach my ( $t, $name ) ( $info->%* ) {
                        subtest "$t ($name)" => sub {
                            my $TODO;

                            $TODO = todo 'This test fails when vercmp is not installed'
                              if ( ( $t =~ /\Anormal_ver_?/ || $t =~ /\Aepoch_/ ) && !can_run('vercmp') );

                            my $c2a = App::cpan2arch->new;
                            $c2a->_process_opts( [ qw< --update >, $FAKE{mod} ] );

                            # Fake necessary data for generation.
                            $c2a->set_env(%env);
                            $c2a->set_meta( $expected->{$DIST}{meta}->%* );
                            $c2a->set_arch_prereqs( $expected->{$DIST}{arch_prereqs}->%* );

                            $c2a->generate_pkgbuild;
                            my %pkgbuild = $c2a->pkgbuild;

                            # Emulate current dir behavior.
                            my $cwd  = Path::Tiny->cwd;
                            my $temp = Path::Tiny->tempdir;
                            chdir $temp or die $!;

                            if ( $t eq 'normal_ver_no_pkger' ) {
                                # Exclude PACKAGER from top/current maintainer.
                                $pkgbuild{output} =~ s{\A}{$CONTRIBS\n};
                            }
                            else {
                                $pkgbuild{output} =~ s{\A}{# Maintainer: $DEFS{packager}\n$CONTRIBS\n};
                            }

                            if ( $t ne 'no_files' ) {
                                $temp->child( $FILES{outfile} )->spew_utf8( $pkgbuild{output} );

                                if ( $t eq 'no_vars' ) {
                                    $temp->child( $FILES{metadata} )->touch;
                                }
                                else {
                                    $temp->child( $FILES{metadata} )->spew_utf8( $SRCINFO{$t} );
                                }
                            }

                            local $ENV{PATH} = '' if $t eq 'epoch_vercmp';

                            my ( $stderr, @ret ) = capture_stderr {
                                return $c2a->write_pkgbuild;
                            };

                            if ( $t =~ /\A(?> no | bogus)_/x || $t eq 'epoch_vercmp' ) {
                                is(
                                    $ret[0], number(1),
                                    'return value (error)',
                                );
                            }
                            else {
                                if ( $t eq 'normal_comp' ) {
                                    $TODO = todo 'This test fails when TTY width is not 80';

                                    test_diff(
                                        $stderr, $comparison,
                                        'STDERR',
                                    );
                                }

                                my $outfile = path( $FILES{outfile} )->slurp_utf8;

                                my $updated = $t eq 'normal_ver_no_pkger'
                                  ? (
                                      # Replace Maintainer with Contributor since co-maintainers
                                      # are not preserved when PACKAGER is not the current
                                      # PKGBUILD maintainer.
                                      $updated_default
                                      =~ s{^# Maintainer:(?= Alice <alice\@domain.tld>$)}{# Contributor:}mr
                                  )
                                  : $updated_default;

                                # Bump pkgrel
                                {
                                    my $pkgrel =
                                        $t eq 'normal_bump' || $t eq 'normal_epoch' ? 2
                                      : $t eq 'normal_comp'                         ? 3
                                      :                                               ();

                                    $updated =~ s{^pkgrel=\K[^\n]+$}{$pkgrel}m
                                      if $t  =~ /\Anormal_(?> bump | comp | epoch)\z/x;
                                }

                                # Add/bump epoch
                                {
                                    my $epoch =
                                        $t eq 'epoch_add' || $t eq 'normal_epoch' ? 1
                                      : $t eq 'epoch_bump'                        ? 2
                                      :                                             ();

                                    $updated =~ s{^pkgrel=[^\n]+\n\K}{epoch=$epoch\n}m
                                      if $t eq 'normal_epoch' || $t =~ /\Aepoch_/;
                                }

                                test_diff(
                                    $outfile, $updated,
                                    "$FILES{outfile} file",
                                );

                                is(
                                    $ret[0], number(0),
                                    'return value (success)',
                                );
                            }

                            chdir $cwd or die $!;  # tempdir cleanup
                        };
                    }
                }
                elsif ( $opt eq '--write' ) {
                    #skip_all;

                    foreach my ( $t, $name ) ( $info->%* ) {
                        subtest "$t ($name)" => sub {
                            my @argv;
                            @argv = ( qw< --write >, $FAKE{mod} );
                            push @argv, '--force' if $t eq 'force';

                            my $c2a = App::cpan2arch->new;
                            $c2a->_process_opts( $t eq 'nothing' ? undef : \@argv );

                            # Generate PKGBUILD to compare against file.
                            my %pkgbuild = ( output => $expected->{$DIST}{pkgbuild} );
                            $c2a->set_pkgbuild(%pkgbuild) if $t ne 'nothing';

                            # Emulate current dir behavior.
                            my $cwd  = Path::Tiny->cwd;
                            my $temp = Path::Tiny->tempdir;
                            chdir $temp or die $!;

                            # Create existing PKGBUILD to trigger file check.
                            $temp->child( $FILES{outfile} )->touch if $t =~ /force/;

                            my ( $stderr, @ret ) = capture_stderr {
                                return $c2a->write_pkgbuild;
                            };

                            if ( $t eq 'no_force' ) {
                                is(
                                    $ret[0], number(1),
                                    'return value (error)',
                                );
                            }
                            else {
                                if ( $t ne 'nothing' ) {
                                    my $outfile = path( $FILES{outfile} )->slurp_utf8;

                                    test_diff(
                                        $outfile, $pkgbuild{output},
                                        "$FILES{outfile} file",
                                    );
                                }

                                is(
                                    $ret[0], number(0),
                                    'return value (success)',
                                );
                            }

                            chdir $cwd or die $!;  # tempdir cleanup
                        };
                    }
                }
                elsif ( $opt eq 'STDOUT' ) {
                    #skip_all;

                    my $c2a = App::cpan2arch->new;

                    # Generate PKGBUILD to compare against STDOUT.
                    my %pkgbuild = ( output => $expected->{$DIST}{pkgbuild} );
                    $c2a->set_pkgbuild(%pkgbuild);

                    my ( $stdout, @ret ) = capture_stdout {
                        return $c2a->write_pkgbuild;
                    };

                    is(
                        $stdout, $pkgbuild{output},
                        "STDOUT match ($info)",
                    );

                    is(
                        $ret[0], number(0),
                        'return value (success)',
                    );
                }
            }
        }
    };
};

T2->done_testing;
