#!perl
# bin-fetchware-util.t tests bin/fetchware's utility subroutines, which provide
# utility and library functionality for bin/fetchware's main command
# subroutines.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '8'; #Update if this changes.

use App::Fetchware::Config ':CONFIG';
use Test::Fetchware ':TESTING';
use Cwd 'cwd';
use File::Spec::Functions qw(catfile splitpath splitdir catdir catpath tmpdir);
use Path::Class;
use Perl::OSType 'is_os_type';
use File::Temp 'tempdir';


# Crank up security to 11.
File::Temp->safe_level( File::Temp::HIGH );


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


# Set FETCHWARE_DATABASE_PATH to a tempdir, so that this test uses a different
# path for your fetchware database than the one fetchware normally uses after it
# is installed. This is to avoid any conflicts with already installed fetchware
# packages, because if the actual fetchware database path is used for this test,
# then this test will actually upgrade any installed fetchware packages. Early
# in testing I found this acceptable, but now it's a massive bug. I've already
# implemented the FETCHWARE_DATABASE_PATH evironment variable, so I may as well
# take advantage of it.
$ENV{FETCHWARE_DATABASE_PATH} = tempdir("fetchware-test-$$-XXXXXXXXXX",
    CLEANUP => 1, TMPDIR => 1); 
ok(-e $ENV{FETCHWARE_DATABASE_PATH},
    'Checked creating upgrade test FETCHWARE_DATABASE_PATH success.');


