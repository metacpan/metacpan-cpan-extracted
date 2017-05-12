package App::Goto2;

use strict;
use warnings;
use 5.10.0;
our $VERSION = '0.04';
use Data::Dumper;

use MooseX::App::Simple qw(Color ConfigHome);

option 'aws' => (
    is => 'ro',
    isa => 'Bool',
    cmd_aliases => ['a'],
    documentation => q/Retrieve AWS EC2 instances instead of using the config file/,
);

option 'list' => (
    is => 'ro',
    isa => 'Bool',
    cmd_aliases => ['l'],
    documentation => q/Just print list of known servers & exit/,
);

option 'verbose' => (
    is => 'ro',
    isa => 'Bool',
    cmd_aliases => ['v'],
    documentation => q/Verbose output/,
);

option 'iterate' => (
    is => 'ro',
    isa => 'Bool',
    cmd_aliases => ['i'],
    documentation => q/Connect to all matching hosts one after the other/,
);

option 'cmd' => (
    is => 'ro',
    isa => 'Str',
    documentation => q/Run a command on the remote server(s)/,
);

has 'config_hosts' => (
    is => 'rw',
    isa => 'Maybe[HashRef]',
);

sub run {
    my ($self) = @_;

    # Use retrieved EC2 hosts instead of local config file entries if appropriate
    $self->get_aws if $self->aws;

    my $hostre = join '.*', @{ $self->extra_argv };

    error("Must supply string to match host(s)") unless $hostre or $self->list;

    my $hosts = $self->hosts;

    my @matching_hosts = grep { m/$hostre/ } sort keys %$hosts;

    error("No matching hosts found") unless @matching_hosts;
    say "Hosts found: @matching_hosts" if $self->verbose;
    # Just print a list of servers if appropriate
    $self->print_list(\@matching_hosts) if $self->list;

    # Either iterate over all matching hosts, or just use the first
    for my $host ( @matching_hosts ) {
        my $cmd = $self->generate_ssh_cmd($hosts->{$host});
        say "Executing command: $cmd" if $self->verbose;
        system( $cmd );
        exit unless $self->iterate;
    }
}

sub get_aws {
    my ($self) = @_;

    use Net::Amazon::EC2;

    my $aws = $self->_config_data->{aws};
    my $ec2 = Net::Amazon::EC2->new(
        AWSAccessKeyId  => $aws->{AWSAccessKeyId},
        SecretAccessKey => $aws->{SecretAccessKey},
        region          => $aws->{region}
    );

    # Get all instances
    my @instances;
    my $reservations = $ec2->describe_instances;
    foreach my $reservation (@$reservations) {
       foreach my $instance ($reservation->instances_set) {
           # Ensure only running instances
           next unless $instance->instance_state->name eq 'running';
           push @instances, $instance->name;
       }
    }

    # Create new hosts hash
    my %hosts = map { $_ => { hostname => $_ . $aws->{domain} } } @instances;

    # Over-write the local config
    $self->config_hosts(\%hosts);
}

sub print_list {
    my ($self, $hostnames) = @_;

    my $hosts = $self->hosts;

    for my $host (@$hostnames) {
        say "$host: " . $hosts->{$host}{hostname};
        }
    exit;
}

sub generate_ssh_cmd {
    my ($self, $host) = @_;

    my $cmd = 'ssh ';

    $cmd .= ' -p ' . $host->{port} . ' ' if $host->{port};
    $cmd .= ' -i ~/.ssh/' . $host->{ssh_key} . ' ' if $host->{ssh_key};

    $cmd .= ' ' . $host->{user} . '@' if $host->{user};
    $cmd .= $host->{hostname};

    $cmd .= " '" . $self->{cmd} . "'" if $self->{cmd};

    return $cmd;
}

sub error {
    my ($msg) = @_;
    say $msg;
    exit 1;
}

sub hosts {
    my ($self) = @_;
    $self->config_hosts( $self->_config_data->{hosts} ) unless $self->config_hosts;
    return $self->config_hosts
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Goto2 - Easily SSH to many servers

=head1 SYNOPSIS

  use App::Goto2;

=head1 DESCRIPTION

App::Goto2 is intended to take the strain out of having a large number of servers you
frequently have to access via SSH. It allows you to set up nicknames, use partial hostnames,
and auto-detect available AWS EC2 instances and work out which one(s) you actually want. It
also allows for iterating over a number of machines one after the other, and the specification
of an optional command to be run on the remote machine(s).

Written by somebody who frequently had to SSH to a vast number of machines in multiple
domains, with SSH running on numerous ports, with a variety of usernames, using a variety of
SSH keys; and got sick of trying to remember all the details when writing for loops to
remotely execute commands on them all.

You can get a lot of the same functionality (port/user/aliases/etc) just by updating your
ssh config file, but (a) it's harder to share a config file, (b) it wouldn't have the EC2
integration and (c) it doesn't lend itself to wildcards so well.

=head2 CONFIG

By default, the config file will be looked for in ~/.go2/config.yml

An example layout:

 ---
 hosts:
   foo:
     hostname: fubar.example.com
     user: myname
     port: 2222
   bar:
     hostname: bar.example.com
     user: myothername
 aws:
   AWSAccessKeyId: ASDFGHJKLZXCVBNMQWER
   SecretAccessKey: kmj5jgGg7gGKJkqkohknKJHkzhk7hKJHLJKt6tw
   region: eu-west-1
   domain: .example.com

=head1 AUTHOR

Dominic Humphries E<lt>dominic@oneandoneis2.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Dominic Humphries

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

App::Goto, App::Goto::Amazon

=cut
