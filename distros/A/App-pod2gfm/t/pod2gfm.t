#!perl
#
# Test every component of App::pod2gfm to ensure correct behavior. App::pod2gfm
# must run as documented in its POD (and its wrapper POD).

use v5.40.0;

use strict;
use warnings;

use Test2::V1 qw<
    is
    isa_ok
    number
    number_gt
    skip_all
    subtest
>;

use App::pod2gfm;

use File::Spec::Functions qw< catdir >;
use Capture::Tiny 0.50 qw< capture_stdout capture_stderr >;
use Path::Tiny 0.150;

my %DEFAULTS = (
    class => 'App::pod2gfm',
    data  => {
        got => <<~'END',
            =head1 TEST

            =for highlighter language=perl

                sub foo () { ... }
            END

        expected => <<~'END',
            # TEST

            ```perl
            sub foo () { ... }
            ```
            END
    },
);

# Unit test each method separately.
subtest 'Unit test' => sub {
    #skip_all;

    # Test constructor.
    subtest 'Construct App::pod2gfm instance' => sub {
        #skip_all;

        my $pod2gfm = App::pod2gfm->new;

        isa_ok(
            $pod2gfm, [ $DEFAULTS{class} ],
            'return value (instance)',
        );
    };

    # Test options processing.
    #
    # NOTE:
    #   Do not test --help and --version because they must exit() immediately when
    #   invoked via CLI; they are so simple that can be skipped.
    subtest 'Options processing' => sub {
        #skip_all;

        my %TESTS_OPTS = (
            'nothing' => {
                success => undef,
            },
            '--bogus' => {
                error => [ qw< --bogus > ],
            },
            '-a, --auto' => {
                success => [ qw< -a --auto > ],
                value   => [ auto => 1 ],
            },
            '-e, --file-extension=s' => {
                success => [ qw< -e markdown --file-extension=markdown > ],
                error   => [ qw< --file-extension > ],
                value   => [ file_ext => 'markdown' ],
            },
            '--no-strip-ext' => {
                success => [ qw< --no-strip-ext > ],
                value   => [ no_strip_ext => 1 ],
            },
            '-t, --target-directory=s' => {
                success => [ qw< -t docs --target-directory=docs > ],
                error   => [ qw< --target-directory > ],
                value   => [ target_dir => 'docs' ],
            },
            '--force' => {
                success => [ qw< --force > ],
                value   => [ force => 1 ],
            },
            '--hl-language=s' => {
                success => [ qw< --hl-language=perl > ],
                error   => [ qw< --hl-language > ],
                value   => [ hl_language => 'perl' ],
            },
            '--man-url-prefix=s' => {
                success => [ qw< --man-url-prefix=http://man.he.net/man > ],
                error   => [ qw< --man-url-prefix > ],
                value   => [ man_url_prefix => 'http://man.he.net/man' ],
            },
            '--perldoc-url-prefix=s' => {
                success => [ qw< --perldoc-url-prefix=metacpan > ],
                error   => [ qw< --perldoc-url-prefix > ],
                value   => [ perldoc_url_prefix => 'metacpan' ],
            },
        );

        my $pod2gfm = App::pod2gfm->new;

        foreach my ( $k, $v ) (%TESTS_OPTS) {
            subtest $k => sub {
                if ( defined $v->{error} ) {
                    my ( $stderr, @return ) = capture_stderr {
                        return $pod2gfm->_process_opts( $v->{error} );
                    };

                    is(
                        $return[0], number(2),
                        'return value (invalid option)',
                    );

                    return if $k eq '--bogus';
                }

                is(
                    $pod2gfm->_process_opts( $v->{success} ), number(0),
                    'return value (success)',
                );

                return if $k eq 'nothing';

                my %opts =
                    $k =~ /\A --(?> hl-language | man-url-prefix | perldoc-url-prefix)=s \z/x
                  ? $pod2gfm->gh_opts
                  : $pod2gfm->opts;

                is(
                    $opts{ $v->{value}[0] }, $v->{value}[1],
                    'opts value match',
                );
            };
        }
    };

    # Test filehandle argument logic.
    subtest 'Filehandle processing' => sub {
        #skip_all;

        my %TESTS = (
            'STDIN -> STDOUT' => {
                args  => undef,
                in_fh => {
                    name => 'STDIN',
                    fd   => 0,
                },
                out_fh => {
                    name => 'STDOUT',
                    fd   => 1,
                },
            },
            'STDIN -> OUTFILE' => {
                args  => [ qw< -  OUTFILE > ],
                in_fh => {
                    name => 'STDIN',
                    fd   => 0,
                },
                out_fh => {
                    name => 'OUTFILE',
                    fd   => 2,
                },
            },
            'INFILE -> STDOUT' => {
                args  => [ qw< INFILE > ],
                in_fh => {
                    name => 'INFILE',
                    fd   => 2,
                },
                out_fh => {
                    name => 'STDOUT',
                    fd   => 1,
                },
            },
            'INFILE -> OUTFILE' => {
                args  => [ qw< INFILE OUTFILE > ],
                in_fh => {
                    name => 'INFILE',
                    fd   => 2,
                },
                out_fh => {
                    name => 'OUTFILE',
                    fd   => 2,
                },
            },
            'INFILE -> OUTFILE (file exists; no --force)' => {
                args     => [ qw< INFILE OUTFILE > ],
                no_force => 1,
            },
        );

        my sub is_fh (%opts)
        {
            my $tempdir = Path::Tiny->tempdir;
            my @args;

            if ( defined $opts{args} ) {
                foreach my $arg ( $opts{args}->@* ) {
                    $arg = Path::Tiny->tempfile if $arg eq 'INFILE';

                    if ( $arg eq 'OUTFILE' ) {
                        $arg =
                          defined $opts{no_force}
                          ? Path::Tiny->tempfile
                          : $tempdir->child('foo.md');
                    }

                    push @args, $arg;
                }
            }

            my $pod2gfm = App::pod2gfm->new->init(@args);

            my ( $stderr, @ret ) = capture_stderr {
                return $pod2gfm->_set_handles;
            };

            my $in_fh  = $pod2gfm->infile;
            my $out_fh = $pod2gfm->outfile;

            if ( defined $opts{no_force} ) {
                is(
                    $ret[0], number(1),
                    'return value (error)',
                );

                return;
            }

            is(
                fileno $in_fh,
                $opts{in_fh}{name} eq 'STDIN'
                ? number( $opts{in_fh}{fd} )
                : number_gt( $opts{in_fh}{fd} ),

                "got $opts{in_fh}{name}",
            );

            is(
                fileno $out_fh,
                $opts{out_fh}{name} eq 'STDOUT'
                ? number( $opts{out_fh}{fd} )
                : number_gt( $opts{out_fh}{fd} ),

                "got $opts{out_fh}{name}",
            );

            is(
                $ret[0], number(0),
                'return value (success)',
            );
        }

        foreach my ( $k, $v ) (%TESTS) {
            subtest $k => sub {
                is_fh( $v->%* );
            };
        }

    };
};

# Test if App::pod2gfm methods work together correctly.
subtest 'Integration test' => sub {
    #skip_all;

    # Test file processing.
    #
    # NOTE:
    #   Assert that pod2gfm runs correctly as documented in the POD.
    #
    #   Do not test --hl-language, --man-url-prefix, and --perldoc-url-prefix options
    #   since they are tested by Pod::Markdown::Githubert and Pod::Markdown distros.
    subtest 'File processing' => sub {
        #skip_all;

        my $data     = $DEFAULTS{data}{got};
        my $expected = $DEFAULTS{data}{expected};

        my %TESTS = (
            'STDIN -> STDOUT' => {
                mode   => 'pair',
                in_fh  => 'STDIN',
                out_fh => 'STDOUT',
            },
            'STDIN -> OUTFILE' => {
                mode   => 'pair',
                in_fh  => '-',
                out_fh => 'outfile',
            },
            'INFILE -> STDOUT' => {
                mode   => 'pair',
                in_fh  => 'infile',
                out_fh => 'STDOUT',
            },
            'INFILE -> OUTFILE' => {
                mode   => 'pair',
                in_fh  => 'infile',
                out_fh => 'outfile',
            },
            'INFILE -> OUTFILE (force)' => {
                mode    => 'pair',
                options => [ qw< --force > ],
                in_fh   => 'infile',
                out_fh  => 'outfile',
            },
            'INFILE -> OUTFILE (multiple files in pairs)' => {
                mode => 'multi_pair',
            },
            'INFILE -> OUTFILE (auto)' => {
                mode    => 'pair',
                options => [ qw< --auto > ],
                in_fh   => 'infile',
                out_fh  => 'outfile',
            },
            'INFILE -> OUTFILE (auto + file-extension)' => {
                mode    => 'pair',
                options => [ qw< --auto --file-extension=markdown > ],
                in_fh   => 'infile',
                out_fh  => 'outfile',
            },
            'INFILE -> OUTFILE (auto + no-strip-ext)' => {
                mode    => 'pair',
                options => [ qw< --auto --no-strip-ext > ],
                in_fh   => 'infile',
                out_fh  => 'outfile',
            },
            'INFILE -> OUTFILE (auto convert all files)' => {
                mode => 'multi_auto',
            },
            'INFILE -> OUTFILE (auto convert all files into directory)' => {
                mode => 'multi_auto_target',
            },
        );

        my sub is_data_pair (%opts)
        {
            my $pod2gfm = App::pod2gfm->new;
            my $tempdir = Path::Tiny->tempdir;

            my $stdin;
            my $infile;
            my $outfile;
            my $got;
            my $return;

            if ( $opts{in_fh} eq 'infile' ) {
                $infile = $tempdir->child('file.pod');
                path($infile)->spew_utf8($data);
            }

            if ( $opts{out_fh} eq 'outfile' ) {
                if ( grep { $_ eq '--force' } $opts{options}->@* ) {
                    $outfile = Path::Tiny->tempfile;
                }
                else {
                    $outfile = $tempdir->child('file.md');
                }
            }

            if ( $opts{in_fh} eq 'STDIN' || $opts{in_fh} eq '-' ) {
                $infile = 'STDIN' if $opts{in_fh} eq 'STDIN';
                $infile = '-'     if $opts{in_fh} eq '-';

                open $stdin, '<', \$data or die $!;
            }
            local *STDIN = $stdin if defined $stdin;

            if ( $opts{out_fh} eq 'STDOUT' ) {
                my ( $stdout, @ret ) = capture_stdout {
                    my $file = $opts{in_fh} eq 'infile' ? $infile : ();

                    return $pod2gfm->init($file)->run;
                };

                $outfile = 'STDOUT';
                $return  = $ret[0];
                $got     = $stdout;
            }
            elsif ( $opts{out_fh} eq 'outfile' ) {
                my @args = ( $infile, $outfile );

                if ( defined $opts{options} ) {
                    unshift @args, $opts{options}->@*;

                    foreach my $opt ( $opts{options}->@* ) {
                        pop @args if $opt eq '--auto';

                        if ( $opt eq '--file-extension=markdown' ) {
                            $outfile = $tempdir->child('file.markdown');
                            push @args, $outfile;
                        }
                        elsif ( $opt eq '--no-strip-ext' ) {
                            $outfile = $tempdir->child('file.pod.md');
                            push @args, $outfile;
                        }
                    }
                }

                $return = $pod2gfm->init(@args)->run;
                $got    = path($outfile)->slurp_utf8;
            }

            is(
                $got, $expected,
                "data match ($opts{mode}: $infile, $outfile)",
            );

            is(
                $return, number(0),
                'return value (success)',
            );
        }

        my sub is_data_multi (%opts)
        {
            my $pod2gfm = App::pod2gfm->new;
            my $tempdir = Path::Tiny->tempdir;

            my %files;
            my @args;

            my sub catpair ($name)
            {
                my $target_dir =
                  $opts{mode} eq 'multi_auto_target'
                  ? 'docs'
                  : '';

                $files{$name}{in}  = catdir( $tempdir, "$name.pod" );
                $files{$name}{out} = catdir( $tempdir, $target_dir, "$name.md" );
            }

            catpair('foo');
            path( $files{foo}{in} )->spew_utf8($data);

            catpair('bar');
            path( $files{bar}{in} )->spew_utf8($data);

            if ( $opts{mode} =~ /\Amulti_auto/ ) {
                catpair('baz');
                path( $files{baz}{in} )->spew_utf8($data);
            }

            @args = (
                $files{foo}{in}, $files{foo}{out},
                $files{bar}{in}, $files{bar}{out},
            );

            if ( $opts{mode} =~ /\Amulti_auto/ ) {
                @args = ( '--auto', $files{foo}{in}, $files{bar}{in}, $files{baz}{in} );

                if ( $opts{mode} eq 'multi_auto_target' ) {
                    my $target_dir = $tempdir->child('docs');
                    path($target_dir)->mkdir;

                    push @args, "--target-directory=$target_dir";
                }
            }

            my $return = $pod2gfm->init(@args)->run;

            foreach my ( $k, $v ) (%files) {
                my $out_data = path( $v->{out} )->slurp_utf8;

                is(
                    $out_data, $expected,
                    "data match ($opts{mode}: $v->{in}, $v->{out})",
                );
            }

            is(
                $return, number(0),
                'return value (success)',
            );
        }

        foreach my ( $k, $v ) (%TESTS) {
            subtest $k => sub {
                if ( $v->{mode} eq 'pair' ) {
                    is_data_pair( $v->%* );
                }
                elsif ( $v->{mode} =~ /\Amulti_/ ) {
                    is_data_multi( $v->%* );
                }
            };
        }
    };
};

T2->done_testing;
