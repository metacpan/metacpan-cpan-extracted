use 5.006;
use strict;
use warnings;

use ExtUtils::CBuilder;
use ExtUtils::MakeMaker;
use Getopt::Long qw( GetOptionsFromArray );
use Path::Class;
use Try::Tiny;

use inc::IO::Interactive::Tiny;

caller
    or run(\@ARGV, [qw{ssl crypto ssl32 ssleay32 eay32 libeay32 z}]);

sub run {
    my $argv = shift;
    my $libs = shift;

    eval "use ExtUtils::MakeMaker::Coverage";
    $@ or print "Adding testcover target\n";

    my @authors = reverse ( # reverse chronological order
        'Gisle Aas',
        'Joshua Chamas',
        'David Landgren',
        'A. Sinan Unur <nanis@cpan.org>',
    );

    my $mm_version = $ExtUtils::MakeMaker::VERSION;
    $mm_version =~ tr/_//d;

    my %opt;
    GetOptionsFromArray(
        $argv,
        \%opt,
        'incpath=s',
        'libpath=s',
        'live-tests!',
        'static',
        'verbose!',
    ) or die "Error parsing command line options\n";

    if ($ENV{AUTOMATED_TESTING}) {
        $opt{verbose} = 1;
    }

    if (
        (not exists $opt{incpath}) and
        (exists $ENV{OPENSSL_INCLUDE})
    )
    {
        $opt{incpath} = $ENV{OPENSSL_INCLUDE};
    }

    if (
        (not exists $opt{libpath}) and
        (exists $ENV{OPENSSL_LIB})
    )
    {
        $opt{libpath} = $ENV{OPENSSL_LIB};
    }

    # Address RT #78848 and RT #88269

    for my $arg (qw(incpath libpath)) {
        next unless exists $opt{$arg};
        my $path = $opt{$arg};

        try {
            $opt{$arg} = file($path)->absolute->resolve
        }
        catch {
            print "Failed to resolve '$arg=$path': $_\n";
            exit 0;
        };
    }

    $libs = filter_libs(\%opt, $libs);

    unless ($ENV{AUTOMATED_TESTING}) {
        show_do_you_need_crypt_ssleay();
    }

    my $my_openssl_version_cmd = eval {
        build_openssl_version(\%opt, 'openssl-version.c');
    };

    unless (defined $my_openssl_version_cmd) {
        print "Failed to build and link a simple executable using OpenSSL\n";
        exit 0;
    };

    show_cmd_output($my_openssl_version_cmd);

    # No live tests by default
    if ($ENV{PERL_MM_USE_DEFAULT}) {
        $opt{'live-tests'} = 0;
    }
    # otherwise, only check other ways of requesting live tests if command
    # line option was not given
    elsif (not exists $opt{'live-tests'}) {
        if (exists $ENV{CRYPT_SSLEAY_LIVE_TEST_WANTED}) {
            $opt{'live-tests'} = $ENV{CRYPT_SSLEAY_LIVE_TEST_WANTED};
        }
        elsif (IO::Interactive::Tiny::is_interactive()) {
            $opt{'live-tests'} = is_live_test_wanted();
        }
    }

    my %params = (
        META_MERGE => {
            keywords => [ qw(lwp lwp-useragent openssl https) ],
            no_index => {
                directory => [ 'inc' ],
            },
            build => {
                recommends => {
                    'Devel::CheckLib' => '0.99',
                },
            },
            resources => {
                repository => 'https://github.com/nanis/Crypt-SSLeay',
            },
        },

        NAME => 'Crypt::SSLeay',

        AUTHOR => \@authors,

        ABSTRACT_FROM => 'SSLeay.pm',

        VERSION_FROM => 'SSLeay.pm',

        INC => $opt{incpath} ? qq{-I$opt{incpath}} : q{},

        LIBS => $opt{libpath}
                ? [ join ' ', "-L$opt{libpath}", map "-l$_", @$libs ]
                : [ join ' ', map "-l$_", @$libs ]
        ,

        ($opt{static} ? (LINK_TYPE => 'static') : ()),

        TEST_REQUIRES => {
            'Try::Tiny' => '0.19',
            'Test::More' => '0.19',
        },

        CONFIGURE_REQUIRES => {
            'ExtUtils::CBuilder' => '0.280205',
            'Getopt::Long' => 0,
            'Path::Class' => '0.26',
            'Try::Tiny' => '0.19',
        },

        PREREQ_PM => {
            'LWP::Protocol::https' => '6.02',
            'MIME::Base64' => 0, # for Net::SSL
        },

        clean => {
            FILES => join(' ',
                'test.config',
                'openssl-version.o',
                $my_openssl_version_cmd,
                'assertlib*',
            ),
        },

        LICENSE => 'artistic_2',

        MIN_PERL_VERSION => 5.006,
    );

    $mm_version = eval $mm_version;

    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};

    if (
        $params{AUTHOR} and
        ref($params{AUTHOR}) eq ref([]) and
        $mm_version < 6.5705
    ) {
        $params{META_ADD}->{author} = $params{AUTHOR};
        $params{AUTHOR}=join(', ', @{$params{AUTHOR}});
    }

    if ($params{TEST_REQUIRES} and $mm_version < 6.64) {
        $params{BUILD_REQUIRES} = {
            %{ $params{BUILD_REQUIRES} || {} },
            %{ $params{TEST_REQUIRES} },
        };
        delete $params{TEST_REQUIRES};
    }

    if ($params{BUILD_REQUIRES} and $mm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} = {
            %{ $params{PREREQ_PM} || {} },
            %{ $params{BUILD_REQUIRES}},
        };
        delete $params{BUILD_REQUIRES};
    }

    delete $params{CONFIGURE_REQUIRES} if $mm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $mm_version < 6.48;
    delete $params{META_MERGE} if $mm_version < 6.46;
    delete $params{META_ADD} if $mm_version < 6.46;
    delete $params{LICENSE} if $mm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);

    write_test_config('test.config' =>
        {
            network_tests => ($opt{'live-tests'} ? 1 : 0),
        }
    );
}

