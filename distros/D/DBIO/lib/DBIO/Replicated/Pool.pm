package DBIO::Replicated::Pool;
# ABSTRACT: Manage a pool of replicant backends

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Base';
use Scalar::Util 'reftype';
use Try::Tiny;
use DBI ();
use DBIO::Util ();
use namespace::clean;

__PACKAGE__->mk_group_accessors(simple => qw/
  maximum_lag
  last_validated
  replicant_type
  storage_class
  next_unknown_replicant_id
/);


sub new {
  my ($class, %args) = @_;

  my $self = bless {
    maximum_lag               => exists $args{maximum_lag} ? $args{maximum_lag} : 0,
    last_validated            => exists $args{last_validated} ? $args{last_validated} : 0,
    replicant_type            => $args{replicant_type} || 'DBIO::Replicated::Backend::Replicant',
    storage_class             => $args{storage_class} || 'DBIO::Storage::DBI',
    next_unknown_replicant_id => $args{next_unknown_replicant_id} || 1,
    replicants                => $args{replicants} || {},
    replicant_order           => $args{replicant_order} || [],
  }, $class;

  $self->master($args{master}) if exists $args{master};

  return $self;
}


sub master {
  my $self = shift;
  $self->{master} = $_[0] if @_;
  return $self->{master};
}


sub replicants {
  my $self = shift;
  $self->{replicants} = $_[0] if @_;
  return $self->{replicants};
}


sub set_replicant {
  my ($self, $key, $value) = @_;
  push @{ $self->{replicant_order} }, $key
    unless exists $self->replicants->{$key};
  return $self->replicants->{$key} = $value;
}

sub get_replicant {
  my ($self, $key) = @_;
  return $self->replicants->{$key};
}


sub has_replicants {
  my $self = shift;
  return scalar keys %{ $self->replicants };
}

sub num_replicants {
  my $self = shift;
  return scalar keys %{ $self->replicants };
}

sub delete_replicant {
  my ($self, $key) = @_;
  $self->{replicant_order} = [
    grep { $_ ne $key } @{ $self->{replicant_order} || [] }
  ];
  return delete $self->replicants->{$key};
}


sub all_replicants {
  my $self = shift;
  return map { $self->replicants->{$_} } @{ $self->{replicant_order} || [] };
}


sub connected_replicants {
  return scalar grep { $_->connected } shift->all_replicants;
}


sub active_replicants {
  my $self = shift;
  return grep { $_->active } $self->all_replicants;
}


sub connect_replicants {
  my $self = shift;
  my $schema = shift;
  my @newly_created;

  foreach my $connect_info (@_) {
    $connect_info = [ $connect_info ] if reftype($connect_info) ne 'ARRAY';

    # A broker-backed replicant ([$broker]) carries no DSN in hand: the DSN
    # is resolved from its CredentialSource at connect time. Never reach into
    # its blessed innards looking for dbh_maker/dsn keys.
    my $is_broker = DBIO::Util::is_access_broker($connect_info->[0]);

    my $connect_coderef =
      (reftype($connect_info->[0]) || '') eq 'CODE' ? $connect_info->[0]
      : !$is_broker && (reftype($connect_info->[0]) || '') eq 'HASH' && $connect_info->[0]->{dbh_maker};

    my $dsn;
    my $replicant = do {
      no warnings 'redefine';
      my $connect = \&DBI::connect;
      local *DBI::connect = sub {
        $dsn = $_[1];
        goto $connect;
      };
      $self->connect_replicant($schema, $connect_info);
    };

    my $key;
    if (!$dsn) {
      if (!$connect_coderef && !$is_broker) {
        $dsn = $connect_info->[0];
        $dsn = $dsn->{dsn} if (reftype($dsn) || '') eq 'HASH';
      }
      else {
        $key = 'UNKNOWN_' . $self->next_unknown_replicant_id;
        $self->next_unknown_replicant_id($self->next_unknown_replicant_id + 1);
      }
    }

    if ($dsn) {
      $replicant->dsn($dsn);
      ($key) = ($dsn =~ m/^dbi\:.+\:(.+)$/i);

      # the name is a pool key (force_pool), shown in traces and messages:
      # never a password in it
      if (defined $key) {
        $key = join ';', grep { !/^\s*(?:password|passwd|pwd)\s*=/i } split /;/, $key;
      }
    }

    $replicant->id($key);
    $self->set_replicant($key => $replicant);
    push @newly_created, $replicant;
  }

  return @newly_created;
}


