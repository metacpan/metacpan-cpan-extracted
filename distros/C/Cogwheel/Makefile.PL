# Load the Module::Install bundled in ./inc/
use 5.8.3;
use inc::Module::Install 0.75;

# Define metadata
name 'Cogwheel';
all_from 'lib/Cogwheel.pm';

# Specific dependencies
requires 'Moose'                    => '0.58';
requires 'Sprocket'                 => '0.07';
requires 'POE::Filter::JSON'        => undef;
requires 'MooseX::Getopt'           => undef;
requires 'MooseX::AttributeHelpers' => undef;
requires 'MooseX::Daemonize'        => undef;

build_requires 'Test::More' => '0';
no_index 'directory' => 'ex';

sub kwalitee() {
    return <<'END';
use Test::More;
eval "use Test::Kwalitee";
plan skip_all => "Test::Kwalitee not installed; skipping" if $@;
END
}

if ( $ENV{TEST_AUTHOR} ) {
    use_test_base;
    use_standard_tests;
    write_test( '000_kwalitee' => kwalitee );
}

auto_install;
WriteAll;
