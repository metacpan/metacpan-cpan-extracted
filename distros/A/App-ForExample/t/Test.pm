package t::Test;

use strict;
use warnings;

use vars qw/@ISA @EXPORT/;
@EXPORT = qw/ run_for_example run_for_example_eg stdout_same_as scratch /;
@ISA = qw/ Exporter /;

use Test::Most;
use Test::Output;

use App::ForExample;
use Path::Class;
use Directory::Scratch;

sub run_for_example (@) {
    App::ForExample->new->run([ @_ ]);
}

sub run_for_example_eg (@) {
    run_for_example @_, qw# --home /home/rob/develop/App-ForExample/Eg --hostname eg.localhost --package Eg #
}

sub stdout_same_as (&$;$) {
    my $run = shift;
    my $file = file( split m/\/+/, shift );
    my $explain = shift;

    my $content = scalar $file->slurp;

    unlike $content, qr/\bUsage: for-example\b/ unless $file =~ m/help/;
    cmp_ok length $content, '>=', 100;
    stdout_is { $run->() } $content, $explain;
}

my $scratch;
sub scratch {
    return $scratch ||= Directory::Scratch->new;
}

1;
