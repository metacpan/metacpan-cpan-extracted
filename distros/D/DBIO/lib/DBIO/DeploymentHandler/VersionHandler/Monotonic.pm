package DBIO::DeploymentHandler::VersionHandler::Monotonic;
# ABSTRACT: Obvious version progressions

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::Base';


sub new {
  my ($class, @args) = @_;
  my $args = @args == 1 ? $args[0] : { @args };
  my $self = bless({}, $class);
  $self->{_version_handler_attrs} ||= {};
  %$self = (%$self, %$args);
  # Coerce database_version → initial_version
  unless (exists $self->{_version_handler_attrs}{initial_version}) {
    if (exists $self->{database_version}) {
      $self->{_version_handler_attrs}{initial_version} = $self->{database_version};
    }
  }
  $self;
}


sub schema_version {
  my $self = shift;
  return $self->{schema_version} if exists $self->{schema_version};
  my $sv = $self->{_version_handler_attrs}{schema_version};
  $self->{schema_version} = ref($sv) ? $sv->schema_version : $sv
    if defined $sv;
  return $self->{schema_version};
}


sub initial_version {
  my $self = shift;
  return $self->{_version_handler_attrs}{initial_version}
    if exists $self->{_version_handler_attrs}{initial_version};
  return $self->{initial_version};
}


sub to_version {
  my $self = shift;
  return $self->{_version_handler_attrs}{to_version} if exists $self->{_version_handler_attrs}{to_version};
  if (exists $self->{to_version}) {
    my $v = $self->{to_version};
    return ref($v) ? $v->numify : $v;
  }
  my $v = $self->schema_version;
  $self->{_version_handler_attrs}{to_version} = ref($v) ? $v->numify : $v;
  return $self->{_version_handler_attrs}{to_version};
}

sub _version {
  my $self = shift;
  return $self->{_version} if exists $self->{_version};
  $self->{_version} = $self->initial_version;
  return $self->{_version};
}


sub previous_version_set {
  my $self = shift;
  my $to = $self->to_version;
  my $v = $self->_version;
  if ($to > $v) {
    require Carp;
    Carp::croak("you are trying to downgrade and your current version is less\n".
          "than the version you are trying to downgrade to.  Either upgrade\n".
          "or update your schema");
  } elsif ( $to == $v) {
    return undef
  } else {
    $self->{_version} = $v - 1;
    return [$v, $v - 1];
  }
}


sub next_version_set {
  my $self = shift;
  my $to = $self->to_version;
  my $v = $self->_version;
  if ($to < $v) {
    require Carp;
    Carp::croak("you are trying to upgrade and your current version is greater\n".
          "than the version you are trying to upgrade to.  Either downgrade\n".
          "or update your schema");
  } elsif ( $to == $v) {
    return undef
  } else {
    $self->{_version} = $v + 1;
    return [$v, $v + 1];
  }
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler::VersionHandler::Monotonic - Obvious version progressions

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

Version handler for integer versions that move one step at a time. It keeps
a cursor that starts at L</initial_version> and walks towards
L</to_version>. Implements L<DBIO::DeploymentHandler::HandlesVersioning>.

=head1 ATTRIBUTES

=head2 schema_version

The version the code declares, as given to L</new>.

=head2 initial_version

The version the cursor starts from.

=head2 to_version

The target version, numified if given as a version object; defaults to
L</schema_version>.

=head1 METHODS

=head2 new

  my $vh = DBIO::DeploymentHandler::VersionHandler::Monotonic->new({
    schema_version  => 3,
    initial_version => 1,   # or database_version => 1
    to_version      => 3,
  });

Takes a hashref or a flat list and keeps every key; C<database_version> is
accepted as an alias for C<initial_version>.

=head2 previous_version_set

Returns C<[$v, $v - 1]> for the current cursor C<$v> and moves the cursor
down by one, or C<undef> once the cursor has reached L</to_version>. Croaks
if L</to_version> is above the cursor.

=head2 next_version_set

Returns C<[$v, $v + 1]> for the current cursor C<$v> and moves the cursor up
by one, or C<undef> once the cursor has reached L</to_version>. Croaks if
L</to_version> is below the cursor.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
