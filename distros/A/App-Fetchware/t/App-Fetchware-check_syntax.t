#!perl
# App-Fetchware-check_syntax.t tests App::Fetchware's check_syntax() subroutine, which
# tests if Fetchwarefiles have all of the mandatory configuration options specified.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '3'; #Update if this changes.

use Test::Fetchware ':TESTING';
use App::Fetchware::Config ':CONFIG';

# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Test if I can load the module "inside a BEGIN block so its functions are exported
# and compile-time, and prototypes are properly honored."
# There is no ':OVERRIDE_START' to bother importing.
BEGIN { use_ok('App::Fetchware', qw(:DEFAULT :OVERRIDE_CHECK_SYNTAX)); }

# Print the subroutines that App::Fetchware imported by default when I used it.
note("App::Fetchware's default imports [@App::Fetchware::EXPORT]");


subtest 'test check_syntax()' => sub {
    # Test check_config_options() parameter checking exceptions.
    eval_ok(sub {check_config_options(BothAreDefined =>
        'a scalar instead of arrayref')}, 
        <<EOE, 'checked check_config_options() arrayref param exception');
App-Fetchware: check_config_options()'s even arguments must be an array
reference. Please correct your arguments, and try again.
EOE
    eval_ok(sub {check_config_options(BothAreDefined =>
        [qw(1 2 3)])}, 
        <<EOE, 'checked check_config_options() arrayref size param exception');
App-Fetchware: check_config_options()'s even arguments must be an array
reference with exactly two elements in it. Please correct and try again.
EOE

    # Define a test Fetchwarefile with just config().
    config(build_commands => 'some commands');

    is(check_config_options(
        BothAreDefined => [ [qw(build_commands)],
            [qw(prefix configure_options make_options)] ]),
        'Syntax Ok', 'checked check_config_options() BothAreDefined success.');

    config(prefix => 'to define both');

    eval_ok(sub {check_config_options(
        BothAreDefined => [ [qw(build_commands)],
            [qw(prefix configure_options make_options)] ])},
        <<EOE, 'checked check_config_options() BothAreDefined exception');
App-Fetchware: Your Fetchwarefile has incompatible configuration options.
You specified configuration options [build_commands] and [prefix configure_options make_options], but these options are not
compatible with each other. Please specifiy either [build_commands] or [prefix configure_options make_options] not both.
EOE

    __clear_CONFIG();

    eval_ok(sub{check_config_options(Mandatory => [ 'program', <<EOM ],)
App-Fetchware: Your Fetchwarefile must specify a program configuration
option. Please add one, and try again.
EOM
        }, <<EOD, 'checked check_config_options() Mandatory exception');
App-Fetchware: Your Fetchwarefile must specify a program configuration
option. Please add one, and try again.
EOD


    config(program => 'Some Program');

    my $retval = check_config_options(Mandatory => [ 'program', <<EOM ],);
App-Fetchware: Your Fetchwarefile must specify a program configuration
option. Please add one, and try again.
EOM

    is($retval, 'Syntax Ok', 'checked check_config_options() Mandatory success.');

    __clear_CONFIG();

    # ConfigOptionEnum only triggers when the specified option, verify_method in
    # this case, has been specified. Therefore, I must specify verify_method in
    # order to test ConfigOptionEnum.
    config(verify_method => 'notgpg');

    eval_ok(sub{check_config_options(
        ConfigOptionEnum => ['verify_method', [qw(gpg sha1 md5)] ],)
        }, <<EOD, 'checked check_config_options() ConfigOptionEnum exception');
App-Fetchware: You specified the option [verify_method], but failed to specify only
one of its acceptable values [gpg sha1 md5]. Please change the value you
specified [notgpg] to one of the acceptable ones listed above, and try again.
EOD

    __clear_CONFIG();

    config(verify_method => 'gpg');

    is(check_config_options(
        ConfigOptionEnum => ['verify_method', [qw(gpg sha1 md5)] ],),
        'Syntax Ok', 'checked check_config_options() ConfigOptionEnum success.');

    __clear_CONFIG();

    # Define a test Fetchwarefile with just config().
    config(program => 'Some Program');
    config(lookup_url => 'scheme://fake.url');
    config(mirror => 'scheme://fake.url');
    
    is(check_config_options(
        BothAreDefined => [ [qw(build_commands)],
            [qw(prefix configure_options make_options)] ],
        Mandatory => [ 'program', <<EOM ],
App-Fetchware: Your Fetchwarefile must specify a program configuration
option. Please add one, and try again.
EOM
        Mandatory => [ 'mirror', <<EOM ],
App-Fetchware: Your Fetchwarefile must specify a mirror configuration
option. Please add one, and try again.
EOM
        Mandatory => [ 'lookup_url', <<EOM ],
App-Fetchware: Your Fetchwarefile must specify a lookup_url configuration
option. Please add one, and try again.
EOM
        ConfigOptionEnum => ['lookup_method', [qw(timestamp versionstring)] ],
        ConfigOptionEnum => ['verify_method', [qw(gpg sha1 md5)] ],
    ), 'Syntax Ok', 'checked check_config_options() all options together.');
};



subtest 'test check_syntax()' => sub {

    is(check_syntax(), 'Syntax Ok',
        'checked check_syntax() success.');
};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
