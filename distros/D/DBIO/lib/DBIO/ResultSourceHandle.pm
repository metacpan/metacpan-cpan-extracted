package DBIO::ResultSourceHandle;
# ABSTRACT: Serializable pointers to ResultSource instances

use strict;
use warnings;

use base qw/DBIO::Base/;

use DBIO::Util qw(help_url);
use Try::Tiny;
use namespace::clean;

use overload
    q/""/ => sub { __PACKAGE__ . ":" . shift->source_moniker; },
    fallback => 1;

__PACKAGE__->mk_group_accessors('simple' => qw/schema source_moniker _detached_source/);

# Schema to use when thawing.
our $thaw_schema;


sub new {
  my ($class, $args) = @_;
  my $self = bless $args, ref $class || $class;

  unless( ($self->{schema} || $self->{_detached_source}) && $self->{source_moniker} ) {
    my $err = 'Expecting a schema instance and a source moniker';
    $self->{schema}
      ? $self->{schema}->throw_exception($err)
      : DBIO::Exception->throw($err)
  }

  $self;
}


sub resolve {
  return $_[0]->{schema}->source($_[0]->source_moniker) if $_[0]->{schema};

  $_[0]->_detached_source || DBIO::Exception->throw( sprintf (
    # vague error message as this is never supposed to happen
    "Unable to resolve moniker '%s' - please contact the dev team at %s",
    $_[0]->source_moniker,
    help_url,
  ), 'full_stacktrace');
}


sub STORABLE_freeze {
  my ($self, $cloning) = @_;

  my $to_serialize = { %$self };

  delete $to_serialize->{schema};
  delete $to_serialize->{_detached_source};
  $to_serialize->{_frozen_from_class} = $self->{schema}
    ? $self->{schema}->class($self->source_moniker)
    : $self->{_detached_source}->result_class
  ;

  Storable::nfreeze($to_serialize);
}


sub STORABLE_thaw {
  my ($self, $cloning, $ice) = @_;
  %$self = %{ Storable::thaw($ice) };

  my $from_class = delete $self->{_frozen_from_class};

  if( $thaw_schema ) {
    $self->schema( $thaw_schema );
  }
  elsif( my $rs = $from_class->result_source_instance ) {
    # in the off-chance we are using CDBI-compat and have leaked $schema already
    if( my $s = try { $rs->schema } ) {
      $self->schema( $s );
    }
    else {
      $rs->source_name( $self->source_moniker );
      $rs->{_detached_thaw} = 1;
      $self->_detached_source( $rs );
    }
  }
  else {
    DBIO::Exception->throw(
      "Thaw failed - original result class '$from_class' does not exist on this system"
    );
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ResultSourceHandle - Serializable pointers to ResultSource instances

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Currently instances of this class are used to allow proper serialization of
L<ResultSources|DBIO::ResultSource> (which may contain unserializable
elements like C<CODE> references).

Originally this module was used to remove the fixed link between
L<Rows|DBIO::Row>/L<ResultSets|DBIO::ResultSet> and the actual
L<result source objects|DBIO::ResultSource> in order to obviate the need
of keeping a L<schema instance|DBIO::Schema> constantly in scope, while
at the same time avoiding leaks due to circular dependencies. This is however
no longer needed after introduction of a proper mutual-assured-destruction
contract between a C<Schema> instance and its C<ResultSource> registrants.

=head1 METHODS

=head2 new

=head2 resolve

Resolve the moniker into the actual ResultSource object

=head2 STORABLE_freeze

Freezes a handle.

=head2 STORABLE_thaw

Thaws frozen handle. Resets the internal schema reference to the package
variable C<$thaw_schema>. The recommended way of setting this is to use
C<< $schema->thaw($ice) >> which handles this for you.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
