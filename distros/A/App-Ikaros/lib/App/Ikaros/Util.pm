package App::Ikaros::Util;
use strict;
use warnings;
use App::Ikaros::Logger;
use parent 'Exporter';

our @EXPORT_OK = qw/run_command_on_remote/;

sub run_command_on_remote {
    my ($host, $command) = @_;
    my ($stdin, $stdout, $stderr, $pid) = $host->connection->open3({}, $command);
    die 'undefined stdout handle' unless (defined $stdout);
    my $logger = App::Ikaros::Logger->new;
    $logger->add($host->hostname, $stdout, $stderr);
    $logger->logging($host->hostname, $pid);
    waitpid($pid, 0);
}

1;
