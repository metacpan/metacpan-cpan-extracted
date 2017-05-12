package Brackup::BackupStats;
use strict;

sub new {
    my $class = shift;
    my %opts = @_;
    croak("Unknown options: " . join(', ', keys %opts)) if %opts;

    my $self = {
        start_time => time,
        ts => Brackup::BackupStats::Data->new,
        data => Brackup::BackupStats::Data->new,
    };

    if (eval { require GTop }) {
        $self->{gtop} = GTop->new;
        $self->{gtop_max} = 0;
        $self->{gtop_data} = Brackup::BackupStats::Data->new;
    }

    return bless $self, $class;
}

sub print {
    my $self = shift;
    my $stats_file = shift;
  
    # Reset iterators
    $self->reset;

    my $fh;
    if ($stats_file) {
        open $fh, ">$stats_file" 
            or die "Failed to open stats file '$stats_file': $!";
    }
    else {
        $fh = *STDOUT;
    }

    my $hash = $stats_file ? '' : '# ';
    print $fh "${hash}BACKUPS STATS:\n";
    print $fh "${hash}\n";

    my $start_time = $self->{start_time};
    my $end_time = time;
    my $fmt = "${hash}%-37s %s\n";
    printf $fh $fmt, 'Start Time:',       scalar localtime $start_time;
    printf $fh $fmt, 'End Time:',         scalar localtime $end_time;

    my $ts = $start_time;
    while (my ($label, $next_ts) = $self->{ts}->next) {
        printf $fh $fmt, "$label Time:", ($next_ts - $ts) . 's';
        $ts = $next_ts;
    }
    printf $fh $fmt, 'Total Run Time:',   ($end_time - $start_time) . 's';
    print $fh "${hash}\n";

    if (my $gtop_data = $self->{gtop_data}) {
        while (my ($label, $size) = $gtop_data->next) {
            printf $fh $fmt, 
                "Post $label Memory Usage:", sprintf('%0.1f MB', $size / (1024 * 1024));
        }
        printf $fh $fmt, 
            'Peak Memory Usage:', sprintf('%0.1f MB', $self->{gtop_max} / (1024 * 1024));
        print $fh "${hash}\n";
    } else {
        print $fh "${hash}GTop not installed, memory usage stats disabled\n";
        print $fh "${hash}\n";
    }

    my $data = $self->{data};
    while (my ($key, $value) = $data->next) {
        printf $fh $fmt, $key, $value;
    }
    print $fh "\n" if $stats_file;
}

# Check/record max memory usage
sub check_maxmem {
    my $self = shift;
    return unless $self->{gtop};
    my $mem = $self->{gtop}->proc_mem($$)->size;
    $self->{gtop_max} = $mem if $mem > $self->{gtop_max};
}

# Record current time (and memory, if applicable) against $label
sub timestamp {
    my ($self, $label) = @_;
    $self->{ts}->set($label => time);
    return unless $self->{gtop};
    $self->{gtop_data}->set($label => $self->{gtop}->proc_mem($$)->size);
    $self->check_maxmem;
}

sub set {
    my $self = shift;
    $self->{data}->set(shift, shift) while @_ >= 2;
}

sub reset {
    my $self = shift;
    $self->{ts}->reset;
    $self->{data}->reset;
    $self->{gtop_data}->reset if $self->{gtop_data};
}

sub note_stored_chunk {
    my ($self, $chunk) = @_;
}

package Brackup::BackupStats::Data;

sub new {
    my $class = shift;
    return bless {
        index => 0,
        list => [],       # ordered list of data keys
        data => {},
    }, $class;
}

sub set {
    my ($self, $key, $value) = @_;
    die "data key '$key' exists" if exists $self->{data}->{$key};
    push @{$self->{list}}, $key;
    $self->{data}->{$key} = $value;
}

# Iterator interface, returning ($key, $value)
sub next {
    my $self = shift;
    return () unless $self->{index} <= $#{$self->{list}};
    my $key = $self->{list}->[$self->{index}++];
    return ($key, $self->{data}->{$key});
}

# Reset/rewind iterator
sub reset {
    my $self = shift;
    $self->{index} = 0;
}

1;

# vim:sw=4
