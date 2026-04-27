package Stress::Chaos;
use strict;
use warnings;
use Future::AsyncAwait;
use Future::IO;

# Periodic CLIENT KILL controller. Uses the server's view of clients
# (CLIENT LIST) rather than caller-supplied addresses — which broke
# under Docker NAT, where the client's local sockhost (127.0.0.1) does
# not match the address Redis sees (e.g. 192.168.65.1). Filtering by
# the `name=` field picks only stress-harness workload connections;
# everything else (replication, external tools, the controller itself)
# is left alone.

sub new {
    my ($class, %args) = @_;
    return bless {
        controller      => $args{controller},
        name_prefix     => $args{name_prefix}     // 'stress-',
        exclude_name    => $args{exclude_name}    // 'stress-controller',
        interval        => $args{interval}        // 30,
        recovery_window => $args{recovery_window} // 5,
        integrity       => $args{integrity},
        running         => 1,
        kills_issued    => 0,
        last_victim     => undef,
    }, $class;
}

async sub run {
    my ($self) = @_;
    while ($self->{running}) {
        await Future::IO->sleep($self->{interval});
        last unless $self->{running};

        my $list = eval { await $self->{controller}->client('LIST') };
        next unless defined $list && length $list;

        my @candidates;
        for my $line (split /\n/, $list) {
            next unless length $line;
            my %f;
            for my $kv (split /\s+/, $line) {
                my ($k, $v) = split /=/, $kv, 2;
                $f{$k} = $v if defined $k && length $k;
            }
            next unless defined $f{id} && length $f{id};
            next unless defined $f{name} && length $f{name};
            next unless index($f{name}, $self->{name_prefix}) == 0;
            next if $f{name} eq $self->{exclude_name};
            push @candidates, { id => $f{id}, name => $f{name}, addr => $f{addr} };
        }
        next unless @candidates;

        my $pick = $candidates[ int rand @candidates ];
        eval { await $self->{controller}->client('KILL', 'ID', $pick->{id}) };
        $self->{kills_issued}++;
        $self->{last_victim} = $pick->{name};
        $self->{integrity}->enter_chaos_window($self->{recovery_window})
            if $self->{integrity};
    }
    return;
}

sub stop {
    my ($self) = @_;
    $self->{running} = 0;
    return;
}

sub snapshot {
    my ($self) = @_;
    return {
        kills_issued => $self->{kills_issued},
        last_victim  => $self->{last_victim},
    };
}

1;
