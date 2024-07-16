use ExtUtils::MakeMaker;
use English qw($PERL_VERSION);

my %M = (
    NAME         => 'Data::Radius',
    VERSION_FROM => 'lib/Data/Radius.pm',
    LICENSE      => "artistic_2",
    MIN_PERL_VERSION => "v5.10.0",
    AUTHOR       => [
        'Sergey Leschenko <sergle.ua at gmail.com>',
        'PortaOne <perl-radius at portaone.com>',
    ],
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => "6.64",
    },
    PREREQ_PM    => {
        'Digest::MD5' => 0,
        'Digest::HMAC_MD5' => 0,
        'Class::Accessor::Fast' => 0,
        'Const::Fast' => 0,
        'Socket' => "2.021",
        'File::Spec' => 0,
        'File::Basename' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Deep' => ( $PERL_VERSION lt v5.12.0 ) ? '== 1.130' : 0,
        'File::Temp' => 0,
        'FindBin' => 0,
        'Data::HexDump' => 0,
        'Test::NoWarnings' => 0,
    },
);

my $has_ipv6 = 0;
eval {
    use Socket;
    if (defined Socket::inet_pton(Socket->AF_INET6, '::1')) {
        $has_ipv6 = 1;
    }
};

if (! $has_ipv6) {
    # Socket inet_pton/inet_ntop doesn't work on Windows XP without IPv6 support
    $M{PREREQ_PM}{'Net::IP'} = "1.26";
}

WriteMakefile(%M);
