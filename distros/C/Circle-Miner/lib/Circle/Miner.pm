package Circle::Miner;

use 5.006;
use strict;
use warnings;
use Circle::Common qw(build_url_template http_json_post http_json_get);
use Mojo::IOLoop::Subprocess;
use File::Spec;
use POSIX ();
use Slurp;
use Carp;
use File::Share ':all';

=head1 NAME

Circle::Miner - The miner module for circle chain sdk.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Circle::Miner example:

    use Circle::Miner;
    use JSON;

    my $miner = Circle::Miner->new();
    my $address = '<your address>';
    my $result = $miner->fetch_my_block($address);
    if ($result->{status} == 200) {
      my $block_header = $result->{blockHeaderHexString};
      my $ip_port = $result->{ipPort};
      my $mined_block = $miner->mine_block($block_header, 2);
      my $result = $miner->post_my_block($address, $mined_block, $ip_port);
      print "post my block result:" . encode_json($result);
    }
    ...

=head1 EXPORT

there are 4 methods for the Circle::Miner module.

=over 4

=item * new  

=item * fetch_my_block

=item * mine_block

=item * post_my_block

=back

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new Circle::Miner object instance.

Parameters:
    None

Returns:
    A new Circle::Miner object instance

Example:
    my $miner = Circle::Miner->new();

=cut

sub new {
    my $class = shift;
    return $class if ref $class;

    return bless {}, $class;
}

=head2 fetch_my_block($address)

Fetches a block for mining based on the provided wallet address.

Parameters:

=over 4

=item * $address - A string representing the wallet address (required)

=back

Returns:
    A hashref containing:

=over 4

=item * status: HTTP status code

=item * data: the data of return

=item * data.blockHeaderHexString: The block header in hex format

=item * data.ipPort: The IP and port of the node

=back

Throws:

=over 4

=item * Croaks if address is not provided

=back

Example:

    my $result = $miner->fetch_my_block('1ABC...');
    if ($result->{status} == 200) {
        # Process the block header
    }


=cut

sub fetch_my_block {
    my $self = shift;
    my ($address) = @_;
    if (!$address) {
        croak "address must be provided!";
    }
    my $url = build_url_template(
        'wallet',
        'fetchMyBlock',
        {
            address => $address
        }
    );
    print "fetch my block url: $url\n";
    return http_json_get($url);
}

sub get_os_arch {
    my $os = $^O;
    if ($os =~ /linux/i) {
        $os = 'linux';
    } elsif ($os =~ /darwin/i) {
        $os = 'mac';
    } elsif ($os =~ /win/i) {
        $os = 'windows';
    }

    my $arch = get_arch_by_config((POSIX::uname)[4]);
    carp "get arch by config: $arch";
    return ($os, $arch);
}

sub get_arch_by_config {
    my ($arch) = @_;
    carp "get arch by config parameter: $arch";
    
    # 更完整的架构匹配
    if ($arch =~ /^(?:x86_64|amd64|x64|intel64)/i) {
        return 'x86_64';
    } elsif ($arch =~ /^(?:i[3456]86|x86|ia32)/i) {
        return 'x86';
    } elsif ($arch =~ /^(?:arm64|aarch64|arm64e)/i) {
        return 'arm64';
    } elsif ($arch =~ /^(?:arm|armv[1-7])/i) {
        return 'arm';
    }
    
    # 如果无法识别架构，返回原始值或抛出错误
    carp "Warning: Unknown architecture: $arch";
    return $arch;
}

=head2 mine_block($header_hex, $thread_count)

Mines a block using the provided block header hex string with multi-threading support.

Parameters:

=over 4

=item * $header_hex   - A hex string representing the block header (required)

=item * $thread_count - Number of threads to use for mining (optional, defaults to 1)

=back

Returns:
    The mined block data read from './mined.txt'

Throws:
    Croaks if header_hex is not provided or invalid

Example:

    my $mined_block = $miner->mine_block($block_header, 2);

Notes:

=over 4

=item * Spawns multiple processes based on thread_count

=item * Each process mines a different nonce range

=item * When first process finds solution, others are terminated

=item * Uses external mining executable (ccm) based on OS/architecture

