#!/usr/bin/perl
#
# ex4: advanced use of Config::Validator with Getopt::Long and Config::General
#
# this is somehow a merge of ex2 and ex3
#
# $ perl ex4.pl -h
# $ perl ex4.pl -d -d --src-host foo --dst-host bar --dst-port 80
# $ perl ex4.pl --src-host foo --config ex4-cfg1
#

use strict;
use warnings;
use Config::General qw(ParseConfig);
use Config::Validator qw(treeify);
use Data::Dumper qw(Dumper);
use Getopt::Long qw(GetOptions);

our($Validator, @Options, %Config, @Tmp, %Tmp);

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

$Validator = Config::Validator->new(
    svc => {
        type => "struct",
        fields => {
            port => {
                type => "integer",
                min => 0,
                max => 65535,
                optional => "true",
            },
            host => { type => "string", match => qr/^[\w\-\.]+$/ },
        },
    },
    cfg => {
        type => "struct",
        fields => {
            debug  => { type => "integer", optional => "true" },
            dst    => { type => "valid(svc)" },
            src    => { type => "valid(svc)" },
        },
    },
);

@Options = sort($Validator->options("cfg"), "config=s", "help|h|?");

foreach my $option (@Options) {
    $option =~ s/^debug.*$/debug|d+/;
}

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
    treeify(\%Config);
    # parse again the command line options using defaults read from the file
    @ARGV = @Tmp;
    GetOptions(\%Config, @Options) or die;
    delete($Config{config});
} else {
    %Config = %Tmp;
}

treeify(\%Config);
$Validator->validate(\%Config, "cfg");

print(Dumper(\%Config));
