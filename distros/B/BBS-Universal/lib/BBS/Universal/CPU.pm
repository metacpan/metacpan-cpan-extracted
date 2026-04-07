package BBS::Universal::CPU;
BEGIN { our $VERSION = '0.002'; }

sub cpu_initialize {
    my $self = shift;
    $self->{'debug'}->DEBUG(['Start CPU Initialize']);
    $self->{'debug'}->DEBUG(['END CPU Initialize']);
    return ($self);
} ## end sub cpu_initialize

sub cpu_info {
    my $self = shift;

    $self->{'debug'}->DEBUG(['Start CPU Info']);
    my $cpu         = $self->cpu_identify();
    my $cpu_cores   = scalar(@{ $cpu->{'CPU'} });
    my $cpu_threads = (exists($cpu->{'CPU'}->[0]->{'logical processors'})) ? $cpu->{'CPU'}->[0]->{'logical processors'} : 'No Hyperthreading';
    my $cpu_bits    = $cpu->{'HARDWARE'}->{'Bits'} + 0;
    my $identity    = $cpu->{'CPU'}->[0]->{'model name'};

    chomp(my $load_average = `cat /proc/loadavg`);

    my $speed = $cpu->{'CPU'}->[0]->{'cpu MHz'} if (exists($cpu->{'CPU'}->[0]->{'cpu MHz'}));

    unless (defined($speed)) {
        chomp($speed = `cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq`);
        $speed /= 1000;
    }

    if ($speed > 999.999) {    # GHz
        $speed = sprintf('%.02f GHz', ($speed / 1000));
    } elsif ($speed > 0) {     # MHz
        $speed = sprintf('%.02f MHz', $speed);
    } else {
        $speed = 'Unknown';
    }
    my $response = {
        'CPU IDENTITY' => $identity,
        'CPU SPEED'    => $speed,
        'CPU CORES'    => $cpu_cores,
        'CPU THREADS'  => $cpu_threads,
        'CPU BITS'     => $cpu_bits,
        'CPU LOAD'     => $load_average,
        'HARDWARE'     => $cpu->{'HARDWARE'}->{'Hardware'},
    };
    $self->{'debug'}->DEBUGMAX([$response]);
    $self->{'debug'}->DEBUG(['End CPU Info']);
    return ($response);
} ## end sub cpu_info

sub cpu_identify {
    my $self = shift;

    return ($self->{'CPUINFO'}) if (exists($self->{'CPUINFO'}));
    $self->{'debug'}->DEBUG(['Start CPU Identity']);
    open(my $CPU, '<', '/proc/cpuinfo');
    chomp(my @cpuinfo = <$CPU>);
    close($CPU);
    $self->{'CPUINFO'} = \@cpuinfo;

    my $cpu_identity;
    my $index = 0;
    chomp(my $bits = `getconf LONG_BIT`);
    my $hardware = { 'Hardware' => 'Unknown', 'Bits' => $bits };
    foreach my $line (@cpuinfo) {
        if ($line ne '') {
            my ($name, $val) = split(/: /, $line);
            $name = $self->trim($name);
            if ($name =~ /^(Hardware|Revision|Serial)/i) {
                $hardware->{$name} = $val;
            } else {
                if ($name eq 'processor') {
                    $index = $val;
                } else {
                    $cpu_identity->[$index]->{$name} = $val;
                }
            } ## end else [ if ($name =~ /^(Hardware|Revision|Serial)/i)]
        } ## end if ($line ne '')
    } ## end foreach my $line (@cpuinfo)
    my $response = {
        'CPU'      => $cpu_identity,
        'HARDWARE' => $hardware,
    };
    if (-e '/usr/bin/lscpu' || -e 'usr/local/bin/lscpu') {
        my $lscpu_short = `lscpu --extended=cpu,core,online,minmhz,maxmhz`;
        chomp(my $lscpu_version = `lscpu -V`);
        $lscpu_version =~ s/^lscpu from util-linux (\d+)\.(\d+)\.(\d+)/$1.$2/;
        my $lscpu_long = ($lscpu_version >= 2.38) ? `lscpu --hierarchic` : `lscpu`;
        $response->{'lscpu'}->{'short'} = $lscpu_short;
        $response->{'lscpu'}->{'long'}  = $lscpu_long;
    } ## end if (-e '/usr/bin/lscpu'...)
    $self->{'CPUINFO'} = $response;    # Cache this stuff
    $self->{'debug'}->DEBUGMAX([$response]);
    $self->{'debug'}->DEBUG(['End CPU Identity']);
    return ($response);
} ## end sub cpu_identify
1;