=back

=cut

sub mine_block {
    my $self = shift;
    my ($header_hex, $thread_count) = @_;
    $thread_count //= 1;
    if (!$header_hex) {
        croak "header_hex is required";
    }
    if ($header_hex !~ /^[0-9a-fA-F]+$/) {
        croak "header_hex is invalid";
    }

    my $ranges = $self->make_ranges($thread_count);
    my ($volume, $directory, $file) = File::Spec->splitpath(__FILE__);
    $directory =~s/\/$//;
    my ($os, $arch) = get_os_arch();
    my $config_path;
    if ($os eq 'windows') {
        $config_path = dist_file('Circle-Miner', "$os/$arch/ccm.exe");
    } else {
        $config_path = dist_file('Circle-Miner', "$os/$arch/ccm");
    }
    my $cmd_path = $config_path;
    print "cmd path: $cmd_path\n";
    my @pids;
    foreach my $range (@{$ranges}) {
        my $command = "$cmd_path $range->[0]-$range->[1] $header_hex";
        my $pid = fork;
        if ($pid) {
            push @pids, $pid;
            next;    # Parent goes to next server.
        }
        die "fork failed: $!" unless defined $pid;

        print "run command: $command\n";
        my $result = `$command`;
        print "mined result: $result\n";
        exit;    # Ends the child process.
    }
    my $first_pid = wait();
    # print "found first pid: $first_pid\n";
    if ($first_pid > 0) {
        my @undone_pids = grep { $_ != $first_pid } @pids;
        # print "undone pids:" . encode_json(\@undone_pids) . "\n";
        for my $child_pid (@undone_pids) {
            kill 'SIGTERM',  $child_pid;
            # print "kill pid: $child_pid\n";
        }
    }

    if (-e "./mined.txt") {
        my $content = slurp("./mined.txt");
        my @lines = split /\n/, $content;
        return $lines[0];
    }
    return "";
}

sub make_ranges {
    my $self = shift;
    my ($thread_count) = @_;
    $thread_count //= 1;
    if ($thread_count == 0) {
        $thread_count = 1;
    }
    my $span = int(100 / $thread_count);
    my @ranges;
    for (my $index = 0; $index < $thread_count; $index++) {
        my $start = $span * $index;
        my $end = ($index+1) * $span;
        if ($index + 1 == $thread_count) {
            $end = 100;
        }
        push @ranges, [$start, $end];
    }
    return \@ranges;
}

=head2 post_my_block($address, $header_hex, $ip_port)

Posts a mined block to the network.

Parameters:

=over 4

=item * $address    - The wallet address (required, must be 34 chars and start with '1')

=item * $header_hex - The mined block header in hex format (required)

=item * $ip_port    - The IP and port of the node to post to (required)

=back

Returns:

=over

=item * status: HTTP status code

=item * data: Response data from the server

=back

Throws:
    Croaks if:

=over 4

=item * Any required parameter is missing

=item * Address format is invalid (length != 34 or doesn't start with '1')

=back

Example:

    my $result = $miner->post_my_block('1ABC...', $mined_block, '0c50c941bb6856b36216c4df1ce5c96815d02c5d5c33ff64c55471f3f1ea1792');
    if ($result->{status} == 200) {
        # Block successfully posted
    }

=cut

sub post_my_block {
    my $self = shift;
    my ( $address, $header_hex, $channelId ) = @_;
    if (!$address || !$header_hex || !$channelId) {
        croak "address header_hex and channelId must be non-empty!";
    }
    if (length($address) != 34 || substr($address, 0, 1) ne "1") {
        croak "address is invalid";
    }
    my $url = build_url_template( 'wallet', 'postMyBlock' );
    return http_json_post(
        $url,
        {
            address              => $address,
            channelId            => $channelId,
            blockHeaderHexString => $header_hex
        }
    );
}

=head1 AUTHOR

charles li, C<< <lidh04 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-circle-miner at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Circle-Miner>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Circle::Miner


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Circle-Miner>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Circle-Miner>

=item * Search CPAN

L<https://metacpan.org/release/Circle-Miner>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by charles li.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Circle::Miner
