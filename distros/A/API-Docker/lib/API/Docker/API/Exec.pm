package API::Docker::API::Exec;
# ABSTRACT: Docker Engine Exec API
our $VERSION = '0.002';
use Moo;
use Carp qw( croak );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


sub create {
  my ($self, $container_id, %config) = @_;
  croak "Container ID required" unless $container_id;
  croak "Cmd required" unless $config{Cmd};
  return $self->client->post("/containers/$container_id/exec", \%config);
}


sub start {
  my ($self, $exec_id, %opts) = @_;
  croak "Exec ID required" unless $exec_id;
  my $body = {
    Detach => $opts{Detach} ? \1 : \0,
    Tty    => $opts{Tty}    ? \1 : \0,
  };
  return $self->client->post("/exec/$exec_id/start", $body);
}


sub resize {
  my ($self, $exec_id, %opts) = @_;
  croak "Exec ID required" unless $exec_id;
  my %params;
  $params{h} = $opts{h} if defined $opts{h};
  $params{w} = $opts{w} if defined $opts{w};
  return $self->client->post("/exec/$exec_id/resize", undef, params => \%params);
}


sub inspect {
  my ($self, $exec_id) = @_;
  croak "Exec ID required" unless $exec_id;
  return $self->client->get("/exec/$exec_id/json");
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::Exec - Docker Engine Exec API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Create an exec instance
    my $exec = $docker->exec->create($container_id,
        Cmd         => ['/bin/sh', '-c', 'echo hello'],
        AttachStdout => 1,
        AttachStderr => 1,
    );

    # Start the exec
    $docker->exec->start($exec->{Id});

    # Inspect exec instance
    my $info = $docker->exec->inspect($exec->{Id});

=head1 DESCRIPTION

This module provides methods for executing commands inside running containers
using the Docker Exec API.

Accessed via C<< $docker->exec >>.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 create

    my $exec = $exec->create($container_id,
        Cmd          => ['/bin/sh', '-c', 'echo hello'],
        AttachStdout => 1,
        AttachStderr => 1,
        Tty          => 0,
    );

Create an exec instance. Returns hashref with C<Id>.

Required config: C<Cmd> (ArrayRef of command and arguments).

Common config keys: C<AttachStdin>, C<AttachStdout>, C<AttachStderr>, C<Tty>,
C<Env>, C<User>, C<WorkingDir>.

=head2 start

    $exec->start($exec_id, Detach => 0);

Start an exec instance. Options: C<Detach>, C<Tty>.

=head2 resize

    $exec->resize($exec_id, h => 40, w => 120);

Resize the TTY for an exec instance. Options: C<h> (height), C<w> (width).

=head2 inspect

    my $info = $exec->inspect($exec_id);

Get information about an exec instance.

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::API::Containers> - Container management

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
