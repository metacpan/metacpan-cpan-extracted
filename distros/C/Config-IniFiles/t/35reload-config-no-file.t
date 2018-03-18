use strict;
use warnings;
use Config::IniFiles;
use Test::More tests => 8;
use File::Temp 'tempfile';

my $config_nofile = Config::IniFiles->new( -allowempty => 1 );
$config_nofile->newval( 'section', 'param', 1 );

my ( $fh, $filename ) = tempfile;

## Import config, set filename, read config, then read again
my $config =
    Config::IniFiles->new( -import => $config_nofile, -allowempty => 1 );

# TEST
ok( $config->val( 'section', 'param' ), 'Configuration is imported' );

$config->SetFileName($filename);
$config->ReadConfig;

# TEST
ok( $config->val( 'section', 'param' ), 'Configuration is still imported' );

$config->ReadConfig;

# TEST
ok( $config->val( 'section', 'param' ), 'Configuration is still imported' );

## Import config that has already been imported
$config = Config::IniFiles->new(
    -import     => $config_nofile,
    -allowempty => 1,
    -file       => $filename
);

# TEST
ok( $config->val( 'section', 'param' ), 'Configuration is imported again' );

$config_nofile = Config::IniFiles->new;
$config_nofile->newval( 'section', 'param', 1 );

## Import config and set filename in constructor, then read again
$config = Config::IniFiles->new(
    -import     => $config_nofile,
    -allowempty => 1,
    -file       => $filename
);

# TEST
ok( $config->val( 'section', 'param' ), 'Configuration is imported' );

$config->ReadConfig;

# TEST
ok( $config->val( 'section', 'param' ), 'Configuration is still imported' );

## Import config that is written to file, but with parameters not written to file, then read again

my ( $fh2, $filename2 ) = tempfile;
my $config_file =
    Config::IniFiles->new( -allowempty => 1, -file => $filename2 );
$config_file->newval( 'section', 'param2', 1 );
$config_file->RewriteConfig;
$config_file->newval( 'section', 'param', 1 );

$config = Config::IniFiles->new(
    -import     => $config_file,
    -allowempty => 1,
    -file       => $filename
);

# TEST
ok( $config->val( 'section', 'param' ), 'Configuration is imported' );

$config->ReadConfig;

# TEST
ok( $config->val( 'section', 'param' ), 'Configuration is still imported' );
