package App::RunCron::Reporter::Fluentd;
use strict;
use warnings;
use utf8;

use Fluent::Logger;

use parent 'App::RunCron::Reporter';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    my $tag = delete $args{tag} || 'runcron';

    bless {
        args => \%args,
        tag  => $tag,
    }, $class;
}

sub run {
    my ($self, $runcron) = @_;

    my $logger = Fluent::Logger->new(%{ $self->{args} });
    $logger->post($self->{tag} => $runcron->report_data);
}

1;
