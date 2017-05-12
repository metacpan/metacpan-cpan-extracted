#!perl
# App-Fetchware-Fetchwarefile.t tests App::Fetchware's Fetchwarefile object that
# represents Fetchwarefile's when new() makes them. It has nothing to do with
# Fetchwarefile's during any other command.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '6'; #Update if this changes.

use File::Spec::Functions qw(splitpath catfile rel2abs tmpdir);
use URI::Split 'uri_split';
use Cwd 'cwd';
use Test::Fetchware ':TESTING';
use Sub::Mage 'clone';

# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Test if I can load the module "inside a BEGIN block so its functions are exported
# and compile-time, and prototypes are properly honored."
# There is no ':OVERRIDE_START' to bother importing.
BEGIN { use_ok('App::Fetchware::Fetchwarefile'); }

# use Sub::Mage's clone() to manually import _append_to_fetchwarefile from
# App::Fetchware into this tests file's main namespace.
clone '_append_to_fetchwarefile' =>
    (from => 'App::Fetchware::Fetchwarefile',
    to =>  __PACKAGE__);



subtest 'check new() exceptions' => sub {
    eval_ok(sub {App::Fetchware::Fetchwarefile->new()},
        qr/Fetchwarefile: you failed to include a header option in your call to/,
        'checked new() header exception');

    eval_ok(sub {App::Fetchware::Fetchwarefile->new(header => 'not undef')},
        qr/Fetchwarefile: Your header does not have a App::Fetchware or App::FetchwareX::*/,
        'checked new() header regex exception.');

    eval_ok(sub {App::Fetchware::Fetchwarefile->new(
            header => 'use App::FetchwareX::Test;')},
        qr/Fetchwarefile: you failed to include a descriptions hash option in your call to/,
        'checked new() descriptions exception');


    eval_ok(sub {App::Fetchware::Fetchwarefile->new(
            header => 'use App::FetchwareX::Test;',
            descriptions => 'Not a hashref'
        )},
        qr/Fetchwarefile: the descriptions hash value must be a hash ref whoose keys are/,
        'checked new() header exception');
};


subtest 'check new() success' => sub {

    my $fetchwarefile = App::Fetchware::Fetchwarefile->new(
        header => <<EOF,
use App::Fetchware;
# Auto generated @{[localtime()]} by fetchware's new command.
# However, feel free to edit this file if fetchware's new command's
# autoconfiguration is not enough.
# 
# Please look up fetchware's documentation of its configuration file syntax at
# perldoc App::Fetchware, and only if its configuration file syntax is not
# malleable enough for your application should you resort to customizing
# fetchware's behavior. For extra flexible customization see perldoc
# App::Fetchware.
EOF
        descriptions => {
            program => <<EOD,
program simply names the program the Fetchwarefile is responsible for
downloading, building, and installing.
EOD
            temp_dir => <<EOD,
temp_dir specifies what temporary directory fetchware will use to download and
build this program.
EOD
        }
    );

    isa_ok($fetchwarefile, 'App::Fetchware::Fetchwarefile');

    # Check if $fetchwarefile's internals are right.
    ok(exists $fetchwarefile->{header},
        'checked new() internals for header');
    ok(exists $fetchwarefile->{descriptions},
        'checked new() internals for descriptions');
};


