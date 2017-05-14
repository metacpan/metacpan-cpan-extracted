package App::GSD;
# ABSTRACT: boost productivity by blocking distracting websites

use strict;
use warnings;
use autodie qw(:all); # including system
use Carp;
use File::Slurp qw(read_file write_file);

my $DEFAULT_HOSTS = '/etc/hosts';

my $START_TOKEN = '## start-gsd';
my $END_TOKEN = '## end-gsd';

sub new {
    my ($class, $config) = @_;
    my $self = bless $config, $class;
    $self->{hosts_file} ||= $DEFAULT_HOSTS;
    $self->{block} ||= [];
    if (exists $self->{network_command} && !ref $self->{network_command}) {
        # Convert single string to arrayref
        $self->{network_command} = [ $self->{network_command} ];
    }

    return $self;
}

sub work {
    my $self = shift;
    my $contents = read_file($self->hosts_file);
    if ($contents =~ /^$START_TOKEN$/ && $contents =~ qr/^$END_TOKEN$/) {
        croak "Work mode already set";
    }

    open my $fh, '>>', $self->hosts_file;
    print {$fh} $START_TOKEN, "\n";
    for my $site ($self->blocklist) {
        print {$fh} "127.0.0.1\t", $site, "\n";
    }
    print {$fh} $END_TOKEN, "\n";

    $self->_flush_dns;
}

sub play {
    my $self = shift;

    my $contents = read_file($self->hosts_file);
    $contents =~ s/\Q$START_TOKEN\E.*\Q$END_TOKEN\E\n//s;
    write_file($self->hosts_file, $contents);

    $self->_flush_dns;
}

# Return what App::GSD thinks the hosts file is
sub hosts_file {
    my $self = shift;
    return $self->{hosts_file};
}

# Return network_command as 'undef' (if not specified)
# or arrayref
sub network_command {
    my $self = shift;
    return $self->{network_command};
}

# List of sites to be blocked
sub blocklist {
    my $self = shift;
    my $block = $self->{block};
    return map { ($_, "www.$_") } @$block;
}

# Determine the best method of flushing DNS, and execute it
sub _flush_dns {
    my $self = shift;
    my $netcmd = $self->network_command;

    if (defined $netcmd && not @$netcmd) {
        # Don't do any network-related stuff
        return;
    }
    else {
        $netcmd ||= $self->_platform_network_command;
        system(@$netcmd);

        if ($^O eq 'linux') {
            $self->_flush_nscd;
        }
    }
}

# Return best method of flushing DNS for the target platform
sub _platform_network_command {
    my $self = shift;
    my $platform = $^O;
    my $cmd;
    if ($platform eq 'linux') {
        $cmd = $self->_flush_dns_linux;
    }
    elsif ($platform eq 'darwin') {
        $cmd = ['dscacheutil', '-flushcache'];
    }
    else {
        croak "don't know how to flush DNS for platform '$platform'";
    }
    return $cmd;
}

# Return DNS flush command for Linux. It needs to support a few scenarios:
#   Ubuntu e.g. '/etc/init.d/networking restart' (or via upstart: 'restart networking')
#   Arch using network module: '/etc/rc.d/network restart'
#   Arch using NetworkManager or wicd: '/etc/rc.d/$foo restart'
sub _flush_dns_linux {
    my $self = shift;
    my $cmd;

    if (-x '/usr/sbin/rc.d') {
        # Try to guess the user's preferred network module by looking for AUTO
        my $services = `/usr/sbin/rc.d list | fgrep AUTO`;
        for my $service (qw(networkmanager wicd network)) {
            if ($services =~ /^\[STARTED\]\[AUTO\] $service$/m) {
                $cmd = ['/usr/sbin/rc.d', 'restart', $service];
                last;
            }
        }
        if (!defined $cmd) {
            croak "You appear to be using rc.d but I can't figure out which network module you are using.";
        }
    }
    elsif (-x '/etc/init.d/networking') {
        $cmd = ['/etc/init.d/networking', 'restart'];
    }
    elsif (-x '/etc/init.d/network') {
        $cmd = ['/etc/init.d/network', 'restart'];
    }
    else {
        croak "I can't figure out how to restart your network.";
    }

    return $cmd;
}

# Try to invalidate nscd/unscd cache if present
sub _flush_nscd {
    my $self = shift;
    return if $^O ne 'linux';
    for my $nscd (qw(nscd unscd)) {
        # Ignore errors if the daemon is installed, but not running
        CORE::system("/usr/sbin/$nscd", '-i', 'hosts');
    }
    return;
}

1;



=pod

=head1 NAME

App::GSD - boost productivity by blocking distracting websites

=head1 VERSION

version 0.4

=head1 SYNOPSIS

 use App::GSD;
 my $app = App:GSD->new({ block => [qw(foo.com bar.com baz.com)] });
 $app->work; # sites are now blocked
 $app->play; # unblocked

=head1 METHODS

=head2 new ( \%args )

The following arguments are accepted:

=over

=item block

An arrayref of hostnames to block, without a 'www.' prefix (if
present) as these will be blocked automatically.

=item hosts_file

Path to the hosts file (e.g. '/etc/hosts'), overriding the
module's guess based on current operating system.

=item network_command

A reference to an array passable to C<system()> that will restart
the network, e.g.

 ['/etc/init.d/network', 'restart']

=back

=head2 work

Set work mode - block the sites specified.

=head2 play

Set play mode - unblock sites.

=head2 blocklist

Return the blocklist, with 'www.' and non-'www.' versions included.

=head2 network_command

Return user-specified network command as arrayref, or undef if
none specified.

=head2 hosts_file

Return path to hosts file.

=head1 METHODS

=head1 AUTHOR

Richard Harris <RJH@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Richard Harris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

