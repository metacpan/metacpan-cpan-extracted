#
#  Copyright (c) 2001, Raphael Manfredi
#  Copyright (c) 2003, Steven Hilton
#  Copyright (c) 2011-2016, Alex Tokarev
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
#
use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;

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
my $github_repo = 'https://github.com/nohuhu/CGI-Test';

my %MAIN_REQ = (
    # Perl 5.20 warns that CGI is going to be removed
    # from the core in 5.22, so we require it here
    CGI                    => 0,

    Storable               => '1.00',
    URI                    => '1.10',
    ($] >= 5.008                       # HTTP::Status is now in
        ? ('HTTP::Message' => 0, )     # HTTP::Message bundle that
        : ('LWP'           => 0, )     # requires 5.8+
    ),
    'HTML::TreeBuilder'    => 0,
    'File::Temp'           => 0,
    'File::Spec'           => 0,
);

my %TEST_REQ = (
    'Test::More' => '0.82', # for explain()
);

WriteMakefile(
    NAME         => 'CGI::Test',
    ABSTRACT     => 'CGI regression test framework',
    LICENSE      => 'artistic_1',

    VERSION_FROM => 'lib/CGI/Test.pm',
    
    ($MM_VERSION >= 6.64
        ? (
            TEST_REQUIRES => \%TEST_REQ,
            PREREQ_PM     => \%MAIN_REQ,
        )
        : (
            ($MM_VERSION >= 6.5503
                ? (
                    BUILD_REQUIRES => \%TEST_REQ,
                    PREREQ_PM      => \%MAIN_REQ,
                )
                : (
                    PREREQ_PM => {
                        %TEST_REQ,
                        %MAIN_REQ,
                    },
                ),
            ),
        ),
    ),

    ($MM_VERSION >= 6.57
        ? ( AUTHOR => [
                'Alex Tokarev <tokarev@cpan.org>',
                'Steven Hilton <mshiltonj@mshiltonj.com>',
                'Raphael Manfredi <Raphael_Manfredi@pobox.com>',
            ]
        )
        : (
            AUTHOR => 'Alex Tokarev <tokarev@cpan.org>',
        ),
    ),

    ($MM_VERSION >= 6.48 ? ( MIN_PERL_VERSION => 5.006000 ) : () ),

    ($MM_VERSION >= 6.46
        ? ( META_MERGE => {
                resources   => {
                    bugtracker  => "$github_repo/issues",
                    repository  => "$github_repo",
                },
            },
        )
        : (),
    ),
);

