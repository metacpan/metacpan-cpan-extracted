#!/usr/bin/perl
#
# ex5: use of Config::Validator's boolean with Getopt::Long and Config::General
#
# note that boolean values can in fact be: undef (i.e. not set), true or false
#
# $ perl ex5.pl -h
# $ perl ex5.pl --flag2 --no-flag3
# $ perl ex5.pl --flag2 --no-flag1 --config ex5-cfg1
#

use strict;
use warnings;
use Config::General qw(ParseConfig);
use Config::Validator qw(is_true is_false);
use Data::Dumper qw(Dumper);
use Getopt::Long qw(GetOptions);

our($Validator, @Options, %Config, @Tmp, %Tmp);

sub clean ($$$$@) {
    my($valid, $schema, $type, $data, @path) = @_;

    return(1) unless $type eq "boolean";
    return(0) if not defined($data) or is_true($data) or is_false($data);
    if ($data eq "0") {
        $_[3] = "false";
    } elsif ($data eq "1") {
        $_[3] = "true";
    }
    return(0);
}

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

$Validator = Config::Validator->new({
    type => "struct",
    fields => {
        flag1 => { type => "boolean", optional => "true" },
        flag2 => { type => "boolean", optional => "true" },
        flag3 => { type => "boolean", optional => "true" },
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

# third step: transform the Getopt::Long boolean values (0 or 1) into true or false

$Validator->traverse(\&clean, \%Config);

$Validator->validate(\%Config);

print(Dumper(\%Config));
