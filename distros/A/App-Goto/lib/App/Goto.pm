package App::Goto;

use strict;
use v5.12;
our $VERSION = '0.07';

use Moo;

has args        => ( is => 'ro', required => 1 );
has config      => ( is => 'ro', required => 1 );
has error       => ( is => 'rw', default => sub { 'Unknown error' } );
has is_success  => ( is => 'rw', default => sub { 1 } );
has cmd         => ( is => 'rw' );
has nick        => ( is => 'rw', default => sub { '' } );
has host        => ( is => 'rw', default => sub { '' } );

sub BUILD {
    my $self = shift;
    my ($server, $command) = @{$self->args};

    my $hostname = $self->_get_host($server);
    return unless $hostname;

    my $remote_command = '';
    if ($command) {
        $remote_command = $self->_get_command($command);
        }

    $self->cmd( "ssh $hostname $remote_command" );
    }

sub _get_host {
    my ($self, $name) = @_;
    # Get known hosts from config
    my $hosts = $self->config->{hosts};
    # Get the first hostname from a sorted list of hosts
    my ($hostname) = grep { $_ =~ m#^$name# } sort keys %{$hosts};
    unless ($hostname) {
        $self->is_success(0);
        $self->error('Cannot find hostname in config') unless $hostname;
        return;
        }
    # Store the retrieved nick&host names for possible later use
    $self->nick($hostname);
    $self->host($hosts->{$hostname});
    # Get the right server details for the found hostname
    return $hosts->{$hostname};
    }

sub _get_command {
    my ($self, $cmd) = @_;
    my $config      = $self->config;
    # If they supplied one, separate out the modifier
    my $modifier;
    ($cmd, undef, $modifier) = $cmd =~ m#^([^/]*)(/(.*))?#;

    # Check if the server has its own instance of this command defined.
    # If so, use it. If not, use the generic version.
    my $command;
    if (my $custom = $config->{$self->nick.'_commands'}{$cmd}) {
        $command = $custom;
        }
    else {
        $command = $config->{commands}{$cmd};
        }

    unless ($command) {
        $self->is_success(0);
        $self->error('Command not recognised');
        return;
        }

    # Replace command's modifier placeholder with supplied modifier
    # (if supplied) or nothing
    $modifier = '' unless $modifier;
    my $nick = $self->nick;
    my $host = $self->host;
    $command =~ s#{{mod}}#$modifier#;
    $command =~ s#{{nick}}#$nick#;
    $command =~ s#{{host}}#$host#;

    # If we have a command, tell SSH to execute it remotely via '-t'
    return "-t $command";
    }

1;
__END__

=encoding utf-8

=head1 NAME

App::Goto - Utility for accessing remote servers via SSH

=head1 SYNOPSIS

  use App::Goto;

  my $goto = App::Goto->({ config => $config, args => $args });

  system( $goto->cmd );

Via included 'g2' script, allows for shortening of commands for connecting
to remote servers. Examples of the type of command that can be shortened
by using g2 are:

    g2 l log        => ssh 127.0.0.1 -t 'cd /var/log/ && bash'
    g2 f top        => ssh firstserver -t 'htop'

See g2's own documentation for further details.

=head1 DESCRIPTION

App::Goto is designed to make it as easy as possible to access remote servers
via SSH, allowing you to give the shortest possible unique string needed to
identify the server, and optionally to specify what command to run upon login -
such as changing to a frequently-used directory for you.

Requires a hashref of config details that define hosts & commands;
and an arrayref of arguments to define the specific host & command to use.

=head1 METHODS

=head2 is_success

Boolean, returns true if the passed-in arguments were correctly parsed.
Otherwise false.

=head2 error

If is_success is false, this should give a useful reason why.

=head2 cmd

Returns the command string calculated based on the passed-in args & config

=head2 nick

Returns the calculated nickname from the possibly-ambiguous supplied argument.

=head2 host

Returns the actual hostname for the supplied nickname.

=head1 AUTHOR

Dominic Humphries E<lt>dominic@oneandoneis2.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Dominic Humphries

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
