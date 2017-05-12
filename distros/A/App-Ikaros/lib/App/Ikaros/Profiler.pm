package App::Ikaros::Profiler;
use strict;
use warnings;
use Data::Dumper;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub add_profile {
    my ($self, $host, $prove_data) = @_;

    my $total_time = 0;
    my @test_names = keys %{$prove_data->{tests}};
    my %each_test_status;
    foreach my $name (@test_names) {
        my $time = $prove_data->{tests}{$name}{elapsed};
        $each_test_status{$name} = {
            name            => $name,
            occupation_rate => 0,
            time            => $time
        };
        $total_time += $time;
    }

    foreach my $name (keys %each_test_status) {
        my $rank = 0;
        my $status = $each_test_status{$name};
        $status->{occupation_rate} = $status->{time} / $total_time * 100;
    }

    $self->add_rank(\%each_test_status);

    $self->{profiled_data}{$host->hostname . $host->workdir} = +{
        name       => sprintf('[%s] : %s', $host->hostname, $host->workdir),
        total_time => $total_time,
        each_test_status => \%each_test_status
    }
}

sub setup {
    my ($self) = @_;
    $self->setup_each_test_speed_ranking;
    $self->setup_each_host_speed_ranking;
}

sub add_rank {
    my ($self, $status) = @_;
    my $rank = 0;
    my @sorted_status = reverse sort {
        $a->{time} <=> $b->{time}
    } values %$status;
    $_->{rank} = ++$rank foreach (@sorted_status);
}

sub setup_each_test_speed_ranking {
    my ($self) = @_;
    my %total_status;
    foreach my $each_host_status (values %{$self->{profiled_data}}) {
        my $each_test_status = $each_host_status->{each_test_status};
        $total_status{$_} = $each_test_status->{$_} foreach (keys %$each_test_status);
    }
    my $total_rank = 0;
    my @sorted_status = reverse sort {
        $a->{time} <=> $b->{time}
    } values %total_status;
    $_->{total_rank} = ++$total_rank foreach (@sorted_status);
    $self->{summary}{test_speed_ranking} = [ map {
        +{
            rank => $_->{total_rank},
            name => $_->{name},
            time => $_->{time},
        }
    } @sorted_status ];
}

sub setup_each_host_speed_ranking {
    my ($self) = @_;
    my @sorted_status = reverse sort {
        $a->{total_time} <=> $b->{total_time}
    } values %{$self->{profiled_data}};
    my $total_rank = 0;
    $_->{total_rank} = ++$total_rank foreach (@sorted_status);
    $self->{summary}{host_speed_ranking} = [ map {
        +{
            rank => $_->{total_rank},
            name => $_->{name},
            time => $_->{total_time}
        }
    } @sorted_status ];
}

sub dump {
    my ($self) = @_;
    print Dumper $self;
}

1;
