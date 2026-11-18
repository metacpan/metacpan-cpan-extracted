package API::Docker::API::Volumes;
# ABSTRACT: Docker Engine Volumes API
our $VERSION = '0.006';
use Moo;
with 'API::Docker::Role::Filters', 'API::Docker::Role::Using';
use API::Docker::Role::Entity::Volume;
use API::Docker::Type::Volume;
use Carp qw( croak );
use namespace::clean;


has client => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


# The class is the caller's argument, as it is on the resource classes whose
# list and inspect really are two definitions -- here all three calls answer
# with the swagger's one `Volume`, and passing it keeps the seam in the same
# place.
#
# from_data, not new: this is a daemon response, and the two entry points of
# API::Docker::Role::Type read it differently. from_data takes the swagger's
# wire names and nothing else, so a key it has not heard of keeps its own
# spelling instead of being read as the Perl name of one it has, and a value
# that disagrees with the swagger costs its own field rather than the whole
# response. `client` is ours rather than the engine's, so it goes beside the
# data instead of into it.
sub _wrap {
  my ($self, $class, $data) = @_;
  return $class->from_data($data, client => $self->client);
}

sub _wrap_list {
  my ($self, $class, $list) = @_;
  return [ map { $self->_wrap($class, $_) } @$list ];
}

sub list {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  my $result = $self->client->get('/volumes',
    params => \%params,
    %{ $self->_request_options },
  );
  return $self->_wrap_list('API::Docker::Type::Volume',
    $result->{Volumes} // []);
}


sub create {
  my ($self, %config) = @_;
  my $result = $self->client->post('/volumes/create', \%config);
  return $self->_wrap('API::Docker::Type::Volume', $result);
}


sub inspect {
  my ($self, $name) = @_;
  croak "Volume name required" unless $name;
  my $result = $self->client->get("/volumes/$name",
    %{ $self->_request_options },
  );
  return $self->_wrap('API::Docker::Type::Volume', $result);
}


sub remove {
  my ($self, $name, %opts) = @_;
  croak "Volume name required" unless $name;
  my %params;
  $params{force} = $opts{force} ? 1 : 0 if defined $opts{force};
  return $self->client->delete_request("/volumes/$name",
    params => \%params,
    %{ $self->_request_options },
  );
}


sub prune {
  my ($self, %opts) = @_;
  my %params;
  $params{filters} = $self->_normalise_filters($opts{filters})
    if defined $opts{filters};
  return $self->client->post('/volumes/prune', undef,
    params => \%params,
    %{ $self->_request_options },
  );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::API::Volumes - Docker Engine Volumes API

=head1 VERSION

version 0.006

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
    say $vol->mountpoint;

    # Remove volume
    $docker->volumes->remove('my-volume');

=head1 DESCRIPTION

This module provides methods for managing Docker volumes including creation,
listing, inspection, and removal.

L</list>, L</inspect> and L</create> all return
L<API::Docker::Type::Volume> objects carrying the convenience methods of
L<API::Docker::Role::Entity::Volume>, so C<< $volume->remove >> works on any
of them. The field names are the swagger's own spelling in snake_case:
C<Mountpoint> is C<< ->mountpoint >>, C<CreatedAt> is C<< ->created_at >>,
C<UsageData> is C<< ->usage_data >> and inflates into an
L<API::Docker::Type::Volume::UsageData>.

This is B<one> class for all three calls, where containers and images have
two: the swagger answers the inspect and the create with the C<Volume>
definition outright and the list with a C<VolumeListResponse> whose
C<Volumes> is an array of that same definition -- see
L<API::Docker::Role::Entity::Volume/"One class for all three calls">. A
volume is also addressed by its C<< ->name >> rather than by an id; it has
none.

Accessed via C<< $docker->volumes >>, or through
L<API::Docker::Role::Using/using> for a run of calls that needs its own
transport bound: C<< $docker->volumes->using(read_timeout => 5) >>.

=head2 client

Reference to L<API::Docker> client. Weak reference to avoid circular dependencies.

=head2 list

    my $volumes = $volumes->list;
    my $unused  = $volumes->list(filters => { dangling => ['true'] });

List volumes. Returns an ArrayRef of L<API::Docker::Type::Volume> objects,
each carrying the methods of L<API::Docker::Role::Entity::Volume>. The
daemon answers this endpoint with a C<VolumeListResponse> rather than a bare
array; the C<Volumes> key is what comes back here, and the C<Warnings>
beside it are dropped.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<dangling>, C<driver>, C<label> and C<name> here.
Shape-checked and normalised by L<API::Docker::Role::Filters>

=back

=head2 create

    my $volume = $volumes->create(
        Name   => 'my-volume',
        Driver => 'local',
    );

Create a volume. Returns an L<API::Docker::Type::Volume> -- the only creating
method in this distribution that wraps its response, because the swagger
answers C<POST /volumes/create> with the same definition an inspect returns.

=head2 inspect

    my $volume = $volumes->inspect('my-volume');

Get detailed information about a volume. Returns an
L<API::Docker::Type::Volume> -- the same class L</list> and L</create>
return, since the swagger describes a volume one way.

=head2 remove

    $volumes->remove('my-volume', force => 1);

Remove a volume. Optional C<force> parameter.

=head2 prune

    my $result = $volumes->prune;
    my $result = $volumes->prune(filters => { label => ['stage=build'] });

Delete unused volumes. Returns hashref with C<VolumesDeleted> and C<SpaceReclaimed>.

Options:

=over

=item * C<filters> - HashRef of filter name to ArrayRef of string values; the
engine accepts C<label> here. Shape-checked and normalised by
L<API::Docker::Role::Filters>

=back

=head1 SEE ALSO

=over

=item * L<API::Docker> - Main Docker client

=item * L<API::Docker::Role::Entity::Volume> - the convenience methods the
returned objects carry

=item * L<API::Docker::Type::Volume> - the fields C<list>, C<inspect> and
C<create> return

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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
