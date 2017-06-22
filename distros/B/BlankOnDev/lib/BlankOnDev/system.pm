package BlankOnDev::system;
use strict;
use warnings FATAL => 'all';

# Import :
use Data::Dumper;
use BlankOnDev::DateTime;
use List::Util qw(max);

# Version :
our $VERSION = '0.1005';

# Subroutine for kill exists process :
# ------------------------------------------------------------------------
sub kill_exists_ps {
    my ($self, $gencfg) = @_;
    my $form_confirm;
    my $curr_timezone = exists $gencfg->{'timezone'} && $gencfg->{'timezone'} ne '' ? $gencfg->{'timezone'} : 'Asia/Makassar';
    my $timestamp = time();
    my $get_dataTime = BlankOnDev::DateTime->get($curr_timezone, $timestamp, {
            'date' => '-',
            'time' => ':',
            'datetime' => ' ',
            'format' => 'DD-MM-YYYY hms'
        });
    my $get_time = $get_dataTime->{'time'};
    my $hour_time = $get_time->{hour};
    my $minutes_time = $get_time->{minute};
    $minutes_time = length $minutes_time == 1 ? '0'.$get_time->{minute} : $get_time->{minute};
    my $time_proccess = "$hour_time:$minutes_time";
    my @ps_list = ();
    my @processes = `ps -ef | grep boidev`;
    @processes = grep(!/grep/, @processes);
#    @processes = grep(!/$time_proccess/, @processes);
    @processes = grep($_ =~ s/\n//g, @processes);
    foreach my $line (@processes)
    {
        if ($line =~ /boidev/) {
            my @list = split(/\s+/, $line);
            push(@ps_list, $list[1]);
        }
    }
    my $curr_pid = max(@ps_list);
    @ps_list = grep(!/$curr_pid/,@ps_list);

    # From Confirm :
    if (scalar(@ps_list) > 0) {
        print "\n";
        print ("There are ", scalar(@ps_list), " boidev is active process. \n");
        print "Do you want to kill that process ? [y or n] ";
        chomp($form_confirm = <STDIN>);
        if ($form_confirm eq 'y' or $form_confirm eq 'Y') {
            kill(9, @ps_list) if (scalar(@ps_list) > 0);
            print ("Kill exists process before : ", scalar(@ps_list));
        }
    }
}
1;