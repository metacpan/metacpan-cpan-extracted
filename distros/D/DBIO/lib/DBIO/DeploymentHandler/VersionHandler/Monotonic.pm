package DBIO::DeploymentHandler::VersionHandler::Monotonic;
# ABSTRACT: Obvious version progressions

use strict;
use warnings;

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

sub _inc_version { $_[0]->{_version}($_[0]->_version + 1 ) }
sub _dec_version { $_[0]->{_version}($_[0]->_version - 1 ) }

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

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
