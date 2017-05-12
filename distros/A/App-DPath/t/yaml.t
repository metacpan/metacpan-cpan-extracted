#! /usr/bin/env perl

use strict;
use warnings;
use Test::More 0.88;

diag qq{

-----------------------------------------------------------------
DON'T PANIC!
Ignore the following YAML parsing errors - that's what we test...
-----------------------------------------------------------------

};

my $program    = "$^X -Ilib bin/dpath";
my $infile     = "t/example.yaml10";

sub dpath_with_yaml_module
{
    my ($module, $like) = @_;

    if ($module) { # skip not installed modules
            eval "require $module";
            if ($@) {
                    diag "Skip '$module' - not installed";
                    return;
            }
    }

    my $yamloption = "";
    $yamloption    = "--yaml-module $module" if $module;

    my $res_yaml_default = `$program -i yaml -o yaml $yamloption / $infile`;
    if ($like) {
            like($res_yaml_default,   qr/Contourscount:/, "-i yaml with '$module' works");
    } else {
            unlike($res_yaml_default, qr/Contourscount:/, "-i yaml with '$module' expectedly fails");
    }
}

my $res_yaml_default = `$program -i yaml -o yaml / $infile`;
unlike($res_yaml_default, qr/Contourscount:/, "yaml default parsing expectedly fails");

dpath_with_yaml_module("",           0); # default internal YAML::Any order
dpath_with_yaml_module("YAML",       0);
dpath_with_yaml_module("YAML::XS",   0);
dpath_with_yaml_module("YAML::Tiny", 0);
dpath_with_yaml_module("YAML::Syck", 1);

done_testing;
