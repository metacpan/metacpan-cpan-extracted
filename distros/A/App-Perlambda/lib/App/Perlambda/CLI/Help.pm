package App::Perlambda::CLI::Help;

use strict;
use warnings;
use utf8;

sub run {
    my ($self, @args) = @_;

    my $module = $args[0] ? ( "App::Perlambda::CLI::" . ucfirst $args[0] ) : "App::Perlambda";
    system "perldoc", $module;
}

1;