sub connect_replicant {
  my ($self, $schema, $connect_info) = @_;

  my $storage_class = $self->storage_class;
  $self->ensure_class_loaded($storage_class);
  DBIO::Util::assert_class_isa(
    storage_class => $storage_class, 'DBIO::Storage::DBI',
  );

  my $storage = $storage_class->new($schema);
  $storage->connect_info($connect_info);
  $storage->_determine_driver if $storage->can('_determine_driver');

  my $replicant_class = $self->replicant_type;
  $self->ensure_class_loaded($replicant_class);
  DBIO::Util::assert_class_isa(
    replicant_type => $replicant_class, 'DBIO::Replicated::Backend::Replicant',
  );

  my $replicant = $replicant_class->new(
    storage => $storage,
    master  => $self->master,
  );

  if ($self->master && $self->master->storage && $self->master->storage->debugobj) {
    $replicant->install_debug_proxy($self->master->storage->debugobj);
  }

  return $replicant;
}

sub _safely_ensure_connected {
  my ($self, $replicant, @args) = @_;
  return $self->_safely($replicant, '->ensure_connected', sub {
    $replicant->ensure_connected(@args);
  });
}

sub _safely {
  my ($self, $replicant, $name, $code) = @_;

  return try {
    $code->();
    1;
  } catch {
    # names the replicant by its DSN: never the password in it (karr k297)
    my $info = $replicant->storage->_dbi_connect_info;
    $replicant->debugobj->print(DBIO::Util::mask_connect_secrets(
      sprintf(
        "Exception trying to $name for replicant %s, error is %s",
        $info->[0], $_,
      ),
      $info,
    ));
    undef;
  };
}


sub validate_replicants {
  my $self = shift;

  foreach my $replicant ($self->all_replicants) {
    if ($self->_safely_ensure_connected($replicant)) {
      my $is_replicating = $replicant->is_replicating;

      unless (defined $is_replicating) {
        $replicant->debugobj->print(
          "Storage Driver " . ref($replicant->storage)
          . " does not support 'is_replicating'. Assuming manual management.\n"
        );
        next;
      }

      if ($is_replicating) {
        my $lag_behind_master = $replicant->lag_behind_master;

        unless (defined $lag_behind_master) {
          $replicant->debugobj->print(
            "Storage Driver " . ref($replicant->storage)
            . " does not support 'lag_behind_master'. Assuming manual management.\n"
          );
          next;
        }

        $replicant->active($lag_behind_master <= $self->maximum_lag ? 1 : 0);
      }
      else {
        $replicant->active(0);
      }
    }
    else {
      $replicant->active(0);
    }
  }

  $self->last_validated(time);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated::Pool - Manage a pool of replicant backends

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Holds the replicant backends of a L<DBIO::Replicated::Storage>, in the order
they were added, and decides which are active. Plain read/write accessors:
C<maximum_lag> (default 0), C<last_validated> (epoch seconds, default 0),
C<replicant_type> (default L<DBIO::Replicated::Backend::Replicant>),
C<storage_class> (default L<DBIO::Storage::DBI>) and
C<next_unknown_replicant_id> (default 1).

=head1 METHODS

=head2 new

  my $pool = DBIO::Replicated::Pool->new(
    master      => $master_backend,
    maximum_lag => 2,
  );

=head2 master

Getter/setter for the master backend handed to new replicants.

=head2 replicants

Getter/setter for the hashref of replicants, keyed by name.

=head2 set_replicant

=head2 get_replicant

=head2 delete_replicant

  $pool->set_replicant($name => $backend);
  my $backend = $pool->get_replicant($name);
  $pool->delete_replicant($name);

Store, fetch and remove one replicant by name, keeping the insertion order
used by L</all_replicants>.

=head2 has_replicants

=head2 num_replicants

Both return the number of replicants.

=head2 all_replicants

All replicants, in the order they were added.

=head2 connected_replicants

The number of replicants that are currently connected.

=head2 active_replicants

The replicants currently flagged active, in order.

=head2 connect_replicants

  my @new = $pool->connect_replicants($schema, @connect_infos);

Creates one replicant per connect info (via L</connect_replicant>) and adds
it to the pool. The replicant is named after the part of its DSN following
C<dbi:Driver:>, without any C<password=>, C<passwd=> or C<pwd=> part, so the
name -- the value C<force_pool> takes -- never carries a password. Replicants whose DSN is not known up front (a
coderef or C<dbh_maker> connect, or an AccessBroker) are named C<UNKNOWN_n>.
Returns the new replicants.

=head2 connect_replicant

  my $replicant = $pool->connect_replicant($schema, $connect_info);

Builds one replicant: a new C<storage_class> storage with this connect info
(driver resolved right away), wrapped in a C<replicant_type> backend tied to
the master, with the master's trace object proxied onto it. Does not add it
to the pool.

=head2 validate_replicants

Checks every replicant and sets its C<active> flag: a replicant that cannot
connect, or reports it is not replicating, is deactivated; one that is
replicating is active if its C<lag_behind_master> is at most
C<maximum_lag>. A replicant whose storage cannot answer C<is_replicating> or
C<lag_behind_master> is left as it is. Updates C<last_validated>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
