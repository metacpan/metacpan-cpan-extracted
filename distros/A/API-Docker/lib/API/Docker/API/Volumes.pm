package API::Docker::API::Volumes;
# ABSTRACT: Docker Engine Volumes API
our $VERSION = '0.002';
use Moo;
use API::Docker::Volume;
use Carp qw( croak );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


sub _wrap {
  my ($self, $data) = @_;
  return API::Docker::Volume->new(
    client => $self->client,
    %$data,
  );
}

sub _wrap_list {
  my ($self, $list) = @_;
  return [ map { $self->_wrap($_) } @$list ];
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $opts{filters} if defined $opts{filters};
  my $result = $self->client->get('/volumes', params => \%params);
  return $self->_wrap_list($result->{Volumes} // []);
}


sub create {
  my ($self, %config) = @_;
  my $result = $self->client->post('/volumes/create', \%config);
  return $self->_wrap($result);
}


sub inspect {
  my ($self, $name) = @_;
  croak "Volume name required" unless $name;
  my $result = $self->client->get("/volumes/$name");
  return $self->_wrap($result);
}


sub remove {
  my ($self, $name, %opts) = @_;
  croak "Volume name required" unless $name;
  my %params;
  $params{force} = $opts{force} ? 1 : 0 if defined $opts{force};
  return $self->client->delete_request("/volumes/$name", params => \%params);
}


sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $opts{filters} if defined $opts{filters};
  return $self->client->post('/volumes/prune', undef, params => \%params);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::Volumes - Docker Engine Volumes API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $docker = API::Docker->new;

    # Create a volume
    my $volume = $docker->volumes->create(
        Name   => 'my-volume',
        Driver => 'local',
    );

    # List volumes
    my $volumes = $docker->volumes->list;

    # Inspect volume
    my $vol = $docker->volumes->inspect('my-volume');
    say $vol->Mountpoint;

    # Remove volume
    $docker->volumes->remove('my-volume');

=head1 DESCRIPTION

This module provides methods for managing Docker volumes including creation,
listing, inspection, and removal.

Accessed via C<< $docker->volumes >>.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 list

    my $volumes = $volumes->list;

List volumes. Returns ArrayRef of L<API::Docker::Volume> objects.

=head2 create

    my $volume = $volumes->create(
        Name   => 'my-volume',
        Driver => 'local',
    );

Create a volume. Returns L<API::Docker::Volume> object.

=head2 inspect

    my $volume = $volumes->inspect('my-volume');

Get detailed information about a volume. Returns L<API::Docker::Volume> object.

=head2 remove

    $volumes->remove('my-volume', force => 1);

Remove a volume. Optional C<force> parameter.

=head2 prune

    my $result = $volumes->prune;

Delete unused volumes. Returns hashref with C<VolumesDeleted> and C<SpaceReclaimed>.

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Volume> - Volume entity class

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
