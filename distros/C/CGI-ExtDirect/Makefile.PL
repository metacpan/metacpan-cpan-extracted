use 5.006000;
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
my $github_repo = 'https://github.com/nohuhu/CGI-ExtDirect';

my %CORE_REQ = (
    # 5.20 warns that CGI is going to be removed from
    # perl core in 5.22, so we require it here
    'CGI'            => 0,
    'RPC::ExtDirect' => '3.24',
);

# CGI.pm was in a flux between 4.00 and 4.20; if we have 4.00+
# let's have the latter one then
eval {
    require CGI;
    $CORE_REQ{CGI} = '4.20' if $CGI::VERSION >= '4.00';
};

my %TEST_REQ = (
    'Test::More' => '0.82', # for explain()
    'CGI::Test'  => '1.100',
);

WriteMakefile(
    NAME         => 'CGI::ExtDirect',
    VERSION_FROM => 'lib/CGI/ExtDirect.pm',
    
    ABSTRACT     => 'RPC::ExtDirect gateway for CGI', 
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

    ($MM_VERSION >= 6.48 ? ( MIN_PERL_VERSION => 5.006000 ) : ()),

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