sub is_live_test_wanted {
    print <<EO_CHUNK;
The test suite can attempt to connect to public servers to ensure that the
code is working properly. If you are behind a strict firewall or have no
network connectivity, these tests may fail (through no fault of the code).
EO_CHUNK
    my $wanted = prompt "Do you want to run the live tests (y/N)?", 'N';
    $wanted =~ s/\A\s+//;
    $wanted =~ s/\s+\z//;

    return $wanted =~ /\Ay(?:es)?\z/i ? 1 : 0;
}

sub write_test_config {
    my $file = shift;
    my $config = shift;

    file($file)->spew(
        [
            map sprintf("%s\t%s\n", $_, $config->{$_}), sort keys %$config
        ]
    );
    return;
}

sub show_cmd_output {
    my ($cmd) = @_;
    my $sep = '=' x 80 . "\n";

    my $output = `$cmd`;

    print $sep,
        defined($output) ? "Output from '$cmd':\n$output"
                         : "No output from '$cmd'",
        $sep
    ;

    return;
}

sub build_openssl_version {
    my $opt = shift;
    my $source = shift;

    my $builder = ExtUtils::CBuilder->new(quiet => !($opt->{verbose} ? 1 : 0));

    my $object = $builder->compile(
        source => $source,
        $opt->{incpath} ? (include_dirs => "$opt->{incpath}") : (),
    );

    my $executable = $builder->link_executable(
        objects => $object,
    );

    return file($executable)->absolute->resolve;
}

sub filter_libs {
    my $opt = shift;
    my $libs = shift;

    return $libs unless eval {
        require Devel::CheckLib;
        Devel::CheckLib->import;
        1;
    };

    my @found;

    for my $lib (@$libs) {
       eval {
           assert_lib(
                debug => ($opt->{verbose} ? 1 : 0),
                lib => $lib,
                header => 'openssl/ssl.h',
                $opt->{libpath} ? (libpath => "$opt->{libpath}") : (),
                $opt->{incpath} ? (incpath => "$opt->{incpath}") : (),
            );
            push @found, $lib;
        };
    }
    unless (grep /crypt|ssl|eay/, @found) {
        printf(
            "Cannot link with any of the requested SSL libraries '%s'\n",
            join(', ' => @$libs),
        );
        exit 0;
    }

    printf "Found libraries '%s'\n", join(', ' => @found);
    return \@found;
}

sub show_do_you_need_crypt_ssleay {
    print <<EO_DO_YOU_NEED_CRYPT_SSLEAY;

    *** THIS IS NOT AN ERROR, JUST A MESSAGE FOR YOUR INFORMATION ***

    Do you really need Crypt::SSLeay?

    Starting with version 6.02 of LWP, https support was unbundled into
    LWP::Protocol::https. This module specifies as one of its prerequisites
    IO::Socket::SSL which is automatically used by LWP::UserAgent unless
    this preference is overridden separately. IO::Socket::SSL is a more
    complete implementation, and, crucially, it allows hostname
    verification. Crypt::SSLeay does not support this. At this point,
    Crypt::SSLeay is maintained to support existing software that already
    depends on it.

    However, it is possible that your software does not really depend on
    Crypt::SSLeay, only on the ability of LWP::UserAgent class to
    communicate with sites over SSL/TLS.

    If are using version LWP 6.02 or later, and therefore have installed
    LWP::Protocol::https and its dependencies, and do not explicitly use
    Net::SSL before loading LWP::UserAgent, or override the default socket
    class, you are probably using IO::Socket::SSL and do not really need
    Crypt::SSLeay.

    Before installing Crypt::SSLeay, you may want to try specifying a
    dependency on LWP::Protocol::https.

EO_DO_YOU_NEED_CRYPT_SSLEAY
}
