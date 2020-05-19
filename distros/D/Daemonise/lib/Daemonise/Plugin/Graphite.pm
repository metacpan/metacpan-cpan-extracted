package Daemonise::Plugin::Graphite;

use Mouse::Role;

# ABSTRACT: Daemonise Graphite plugin

use Net::Graphite;
use Scalar::Util qw(looks_like_number);
use Carp;


has 'graphite_host' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'localhost' },
);


has 'graphite_port' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 2003 },
);


has 'graphite_proto' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'tcp' },
);


has 'graphite' => (
    is  => 'rw',
    isa => 'Net::Graphite',
);


after 'configure' => sub {
    my ($self, $reconfig) = @_;

    if ($reconfig and exists $self->graphite->{_socket}) {
        $self->log("closing graphite socket") if $self->debug;
        $self->graphite->close;
    }

    $self->log("configuring Graphite plugin") if $self->debug;

    if (ref($self->config->{graphite}) eq 'HASH') {
        foreach my $conf_key ('host', 'port', 'proto') {
            my $attr = "graphite_" . $conf_key;
            $self->$attr($self->config->{graphite}->{$conf_key})
                if defined $self->config->{graphite}->{$conf_key};
        }
    }

    $self->graphite(
        Net::Graphite->new(
            host            => $self->graphite_host,
            port            => $self->graphite_port,
            proto           => $self->graphite_proto,
            fire_and_forget => 1,
        ));

    return;
};


sub graph {
    my ($self, $service, $state, $metric, $desc) = @_;

    unless (ref \$service eq 'SCALAR'
        and defined $service
        and ref \$state eq 'SCALAR'
        and defined $state
        and ref \$metric eq 'SCALAR'
        and defined $metric)
    {
        carp 'missing or wrong type of mandatory argument! '
            . 'usage: $d->graph("$service", "$state", $metric, "$desc")';
        return;
    }

    unless ($service =~ m/\w\.\w/) {
        carp 'service has to have at least one namespace! '
            . 'e.g.: "site.graph.thing"';
        return;
    }

    unless (looks_like_number($metric)) {
        carp "metric has to be an integer or float";
        return;
    }

    if ($self->debug) {
        $self->log("[graphite] $service.$state: $metric");
        return;
    }

    # $self->async and return;

    eval {
        $self->graphite->send(
            path  => "${service}.${state}",
            value => $metric,
        );
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

Daemonise::Plugin::Graphite - Daemonise Graphite plugin

=head1 VERSION

version 2.13

=head1 SYNOPSIS

This plugin conflicts with other plugins that provide graphing, like the Riemann plugin.

    use Daemonise;
    
    my $d = Daemonise->new();
    $d->debug(1);
    $d->foreground(1) if $d->debug;
    $d->config_file('/path/to/some.conf');
    
    $d->load_plugin('Graphite');
    
    $d->configure;
    
    # send a metric to graphite server
    # (service, state, metric, optional description)
    $d->graph("interwebs", "slow", 1.4, "MB/s");

=head1 ATTRIBUTES

=head2 graphite_host

=head2 graphite_port

=head2 graphite_udp

=head2 graphite

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
