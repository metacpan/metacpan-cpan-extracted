#!env perl
use strict;
use warnings;
use Test::More;
use lib './lib';
use Config::IniFiles::Check::Health;
use Test::Exception;

use_ok("Config::IniFiles");

my $ini_fn = "t/testdata/20-doubleval.ini";
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

dies_ok {
    $obj->check_for_duplicate_vars_in_one_section({
        section => 'berlin'
    });
}
"duplicate var -> dies";

done_testing();

