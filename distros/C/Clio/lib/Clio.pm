
package Clio;
BEGIN {
  $Clio::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::VERSION = '0.02';
}
# ABSTRACT: Command Line Input/Output with sockets and HTTP

use strict;
use Moo;

use Clio::Config;
use Clio::ProcessManager;

use Net::Server::Daemonize qw(daemonize);


has 'config_file' => (
    is => 'ro',
    required => 1,
);


has 'config' => (
    is => 'lazy',
    init_arg => undef,
);


has 'process_manager' => (
    is => 'lazy',
    init_arg => undef,
);


has 'server' => (
    is => 'lazy',
    init_arg => undef,
);

has '_logger' => (
    is => 'lazy',
    init_arg => undef,
    builder => '_build_logger',
);

sub _build_config {
    my $self = shift;

    my $config = Clio::Config->new(
        config_file => $self->config_file
    );

    return $config;
}

sub _build_logger {
    my $self = shift;

    my $logger_class = $self->config->logger_class;
    my $logger = $logger_class->new(
        c => $self,
    );
    return $logger;
}

sub _build_process_manager {
    my $self = shift;

    my $proc_mngr = Clio::ProcessManager->new(
        c => $self,
    );

    return $proc_mngr;
}

sub _build_server {
    my $self = shift;

    my $server_class = $self->config->server_class;

    return $server_class->new(
        c => $self,
    );
}

sub BUILD {
    my $self = shift;

    $self->config->process;
};



sub run {
    my $self = shift;

    $self->_daemonize();

    $self->process_manager->start;

    $self->server->start;
};


sub log {
    my $self = shift;
    my $caller = shift || caller();

    $self->_logger->logger($caller);
}

sub _daemonize {
    my $self = shift;

    my $log_method;

    my ($user, $group) = @{ $self->config->run_as_user_group };

    return unless defined $user && defined $group;

    # set user
    my $uid = $user =~ /\A\d+\z/ ? $user : getpwnam($user);

    # set group
    my $gid = $group =~ /\A\d+\z/ ? $group : getgrnam($group);

    daemonize( $uid, $gid, $self->config->pid_file );
}


1;

__END__
=pod

=encoding utf-8

=head1 NAME

Clio - Command Line Input/Output with sockets and HTTP

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Clio will allow you to connect to your command line utilities over network
socket and HTTP.

Please see L<clio> for configuration options and usage.

=head1 ATTRIBUTES

=head2 config_file

Path to Clio config file.

Required.

=head2 config

L<Clio::Config> object.

=head2 process_manager

L<Clio::ProcessManager> object.

=head2 server

Server object of class specified in configuration.

=head1 METHODS

=head2 run

Daemonizes if required by configuration.

Starts L<"process_mananager"> and L<"server">.

=head2 log

    my $logger = $c->log( $caller);

Returns logger object of class specified by configuration.

=head1 INSTALLATION

    cpanm Clio

=for Pod::Coverage BUILD

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