subtest 'test parse_fetchwarefile(Fetchwarefile)' => sub {
    skip_all_unless_release_testing();

    my $correct_fetchwarefile = <<EOF;
use App::Fetchware;
program 'who cares';

lookup_url 'http://doesnt.exist/anywhere';

mirror 'http://doesnt.exist/anywhere/either';
EOF

    # Use a scalar ref instead of a real file to avoid having to write and read
    # files unnecessarily.
    ok(parse_fetchwarefile(\$correct_fetchwarefile),
        'checked parse_fetchwarefile() success');

    test_config({program => 'who cares',
            lookup_url => 'http://doesnt.exist/anywhere'},
        'checked parse_fetchwarefile() success CONFIG');

    my $no_use_fetchware = <<EOS;
program 'who cares';

lookup_url 'http://doesnt.exist/anywhere';

mirror 'http://doesnt.exist/anywhere/either';
EOS
    eval_ok(sub {parse_fetchwarefile(\$no_use_fetchware)},
        <<EOE, 'checked parse_fetchwarefile() no use fetchware');
fetchware: The fetchwarefile you provided did not have a [use App::Fetchware]
line in it. This line is required, because it is an important part of how
fetchware uses Perl for its configuration file. Your fetchware file was.
[program 'who cares';

lookup_url 'http://doesnt.exist/anywhere';

mirror 'http://doesnt.exist/anywhere/either';
]
EOE

    my $syntax_errors = <<EOS;
# J Random syntax error.
# Test for syntax error other than forgetting to use App::Fetchware;
use App::Fetchware;
for {
EOS

    eval_ok(sub {parse_fetchwarefile(\$syntax_errors)},
        qr/fetchware failed to execute the Fetchwarefile/,
        'checked parse_fetchwarefile() failed to execute Fetchwarefile');

    # Cleanup previous calls.
    __clear_CONFIG();

    my $api_subs_exported = <<EOS;
use App::Fetchware;

program 'who cares';
lookup_url 'none://';

mirror 'http://doesnt.exist/anywhere/either';

# Use extra perl code to "delete" some of the API subs to test that they weren't
# exported.
use Sub::Mage;
withdraw('lookup');
withdraw('install');
EOS

    eval_ok(sub {parse_fetchwarefile(\$api_subs_exported)},
        qr/fetchware: The App::Fetchware module you choose in your fetchwarefile does not/,
        'checked parse_fetchwarefile() failed to export api subs.');
};


subtest 'test create_fetchware_package()' => sub {
    ###BUGALERT### Must add tests for adding the gpg generated files to the
    #fetchware package, so that gpg doesn't have to download the keys again.
    #Also, I must actually add code for this in bin/fetchware.

    my $fetchwarefile = '# Fake Fetchwarefile for testing';

    # Create a hopefully successful fetchware package using the current working
    # directory (my Fetchware git checkout) and the fake Fetchwarefile I created
    # above.
    my $cwd = dir(cwd());
    my $cwd_parent = $cwd->parent();
    my $cwd_lastdir = $cwd->dir_list(-1, 1);
    is(create_fetchware_package(\$fetchwarefile, cwd(), $cwd_parent),
        catfile($cwd_parent, "$cwd_lastdir.fpkg"),
        'checked create_fetchware_package() success');

    is(cwd(), $cwd,
        'checked create_fetchware_package() chdir back to base directory');

    # Delete generated files.
    ok(unlink(catfile($cwd_parent,"$cwd_lastdir.fpkg")) == 1,
        'checked create_fetchware_package() delete generated files');

##CANNOTTEST## Can't test anymore, because the doesntexist.ever-anywhere file
#will fail the unless conditional and skip the cp() call, so I can't test for
#this specifically anymore.
##CANNOTTEST##    eval_ok(sub {create_fetchware_package('doesntexist.ever-anywhere', cwd())},
##CANNOTTEST##        <<EOE, 'checked create_fetchware_package() cp failure');
##CANNOTTEST##fetchware: run-time error. Fetchware failed to copy the Fetchwarefile you
##CANNOTTEST##specified [doesntexist.ever-anywhere] on the command line or was contained in the
##CANNOTTEST##fetchware package you specified to the newly created fetchware package. Please
##CANNOTTEST##see perldoc App::Fetchware. OS error [No such file or directory].
##CANNOTTEST##EOE

    ok(chdir($cwd), 'checked create_fetchware_package() chdir back to base directory');

};


subtest 'check fetchware_database_path()' => sub {
    # $ENV{FETCHWARE_DATABASE_PATH} has been set to a temporary directory at the
    # top of this file, so it applies to all of these tests too; however, the
    # tests below do not read or write to the actual FETCHWARE_DATABASE_PATH;
    # instead, they just return what it should be and test that the correct
    # things are being returned. Because fetchware_database_path()'s normal
    # behavior is needed to properly test this function even as root, we should
    # local delete $ENV{FETCHWARE_DATABASE_PATH} just for this one function,
    # fetchware_database_path(), because it needs "normal" behavior for proper
    # testing, and such proper testing has no side effects like messing witht he
    # filesystem.
    local $ENV{FETCHWARE_DATABASE_PATH};
    delete $ENV{FETCHWARE_DATABASE_PATH};

    if (is_os_type('Unix', $^O)) {
        # If we're effectively root use a "system" directory.
        if ($> == 0) {
            is(fetchware_database_path(), '/var/log/fetchware',
                'checked fetchware_database_path() as root');
        # else use a "user" directory.
        } else {
            like(fetchware_database_path(),
                # Add a generic "fetchware-test", because ~/.local and /tmp are
                # not the only possibilities especially among CPAN Testers, who
                # often have tempdirs set to cwd(), or other weird paths ending
                # up being used in the test suite. This should fix this.
                # Specific CPAN Tester Report this fixes:
                # http://www.cpantesters.org/cpan/report/3ac3bd5a-4f45-11e5-bcc7-9db5dfbfc7aa
                qr!Perl/dist/fetchware$|/tmp/fetchware-test|fetchware-test!i,
                'checked fetchware_database_path() as user');
        }
    } elsif ($^O eq "MSWin32") {
        # Load main Windows module to use to see if we're Administrator or not.
        BEGIN {
            if ($^O eq "MSWin32")
            {
                require Win32;
                Module->import();  # assuming you would not be passing arguments to "use Module"
            }
        }
        if (Win32::IsAdminUser()) {
            is(fetchware_database_path(), 'C:\fetchware',
                'checked fetchware_database_path() as Administrator on Win32');
        } else {
            ###BUGALERT### Add support for this test on Windows!
            fail('Must add support for non-admin on Windows!!!');
        }
    # Fall back on File::HomeDir's recommendation if not "Unix" or windows.
    } else {
            ###BUGALERT### Add support for everything else too!!!
            fail('Must add support for your OS!!!');
    }

    # Test fetchware_database_path() when the fetchware_database_path
    # configuration option has been specified.
    config(fetchware_db_path => cwd());
    is(fetchware_database_path(), cwd(),
        'check fetchware_database_path() config option success.');
    config_delete('fetchware_db_path');

    # Test FETCHWARE_DATABASE_PATH too.
    local $ENV{FETCHWARE_DATABASE_PATH} = cwd();
    is(fetchware_database_path(), cwd(),
        'check fetchware_database_path() ENV option success.');

    # Now test both of them together.
    config(fetchware_db_path => dir(cwd())->parent());
    is(fetchware_database_path(), dir(cwd())->parent(),
        'check fetchware_database_path() both options success.');

    # Clean up after ourselves.
    delete $ENV{FETCHWARE_DATABASE_PATH};
    config_delete('fetchware_db_path');
};


subtest 'check determine_fetchware_package_path()' => sub {

    # Write some test files to my fetchware_database_path() to test determining
    # if they're there or not.
    my $fetchware_db_path = fetchware_database_path();
    my @test_files = qw(fake-apache fake-apache2 fake-mariadb fake-qmail fake-nginx);
    for my $file (@test_files) {
        ok(open( my $fh, '>', catfile($fetchware_db_path, $file)),
            "check determine_fetchware_package_path() test file creation [$file]");
        print $fh "# Meaningless test Fetchwarefile $file";
        close $fh;
    }

    # Now test multiple results with one query.
    eval_ok(sub {determine_fetchware_package_path('apache')},
        <<EOE, 'checked determine_fetchware_package_path() multiple values');
Choose which package from the list above you want to upgrade, and rerun
fetchware upgrade using it as the argument for the package you want to upgrade.
EOE

    # Remove both apache's from further tests, because it will return 2 instead
    # of a single scalar like the test assumes.
    my @apacheless_test_files = grep { $_ !~ /apache/ } @test_files;

    for my $file (@apacheless_test_files) {
        like(determine_fetchware_package_path($file), qr/$file/,
            "checked determine_fetchware_package_path() [$file] success");
    }
    
    ok( ( map { unlink catfile($fetchware_db_path, $_) } @test_files ) == 5,
        'checked determine_fetchware_package_path() delete test files');
};


subtest 'check extract_fetchwarefile()' => sub {
    skip_all_unless_release_testing();

    my $fetchwarefile = '# Fake testing Fetchwarefile.';

    my $cwd = dir(cwd());
    my $last_dir = $cwd->dir_list(-1, 1);



    # Create a test fetchware package to text extract_fetchwarefile().
    # Use a third arg to have the fpkg created in /tmp instead of cwd().
    my $fetchware_package_path
        =
        create_fetchware_package(\$fetchwarefile, $cwd, tmpdir());


    is(${extract_fetchwarefile($fetchware_package_path)},
        $fetchwarefile, 'checked extract_fetchwarefile() success');

    my $temp_fpkg = catfile(tmpdir(), "$last_dir.fpkg");

    # Test existence of generated files.
    ok(-e $temp_fpkg,
        'checked extract_fetchwarefile() existence of generated files');
    
    # Delete generated files.
    ok(unlink($temp_fpkg),
        'checked extract_fetchwarefile() delete generated files');
};



subtest 'check copy_fpkg_to_fpkg_database()' => sub {

    # Build a fetchwarefile package needed, so I can test installing it.
    my $fetchwarefile = '# Fake Fetchwarefile just for testing';
    my $fetchware_package_path = create_fetchware_package(\$fetchwarefile, cwd());

    my $fpkg_copy = copy_fpkg_to_fpkg_database($fetchware_package_path);

    # Get filename from the test packages original path.
    my ($fetchware_package_filename) = ( splitpath($fetchware_package_path) )[2];

    ok(-e catfile(fetchware_database_path(), $fetchware_package_filename),
        'check copy_fpkg_to_fpkg_database() success');

    ###BUGALERT### Use Sub::Override to override fetchware_package_path(), so I
    #can override its behavior and test this subroutine for failure.

    # Figure out what the create_fetchware_package() named its file.
    my $cwd = dir(cwd());
    my $cwd_parent = $cwd->parent();
    my $cwd_lastdir = $cwd->dir_list(-1, 1);

    # Delete generated files.
    ok(unlink("../Fetchwarefile", "../$cwd_lastdir.fpkg", $fpkg_copy),
        'checked extract_fetchwarefile() delete generated files');
};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();


sub test_config {
    my ($expected_config_hash, $message) = @_;

    for my $expected_key (keys %$expected_config_hash) {
        unless ($expected_config_hash->{$expected_key}
            eq
            config($expected_key)) {
            fail($message);
        }
    }
    pass($message);
}
