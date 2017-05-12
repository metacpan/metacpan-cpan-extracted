package App::RunCron::Announcer::Command;
use strict;
use warnings;
use JSON::PP;

sub new {
    my ($class, $command) = @_;
    $command = ref $command ? $command : [$command];
    bless $command, $class;
}

sub run {
    my ($self, $runner) = @_;

    open my $pipe, '|-', @$self or die $!;
    print $pipe encode_json($runner->announce_data);
    close $pipe;
}

1;
