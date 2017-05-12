# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
use lib 't/lib','./blib/lib';
use Test::More;
$VERSION = sprintf("%d.%02d", q$Revision: 1.07 $ =~ /(\d+)\.(\d+)/);
my @TestTheseOnly;# = qw(Sherlock); # this is active only when WWW::Scraper::isGlennWood;

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use WWW::Scraper(qw(3.01));
BEGIN { select STDERR; $| = 1; select STDOUT; $| = 1; }
END {
    }

my $countErrorMessages = 0;
my $countWarningMessages = 0;


use FileHandle;
    my $traceFile = new FileHandle('>test.trace') or die "Can't open test.trace file: $!";
    select ($traceFile); $| = 1; select STDOUT;

# Report current versions of modules we depend on.
    traceBreak(); ##_##_##_##_##_##_##_##_##_##_##_##_##_##_##_##
    print $traceFile "Operating system: $^O\n";
    print $traceFile "Perl version: $]\n";
    my $msg = <<EOT;
VERSIONS OF MODULES ON WHICH SCRAPER DEPENDS
EOT
    print $traceFile $msg;
    diag $msg;

    open TMP, "<Makefile.PL";
    my @makefile = <TMP>;
    close TMP;
    my $makefile = join '',@makefile;
    use vars qw($prereq_pm);
    $makefile =~ s/^.*'PREREQ_PM'\s*=>([^}]*}).*$/\$prereq_pm = $1/s;
    eval $makefile;
    for ( sort keys %$prereq_pm ) {
        my $mod_version = '';
        eval "use $_($$prereq_pm{$_}); \$mod_version = \$$_\:\:VERSION;";
        $mod_version = '' unless $mod_version;
        print $traceFile "    using $_($mod_version);\n";
        diag "    using $_($mod_version);\n";
    }
    traceBreak(); ##_##_##_##_##_##_##_##_##_##_##_##_##_##_##_##
    
    print $traceFile <<EOT;
LIST SCRAPER SUB-CLASSES, FROM THE MANIFEST
EOT
    open TMP, "<MANIFEST";
    my (@modules, @skipModules, @todoModules);
    while (<TMP>) {
        if ( my ($scraperEngine) = m-^lib/WWW/Scraper/(\w+)\.pm$- ) {
                        
            # If parameters supplied to "make test", then test just those engines.
            if ( WWW::Scraper::isGlennWood and @TestTheseOnly ) {
                my $testThis;
                map { $testThis = ( $scraperEngine eq $_ ) } @TestTheseOnly;
                unless ( $testThis ) {
                    TRACE(0, "    - $scraperEngine will not be tested: it is not in the \@TestTheseOnly list.\n");
                    next;
                }
            }

            my $testParameters;
            eval "use WWW::Scraper::$1; \$testParameters = &WWW::Scraper::$1\::testParameters()";
            if ( $@ ) { # $@ just means the module is not a Scraper sub-class.
                TRACE(0, "    - $scraperEngine will not be tested: it is not a Scraper sub-class.\n");
            }
            elsif ( $testParameters ) {
                if ( $testParameters->{'SKIP'} ) {
                    push @skipModules, $scraperEngine;
                }
                elsif ( $testParameters->{'TODO'} ) {
                    push @todoModules, $scraperEngine;
                }
                else {
                    push @modules, $scraperEngine;
                }
                my $mod_version;
                eval "\$mod_version = \$WWW::Scraper::$scraperEngine\:\:VERSION;";
                $mod_version = '' unless $mod_version;
                TRACE(0, "    + $1($mod_version)\n");
            }
        }
    }
    close TMP;
    traceBreak(); ##_##_##_##_##_##_##_##_##_##_##_##_##_##_##_##
    
    my $testCount = scalar(@modules) + scalar(@skipModules) + scalar(@todoModules);
    plan(tests => $testCount + 2);
    ok(1, "$testCount Scraper modules listed in MANIFEST (".scalar(@modules).','.scalar(@todoModules).','.scalar(@skipModules).')');
    
