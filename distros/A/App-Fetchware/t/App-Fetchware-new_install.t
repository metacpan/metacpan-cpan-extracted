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
use Test::More 0.98 tests => '4'; #Update if this changes.

use App::Fetchware::Config ':CONFIG';
use Test::Fetchware ':TESTING';
use App::Fetchware::Fetchwarefile;
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

# Test if I can load the module "inside a BEGIN block so its functions are exported
# and compile-time, and prototypes are properly honored."
# And include :DEFAULT as well, so we have access to new_install() as well.
BEGIN { use_ok('App::Fetchware', qw(:DEFAULT :OVERRIDE_NEW_INSTALL)); }
# fetchware must be loaded, because App::Fetchware's
# ask_to_install_now_to_test_fetchwarefile() abuses encapsulation, and reuses
# cmd_install() to directly cause App::Fetchware to install the associated
# Fetchwarefile. Because of this fact fetchware must be loaded by something at
# some point in time. Because of the encapsulation violation I'm not having
# App::Fetchware directly loading fetchware instead, it will rely on the fact
# that of loading it itself. Therefore, in this test suite, I have to load
# fetchware, so ask_to_install_now_to_test_fetchwarefile() can call it.
BEGIN {
    use lib 'bin';
    ok(require('fetchware'),
        'checked loading fetchware itself for access to cmd_install');
}



SKIP: {
    # Must be 2 less than the number of tests in the Test::More use line above.
    my $how_many = 2;
    # Skip testing if STDIN is not a terminal, or if AUTOMATED_TESTING is set,
    # which most likely means we're running under a CPAN Tester's smoker, which
    # may be chroot()ed or something else like LXC that might screw up having a
    # functional terminal.
    if (exists $ENV{AUTOMATED_TESTING}
            and $ENV{AUTOMATED_TESTING}
            or not -t
        ) {
        skip 'Not on a terminal or AUTOMATED_TESTING is set', $how_many; 
    }


# Set Term::UI's AUTOREPLY to true so that it will answer with whatever default
# option I provide or if no default option is provided Term::UI will reply with
# undef.
#
# This lame hack is, so that I can test my use of Term::UI, which is just as
# untestable as Term::ReadLine with which it is based. Term::UI tests itself
# using this exact same method except it uses a default option, but I do not
# want my calls to have a default option or add some stupid wrapper to do it for
# me. This works just fine. Just remember to ignore the warning:
# You have '$AUOTREPLY' set to true, but did not provide a default!
#
# I have tried to figure out how to test this. I even posted some insane code
# that sadly does not work on perlmonks:
# http://www.perlmonks.org/?node_id=991229
$Term::UI::AUTOREPLY = 1;
###BUGALERT### Because I can't test things interactvely, even using the cool
#insane code listed in the perlmonks post above, I'm stuck using the lame
#AUTOREPLY garbage. Either figure out how to programatically press <Enter>, or
#create a interactive option for this test file similar to what Term::ReadLine
#itself does. At least add an xt/ and FETCHWARE_RELEASE_TESTING test that
#prints a lame reminder to at least test new() manually using fetchware new
#itself.


subtest 'test ask_to_install_now_to_test_fetchwarefile success' => sub {
    skip_all_unless_release_testing();
    unless ($< == 0 or $> == 0) {
        plan skip_all => 'Test suite not being run as root.'
    }

    # Create test Term::UI object.
    my $term = Term::ReadLine->new('fetchware');

my $fetchwarefile = <<EOF;
use App::Fetchware;

program 'Apache 2.2';

lookup_url '$ENV{FETCHWARE_HTTP_LOOKUP_URL}';

mirror '$ENV{FETCHWARE_FTP_MIRROR_URL}';

gpg_keys_url "$ENV{FETCHWARE_HTTP_LOOKUP_URL}/KEYS";

filter 'httpd-2.2';
EOF

note('FETCHWAREFILE');
note("$fetchwarefile");



    my $new_fetchware_package_path =
        ask_to_install_now_to_test_fetchwarefile($term, \$fetchwarefile,
            'Apache 2.2');

    # Prepend 'fetchware' to fetchware_database_path(), because that subroutine
    # is in fetchware, which I need to load so that
    # ask_to_install_now_to_test_fetchwarefile() has access to cmd_install(),
    # but I don't import anything, because doing so may affect how I'm testing
    # the encapsulation violation.
    ok(grep /httpd-2\.2/, glob(catfile(fetchware::fetchware_database_path(), '*')),
        'check cmd_install(Fetchware) success.');

    ok(unlink $new_fetchware_package_path,
        'checked ask_to_install_now_to_test_fetchwarefile() cleanup file');

};


subtest 'test new_install() success' => sub {
    skip_all_unless_release_testing();
    unless ($< == 0 or $> == 0) {
        plan skip_all => 'Test suite not being run as root.'
    }

    # Create test Term::UI object.
    my $term = Term::ReadLine->new('fetchware');

my $fetchwarefile = <<EOF;
use App::Fetchware;

program 'Apache 2.2';

lookup_url '$ENV{FETCHWARE_HTTP_LOOKUP_URL}';

mirror '$ENV{FETCHWARE_FTP_MIRROR_URL}';

gpg_keys_url "$ENV{FETCHWARE_HTTP_LOOKUP_URL}/KEYS";

filter 'httpd-2.2';
EOF

note('FETCHWAREFILE');
note("$fetchwarefile");

    my $fetchware_package_path = new_install($term, 'Apache 2.2',
        $fetchwarefile);

    ok(-e $fetchware_package_path,
        'checked new_install() success.');
};


} # #End of gigantic skip block.

# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
