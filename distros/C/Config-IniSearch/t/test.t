#
# test.t -- Test Config::IniSearch module
#
#####################################################################

use strict;
use Test::More tests => 11;
require_ok( 'Config::IniSearch' );
my $status;

my $test = "Test to access specified INI file";
my $iniFile = "/etc/global.ini";
SKIP:
{
	skip "/etc/global.ini missing, please read README", 1 if !-r "/etc/global.ini";
	my $config = new Config::IniSearch( 'testSection', $iniFile );
	( $config->{fileName} eq '/etc/global.ini' ) ? 
		( $status = 'ok' ) : ( $status = 'FAILED' );
	ok( $status eq 'ok', $test );
}

# Tests starting with most specific ini file and progressing to global
# ini file
$test = "Find section-specific ini file in cwd";
my $config = new Config::IniSearch( 'testSection' );
( $config->{fileName} eq './testSection.ini' ) ?
    ( $status = 'ok' ) : ( $status = 'FAILED' );
ok( $status eq 'ok', $test );
rename './testSection.ini', './testSection.ini.moved';

$test = "Find global ini file in cwd";
$config = new Config::IniSearch( 'testSection' );
( $config->{fileName} eq './global.ini' ) ?
    ( $status = 'ok' ) : ( $status = 'FAILED' );
ok( $status eq 'ok', $test );
rename './global.ini', './global.ini.moved';

$test = "Find section-specific ini file in ..";
$config = new Config::IniSearch( 'testSection' );
( $config->{fileName} eq 't/testSection.ini' ) ?
    ( $status = 'ok' ) : ( $status = 'FAILED' );
ok( $status eq 'ok', $test );
rename 't/testSection.ini', 't/testSection.ini.moved';

$test = "Find global ini file in cwd";
$config = new Config::IniSearch( 'testSection' );
( $config->{fileName} eq 't/global.ini' ) ?
    ( $status = 'ok' ) : ( $status = 'FAILED' );
ok( $status eq 'ok', $test );
rename 't/global.ini', 't/global.ini.moved';

SKIP:
{
	skip "/etc/global.ini missing, please read README", 1 if !-r "/etc/testSection.ini";
	$test = "Find section-specific ini file in /etc";
	$config = new Config::IniSearch( 'testSection' );
	( $config->{fileName} eq '/etc/testSection.ini' ) ?
		( $status = 'ok' ) : ( $status = 'FAILED' );
	ok( $status eq 'ok', $test );
}

SKIP:
{
	skip "/etc/global.ini missing, please read README", 1 if !-r "/etc/testSection.ini";
	$test = "Find global ini file in /etc";
	$config = new Config::IniSearch( 'testSection2' );
	( $config->{fileName2} eq '/etc/global.ini' ) ?
		( $status = 'ok' ) : ( $status = 'FAILED' );
	ok( $status eq 'ok', $test );
}

# Restore files
rename './testSection.ini.moved', './testSection.ini';
rename './global.ini.moved', './global.ini';
rename 't/testSection.ini.moved', 't/testSection.ini';
rename 't/global.ini.moved', 't/global.ini';

# Test various Config::IniHash case options

$test = "Lowercase test";
$config = new Config::IniSearch( 'testSection', undef, case=>'lower' );
( $config->{uppercase} =~ /success/ ) ?
    ( $status = 'ok' ) : ( $status = 'FAILED' );
ok( $status eq 'ok', $test );

$test = "Uppercase test";
$config = new Config::IniSearch( 'testSection', undef, case=>'upper' );
( $config->{LOWERCASE} =~ /success/ ) ?
    ( $status = 'ok' ) : ( $status = 'FAILED' );
ok( $status eq 'ok', $test );

$test = "Preserve case";
$config = new Config::IniSearch( 'testSection', undef, case=>'preserve' );
( $config->{MiXeDcAsE} =~ /success/ ) ?
    ( $status = 'ok' ) : ( $status = 'FAILED' );
ok( $status eq 'ok', $test );