use strict;
use WWW::Scraper(qw(2.13));
use WWW::Scraper::Request;
    ok(1, "WWW::Scraper loaded");

    push @modules, @todoModules, @skipModules;
    for my $sEngine ( sort @modules ) {
    SKIP: {
    TODO: {
            traceBreak(); ##_##_##_##_##_##_##_##_##_##_##_##_##_##_##_##
            my $testParameters;
            eval "\$testParameters = &WWW::Scraper::$sEngine\::testParameters()";
            skip $testParameters->{'SKIP'}, 1 if $testParameters->{'SKIP'};
            local $TODO = $testParameters->{'TODO'} if $testParameters->{'TODO'};
            
            my $result;
            eval { $result = TestThisEngine($sEngine) };

            if ( (not $@) and $result ) {
                ok (1, "$sEngine");
            } else {
                TRACE(0, "Scraper engine $sEngine failed once: $@\n");
                # Some of these search engines don't always work the first time.
                # Give them a second shot before declaring that Scraper is the one that failed!
                eval { $result = TestThisEngine($sEngine) };
                if ( (not $@) and $result ) {
                    ok(1, "$sEngine");
                } else {
                    ok(0, "$sEngine");
                    diag $@ if $@;
                    TRACE(2, "Scraper engine $sEngine failed twice: $@\n");
                }
            }
        }
        }
    }

    close $traceFile;

    if ( $countWarningMessages and WWW::Scraper::isGlennWood() ) {
        diag "$countWarningMessages warning".(($countWarningMessages>1)?'s':'').". See file 'test.trace' for details.\n";
    }
    if ( $countErrorMessages ) {
        diag "$countErrorMessages test".(($countErrorMessages>1)?'s':'')." had problems. See file 'test.trace' for details.\n";
    }
    if ( $countErrorMessages ) {
        open TMP, "<test.trace";
        print join '', <TMP>;
        close TMP;
    }



#######################################################################################
#######################################################################################
#######################################################################################
#######################################################################################
#######################################################################################
#######################################################################################
sub TestThisEngine {
    my ($sEngine) = @_;    
    my $success = 1;
    my $jTest = 0;

    TRACE(0, "Test #$jTest: $sEngine\n");
    my $oSearch = new WWW::Scraper($sEngine);
    if ( not ref($oSearch)) {
        TRACE(1, "Can't load scraper module for $sEngine: $!\n");
        return 0;
    }

#######################################################################################
#
#       BOGUS QUERY 
#
#   This test returns no results (but we should not get an HTTP error):
#
#######################################################################################
    $jTest++;
    TRACE(0, "Test #$jTest: $sEngine 'bogus' search\n");
    my $iResults = 0;
    my ($sQuery, $options, $onePageCount, $multiPageCount, $bogusPageCount) = $oSearch->setupStandardAndExceptionalOptions($sEngine);
    $sQuery = "Bogus" . $$ . "NoSuchWord" . time;
    my $request = new WWW::Scraper::Request($oSearch, $sQuery, $options);
    $oSearch->setScraperTrace($ENV{'SCRAPER_DEBUG_MODE'});
    $oSearch->SetRequest($request);

    my @aoResults = $oSearch->results();
    $iResults = scalar(@aoResults);
    if ( $bogusPageCount < $iResults ) {
        TRACE (2, " --- got $iResults 'bogus' results, expected $bogusPageCount\n");
        #$success = 0; # A fail of the bogus query is not a fail of the installation, right? reallY?
    }

#######################################################################################
#
#       ONE-PAGE QUERY
#
#   This query returns 1 page of results
#
#######################################################################################

    $jTest++;
    TRACE(0, "Test #$jTest: $sEngine one-page search\n");

# Set up standard, and exceptional, options.
    ($sQuery, $options, $onePageCount, $multiPageCount, $bogusPageCount) = $oSearch->setupStandardAndExceptionalOptions($sEngine);

    # Skip this test if no results are expected anyway.
    if ( $onePageCount ) {
        my $request = new WWW::Scraper::Request($oSearch, $sQuery, $options);

        $oSearch->native_query($sQuery); # This let's us test pre-v2.00 modules from here, too.
        $oSearch->SetRequest($request);

        my $maximum_to_retrieve = $onePageCount;
        $oSearch->maximum_to_retrieve($maximum_to_retrieve); # 1 page
        my $iResults = 0;
        eval { 
            my @aoResults = $oSearch->results();
            $iResults = scalar(@aoResults);
        };

        TRACE(0, " + got $iResults results for '$sQuery'\n");
        if ( $maximum_to_retrieve > $iResults )
        {
            my ($message, $bytes);
            if (my $response = $oSearch->response) {
                $message = $response->status_line();
                $bytes = length $response->content();
            } else {
                ($message,$bytes) = ('(no response object)', '(no response object)');
            }
            TRACE(1, <<EOT);
 --- got $iResults results for $sEngine '$sQuery', but expected $maximum_to_retrieve
 --- base URL: $oSearch->{'_base_url'}
 --- first URL: $oSearch->{'_first_url'}
 --- last URL: $oSearch->{'_last_url'}
 --- next URL: $oSearch->{'_next_url'}
 --- response message: $message
 --- content size (bytes): $bytes
 --- ERRNO: $!
 --- Extended OS error: $^E
EOT
            return 0;
        }
    }


#######################################################################################
#
#       MULTI-PAGE QUERY
#
#   This query returns MANY pages of results
#
#######################################################################################
    $jTest++;
    TRACE(0, "Test #$jTest: $sEngine multi-page search\n");
    ($sQuery, $options, $onePageCount, $multiPageCount, $bogusPageCount) = $oSearch->setupStandardAndExceptionalOptions($sEngine);
    # Don't bother with this test if $multiPageCount <= $onePageCount - we've already done it.
    if ( $multiPageCount > $onePageCount ) {
        my $maximum_to_retrieve = $multiPageCount; # 2 or 3 pages
        $oSearch->maximum_to_retrieve($maximum_to_retrieve); # 2 or 3 pages
        my $request = new WWW::Scraper::Request($oSearch, $sQuery, $options);
        $oSearch->native_query($sQuery); # This let's us test pre-v2.00 modules from here, too.
        $oSearch->SetRequest($request);
        $iResults = 0;
        eval { 
            while ( $iResults < $maximum_to_retrieve ) {
                last unless $oSearch->next_response();
                $iResults += 1;
            }
        };
        TRACE(0, " + got $iResults multi-page results for '$sQuery'\n");
        if ( $maximum_to_retrieve > $iResults )
        {
            my $message = $oSearch->response()->status_line();
            my $bytes = length $oSearch->response()->content();
            my $contentAnalysis = ' --- Content Analysis: '.${$oSearch->ContentAnalysis()}."'\n";
            $contentAnalysis =~ s/\n/\n --- /gs;
            TRACE(1, <<EOT);
 --- got $iResults results for multi-page $sEngine '$sQuery', but expected $maximum_to_retrieve.
 --- base URL: $oSearch->{'_base_url'}
 --- first URL: $oSearch->{'_first_url'}
 --- last URL: $oSearch->{'_last_url'}
 --- next URL: $oSearch->{'_next_url'}
 --- response message: $message
 --- content size (bytes): $bytes
 --- ERRNO: $!
 --- Extended OS error: $^E
$contentAnalysis
EOT
         #$success = 0; # A fail of the multi-page query is not a fail of the installation, right? reallY?
        }
    }
    return $success;
}



