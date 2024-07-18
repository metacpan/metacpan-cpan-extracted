package DBIx::Class::DeploymentHandler::VersionHandler::DatabaseToSchemaVersions;
$DBIx::Class::DeploymentHandler::VersionHandler::DatabaseToSchemaVersions::VERSION = '0.002234';
use Moose;

# ABSTRACT: Go straight from Database to Schema version

with 'DBIx::Class::DeploymentHandler::HandlesVersioning';

has schema_version => (
  is       => 'ro',
  required => 1,
);

has initial_version => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has to_version => ( # configuration
  is         => 'ro',
  isa        => 'Str',
  lazy_build => 1,
);

sub _build_to_version { $_[0]->schema_version }

has once => (
  is      => 'rw',
  isa     => 'Bool',
  default => undef,
);

# provide backwards compatibility for initial_version/database_version
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);
    $args->{initial_version} = $args->{database_version}
      if exists $args->{database_version} && !exists $args->{initial_version};
    return $args;
};

sub next_version_set {
  my $self = shift;
  return undef
    if $self->once;

  $self->once(!$self->once);
  return undef
    if $self->initial_version eq $self->to_version;
  return [$self->initial_version, $self->to_version];
}

sub previous_version_set {
  my $self = shift;
  return undef
    if $self->once;

  $self->once(!$self->once);
  return undef
    if $self->initial_version eq $self->to_version;
  return [$self->initial_version, $self->to_version];
}


__PACKAGE__->meta->make_immutable;

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=head1 NAME

DBIx::Class::DeploymentHandler::VersionHandler::DatabaseToSchemaVersions - Go straight from Database to Schema version

=head1 SEE ALSO

This class is an implementation of
L<DBIx::Class::DeploymentHandler::HandlesVersioning>.  Pretty much all the
documentation is there.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
