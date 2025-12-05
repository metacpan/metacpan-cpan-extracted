use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::dnsq',
    AUTHOR           => 'Isaac Caldwell <solangiishaque49@gmail.com>',
    VERSION          => '1.1.0',
    ABSTRACT         => 'A full-featured dig-like DNS query tool with JSON output, caching, and batch processing',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => 5.010,

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    PREREQ_PM => {
        'Net::DNS'         => '1.0',
        'JSON'             => '2.0',
        'Time::HiRes'      => 0,
        'IO::Socket::INET' => 0,
        'Term::ReadLine'   => 0,
        'Getopt::Long'     => 0,
        'POSIX'            => 0,
        'Storable'         => 0,
        'File::Spec'       => 0,
    },

    TEST_REQUIRES => {
        'Test::More' => '0.98',
        'File::Temp' => 0,
    },

    EXE_FILES => ['bin/dnsq'],

    META_MERGE => {
        'meta-spec' => { version => 2 },
        recommends => {
            'Parallel::ForkManager' => '2.0',
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bl4ckstack/dnsq.git',
                web  => 'https://github.com/bl4ckstack/dnsq',
            },
            bugtracker => {
                web => 'https://github.com/bl4ckstack/dnsq/issues',
            },
            homepage => 'https://github.com/bl4ckstack/dnsq',
        },
        keywords => [
            'dns','query','dig','network','resolver','dnssec','batch','json'
        ],
        provides => {
            'App::dnsq' => { file => 'lib/App/dnsq.pm', version => '1.1.0' },
            'DNSQuery::Banner' => { file => 'lib/DNSQuery/Banner.pm', version => '1.1.0' },
            'DNSQuery::Batch' => { file => 'lib/DNSQuery/Batch.pm', version => '1.1.0' },
            'DNSQuery::Cache' => { file => 'lib/DNSQuery/Cache.pm', version => '1.1.0' },
            'DNSQuery::Constants' => { file => 'lib/DNSQuery/Constants.pm', version => '1.1.0' },
            'DNSQuery::Interactive' => { file => 'lib/DNSQuery/Interactive.pm', version => '1.1.0' },
            'DNSQuery::Output' => { file => 'lib/DNSQuery/Output.pm', version => '1.1.0' },
            'DNSQuery::Resolver' => { file => 'lib/DNSQuery/Resolver.pm', version => '1.1.0' },
            'DNSQuery::Validator' => { file => 'lib/DNSQuery/Validator.pm', version => '1.1.0' },
        },
    },

    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },

    clean => {
        FILES => 'DNSQuery-* *.bak *~ *.swp *.swo',
    },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
install ::
	@echo ""
	@echo "=========================================="
	@echo "DNSQuery v1.1.0 installed successfully!"
	@echo "=========================================="
	@echo ""
	@echo "Usage:"
	@echo "  dnsq google.com"
	@echo "  dnsq --json --short example.com"
	@echo "  dnsq --batch queries.txt"
	@echo "  dnsq --interactive"
	@echo ""
	@echo "Documentation:"
	@echo "  perldoc DNSQuery::Resolver"
	@echo "  perldoc DNSQuery::Validator"
	@echo "  perldoc DNSQuery::Cache"
	@echo "  dnsq --help"
	@echo ""
	@echo "For more information, see:"
	@echo "  https://github.com/bl4ckstack/dnsq"
	@echo ""
MAKE_FRAG
}
