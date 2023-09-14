GetOptions(
    'help|h|?'       => sub { pod2usage(1) },
    'serial-dev|d=s' => \my $opt_serial_dev= '/dev/delorean',
    'socket|S=s'     => \my $opt_socket= '/run/uctl-daemon.sock',
) or pod2usage(2);
