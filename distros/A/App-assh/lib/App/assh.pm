package App::assh;
BEGIN {
  $App::assh::AUTHORITY = 'cpan:DBR';
}
{
  $App::assh::VERSION = '1.1.2';
}

#  PODNAME: App::assh
# ABSTRACT: A wrapper around autossh.

use Moo;
use true;
use 5.010;
use strict;
use warnings;
use methods-invoker;
use MooX::Options skip_options => [qw<os cores>];
use MooX::Types::MooseLike::Base qw(:all);

has hosts => (
    is => 'lazy',
    isa => HashRef,
);

has ports => (
    is => 'lazy',
    isa => HashRef,
);

has ssh_config_file => (
    is => 'ro',
    isa => Str,
    default => sub {
        "$ENV{HOME}/.ssh/config"
    },
);

has ports_config_file => (
    is => 'ro',
    isa => Str,
    default => sub {
        "$ENV{HOME}/.autossh_rc"
    },
);

method _build_hosts {
    $_ = do { local(@ARGV, $/) = $->ssh_config_file; <>; };
    s/\s+/ /g;

    my $ret = {};
    while (m<Host\s(.+?)\sHostName\s(.+?)\sUser\s(.+?)\s>xg) {
        $ret->{$1} = { NAME => $2, USER => $3 }
    }

    return $ret;
}

method _build_ports {
    open my $portsfile, "<", $->ports_config_file or die $!;
    my $h = {};
    while(<$portsfile>) {
        chomp;
        my ($host, $port) = split;
        $h->{$host} = $port;
    }
    return $h
}

method run {
    my $host = shift;

    not defined $host and do {
        say for keys %{$->hosts};
    };

    defined $->hosts->{$host} and do {
        $->autossh_exec($host);
    };
}

method autossh_exec {
    my $host = shift;
    exec 'AUTOPOLL=5 autossh -M ' . $->ports->{$host} . ' ' . $->hosts->{$host}{USER} . '@' . $->hosts->{$host}{NAME}
}

no Moo;

__END__

=pod

=encoding utf-8

=head1 NAME

App::assh - A wrapper around autossh.

=head1 VERSION

version 1.1.2

=head1 SYNOPSIS

A wrapper around autossh.

=for Pod::Coverage ports_config_file  ssh_config_file

=head1 MOTIVATION

`autossh` is a nifty little ssh-keepalive-connection-holder.

Passing in the ports for the keepalive can be clumsy though: `assh` helps you to avoid that.

=head1 USAGE

     assh
     assh HOSTNAME

=head1 REQUIREMENTS

First, you will need a file `~E<sol>.sshE<sol>config`. It looks something like this:

     Host foo
     HostName bar.example.com
     User baz

With this, you can already leverage standard `ssh` connections:

     ssh foo

... instead of

     ssh baz@bar.example.com

Next, generate a file `~E<sol>.autossh_rc` with the following format:

     foo 12345

... with the first entry on the line representing your `Host` in `~E<sol>.sshE<sol>config` and the second item on the line being the port over which to keep the autossh connection alive.

Now you can permanently connect using:

     assh foo

... with the connection kept alive across network switches and computer shutdowns.

=head1 ATTRIBUTES

=over

=item *

hosts: HashRef holding the values HOSTNAME =E<gt> AUTOSSH_PORT

=back

=over

=item *

ports: HashRef holding the values HOSTNAME =E<gt> C<<< USER => USERNAME, HOST => HOSTNAME >>>

=back

=over

=item *

ssh_config_file: The path to the ssh config file. Default: `~E<sol>.sshE<sol>config`

=back

=over

=item *

ports_config_file: The path to the ports config (this is what I have chosen): `~E<sol>.autossh_rc`

=back

=head1 SEE ALSO

=over

=item *

autossh: E<lt>http:E<sol>E<sol>www.harding.motd.caE<sol>autosshE<sol>E<gt>

=back

=head1 AUTHOR

DBR <dbr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DBR.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut
