package App::RunCron::Reporter::Command;
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

    my $d = $runner->report_data;
    $d->{is_success} = $d->{is_success} ? $JSON::PP::true : $JSON::PP::false;
    print $pipe encode_json($d);
    close $pipe;
}

1;
