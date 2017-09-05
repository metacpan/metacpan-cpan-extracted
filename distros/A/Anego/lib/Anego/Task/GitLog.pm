package Anego::Task::GitLog;
use strict;
use warnings;
use utf8;

use Anego::Config;
use Anego::Git;
use Anego::Logger;

sub fetch {
    my $config = Anego::Config->load;
    my @revs = map { +{
        hash    => $_->[0],
        message => $_->[1],
    } } map {
        [ split /\t/, $_ ]
    } git_log("--pretty=format:%h\t%s", $config->schema_path);
    return \@revs;
}

1;
