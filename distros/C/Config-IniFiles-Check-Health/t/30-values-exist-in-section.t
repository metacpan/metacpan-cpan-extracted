#!env perl
use strict;
use warnings;
use Test::More;
use lib './lib';
use Config::IniFiles::Check::Health;
use Test::Exception;

use_ok("Config::IniFiles");

my $ini_fn = "t/testdata/30-values-exist-in-section.ini";
ok( -e ($ini_fn), "inifile '$ini_fn' exists" );

my $ini_obj = Config::IniFiles->new( -file => $ini_fn );
is( ref($ini_obj), "Config::IniFiles", "create Config::IniFiles-Object" );

my $obj;

lives_ok {
    $obj = Config::IniFiles::Check::Health->new(
        {
            logger  => undef,
            ini_obj => $ini_obj
        }
    );
}
"ini_obj is good object -> live, logger is undef -> live";

lives_ok {
    $obj->check_inifile_for_values(
        {
            values_must_exist => [
                { section => 'berlin', varname => 'dogs' },
            ]
        }
    );
}
"dogs mentioned, but no cats are mentioned";

lives_ok {
    $obj->check_inifile_for_values(
        {
            values_must_exist => [
                { section => 'berlin', varname => 'dogs' },
                { section => 'berlin', varname => 'cats' },
            ]
        }
    );
}
"dogs and cats, but no birds are mentioned";

dies_ok {
    $obj->check_inifile_for_values(
        {
            values_must_exist => [
                { section => 'berlin', varname => 'dogs' },
                { section => 'berlin', varname => 'cats' },
                { section => 'berlin', varname => 'birds' },
            ]
        }
    );
}
"dogs and cats, but no birds exist";

done_testing();

