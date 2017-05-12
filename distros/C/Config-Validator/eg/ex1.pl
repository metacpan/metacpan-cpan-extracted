#!/usr/bin/perl
#
# ex1: simple use of Config::Validator with Getopt::Long
#
# $ perl ex1.pl -h
# $ perl ex1.pl --src-host foo --dst-host bar
#

use strict;
use warnings;
use Config::Validator qw();
use Data::Dumper qw(Dumper);
use Getopt::Long qw(GetOptions);

our($Validator, @Options, %Config);

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

$Validator = Config::Validator->new({
    type => "struct",
    fields => {
        "debug" => { type => "integer", optional => "true" },
        "dst-port" => {
            type => "integer",
            min => 0,
            max => 65535,
            optional => "true",
        },
        "dst-host" => { type => "string", match => qr/^[\w\-\.]+$/ },
        "src-port" => {
            type => "integer",
            min => 0,
            max => 65535,
            optional => "true",
        },
        "src-host" => { type => "string", match => qr/^[\w\-\.]+$/ },
    },
});

@Options = sort($Validator->options(), "help|h|?");

GetOptions(\%Config, @Options) or die;

if ($Config{help}) {
    printf("Options:%s\n", join("\n  --", "", @Options));
    exit(0);
}

$Validator->validate(\%Config);

print(Dumper(\%Config));
