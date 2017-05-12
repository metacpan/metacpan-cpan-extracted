#!perl
# App-Fetchware-config-file.t tests App::Fetchware's configuration file
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
use Test::More 0.98 tests => '4'; #Update if this changes.

use App::Fetchware::Config ':CONFIG';
use Test::Fetchware ':TESTING';

# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Test if I can load the module "inside a BEGIN block so its functions are exported
# and compile-time, and prototypes are properly honored."
BEGIN { use_ok('App::Fetchware', ':DEFAULT'); }
#BEGIN { use_ok('App::Fetchware'); }#, ':DEFAULT'); }
#BEGIN { require('App::Fetchware'); App::Fetchware->import();}

# Print the subroutines that App::Fetchware imported by default when I used it.
note("App::Fetchware's default imports [@App::Fetchware::EXPORT]");

###BUGALERT### _make_config_sub() has no tests!!!

subtest 'test config file subs' => sub {
    # Test 'ONE' and 'BOOLEAN' config subs.
    program 'test';
    filter 'test';
    temp_dir 'test';
    fetchware_db_path 'test';
    user 'test';
    prefix 'test';
    configure_options 'test';
    make_options 'test';
    build_commands 'test';
    install_commands 'test';
    lookup_url 'test';
    lookup_method 'test';
    gpg_sig_url 'test';
    gpg_keys_url 'test';
    sha1_url 'test';
    md5_url 'test';
    verify_method 'test';
    no_install 'test';
    verify_failure_ok 'test';
    stay_root 'test';
    user_keyring 'test';

    debug_CONFIG();

    for my $config_sub (qw(
        temp_dir
        user
        prefix
        configure_options
        make_options
        build_commands
        install_commands
        lookup_url
        lookup_method
        gpg_sig_url
        verify_method
        no_install
        verify_failure_ok
        stay_root
    )) {
        is(config($config_sub), 'test', "checked config sub $config_sub");
    }

    # Test 'MANY' config subs.
    mirror 'test';
    mirror 'test';
    mirror 'test';
    mirror 'test';
    mirror 'test';

    debug_CONFIG();

    for my $mirror (config('mirror')) {
        is($mirror, 'test', 'checked config sub mirror');
    }
    ok(config('mirror') == 5, 'checked only 5 entries in mirror');

};

# Clear %CONFIG
__clear_CONFIG();

subtest 'test ONEARRREF config_file_subs()' => sub {
    my @onearrref_or_not = (
        [ program => 'ONE' ],
        [ filter => 'ONE' ],
        [ temp_dir => 'ONE' ],
        [ fetchware_db_path => 'ONE' ],
        [ user => 'ONE' ],
        [ prefix => 'ONE' ],
        [ configure_options=> 'ONEARRREF' ],
        [ make_options => 'ONEARRREF' ],
        [ build_commands => 'ONEARRREF' ],
        [ install_commands => 'ONEARRREF' ],
        [ uninstall_commands => 'ONEARRREF' ],
        [ lookup_url => 'ONE' ],
        [ lookup_method => 'ONE' ],
        [ gpg_keys_url => 'ONE' ],
        [ gpg_sig_url => 'ONE' ],
        [ sha1_url => 'ONE' ],
        [ md5_url => 'ONE' ],
        [ verify_method => 'ONE' ],
        [ mirror => 'MANY' ],
        [ no_install => 'BOOLEAN' ],
        [ verify_failure_ok => 'BOOLEAN' ],
        [ stay_root => 'BOOLEAN' ],
        [ user_keyring => 'BOOLEAN' ],
    );

    { no strict 'refs';

        for my $config_sub (@onearrref_or_not) {
            if ($config_sub->[1] eq 'ONE'
                or $config_sub->[1] eq 'BOOLEAN') {
#            eval_ok( sub {eval "$config_sub->[0] 'onevalue', 'twovalues';"},
                eval_ok( sub {("$config_sub->[0]")->('onevalue', 'twovalues');},
                    <<EOE, "checked $config_sub->[0] ONEARRREF support");
App-Fetchware: internal syntax error. $config_sub->[0] was called with more than one
option. $config_sub->[0] only supports just one option such as '$config_sub->[0] 'option';'. It does
not support more than one option such as '$config_sub->[0] 'option', 'another option';'.
Please chose one option not both, or combine both into one option. See perldoc
App::Fetchware.
EOE
                
            } elsif ($config_sub->[1] eq 'ONEARRREF'
                or $config_sub->[1] eq 'MANY') {
#            eval "$config_sub->[0] 'onevalue', 'twovalues';"
                ("$config_sub->[0]")->('onevalue', 'twovalues');
            } else {
                fail('Unknown config sub type!');
            }
        }
    }
};


subtest 'test hook() success' => sub {
    use Test::More;
    use App::Fetchware::Util ':UTIL';
    use App::Fetchware;

    # Test hook()'s returning success when it successfully replaces something.
    my $test_string = 'start() overridden';
    ok((hook start => sub { return $test_string}),
        'checked hook() success.');

    # Now let's test that start() was successfully overridden.
    is(start(), $test_string,
        'checked hook() override success.');

    eval_ok(sub {hook doesntexistever134 => sub { return $test_string}},
        <<EOE, 'checked hook() exception');
App-Fetchware: The subroutine [doesntexistever134] you attempted to override does
not exist in this package. Perhaps you misspelled it, or it does not exist in
the current package.
EOE

};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