subtest 'test config_options() success' => sub {
    
    # Need a $fetchwarefile object to test config_options().
    my $fetchwarefile = App::Fetchware::Fetchwarefile->new(
        header => <<EOF,
use App::Fetchware;
# Auto generated @{[localtime()]} by fetchware's new command.
# However, feel free to edit this file if fetchware's new command's
# autoconfiguration is not enough.
# 
# Please look up fetchware's documentation of its configuration file syntax at
# perldoc App::Fetchware, and only if its configuration file syntax is not
# malleable enough for your application should you resort to customizing
# fetchware's behavior. For extra flexible customization see perldoc
# App::Fetchware.
EOF
        descriptions => {
            program => <<EOD,
program simply names the program the Fetchwarefile is responsible for
downloading, building, and installing.
EOD
            temp_dir => <<EOD,
temp_dir specifies what temporary directory fetchware will use to download and
build this program.
EOD
            mirror => <<EOD,
The mirror configuration option provides fetchware with alternate servers to
try to download this program from. This option is used when the server
specified in the url options in this file is unavailable or times out.
EOD
        }
    );

    my %test_config_options = (
        program => 'Test Program',
        temp_dir => '/var/tmp',
        mirror => [qw(http://fake.mirror/1 ftp://fake.mirror/2)],
    );

    my %test_config_order = (
        program => 1,
        temp_dir => 2,
        mirror => 3,
    );
 
    # Add the test config options to the $fetchwarefile object.
    $fetchwarefile->config_options($_, $test_config_options{$_})
        for sort { $test_config_order{$a} <=> $test_config_order{$b} }
        keys %test_config_order;

    is_deeply($fetchwarefile->{config_options_value}, \%test_config_options,
        'checked config_options() adding new options');

    # Be sure to test that they were stored in the proper order.
    for my $test_key (keys %test_config_order) {
        is($fetchwarefile->{config_options_order}->{$test_key},
            $test_config_order{$test_key},
            "checked config_options() [$test_key] order");
    }

    # Test config_options() as an accessor.
    for my $test_config_option (qw(program temp_dir)) {
        is_deeply([$fetchwarefile->config_options($test_config_option)],
            [$test_config_options{$test_config_option}],
            "checked config_options() getter [$test_config_option]");
    }
    is_deeply([$fetchwarefile->config_options('mirror')],
        $test_config_options{mirror},
        "checked config_options() getter [mirror]");

    # Make a new $fetchwarefile.
    $fetchwarefile = App::Fetchware::Fetchwarefile->new(
        header => 'use App::FetchwareX::Test;',
        descriptions => { mirror => 'mirrors' }
    );
    # Fetchwarefile supports 'MANY' and 'ONEARRREF' types, so test config
    # options that have more than one value.
    my @mirrors = 1 .. 5;
    $fetchwarefile->config_options(mirror => \@mirrors);

    is_deeply([@{$fetchwarefile->{config_options_value}->{mirror}}],
        [@mirrors],
        'checked config_options multiple options');

    is_deeply([$fetchwarefile->config_options('mirror')],
        [@mirrors],
        'checked config_options getter multiple options');

    # Do the same thing as before except call config_options only once with an
    # arraryref of arguments.
    # Make a new $fetchwarefile.
    $fetchwarefile = App::Fetchware::Fetchwarefile->new(
        header => 'use App::FetchwareX::Test;',
        descriptions => { mirror => 'mirrors' }
    );
    $fetchwarefile->config_options(mirror => $_) for @mirrors;
    is_deeply([@{$fetchwarefile->{config_options_value}->{mirror}}],
        [@mirrors],
        'checked config_options multiple options at once');

    is_deeply([$fetchwarefile->config_options('mirror')],
        [@mirrors],
        'checked config_options getter multiple options at once');

    # Check that mirror's order is still 1 despite being called with the
    # mirror key 5 times.
    is($fetchwarefile->{config_options_order}->{mirror}, 1,
        'checked config_options() mirror order.');
};


subtest 'test _append_to_fetchwarefile() success' => sub {
    my $fetchwarefile;

    _append_to_fetchwarefile(\$fetchwarefile,
        'program', 'test-dist', 'A meaningless test example.');
    is($fetchwarefile,
        <<EOE, 'checked _append_to_fetchwarefile() success.');


# A meaningless test example.
program 'test-dist';
EOE

    undef $fetchwarefile;

    # Test a description with more than 80 chars.
    _append_to_fetchwarefile(\$fetchwarefile,
                'program', 'test-dist',
            q{test with more than 80 chars to test the logic that chops it up into lines that are only 80 chars long. Do you think it will work?? Well, let's hope so!
    });
    is($fetchwarefile,
        <<EOE, 'checked _append_to_fetchwarefile() success.');


# test with more than 80 chars to test the logic that chops it up into lines
# that are only 80 chars long. Do you think it will work?? Well, let's hope so!
program 'test-dist';
EOE

    eval_ok(sub {_append_to_fetchwarefile($fetchwarefile,
        'program', 'test-dist', 'description')},
    <<EOE, 'checked _append_to_fetchwarefile() excpetion');
fetchware: run-time error. You called _append_to_fetchwarefile() with a
fetchwarefile argument that is not a scalar reference. Please add the need
backslash reference operator to your call to _append_to_fetchwarefile() and try
again.
EOE
};


subtest 'Test genrate() success' => sub {
    
    # Need a $fetchwarefile object to test config_options().
    my $fetchwarefile = App::Fetchware::Fetchwarefile->new(
        header => <<EOF,
use App::Fetchware;
# Auto generated by fetchware's new command.
# However, feel free to edit this file if fetchware's new command's
# autoconfiguration is not enough.
#
# Please look up fetchware's documentation of its configuration file syntax at
# perldoc App::Fetchware, and only if its configuration file syntax is not
# malleable enough for your application should you resort to customizing
# fetchware's behavior. For extra flexible customization see perldoc
# App::Fetchware.
EOF
        descriptions => {
            program => <<EOD,
program simply names the program the Fetchwarefile is responsible for
downloading, building, and installing.
EOD
            temp_dir => <<EOD,
temp_dir specifies what temporary directory fetchware will use to download and
build this program.
EOD
            mirror => <<EOD,
The mirror configuration option provides fetchware with alternate servers to
try to download this program from. This option is used when the server
specified in the url options in this file is unavailable or times out.
EOD
        }
    );

    # Add some options to my $fetchwarefile.
    $fetchwarefile->config_options(
        program => 'Test Program',
        temp_dir => '/var/tmp',
        mirror => [qw(http://fake.mirror/1 ftp://fake.mirror/2)],
    );

    my $expected_fetchwarefile = <<EOF;
use App::Fetchware;
# Auto generated by fetchware's new command.
# However, feel free to edit this file if fetchware's new command's
# autoconfiguration is not enough.
#
# Please look up fetchware's documentation of its configuration file syntax at
# perldoc App::Fetchware, and only if its configuration file syntax is not
# malleable enough for your application should you resort to customizing
# fetchware's behavior. For extra flexible customization see perldoc
# App::Fetchware.


# program simply names the program the Fetchwarefile is responsible for
# downloading, building, and installing.
program 'Test Program';


# temp_dir specifies what temporary directory fetchware will use to download and
# build this program.
temp_dir '/var/tmp';


# The mirror configuration option provides fetchware with alternate servers to
# try to download this program from. This option is used when the server
# specified in the url options in this file is unavailable or times out.
mirror 'http://fake.mirror/1';
mirror 'ftp://fake.mirror/2';
EOF

    is($fetchwarefile->generate(),
        $expected_fetchwarefile,
        'checked generate() success');
};



# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