sub TRACE {
    $countWarningMessages += 1 if $_[0] == 1;
    $countErrorMessages   += 1 if $_[0] == 2;
    $traceFile->print($_[1]);
#    print $_[1] if WWW::Scraper::isGlennWood();
}



{ package WWW::Scraper;
# Set up standard, and exceptional, options.
sub setupStandardAndExceptionalOptions {
    my ($oSearch, $sEngine) = @_;

    my $sQuery = 'Perl';
    my $options;
    my $onePageCount = 9;
    my $multiPageCount = 41;
    my $bogusPageCount = 0;
    my %specialOptions;
    
    # Most Scraper sub-classes will define their own testParameters . . .
    # See Dogpile.pm for the most mature example of how to set your testParameters.
    if ( my $testParameters = $oSearch->testParameters() ) {
        $sQuery = $testParameters->{'testNativeQuery'} || $sQuery;
        $options = $testParameters->{'testNativeOptions'};
        $options = {} unless $options;
        ($onePageCount,$multiPageCount,$bogusPageCount) = (9,41,0);
        $onePageCount   = $testParameters->{'expectedOnePage'}   || $onePageCount;
        $multiPageCount = $testParameters->{'expectedMultiPage'} || $multiPageCount;
        $bogusPageCount = $testParameters->{'expectedBogusPage'} || $bogusPageCount;

        return ($sQuery, $options, $onePageCount, $multiPageCount, $bogusPageCount);
    }

    # . . . others aren't ready for prime-time, so we hard wire their testParameters here.

    my %specialQuery = (
                       ); 
    $sQuery = $specialQuery{$sEngine} if defined $specialQuery{$sEngine};

    return ($sQuery,$options,$onePageCount,$multiPageCount,$bogusPageCount);
}
}

sub traceBreak {
    print $traceFile <<EOT;
##_##_##_##_##_##_##_##_##_##_##_##_##_##_##
EOT
}

__END__

