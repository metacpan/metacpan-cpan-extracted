package Consul::Simple::Test;
$Consul::Simple::Test::VERSION = '1.142430';
my $consul_data_dir = '/tmp/consul_data_' . $$;
our $consul_daemon_pid;

sub init_tests {
    my $can_test = init_server();
    if(not $can_test) {
        print STDERR "#full tests can only be run on Linux or MacOS(Darwin) x86_64.  Skipping all.\n";
        exit 0;
    }
}

sub init_server {
    my $uname = `uname 2>&1`;
    chomp $uname;
    if($uname ne 'Linux' and $uname ne 'Darwin') {
        return 0;
    }
    my $arch = `uname -m 2>&1`;
    chomp $arch;
    if($arch ne 'x86_64') {
        return 0;
    }
    mkdir $consul_data_dir || return 0;
    my $new_pid = fork;
    return 0 if not defined $new_pid; #fork failed. (!??)
    if(not $new_pid) { #child
        my $consul_bin = 'testbin/consul_' . $uname . '_' . $arch;
        $consul_bin = '../' . $consul_bin if $ENV{PWD} and $ENV{PWD} =~ /\/t$/;
        my @args = ('agent', '-server', '-bootstrap-expect', '1', '-data-dir', $consul_data_dir, '-log-level', 'err');
        print STDERR "##Ignore WARNING: Bootstrap* and [ERR] agent* output from consul daemon\n";
        exec $consul_bin, @args;
        exit;
    }
    $consul_daemon_pid = $new_pid; #parent
    sleep 3;
    my $ret = `ps -p $consul_daemon_pid > /dev/null 2>&1;echo \$?`;
    chomp $ret;
    return 0 unless $ret eq '0';
    return 1;
}

END {
    kill 9, $consul_daemon_pid if $consul_daemon_pid;
    sleep 1;
    system "rm -rf $consul_data_dir > /dev/null 2>&1";
    system 'rm -rf /tmp/consul*';
};

1;
