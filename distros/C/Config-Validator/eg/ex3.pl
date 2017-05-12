#!/usr/bin/perl
#
# ex3: simple use of Config::Validator with Getopt::Long and Config::General
#
# compared to ex1:
#  - the --config option has been added
#  - configuration can come both from a file and from the command line
#
# $ perl ex3.pl -h
# $ perl ex3.pl --src-host foo --dst-host bar
# $ perl ex3.pl --src-host foo --config ex3-cfg1
#

use strict;
use warnings;
use Config::General qw(ParseConfig);
use Config::Validator qw();
use Data::Dumper qw(Dumper);
use Getopt::Long qw(GetOptions);

our($Validator, @Options, %Config, @Tmp, %Tmp);

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

@Options = sort($Validator->options(), "config=s", "help|h|?");

# first step: parse the command line options to handle options like --help or --config

@Tmp = @ARGV;
GetOptions(\%Tmp, @Options) or die;
if ($Tmp{help}) {
    printf("Options:%s\n", join("\n  --", "", @Options));
    exit(0);
}

# second step: handle the --config option

if ($Tmp{config}) {
    %Config = ParseConfig(-ConfigFile => $Tmp{config});
    # parse again the command line options using defaults read from the file
    @ARGV = @Tmp;
    GetOptions(\%Config, @Options) or die;
    delete($Config{config});
} else {
    %Config = %Tmp;
}

$Validator->validate(\%Config);

print(Dumper(\%Config));
