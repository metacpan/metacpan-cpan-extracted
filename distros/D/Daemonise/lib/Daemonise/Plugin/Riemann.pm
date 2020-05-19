package Daemonise::Plugin::Riemann;

use Mouse::Role;

# ABSTRACT: Daemonise Riemann plugin

use Riemann::Client;
use Scalar::Util qw(looks_like_number);
use Carp;


has 'riemann_host' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'localhost' },
);


has 'riemann_port' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 5555 },
);


has 'riemann_proto' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'tcp' },
);


has 'riemann' => (
    is  => 'rw',
    isa => 'Riemann::Client',
);


after 'configure' => sub {
    my ($self, $reconfig) = @_;

    if ($reconfig and exists $self->riemann->{transport}->{socket}) {
        $self->log("closing riemann socket") if $self->debug;
        $self->riemann->transport->clear_socket;
    }

    $self->log("configuring Riemann plugin") if $self->debug;

    if (ref($self->config->{riemann}) eq 'HASH') {
        foreach my $conf_key ('host', 'port', 'proto') {
            my $attr = "riemann_" . $conf_key;
            $self->$attr($self->config->{riemann}->{$conf_key})
                if defined $self->config->{riemann}->{$conf_key};
        }
    }

    $self->riemann(
        Riemann::Client->new(
            host  => $self->riemann_host,
            port  => $self->riemann_port,
            proto => $self->riemann_proto,
        ));

    return;
};


sub graph {
    my ($self, $service, $state, $metric, $desc, $tags) = @_;

    unless (ref \$service eq 'SCALAR'
        and defined $service
        and ref \$state eq 'SCALAR'
        and defined $state
        and ref \$metric eq 'SCALAR'
        and defined $metric)
    {
        carp 'missing or wrong type of a mandatory argument! '
            . 'usage: $d->graph("$service", "$state", $metric, "$desc")';
        return;
    }

    unless (looks_like_number($metric)) {
        carp "metric has to be an integer or float";
        return;
    }

    if ($desc and ref(\$desc) ne 'SCALAR') {
        carp "description must be of SCALAR type, ignoring";
        undef $desc;
    }

    if ($self->debug) {
        $self->log("[riemann] $service.$state: $metric");
        return;
    }

    # $self->async and return;

    eval {
        $self->riemann(
            Riemann::Client->new(
                host  => $self->riemann_host,
                port  => $self->riemann_port,
                proto => $self->riemann_proto,
            )) unless defined $self->riemann;

        $self->riemann->send({
            host    => $self->hostname,
            service => $service,
            state   => $state,
            metric  => $metric,
            defined $desc        ? (description => $desc) : (),
            ref $tags eq 'ARRAY' ? (tags        => $tags) : (),
        });
    };
    carp "sending metric failed: $@" if $@;

    # exit; # async
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Daemonise::Plugin::Riemann - Daemonise Riemann plugin

=head1 VERSION

version 2.13

=head1 SYNOPSIS

This plugin conflicts with other plugins that provide graphing, like the Graphite plugin.

    use Daemonise;
    
    my $d = Daemonise->new();
    $d->debug(1);
    $d->foreground(1) if $d->debug;
    $d->config_file('/path/to/some.conf');
    
    $d->load_plugin('Riemann');
    
    $d->configure;
    
    # send a metric to riemann server
    # (service, state, metric, optional description)
    $d->graph("interwebs", "slow", 1.4, "MB/s");

=head1 ATTRIBUTES

=head2 riemann_host

=head2 riemann_port

=head2 riemann_udp

=head2 riemann

=head1 SUBROUTINES/METHODS provided

=head2 configure

=head2 graph

=head1 AUTHOR

Lenz Gschwendtner <norbu09@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lenz Gschwendtner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
