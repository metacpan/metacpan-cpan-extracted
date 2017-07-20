# tests that serve to expose a problem with the interaction of filtering and
# multiple values in get_regexp() in Config::GitLike 1.16

use strict;
use warnings;

use File::Copy;
use Test::More tests => 30;
use Test::Exception;
use File::Spec;
use File::Temp qw/tempdir/;
use lib 't/lib';
use TestConfig;

# create an empty test directory in /tmp
my $config_dirname = tempdir( CLEANUP => !$ENV{CONFIG_GITLIKE_DEBUG} );
my $config_filename = File::Spec->catfile( $config_dirname, 'config' );

diag "config file is: $config_filename" if $ENV{TEST_VERBOSE};

my $config
    = TestConfig->new( confname => 'config', tmpdir => $config_dirname );

$config->burp(
    '# foo
[section]
	b = off
	b = on
	exact = 0
	inexact = 01
	delicieux = true
'
);

$config->load;

# 'delicieux' has only 1 value
is_deeply(
    scalar $config->get_all( key => 'section.delicieux' ),
    ['true'], 'get all values for key delicieux'
);

is_deeply(
    scalar $config->get_all( key => 'section.delicieux', filter => 'true' ),
    ['true'], 'get all values for key delicieux, filter by regexp'
);

is_deeply(
    scalar $config->get_all( key => 'section.delicieux', filter => 'false' ),
    [], 'get all values for key delicieux, filter by regexp "false"'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.delicieux' ),
    { 'section.delicieux' => 'true' }, 'get all values for key delicieux by regexp'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.delicieux', filter => 'true' ),
    { 'section.delicieux' => 'true' }, 'get all values for key delicieux by regexp, filter by true'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.delicieux', filter => '!true' ),
    {}, 'get all values for key delicieux by regexp, filter by !true'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.delicieux', filter => 'false' ),
    {}, 'get all values for key delicieux by regexp, filter by false'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.delicieux', filter => '!false' ),
    { 'section.delicieux' => 'true' }, 'get all values for key delicieux by regexp, filter by !false'
);

# 'b' has multiple values (2)
is_deeply(
    scalar $config->get_all( key => 'section.b' ),
    ['off', 'on'], 'get all values for key b'
);

is_deeply(
    scalar $config->get_all( key => 'section.b', filter => 'o' ),
    ['off', 'on'], 'get all values for key b, filter by letter "o"'
);

is_deeply(
    scalar $config->get_all( key => 'section.b', filter => 'n' ),
    ['on'], 'get all values for key b, filter by letter "n"'
);

is_deeply(
    scalar $config->get_all( key => 'section.b', filter => 'Q' ),
    [], 'get all values for key b, filter by letter "Q"'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b' ),
    { 'section.b' => ['off', 'on'] }, 'get all values for key b by regexp'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '' ),
    { 'section.b' => ['off', 'on'] }, 'get all values for key b by regexp, filter by empty regex'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '.*' ),
    { 'section.b' => ['off', 'on'] }, 'get all values for key b by regexp, filter by catch-all regex'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '^.*$' ),
    { 'section.b' => ['off', 'on'] }, 'get all values for key b by regexp, filter by anchored catch-all regex'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => qr/(on|off)/ ),
    { 'section.b' => ['off', 'on'] }, 'get all values for key b by regexp, filter by regex on|off'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => qr/^(on|off)$/ ),
    { 'section.b' => ['off', 'on'] }, 'get all values for key b by regexp, filter by anchored regex on|off'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => 'o' ),
    { 'section.b' => ['off', 'on'] }, 'get all values for key b by regexp, filter by letter "o"'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => 'n' ),
    { 'section.b' => 'on' }, 'get all values for key b by regexp, filter by letter "n"'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => 'Q' ),
    {}, 'get all values for key b by regexp, filter by letter "Q"'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => 'ARRAY' ),
    {}, 'get all values for key b by regexp, filter by word "ARRAY"'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '!' ),
    {}, 'get all values for key b by regexp, filter by negated regex'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '!.*' ),
    {}, 'get all values for key b by regexp, filter by negated catch-all regex'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '!(on|off)' ),
    {}, 'get all values for key b by regexp, filter by "!(on|off)"'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '!on|off' ),
    {}, 'get all values for key b by regexp, filter by "!on|off"'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '!good|bad' ),
    { 'section.b' => ['off', 'on'] }, 'get all values for key b by regexp, filter by negated regex good|bad'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '!o' ),
    {}, 'get all values for key b by regexp, filter by "!o"'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '!n' ),
    { 'section.b' => 'off' }, 'get all values for key b by regexp, filter by "!n"'
);

is_deeply(
    scalar $config->get_regexp( key => 'section\.b', filter => '!ARRAY' ),
    { 'section.b' => ['off', 'on'] }, 'get all values for key b by regexp, filter by "!ARRAY"'
);
