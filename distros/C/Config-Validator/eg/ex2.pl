#!/usr/bin/perl
#
# ex2: advanced use of Config::Validator with Getopt::Long
#
# compared to ex1:
#  - --debug can be repeated (Getopt::Long's "+") and is aliased to -d
#  - named schemas are used to avoid schema duplication
#  - the configuration hash is treeified
#
# $ perl ex2.pl -h
# $ perl ex2.pl -d -d --src-host foo --dst-host bar --dst-port 80
#

use strict;
use warnings;
use Config::Validator qw(treeify);
use Data::Dumper qw(Dumper);
use Getopt::Long qw(GetOptions);

our($Validator, @Options, %Config);

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
            debug => { type => "integer", optional => "true" },
            dst   => { type => "valid(svc)" },
            src   => { type => "valid(svc)" },
        },
    },
);

@Options = sort($Validator->options("cfg"), "help|h|?");

foreach my $option (@Options) {
    $option =~ s/^debug.*$/debug|d+/;
}

GetOptions(\%Config, @Options) or die;

if ($Config{help}) {
    printf("Options:%s\n", join("\n  --", "", @Options));
    exit(0);
}

treeify(\%Config);
$Validator->validate(\%Config, "cfg");

print(Dumper(\%Config));
