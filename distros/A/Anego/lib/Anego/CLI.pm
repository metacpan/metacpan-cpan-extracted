package Anego::CLI;
use strict;
use warnings;
use utf8;
use Getopt::Long;
use Module::Load;
use Try::Tiny;

use Anego::Logger;

sub run {
    my ($self, @args) = @_;

    local @ARGV = @args;
    my $parser = Getopt::Long::Parser->new(
        config => [ "no_ignore_case", "pass_through" ],
    );
    $parser->getoptions(
        "config=s" => \$Anego::Config::CONFIG_PATH,
    );

    my @commands = @ARGV;;
    my $command = shift @commands || 'help';
    my $klass = sprintf('Anego::CLI::%s', ucfirst($command));

    try {
        Module::Load::load $klass;
        try {
            $klass->run(@commands);
        } catch {
            errorf("$_\n");
        };
    } catch {
        warnf("Could not find command: %s\n", $command);
        errorf("$_\n") if $_ !~ /^Can't locate Anego/;
        exit 2;
    };
}

1;
