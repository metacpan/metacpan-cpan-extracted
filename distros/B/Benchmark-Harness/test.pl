# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;
use lib 't/lib','./blib/lib','./lib';
use Benchmark::Harness;
use Test::Simple tests => 8;
use strict;
use Time::HiRes;

use vars qw($AuthenticationForTesting);
$AuthenticationForTesting = 'benchmark:password';

{ package Benchmark::Harness; # Override the Authenticate method for testing purposes
sub Authenticate {
    my ($self, $givenAuthentication) = @_;

# NOTE: You must code the required user/psw in the form "userId:password".
my $Authentication = $main::AuthenticationForTesting;
    return undef unless defined $Authentication;
    my ($rUserId, $rPassword) = split /\:/,$Authentication;
    my ($gUserId, $gPassword) = split /\:/,$givenAuthentication;
    return ($rUserId eq $gUserId) && ($rPassword eq $gPassword);
}
}

use vars qw($CVS_VERSION); $CVS_VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/);


### yinst install Proc::ProcessTable -nosudo -root /home/goto/big/stats




######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { select STDERR; $| = 1; select STDOUT; $| = 1; }

my @Tests = qw(Trace TraceHighRes Values ValuesHighRes);
for my $handler ( @Tests ) {
    my $startTime = Time::HiRes::time();

# THIS ALSO SERVES AS AN EXAMPLE OF A FULLY FUNCTIONAL Benchmark::Harness CLIENT
    # Trace simple looping
    my @traceParameters = qw(TestServer::Loop (0)TestServer::Max (2|1)TestServer::M.*);
    my $traceHarness = new  Benchmark::Harness($AuthenticationForTesting, $handler.'(1)', @traceParameters);
    my $doh          = Benchmark::Harness::new($AuthenticationForTesting, $handler.'(1)', @traceParameters);
    for (my $i=0; $i<10; $i++ ) {
        TestServer::new(5,10,15,3,4); # Fire the server method,
    }

    my $old = $traceHarness->old(); # and here's our result.
## THAT'S ALL THERE IS TO THE ILLUSTRATION!

    ok($old, "$handler performed");
    print "Elapsed: ".(Time::HiRes::time() - $startTime)."\n";

    # Save result for Glenn's easy viewing (before mangling below).
    if ( ($^O eq 'MSWin32') && ($ENV{HSP_USERNAME} eq 'GlennWood') ) {
        open XML, ">t/benchmark.$handler.temp.xml" or die "Doh! $@$!";
        print XML $$old; close XML;
    }

    # These attributes will not be the same for all tests, once each.
    $$old =~ s{\n}{}gs;
    for ( qw(v V n tm pid userid os) ) {
        $$old =~ s{ $_=(['"]).*?\1}{};
    }
    # These attributes will not be the same for all tests, many times.
    for ( qw(t f p r s m u x) ) {
        $$old =~ s{ $_=(['"]).*?\1}{}gs;
    }
    
    # New-lines, of whatever religion, do not matter to us here
    $$old =~ s{\r?\n}{}g;

    # Values traces will have different ARRAY(ref) strings
    $$old =~ s{(ARRAY)\([^)]*\)}{$1}gs if ( $handler =~ m{Values} );

    # Compare our results with what is expected.
    if ( open TMP, "<t/benchmark.$handler.xml" ) {
        my $tmp = join '',<TMP>; close TMP;
        
        # New-lines, of whatever religion, do not matter to us here
        $tmp =~ s{\n}{}g;
        $tmp =~ s{>\s*}{>}g;
        $tmp =~ s{="([^"]*)"}{='$1'}g;
        $tmp =~ s{\s\s}{ }g; # your're kiding!
        $$old =~ s{\n}{}g;
        $$old =~ s{>\s*}{>}g;
        $$old =~ s{="([^"]*)"}{='$1'}g;
        $$old =~ s{\s\s}{ }g; # your're kiding!
 
        my $success = $tmp eq $$old;
        ok ( $success, "Result cmp Expected (result ".($success?'eq':'ne')." t/benchmark.$handler.xml)" ) ;
    } else {
        ok ( 0, "t/benchmark.$handler.xml not found" );
    }

    # Glenn's easy viewing.
    if ( ($^O eq 'MSWin32') && ($ENV{HSP_USERNAME} eq 'GlennWood') ) {
        open XML, ">t/benchmark.$handler.trimmed.xml";
        print XML $$old; close XML;
    }
}
    # Glenn's easy viewing.
    if ( ($^O eq 'MSWin32') && ($ENV{HSP_USERNAME} eq 'GlennWood') ) {
        #system("t\\benchmark.$Tests[0].temp.xml");
    }

__END__

