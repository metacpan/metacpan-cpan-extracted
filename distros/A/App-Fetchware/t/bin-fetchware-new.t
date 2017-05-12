#!perl
# bin-fetchware-new.t tests bin/fetchware's cmd_new() subroutine, which
# interactively creates new Fetchwarefiles, and optionally initially installs
# them as fetchware packages.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '1'; #Update if this changes.

use App::Fetchware::Config ':CONFIG';
use Test::Fetchware ':TESTING';
use Cwd 'cwd';
use File::Copy 'cp';
use File::Spec::Functions qw(catfile splitpath);
use Path::Class;
use Test::Deep;


# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Load bin/fetchware "manually," because it isn't a real module, and has no .pm
# extenstion use expects.
BEGIN {
    my $fetchware = 'fetchware';
    use lib 'bin';
    require $fetchware;
    fetchware->import(':TESTING');
    ok(defined $INC{$fetchware}, 'checked bin/fetchware loading and import')
}



##TODO##SKIP: {
##TODO##    # Must be 1 less than the number of tests in the Test::More use line above.
##TODO##    my $how_many = 1;
##TODO##    # Skip testing if STDIN is not a terminal, or if AUTOMATED_TESTING is set,
##TODO##    # which most likely means we're running under a CPAN Tester's smoker, which
##TODO##    # may be chroot()ed or something else like LXC that might screw up having a
##TODO##    # functional terminal.
##TODO##    if (exists $ENV{AUTOMATED_TESTING}
##TODO##            and $ENV{AUTOMATED_TESTING}
##TODO##            or not -t
##TODO##        ) {
##TODO##        skip 'Not on a terminal or AUTOMATED_TESTING is set.', $how_many; 
##TODO##    }
##TODO##
##TODO##
##TODO### Set Term::UI's AUTOREPLY to true so that it will answer with whatever default
##TODO### option I provide or if no default option is provided Term::UI will reply with
##TODO### undef.
##TODO###
##TODO### This lame hack is, so that I can test my use of Term::UI, which is just as
##TODO### untestable as Term::ReadLine with which it is based. Term::UI tests itself
##TODO### using this exact same method except it uses a default option, but I do not
##TODO### want my calls to have a default option or add some stupid wrapper to do it for
##TODO### me. This works just fine. Just remember to ignore the warning:
##TODO### You have '$AUOTREPLY' set to true, but did not provide a default!
##TODO###
##TODO### I have tried to figure out how to test this. I even posted some insane code
##TODO### that sadly does not work on perlmonks:
##TODO### http://www.perlmonks.org/?node_id=991229
##TODO##$Term::UI::AUTOREPLY = 1;
##TODO#####BUGALERT### Because I can't test things interactvely, even using the cool
##TODO###insane code listed in the perlmonks post above, I'm stuck using the lame
##TODO###AUTOREPLY garbage. Either figure out how to programatically press <Enter>, or
##TODO###create a interactive option for this test file similar to what Term::ReadLine
##TODO###itself does. At least add an xt/ and FETCHWARE_RELEASE_TESTING test that
##TODO###prints a lame reminder to at least test new() manually using fetchware new
##TODO###itself.
##TODO##
##TODO##
##TODO####TODO## I must actually write a real test for cmd_new(), because previously
##TODO###this test file, which tested cmd_new() failed to actually test cmd_new(),
##TODO###because its Test::Expect tests failed for some reason. Expect just got
##TODO###confused, and failed to find the right regexes, and no amount of messing with
##TODO###it could get it working, so I gave up, and cmd_new() is never actually tested
##TODO###in full.
##TODO###
##TODO###Maybe IO::React, and a quickly made react_ok() could work?
##TODO##
##TODO##
##TODO####BROKEN##subtest 'test cmd_new() success' => sub {
##TODO####BROKEN##    skip_all_unless_release_testing();
##TODO####BROKEN##
##TODO####BROKEN##    plan(skip_all => 'Optional Test::Expect testing module not installed.')
##TODO####BROKEN##        unless eval {require Test::Expect; Test::Expect->import(); 1;};
##TODO####BROKEN##
##TODO####BROKEN##    # Disable Term::UI's AUTOREPLY for this subtest, because unless I use
##TODO####BROKEN##    # something crazy like Test::Expect, this will have to be tested "manually."
##TODO####BROKEN##    local $Term::UI::AUTOREPLY = 0;
##TODO####BROKEN##    # Fix the "out of orderness" thanks to Test::Builder messing with
##TODO####BROKEN##    # STD{OUT,ERR}.
##TODO####BROKEN###    local $| = 1;
##TODO####BROKEN##
##TODO####BROKEN##    # Have Expect tell me what it's doing for easier debugging.
##TODO####BROKEN##    $Expect::Exp_Internal = 1;
##TODO####BROKEN##
##TODO####BROKEN##    expect_run(
##TODO####BROKEN##        command => 't/bin-fetchware-new-cmd_new',
##TODO####BROKEN###        prompt => [-re => qr/((?<!\?  \[y\/N\]): |\? )/ms],
##TODO####BROKEN##        #prompt => [-re => qr/(\?|:) \[y\/N\] |\? |: /ims],
##TODO####BROKEN###        prompt => [-re => qr/((?:\?|:) \[y\/N\]: )|\? |: /i],
##TODO####BROKEN##        prompt => [-re => qr/ \[y\/N\]: |\? |: /i],
##TODO####BROKEN###        prompt => [-re => qr/\? \n/ims],
##TODO####BROKEN##        quit => "\cC"
##TODO####BROKEN##    );
##TODO####BROKEN##
##TODO####BROKEN##    # Have Expect restart its timeout anytime output is received. Should keep
##TODO####BROKEN##    # expect from timeingout while it's waiting for Apache to compile.
##TODO####BROKEN##    #my $exp = expect_handle();
##TODO####BROKEN##    #$exp->restart_timeout_upon_receive(1);
##TODO####BROKEN##
##TODO####BROKEN##    # First test that the command produced the correct outout.
##TODO####BROKEN##    expect_like(qr/Fetchware's new command is reasonably sophisticated, and is smart enough to/ms,
##TODO####BROKEN##        'checked cmd_new() received correct name prompt');
##TODO####BROKEN##
##TODO####BROKEN##    expect_send('Apache',
##TODO####BROKEN##        'check cmd_new() sent Apache as my name.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_like(qr/Fetchware's heart and soul is its lookup_url. This is the configuration option/ms,
##TODO####BROKEN##        'checked cmd_new() received lookup_url prompt.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_send("$ENV{FETCHWARE_HTTP_LOOKUP_URL}",
##TODO####BROKEN##        'checked cmd_new() say lookup_url.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_like(qr/Fetchware requires you to please provide a mirror. This mirror is required,/ms,
##TODO####BROKEN##        'checked cmd_new() received mirror prompt.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_send("$ENV{FETCHWARE_HTTP_MIRROR_URL}",
##TODO####BROKEN##        'checked cmd_new() say mirror.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_like(qr/In addition to the one required mirror that you must define in order for/ms,
##TODO####BROKEN##        'checked cmd_new() received more mirrors prompt.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_send('N',
##TODO####BROKEN##        'checked cmd_new() say N for more mirrors.');
##TODO####BROKEN##
##TODO####BROKEN##    #expect_like(qr!\[y/N\]|gpg digital signatures found. Using gpg verification.!ms,
##TODO####BROKEN##    expect_like(qr!.*|gpg digital signatures found. Using gpg verification.!ms,
##TODO####BROKEN##        'checked cmd_new() received filter prompt.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_send('httpd-2.2',
##TODO####BROKEN##        'checked cmd_new() say httpd-2.2 for filter option.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_like(qr/Fetchware has many different configuration options that allow you to control its/ms,
##TODO####BROKEN##        'checked cmd_new() received extra config prompt.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_send('N',
##TODO####BROKEN##        'checked cmd_new() say N for more config options prompt.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_like(qr/Fetchware has now asked you all of the needed questions to determine what it/ms,
##TODO####BROKEN##        'checked cmd_new() received edit config prompt.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_send('N',
##TODO####BROKEN##        'checked cmd_new() say N for edit config prompt.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_like(qr/It is recommended that fetchware go ahead and install the program based on the/ms,
##TODO####BROKEN##        'checked cmd_new() received install program prompt.');
##TODO####BROKEN##
##TODO####BROKEN##    # Say no to avoid actually installing Apache yet again.
##TODO####BROKEN##    expect_send('N',
##TODO####BROKEN##        'checked cmd_new() say N for install program prompt.');
##TODO####BROKEN##
##TODO####BROKEN##    expect_quit();
##TODO####BROKEN##};
##TODO##
##TODO##} # #End of gigantic skip block.

# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
