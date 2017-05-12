#!perl
# App-Fetchware-Config.t tests App::Fetchware's %CONFIG data structure that
# holds fetchware's internal represenation of Fetchwarefiles.
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

use File::Spec::Functions qw(splitpath catfile rel2abs tmpdir);
use URI::Split 'uri_split';
use Cwd 'cwd';
use Test::Fetchware ':TESTING';

# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Test if I can load the module "inside a BEGIN block so its functions are exported
# and compile-time, and prototypes are properly honored."
# There is no ':OVERRIDE_START' to bother importing.
BEGIN { use_ok('App::Fetchware::Config', ':CONFIG'); }

# Print the subroutines that App::Fetchware imported by default when I used it.
note("App::Fetchware::Config's default imports [@App::Fetchware::Config::EXPORT_OK]");





subtest 'CONFIG export what they should' => sub {
    my @expected_util_exports = qw(
        config
        config_iter
        config_replace
        config_delete
        __clear_CONFIG
        debug_CONFIG
    );

    # sort them to make the testing their equality very easy.
    my @sorted_util_tag = sort @{$App::Fetchware::Config::EXPORT_TAGS{CONFIG}};
    @expected_util_exports = sort @expected_util_exports;
    is_deeply(\@sorted_util_tag, \@expected_util_exports,
        'checked for correct CONFIG @EXPORT_TAG');
};


subtest 'test config()' => sub {
    # Test accessing existing config options.
    # You have to make them first.
    config(testaccess => 1);
    config(testarray => qw(0 1 2 3 4 5 6 7 8 9 ));
    is(config('testaccess'), 1,
        'checked config() simple access');
    my $i = 0;
    for my $testval (config('testarray')) {
        is($testval, $i,
            "checked config() many values iteration [$i]");
        $i++;
    }


    # Test adding one and then many things to an existing arrayref.
    config(existingref => qw(0 1));
    config(existingref => 2);
    config(existingref => qw(3 4 5));
    my $y = 0;
    for my $testval (config('existingref')) {
        is($testval, $y,
            "checked config() existing crazy many values iteration [$y]");
        $y++;
    }
    


    # Test adding crazy stuff with config to one thing already existing.
    config(testaccess => qw(2 3 4 5));
    my $z = 1;
    for my $testval (config('testaccess')) {
        is($testval, $z,
            "checked config() crazy many values iteration [$z]");
        $z++;
    }
};


# Clear %CONFIG between tests.
__clear_CONFIG();


subtest 'test config_iter()' => sub {
    # Test config_iter() returns a coderef.
    ok(ref(config_iter('testval')) eq 'CODE',
        'checked config_iter() return value');

    # Test config_iter() iterating over a config option that has a single value.
    config(testval => 'testvalvalue');
    is(config_iter('testval')->(), 'testvalvalue',
        'checked config_iter() return single value');

    # Test config_iter() iterating over multiple values in a loop.
    my @testvals = (qw(
       kdfj
       akdjflkdj
       34ie
       3ikjr3ir
       12343434
       389028
       kifjdkljf2
       kij23i5j14lotSdgt
       1234i5
       1
       45
       4
       arrij
       42
       foo
       bar
       baz
       foobar
       FUBAR
    ));

    # Put @testvals into %CONFIG.
    config('testmany' => @testvals);

    # Iterate over the testmany ARRREF to see if they're correct.
    my $testmany = config_iter('testmany');

    my $testval;
    my $i = 0;
    while (defined($testval = $testmany->())) {
        is($testval, ( config('testmany') )[$i],
            "checked config_iter() many values iteration [$i]");
        $i++;
    }

};


# Clear %CONFIG between tests.
__clear_CONFIG();



subtest 'test config_replace()' => sub {
    # Test config_replace()'s exception
    eval_ok(sub {config_replace();},
        <<EOE, 'check config_replace() exception');
App::Fetchware: run-time error. config_replace() was called with only one
argument, but it requres two arguments. Please add the other option. Please see
perldoc App::Fetchware.
EOE

    # Test replacing something with just one value.
    config(replaceme => 0);
    is(config('replaceme'), 0,
        'checked config_replace() initial test value');

    config_replace(replaceme => 1);
    is(config('replaceme'), 1,
        'checked config_replace() replacement value');

    # Test replacing something with a bunch of values.

    config_replace(replaceme => qw(2 3 4 5));
    my $z = 2;
    for my $testval (config('replaceme')) {
        is($testval, $z,
            "checked config_replace() crazy many values iteration [$z]");
        $z++;
    }


};


# Clear %CONFIG between tests.
__clear_CONFIG();


subtest 'test config_delete()' => sub {
    # Add something to delete
    config(delme => 1);
    is(config('delme'), 1,
        'checked config_delete() create test data');

    # Now delete it, and see if it exists.
    config_delete('delme');
    is(config('delme'), undef,
        'checked config_delete() success');
};


# Clear %CONFIG between tests.
__clear_CONFIG();


subtest 'test __clear_CONFIG()' => sub {
    # Create multiple test values.
    config(a => 1);
    config(b => 1);
    is(config('a'), 1,
        'checked __clear_CONFIG() inital data setup');
    is(config('b'), 1,
        'checked __clear_CONFIG() inital data setup');

    # Clear the whole %CONFIG and see if they exist now.
    __clear_CONFIG();

    # Now they should be undef.
    is(config('a'), undef,
        'checked __clear_CONFIG() inital data setup');
    is(config('b'), undef,
        'checked __clear_CONFIG() inital data setup');
};


# Clear %CONFIG between tests.
__clear_CONFIG();


subtest 'test debug_CONFIG()' => sub {
    # Create a test %CONFIG.
    config(a => 1);
    is(config('a'), 1,
        'checked __clear_CONFIG() inital data setup');

    # Now test debug_CONFIG()'s output.
    # Note: Only one value is stored in %CONFIG so that I do not have to worry
    # about any hash ordering randomization issues.
    print_ok(sub {debug_CONFIG()},
        <<'EOP', 'checked debug_CONFIG() success');
$VAR1 = {
          'a' => 1
        };
EOP


};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
