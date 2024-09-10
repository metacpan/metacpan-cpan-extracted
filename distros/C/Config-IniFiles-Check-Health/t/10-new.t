#!env perl
use strict;
use warnings;
use Test::More;
use lib './lib';
use Config::IniFiles::Check::Health;
use Test::Exception;

use_ok("Config::IniFiles");

my $ini_fn = "t/testdata/10-new.ini";
ok( -e ($ini_fn), "inifile '$ini_fn' exists" );

my $ini_obj = Config::IniFiles->new( -file => $ini_fn );
is( ref($ini_obj), "Config::IniFiles", "create Config::IniFiles-Object" );

my $obj;
dies_ok {
    $obj = Config::IniFiles::Check::Health->new(
        {
            logger  => undef,
            ini_obj => undef
        }
    );
} "logger=undef, ini_obj=undef -> die";

lives_ok {
    $obj = Config::IniFiles::Check::Health->new(
        {
            logger  => undef,
            ini_obj => $ini_obj
        }
    );
}
"ini_obj is good object -> live, logger is undef -> live";

done_testing();

