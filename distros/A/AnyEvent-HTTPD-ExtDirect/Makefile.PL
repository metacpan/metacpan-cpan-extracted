use 5.008000;
use ExtUtils::MakeMaker;

# Add the `devtest` target to run regression and POD tests in one go
sub MY::postamble {
    return <<'END';
devtest :
	REGRESSION_TESTS=1 POD_TESTS=1 $(MAKE) test

END
}

# Override `disttest` so it would behave as `devtest`
sub MY::dist_test {
	return <<'END';
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) devtest $(PASTHRU)

END
}

my $MM_VERSION  = $ExtUtils::MakeMaker::VERSION;
my $github_repo = 'https://github.com/nohuhu/AnyEvent-HTTPD-ExtDirect';

my %CORE_REQ = (
    'AnyEvent::HTTPD' => '0.93',
    'RPC::ExtDirect'  => '3.20',
    'HTTP::Request'   => 0,
);

my %TEST_REQ = (
    'Test::More' => '0.82', # for explain()
    'URI'        => 0,
);

WriteMakefile(
    NAME         => 'AnyEvent::HTTPD::ExtDirect',
    VERSION_FROM => 'lib/AnyEvent/HTTPD/ExtDirect.pm',
    
    ABSTRACT     => 'RPC::ExtDirect gateway for AnyEvent::HTTPD',
    AUTHOR       => 'Alex Tokarev <tokarev@cpan.org>',
    LICENSE      => 'perl',
    
    ($MM_VERSION >= 6.64
        ? (
            TEST_REQUIRES => \%TEST_REQ,
            PREREQ_PM     => \%CORE_REQ,
        )
        : (
            ($MM_VERSION >= 6.5503
                ? (
                    BUILD_REQUIRES => \%TEST_REQ,
                    PREREQ_PM      => \%CORE_REQ,
                )
                : (
                    PREREQ_PM => {
                        %TEST_REQ,
                        %CORE_REQ,
                    },
                )
            ),
        ),
    ),
    
    ($MM_VERSION >= 6.48 ? ( MIN_PERL_VERSION => 5.008000 ) : ()),
    
    ($MM_VERSION >= 6.46
        ? ( META_MERGE => {
                resources   => {
                    bugtracker  => "$github_repo/issues",
                    repository  =>  $github_repo,
                },
            },
        )
        : ()
    ),
);

