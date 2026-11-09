package DBIO::Row;
# ABSTRACT: Basic row methods

use strict;
use warnings;

our $VERSION = '0.900004';

use base qw/DBIO::Base/;

use Scalar::Util 'blessed';
use List::Util ();
use Sub::Util ();
use Try::Tiny;
use DBIO::Carp;
use DBIO::Util qw(is_literal_value assert_column_value);

###
### Internal method
### Do not use
###
BEGIN {
  *MULTICREATE_DEBUG =
    $ENV{DBIO_MULTICREATE_DEBUG}
      ? sub () { 1 }
      : sub () { 0 };
}

use namespace::clean;

__PACKAGE__->mk_group_accessors ( simple => [ in_storage => '_in_storage' ] );


## It needs to store the new objects somewhere, and call insert on that list later when insert is called on this object. We may need an accessor for these so the user can retrieve them, if just doing ->new().
## This only works because DBIO doesn't yet care to check whether the new_related objects have been passed all their mandatory columns
## When doing the later insert, we need to make sure the PKs are set.
## using _relationship_data in new and funky ways..
## check Relationship::CascadeActions and Relationship::Codegen for compat
## tests!

sub __new_related_find_or_new_helper {
  my ($self, $rel_name, $values) = @_;

  my $rsrc = $self->result_source;

  # create a mock-object so all new/set_column component overrides will run:
  my $rel_rs = $rsrc->related_source($rel_name)->resultset;
  my $new_rel_obj = $rel_rs->new_result($values);
  my $proc_data = { $new_rel_obj->get_columns };

  if ($self->__their_pk_needs_us($rel_name)) {
    MULTICREATE_DEBUG and print STDERR "MC $self constructing $rel_name via new_result\n";
    return $new_rel_obj;
  }
  elsif ($rsrc->_pk_depends_on($rel_name, $proc_data )) {
    if (! keys %$proc_data) {
      # there is nothing to search for - blind create
      MULTICREATE_DEBUG and print STDERR "MC $self constructing default-insert $rel_name\n";
    }
    else {
      MULTICREATE_DEBUG and print STDERR "MC $self constructing $rel_name via find_or_new\n";
      # this is not *really* find or new, as we don't want to double-new the
      # data (thus potentially double encoding or whatever)
      # only a belongs_to row that the data identifies is looked up, every
      # other related row is created (ADR 0071)
      my $exists = $rsrc->_relationship_depends_on($rel_name)
        && $rel_rs->_find_identified($proc_data);
      return $exists if $exists;
    }
    return $new_rel_obj;
  }
  else {
    my $us = $rsrc->source_name;
    $self->throw_exception (
      "Unable to determine relationship '$rel_name' direction from '$us', "
    . "possibly due to a missing reverse-relationship on '$rel_name' to '$us'."
    );
  }
}

# Mass assignment (ADR 0071). Called for every key of the hash the caller gave
# to new before anything is stored: a column marked is_guarded takes no value,
# a guarded relationship takes no hash of data, and a relationship that holds
# this row's foreign key (belongs_to) may not set a guarded foreign key column.
# Relationship values that only resolve to columns later (a row created along)
# are checked at the point they are set, see __set_from_related_by_caller.
sub __assert_caller_assignment {
  my ($self, $key, $value) = @_;

  my $rsrc = $self->result_source;

  if (ref $value and ! is_literal_value($value) and $rsrc->relationship_info($key)) {
    $rsrc->_assert_relationship_not_guarded($key)
      if ref $value eq 'HASH' or ref $value eq 'ARRAY';

    $rsrc->_assert_columns_not_guarded($rsrc->_relationship_self_columns($key))
      if $rsrc->_relationship_depends_on($key);
  }
  else {
    $rsrc->_assert_columns_not_guarded($key);
  }

  return;
}

# The columns a value the caller gave for a relationship resolves to may not be
# guarded and may not contradict the equalities of the resultset's condition
sub __assert_resolved_assignable {
  my ($self, $cols) = @_;

  my $rsrc = $self->result_source;

  $rsrc->_assert_columns_not_guarded(sort keys %$cols);
  $rsrc->_assert_scope_agrees($cols, $self->{_scope_values}) if $self->{_scope_values};

  return;
}

# set_from_related for a relationship value the caller gave to new
sub __set_from_related_by_caller {
  my ($self, $rel_name, $rel_obj) = @_;

  $self->__assert_resolved_assignable($self->_inferred_from_related($rel_name, $rel_obj));

  return $self->set_from_related($rel_name, $rel_obj);
}

# update(\%hash) assigns what the caller gives: guarded columns take no value,
# and neither does a relationship value that resolves to one
sub __assert_update_assignable {
  my ($self, $upd) = @_;

  my $rsrc = $self->result_source or return;

  for my $key (sort keys %$upd) {
    my $value = $upd->{$key};
    my $info = ( ! defined $value or ( ref $value and ! is_literal_value($value) ) )
      ? $rsrc->relationship_info($key)
      : undef
    ;

    my $acc_type = $info ? $info->{attrs}{accessor} || '' : '';

    if ($acc_type eq 'single' or $acc_type eq 'filter') {
      $self->__assert_resolved_assignable($self->_inferred_from_related($key, $value));
    }
    elsif (! $info) {
      $rsrc->_assert_columns_not_guarded($key);
    }
  }

  return;
}

sub __their_pk_needs_us { # this should maybe be in resultsource.
  my ($self, $rel_name) = @_;
  my $rsrc = $self->result_source;
  my $reverse = $rsrc->reverse_relationship_info($rel_name);
  my $rel_source = $rsrc->related_source($rel_name);
  my $us = { $self->get_columns };
  foreach my $key (keys %$reverse) {
    # if their primary key depends on us, then we have to
    # just create a result and we'll fill it out afterwards
    return 1 if $rel_source->_pk_depends_on($key, $us);
  }
  return 0;
}

sub new {
  my ($class, $attrs) = @_;
  $class = ref $class if ref $class;

  my $new = bless { _column_data => {}, _in_storage => 0 }, $class;

  if ($attrs) {
    $new->throw_exception("attrs must be a hashref")
      unless ref($attrs) eq 'HASH';

    my $rsrc = delete $attrs->{-result_source};

    $new->result_source($rsrc) if $rsrc;

    if (my $col_from_rel = delete $attrs->{-cols_from_relations}) {
      @{$new->{_ignore_at_insert}={}}{@$col_from_rel} = ();
    }

    # ADR 0071: which keys are the caller's assignment (all of them, unless
    # the resultset names them) and the equalities of the resultset's condition
    # a value of the caller may not contradict
    my $caller_keys = delete $attrs->{-caller_keys};
    my $scope_values = delete $attrs->{-scope_values};
    my %caller = map { $_ => 1 } ( $caller_keys ? @$caller_keys : keys %$attrs );

    $new->{_scope_values} = $scope_values if $scope_values and %$scope_values;

    if ($rsrc) {
      $new->__assert_caller_assignment($_, $attrs->{$_}) for sort grep { $caller{$_} } keys %$attrs;
    }

    my ($related,$inflated);

    foreach my $key (keys %$attrs) {
      if (ref $attrs->{$key} and ! is_literal_value($attrs->{$key}) ) {
        ## Can we extract this lot to use with update(_or .. ) ?
        $new->throw_exception("Can't do multi-create without result source")
          unless $rsrc;
        my $info = $rsrc->relationship_info($key);
        my $acc_type = $info->{attrs}{accessor} || '';
        if ($acc_type eq 'single') {
          my $rel_obj = delete $attrs->{$key};
          if(!blessed $rel_obj) {
            $rel_obj = $new->__new_related_find_or_new_helper($key, $rel_obj);
          }

          $new->{_caller_rels}{$key} = 1 if $caller{$key};

          if ($rel_obj->in_storage) {
            $new->{_rel_in_storage}{$key} = 1;
            $caller{$key}
              ? $new->__set_from_related_by_caller($key, $rel_obj)
              : $new->set_from_related($key, $rel_obj)
            ;
          } else {
            MULTICREATE_DEBUG and print STDERR "MC $new uninserted $key $rel_obj\n";
          }

          $related->{$key} = $rel_obj;
          next;
        }
        elsif ($acc_type eq 'multi' && ref $attrs->{$key} eq 'ARRAY' ) {
          my $others = delete $attrs->{$key};
          my $total = @$others;
          my @objects;
          foreach my $idx (0 .. $#$others) {
            my $rel_obj = $others->[$idx];
            if(!blessed $rel_obj) {
              $rel_obj = $new->__new_related_find_or_new_helper($key, $rel_obj);
            }

            if ($rel_obj->in_storage) {
              $rel_obj->throw_exception ('A multi relationship can not be pre-existing when doing multicreate. Something went wrong');
            } else {
              MULTICREATE_DEBUG and
                print STDERR "MC $new uninserted $key $rel_obj (${\($idx+1)} of $total)\n";
            }
            push(@objects, $rel_obj);
          }
          $related->{$key} = \@objects;
          next;
        }
        elsif ($acc_type eq 'filter') {
          ## 'filter' should disappear and get merged in with 'single' above!
          my $rel_obj = delete $attrs->{$key};
          if(!blessed $rel_obj) {
            $rel_obj = $new->__new_related_find_or_new_helper($key, $rel_obj);
          }
          $new->{_caller_rels}{$key} = 1 if $caller{$key};

          if ($rel_obj->in_storage) {
            $new->{_rel_in_storage}{$key} = 1;

            # its key is set when the row is inserted, say now if it may not be
            $new->__assert_resolved_assignable($new->_inferred_from_related($key, $rel_obj))
              if $caller{$key};
          }
          else {
            MULTICREATE_DEBUG and print STDERR "MC $new uninserted $key $rel_obj\n";
          }
          $inflated->{$key} = $rel_obj;
          next;
        }
        elsif (
          $rsrc->has_column($key)
            and
          $rsrc->column_info($key)->{_inflate_info}
        ) {
          $inflated->{$key} = $attrs->{$key};
          next;
        }
      }
      $new->store_column($key => $attrs->{$key});
    }

    $new->{_relationship_data} = $related if $related;
    $new->{_inflated_column} = $inflated if $inflated;
  }

  # StorageValues (integrated helper): per-row snapshot slot.
  # Zero-cost when no column declares keep_storage_value.
  $new->_storage_values({});

  return $new;
}


sub insert {
  my ($self) = @_;
  return $self if $self->in_storage;
  my $rsrc = $self->result_source;
  $self->throw_exception("No result_source set on this object; can't insert")
    unless $rsrc;

  my $storage = $rsrc->storage;

  # whatever a component has to do before this row is written
  $self->prepare_insert;

  my $rollback_guard;

  # Check if we stored uninserted relobjs here in new()
  my %related_stuff = (%{$self->{_relationship_data} || {}},
                       %{$self->{_inflated_column} || {}});

  # insert what needs to be inserted before us
  my %pre_insert;
  for my $rel_name (keys %related_stuff) {
    my $rel_obj = $related_stuff{$rel_name};

    if (! $self->{_rel_in_storage}{$rel_name}) {
      next unless (blessed $rel_obj && $rel_obj->isa('DBIO::Row'));

      next unless $rsrc->_pk_depends_on(
                    $rel_name, { $rel_obj->get_columns }
                  );

      # The guard will save us if we blow out of this scope via die
      $rollback_guard ||= $storage->txn_scope_guard;

      MULTICREATE_DEBUG and print STDERR "MC $self pre-reconstructing $rel_name $rel_obj\n";

      my $them = { %{$rel_obj->{_relationship_data} || {} }, $rel_obj->get_columns };
      my $existing;

      # a belongs_to row that the data identifies is the row to link to; any
      # other related row is created (ADR 0071)
      if (
        $rsrc->_relationship_depends_on($rel_name)
          and
        keys %$them
          and
        $existing = $rsrc->related_source($rel_name)->resultset->_find_identified($them)
      ) {
        %{$rel_obj} = %{$existing};
      }
      else {
        $rel_obj->insert;
      }

      $self->{_rel_in_storage}{$rel_name} = 1;
    }

    $self->{_caller_rels}{$rel_name}
      ? $self->__set_from_related_by_caller($rel_name, $rel_obj)
      : $self->set_from_related($rel_name, $rel_obj)
    ;
    delete $related_stuff{$rel_name};
  }

  # start a transaction here if not started yet and there is more stuff
  # to insert after us. What is left in %related_stuff is not enough to say
  # so: an object waiting in _inflated_column for its column's deflation is
  # in there as well and writes nothing (karr k331). The pre-insert loop
  # above flagged what it handled as _rel_in_storage, so the reason is asked
  # only about what insert() still has to write after this row.
  if (keys %related_stuff and $self->_insert_cascade_reason) {
    $rollback_guard ||= $storage->txn_scope_guard
  }

  MULTICREATE_DEBUG and do {
    no warnings 'uninitialized';
    print STDERR "MC $self inserting (".join(', ', $self->get_columns).")\n";
  };

  # perform the insert - the storage will return everything it is asked to
  # (autoinc primary columns and any retrieve_on_insert columns)
  my %current_rowdata = $self->get_columns;
  assert_column_value($_, $current_rowdata{$_}) for sort keys %current_rowdata;
  my $returned_cols = $storage->insert(
    $rsrc,
    { %current_rowdata }, # what to insert, copy because the storage *will* change it
  );

  $self->_store_inserted_columns(\%current_rowdata, $returned_cols);

  foreach my $rel_name (keys %related_stuff) {
    next unless $rsrc->has_relationship ($rel_name);

    my @cands = ref $related_stuff{$rel_name} eq 'ARRAY'
      ? @{$related_stuff{$rel_name}}
      : $related_stuff{$rel_name}
    ;

    if (@cands && blessed $cands[0] && $cands[0]->isa('DBIO::Row')
    ) {
      my $reverse = $rsrc->reverse_relationship_info($rel_name);
      foreach my $obj (@cands) {
        $obj->set_from_related($_, $self) for keys %$reverse;
        if ($self->__their_pk_needs_us($rel_name)) {
          if (exists $self->{_ignore_at_insert}{$rel_name}) {
            MULTICREATE_DEBUG and print STDERR "MC $self skipping post-insert on $rel_name\n";
          }
          else {
            MULTICREATE_DEBUG and print STDERR "MC $self inserting $rel_name $obj\n";
            $obj->insert;
          }
        } else {
          MULTICREATE_DEBUG and print STDERR "MC $self post-inserting $obj\n";
          $obj->insert();
        }
      }
    }
  }

  delete $self->{_ignore_at_insert};

  $rollback_guard->commit if $rollback_guard;

  # StorageValues (integrated helper): snapshot the now-stored values.
  $self->store_storage_values if @{$self->storage_value_columns};

  return $self;
}

# Fold the columns the storage returned from an insert (autoinc PKs and any
# retrieve_on_insert columns) back into the object, mark it stored and clean.
# Shared by the synchronous insert() and the async insert_async() so both build
# the now-stored object identically.
sub _store_inserted_columns {
  my ($self, $current_rowdata, $returned_cols) = @_;

  for (keys %$returned_cols) {
    $self->store_column($_, $returned_cols->{$_})
      # this ensures we fire store_column only once
      # (some asshats like overriding it)
      if (
        (!exists $current_rowdata->{$_})
          or
        (defined $current_rowdata->{$_} xor defined $returned_cols->{$_})
          or
        (defined $current_rowdata->{$_} and $current_rowdata->{$_} ne $returned_cols->{$_})
      );
  }

  delete $self->{_column_data_in_storage};
  $self->in_storage(1);

  $self->{_dirty_columns} = {};
  $self->{related_resultsets} = {};

  return $self;
}

# Row-level mirror of DBIO::ResultSet::_rs_run_async (ADR 0030/0031): route to a
# live embedded backend, degrade synchronously in the 'immediate' mode, or croak
# on a sync instance.
sub _row_run_async {
  my ($self, $name, $backend_build, $sync_run) = @_;

  my $storage = $self->result_source->storage;
  my $fc = $storage->future_class;

  # A pinned context inherited from a context-bound resultset (or bound
  # directly via ->with_context) wins over the pooled backend, so this row's
  # insert/update/delete_async runs on the pinned txn/pipeline connection. A
  # terminal pipeline or transaction context refuses loudly rather than dropping
  # to the pool. No context => historical path below, unchanged.
  if (my $ctx = $self->_async_context) {
    $self->_assert_async_context_active($ctx, $name);
    $storage->_assert_async_context_owner($ctx);
    return $backend_build->($ctx, $fc);
  }

  if (my $backend = $storage->_async_storage) {
    # A Future derived from the storage's own is reported to the pool (k397).
    return $backend->can('_note_pooled_derivation')
      ? $backend->_note_pooled_derivation(sub { $backend_build->($backend, $fc) })
      : $backend_build->($backend, $fc);
  }

  $self->throw_exception(
    "not an async connection -- connect with { async => ... } to use ${name}_async"
  ) unless defined $storage->_async_mode;

  my @r = eval { $sync_run->() };
  if (my $error = $@) {
    # Inside an immediate txn_do_async this is a statement of the transaction
    # like any other: its failure fails it, awaited or not (karr k331).
    $storage->_note_immediate_failure($error);
    return $fc->fail($error);
  }
  return $fc->done(@r);
}

# ADR 0045: the pinned async context bound to this row (undef if unbound) and
# active-context / sync-punt guards. Kept in step with the same-named helpers on
# DBIO::ResultSet -- a row derived from a context-bound resultset inherits its
# context (see DBIO::ResultSet::_construct_results / new_result) so that a chain
# like $rs->with_context($ctx)->first_async->then(sub { $_[0]->update_async })
# writes back on the pinned connection instead of the pool.
sub _async_context { $_[0]->{_async_context} }

# ADR 0045 / karr k195: stamp a pinned async context onto this row and cascade it
# into any eagerly-prefetched children -- the related resultsets cached on the
# row and the child rows in their caches -- so a child fetched off a
# context-bound parent stays on the pinned connection instead of a sibling pool
# connection outside the transaction/pipeline. Called by
# DBIO::ResultSet::_construct_results on each top-level row built from a
# context-bound resultset, and by with_context on a pre-filled cache. The
# prefetch tree is finite and acyclic (built to the prefetch spec's depth), so
# the recursion terminates without a visited-set.
sub _bind_async_context {
  my ($self, $ctx) = @_;
  $self->{_async_context} = $ctx;
  for my $rrs (values %{ $self->{related_resultsets} || {} }) {
    next unless blessed $rrs;
    $rrs->{_async_context} = $ctx;
    my $cache = $rrs->get_cache or next;
    for my $child (@$cache) {
      $child->_bind_async_context($ctx)
        if blessed $child and $child->can('_bind_async_context');
    }
  }
  return $self;
}


sub with_context {
  my ($self, $ctx) = @_;
  $self->throw_exception(
    'with_context requires an async context object (the one passed to a '
  . 'txn_do_async / pipeline coderef)'
  ) unless defined $ctx and blessed($ctx) and $ctx->can('select_async');
  my $storage = $self->result_source->storage;
  $storage->_assert_async_context_owner($ctx);
  my $clone = bless { %$self }, ref $self;
  $clone->{_async_context} = $ctx;

  # ADR 0045 / karr k203: if this row carries eagerly-prefetched children
  # (cached related resultsets), the pin must cascade THROUGH them -- a
  # grandchild fetched off the bound clone has to stay on the pinned connection.
  # But the shallow clone above shares the source's {related_resultsets} hashref,
  # so binding those in place would mutate the unbound source (and its shared
  # child rows). Rebuild the map on the clone from bound clones instead:
  # ResultSet::with_context clones each child rs (search_rs) and rebinds its cache
  # into a fresh cache of bound row clones, recursing back through here for the
  # grandchildren -- non-mutating all the way down. This is the clone-and-rebind
  # sibling of _construct_results' in-place _bind_async_context, which is correct
  # there because those rows are freshly built and owned by the query.
  if (my $rrs_map = $self->{related_resultsets}) {
    $clone->{related_resultsets} = {
      map {
        my $rrs = $rrs_map->{$_};
        ( blessed $rrs and $rrs->can('with_context') )
          ? ( $_ => $rrs->with_context($ctx) )
          : ( $_ => $rrs );
      } keys %$rrs_map
    };
  }

  return $clone;
}

sub _assert_async_context_active {
  my ($self, $ctx, $name) = @_;
  return if !$ctx->can('_context_active') || $ctx->_context_active;
  $self->throw_exception(
    "the async context bound to this result is no longer active; ${name}_async "
  . "cannot be routed onto it. Pipeline contexts stop accepting work when their "
  . "synchronous batch coderef returns; transaction contexts stop on their "
  . "terminal BEGIN / COMMIT / ROLLBACK path. Issue the async work while its "
  . "owning context remains active, not from a row held past it."
  );
}

# A row write that is not a single pinned async statement (related
# multi-create, OnColumnChange/cascade_update, cascade-delete) must not silently
# run the synchronous fallback while a pinned context is bound -- that would
# execute outside the pinned transaction/pipeline (consequence 4). Refuse,
# named. Without a context this is the historical sync-and-resolve punt.
#
# In the 'immediate' mode the context is the storage itself (ADR 0055), and
# the fallback would run inside the transaction. The refusal stands there too,
# so that a bound row behaves the same in every async mode; only the reason
# given is the one that is true there (karr k282).
#
# $lead, if given, is what the refusal says in place of "it is not expressible
# as a single pinned statement ($why)" -- the override gate (see
# _async_override_gap), whose reason is not the shape of the statement.
sub _async_ctx_or_sync_punt {
  my ($self, $fc, $op, $why, $sync_cref, $lead) = @_;
  if (my $ctx = $self->_async_context) {
    $lead //= "it is not expressible as a single pinned statement ($why)";
    $self->throw_exception(
      "${op}_async cannot run on a bound async context: $lead. "
    . "In the 'immediate' mode the "
    . "synchronous fallback would run inside the transaction, but a bound "
    . "object refuses it in every async mode alike. Restructure so this runs "
    . "unbound -- in this mode that is still inside the transaction."
    ) if $ctx == $self->result_source->storage;

    my $where = $ctx->can('in_txn') && $ctx->in_txn ? 'transaction' : 'pipeline';
    $self->throw_exception(
      "${op}_async cannot run on a bound async context: $lead, and the "
    . "synchronous fallback would run outside the pinned $where. Restructure "
    . "so this runs outside the "
    . "context."
    );
  }
  my $r = eval { $sync_cref->() };
  return $@ ? $fc->fail($@) : $fc->done($r);
}

# The override gate (karr k331). insert_async / update_async / delete_async
# send their statement through the backend and are a new method name beside
# insert / update / delete, so an override of the synchronous method higher
# up the class's MRO -- a component's, the user class's, a Moo `around` -- is
# not on their way. This answers: which package before DBIO::Row defines
# $op itself without defining ${op}_async in that same package? undef if there
# is none. The caller then takes the full synchronous method instead (see
# _async_ctx_or_sync_punt): unbound, that is the old synchronous-and-settled
# answer; bound, it is refused, as the statement would run outside the pinned
# context.
#
# DBIO::Relationship::CascadeActions is exempt: it overrides update and delete
# and is covered by their own, finer predicates (_has_cascade_update_relateds,
# _has_cascade_delete_relateds), which punt only where it would cascade -- the
# gate would punt every row of every class, as it is in every result class.
# The list is closed on purpose: a component that does its work BEFORE the
# write uses the prepare_* hooks and defines no insert / update / delete.
#
# Not cached: the walk is a handful of stash lookups per call, and a
# load_components or a Moo around after the first call would make a cache lie.
my %ASYNC_GATE_EXEMPT = (
  'DBIO::Relationship::CascadeActions' => 1,
);

sub _async_override_gap {
  my ($self, $op) = @_;

  no strict 'refs';
  for my $pkg (@{ mro::get_linear_isa(ref $self) }) {
    last if $pkg eq 'DBIO::Row';
    next if $ASYNC_GATE_EXEMPT{$pkg};
    next unless defined &{"${pkg}::${op}"};
    return $pkg unless defined &{"${pkg}::${op}_async"};
  }
  return undef;
}

sub _async_override_gap_lead {
  my ($self, $pkg, $op) = @_;
  return "class $pkg overrides $op and has no ${op}_async sibling in that "
       . "class, so ${op}_async would run past the override (implement "
       . "${op}_async beside it, or move the work done before the write into "
       . "prepare_$op, see DBIO::Manual::Component)";
}


sub insert_async {
  my $self = shift;

  return $self->_row_run_async('insert',
    sub {
      my ($backend, $fc) = @_;

      my $rsrc = $self->result_source;
      $self->throw_exception("No result_source set on this object; can't insert")
        unless $rsrc;

      return $fc->done($self) if $self->in_storage;

      # An override of insert() the backend would run past: see
      # _async_override_gap.
      if (my $pkg = $self->_async_override_gap('insert')) {
        return $self->_async_ctx_or_sync_punt($fc, 'insert',
          'an override of insert', sub { $self->insert },
          $self->_async_override_gap_lead($pkg, 'insert'));
      }

      # Related-object multi-create is a multi-statement (and transactional)
      # cascade, not a single insert_async; run it synchronously and resolve.
      if (my $cascade = $self->_insert_cascade_reason) {
        return $self->_async_ctx_or_sync_punt($fc, 'insert',
          "related-object multi-create is a transactional cascade: $cascade",
          sub { $self->insert });
      }

      # insert() calls it at this point as well; the punts above run the full
      # insert(), which calls it itself.
      $self->prepare_insert;

      # What is left in the two slots writes nothing of its own. A related row
      # that was in storage when the row was built gives its key to ours, as
      # insert() has it do at this point; an inflated value is deflated by the
      # get_columns below, as it is there.
      my %related_stuff = (%{$self->{_relationship_data} || {}},
                           %{$self->{_inflated_column} || {}});
      $self->set_from_related($_, $related_stuff{$_})
        for grep { $self->{_rel_in_storage}{$_} } keys %related_stuff;

      my %current_rowdata = $self->get_columns;
      return $backend->insert_async( $rsrc, { %current_rowdata } )->then(sub {
        my ($returned_cols) = @_;
        $self->_store_inserted_columns(\%current_rowdata, $returned_cols);
        $self->store_storage_values if @{$self->storage_value_columns};
        return $self;
      });
    },
    sub { $self->insert },
  );
}

# Why insert() would send more than the one INSERT for THIS row, or undef if
# it would not -- mirrors what insert()'s own two loops over
# _relationship_data and _inflated_column do, entry by entry, rather than the
# coarser "is anything in those slots at all" (karr k282). Both slots hold
# more than multi-create data: _inflated_column is where an object for a
# column with an inflator sits until get_columns deflates it, and a related
# row that was in storage when the row was built is flagged _rel_in_storage
# and only lends its key. Neither writes a statement of its own, and a row
# carrying only those is a plain single-row insert.
#
# What does write, and so makes the insert a cascade:
#   - a related row our foreign key depends on that is not flagged: insert()
#     looks it up, and inserts it if it is not there, BEFORE this row;
#   - related rows whose foreign key depends on us (a has_many's arrayref, a
#     has_one / might_have object): insert() inserts them AFTER this row.
sub _insert_cascade_reason {
  my $self = shift;
  my $rsrc = $self->result_source;

  my %related_stuff = (%{$self->{_relationship_data} || {}},
                       %{$self->{_inflated_column} || {}});

  for my $rel_name (sort keys %related_stuff) {
    next if $self->{_rel_in_storage}{$rel_name};

    my $rel_obj = $related_stuff{$rel_name};

    return "the row for '$rel_name' is looked up or inserted before this one"
      if blessed $rel_obj
     and $rel_obj->isa('DBIO::Row')
     and $rsrc->_pk_depends_on($rel_name, { $rel_obj->get_columns });

    next unless $rsrc->has_relationship($rel_name);

    my @cands = ref $rel_obj eq 'ARRAY' ? @$rel_obj : $rel_obj;
    return "the rows for '$rel_name' are linked and inserted after this one"
      if @cands && blessed $cands[0] && $cands[0]->isa('DBIO::Row');
  }

  return undef;
}

# True if this row's class has any OnColumnChange before/around/after
# callback registered -- mirrors update()'s own $has_change_cbs gate
# (Row.pm's `update`, above).
sub _has_on_column_change_cbs {
  my $self = shift;
  return !! ( $self->_before_change || $self->_around_change || $self->_after_change );
}

# True if update()'s CascadeActions wrap would actually attempt a cascade for
# THIS row instance, once $upd (if any) has been applied -- mirrors its
# per-relationship skip condition exactly (Relationship::CascadeActions::
# update's own `next if $accessor eq 'single' && !exists
# $self->{_relationship_data}{$rel}`), rather than the coarser "does a
# cascade_update relationship exist on the source at all" question.
#
# A 'single'-accessor relationship (has_one/might_have, the cascade_update
# default) only cascades if its accessor has already been touched on this
# instance: explicitly assigned, or fetched at least once as a getter --
# either way, that's what populates _relationship_data (see
# Relationship::Codegen's 'single' accessor codegen). A freshly-loaded row
# that never touched the accessor has _relationship_data{$rel} unset, so
# CascadeActions itself would skip it -- nothing to cascade, and update_async
# must not punt over it either, or a plain one-column update on any class
# with a has_one/might_have relationship would never be truly async.
#
# $upd is checked too, and must be: set_inflated_columns (called from
# update()'s own body) populates _relationship_data for a 'single'-accessor
# key found in $upd as it processes it -- but that happens AFTER this gate
# would otherwise already have decided not to punt, since update_async calls
# this predicate before ever calling set_inflated_columns on the fast path.
# Without this check, assigning a cascade_update relationship via the update
# hashref itself (update_async({ rel => $obj })), rather than via a prior
# separate accessor call, would silently dispatch truly async and skip the
# cascade sync performs for the exact same call shape.
#
# Both checks are pure hash-key tests -- no accessor call, no I/O, no second
# invocation of set_inflated_columns -- calling the accessor itself to check
# would trigger the very query this predicate exists to let update_async
# avoid.
#
# A cascade_update relationship whose accessor attr is not 'single' (only
# possible via manual configuration; has_one/might_have always use 'single')
# is not skippable in CascadeActions's own logic, so it is always treated as
# cascading here too, matching CascadeActions's unconditional proceed for
# that case.
sub _has_cascade_update_relateds {
  my ($self, $upd) = @_;
  my $source = $self->result_source;
  my %rels = map { $_ => $source->relationship_info($_) } $source->relationships;

  for my $rel (grep { $rels{$_}{attrs}{cascade_update} } keys %rels) {
    my $accessor = $rels{$rel}{attrs}{accessor} || '';
    if ($accessor eq 'single') {
      next unless exists $self->{_relationship_data}{$rel}
        or ($upd and exists $upd->{$rel} and (!defined $upd->{$rel} or ref $upd->{$rel}));
    }
    return 1;
  }
  return 0;
}


sub update_async {
  my ($self, $upd) = @_;

  return $self->_row_run_async('update',
    sub {
      my ($backend, $fc) = @_;

      # ADR 0071: the hash is an assignment of the caller's
      $self->__assert_update_assignable($upd) if $upd;

      if (my $pkg = $self->_async_override_gap('update')) {
        return $self->_async_ctx_or_sync_punt($fc, 'update',
          'an override of update', sub { $self->update($upd) },
          $self->_async_override_gap_lead($pkg, 'update'));
      }

      if ($self->_has_on_column_change_cbs or $self->_has_cascade_update_relateds($upd)) {
        return $self->_async_ctx_or_sync_punt($fc, 'update',
          'an OnColumnChange callback or cascade_update relationship wraps update()',
          sub { $self->update($upd) });
      }

      # update() calls it first as well; the punts above run the full
      # update(), which calls it itself. It may take keys out of $upd.
      $self->prepare_update($upd);

      $self->{_dirty_columns} ||= {};
      delete local @{$self->{_dirty_columns}}{@{$self->_proxy_slots||[]}};

      $self->set_inflated_columns($upd) if $upd;

      my %to_update = $self->get_dirty_columns;
      return $fc->done($self) unless %to_update;

      $self->throw_exception( "Not in database" ) unless $self->in_storage;

      my $rsrc = $self->result_source;
      my $ident_cond = $self->_storage_ident_condition;

      return $backend->update_async($rsrc, \%to_update, $ident_cond)->then(sub {
        my ($rows) = @_;
        if ($rows == 0) {
          $self->throw_exception( "Can't update ${self}: row not found" );
        } elsif ($rows > 1) {
          $self->throw_exception("Can't update ${self}: updated more than one row");
        }
        $self->{_dirty_columns} = {};
        $self->{related_resultsets} = {};
        delete $self->{_column_data_in_storage};
        $self->store_storage_values if @{$self->storage_value_columns};
        return $self;
      });
    },
    sub { $self->update($upd) },
  );
}


sub update {
  my ($self, $upd) = @_;

  # ADR 0071: the hash is an assignment of the caller's
  $self->__assert_update_assignable($upd) if $upd;

  # whatever a component has to do before the columns are set and written;
  # it may take keys out of $upd
  $self->prepare_update($upd);

  # ProxyResultSetMethod (integrated helper): strip proxy slots from the
  # dirty-column set so UPDATE statements never include them. "delete
  # local" localises the deletion for the scope of this sub, so the
  # original dirty flags are restored when update returns.
  $self->{_dirty_columns} ||= {};
  delete local @{$self->{_dirty_columns}}{@{$self->_proxy_slots||[]}};

  # OnColumnChange (integrated helper): short-circuit when nothing is
  # registered. When callbacks exist, build the before/around/after
  # chain, then delegate to _update_body via around-wrapper; the whole
  # orchestration is a no-op if none of the registered columns are dirty.
  my $has_change_cbs =
       $self->_before_change
    || $self->_around_change
    || $self->_after_change;

  if ($has_change_cbs) {
    $self->set_inflated_columns($upd) if $upd;

    my %dirty = $self->get_dirty_columns
      or return $self;

    my @all_before = @{$self->_before_change || []};
    my @all_around = @{$self->_around_change || []};
    my @all_after  = @{$self->_after_change  || []};

    my @before = grep { defined $dirty{$_->{column}} } @all_before;
    my @around = grep { defined $dirty{$_->{column}} } @all_around;
    my @after  = grep { defined $dirty{$_->{column}} } @all_after;

    my $allow_override = $self->on_column_change_allow_override_args;
    my $final = $allow_override
      ? sub { $self->_update_body }
      : sub { $self->_update_body($upd) };

    for (reverse @around) {
      my $fn  = $_->{method};
      my $old = $self->get_storage_value($_->{column});
      my $new = $dirty{$_->{column}};
      my $old_final = $final;
      $final = sub { $self->$fn($old_final, $old, $new) };
    }

    my $txn_wrap = List::Util::first {
      defined $dirty{$_->{column}} && $_->{txn_wrap}
    } @all_before, @all_around, @all_after;

    my $guard;
    $guard = $self->result_source->schema->txn_scope_guard if $txn_wrap;

    for (@before) {
      my $fn  = $_->{method};
      my $old = $self->get_storage_value($_->{column});
      my $new = $dirty{$_->{column}};
      $self->$fn($old, $new);
    }

    my $ret = $final->();

    for (@after) {
      my $fn  = $_->{method};
      my $old = $self->get_storage_value($_->{column});
      my $new = $dirty{$_->{column}};
      $self->$fn($old, $new);
    }

    $guard->commit if $txn_wrap;

    return $ret;
  }

  return $self->_update_body($upd);
}

# Core update logic, extracted so OnColumnChange (above) can wrap it
# with before/around/after callbacks without mutual recursion.
sub _update_body {
  my ($self, $upd) = @_;

  $self->set_inflated_columns($upd) if $upd;

  my %to_update = $self->get_dirty_columns
    or return $self;

  $self->throw_exception( "Not in database" ) unless $self->in_storage;

  assert_column_value($_, $to_update{$_}) for sort keys %to_update;

  my $rows = $self->result_source->storage->update(
    $self->result_source, \%to_update, $self->_storage_ident_condition
  );
  if ($rows == 0) {
    $self->throw_exception( "Can't update ${self}: row not found" );
  } elsif ($rows > 1) {
    $self->throw_exception("Can't update ${self}: updated more than one row");
  }
  $self->{_dirty_columns} = {};
  $self->{related_resultsets} = {};
  delete $self->{_column_data_in_storage};

  # StorageValues (integrated helper): refresh snapshot post-UPDATE.
  $self->store_storage_values if @{$self->storage_value_columns};

  return $self;
}


sub delete {
  my $self = shift;
  if (ref $self) {
    $self->throw_exception( "Not in database" ) unless $self->in_storage;

    $self->prepare_delete;

    $self->result_source->storage->delete(
      $self->result_source, $self->_storage_ident_condition
    );

    delete $self->{_column_data_in_storage};
    $self->in_storage(0);
  }
  else {
    my $rsrc = try { $self->result_source_instance }
      or $self->throw_exception("Can't do class delete without a ResultSource instance");

    my $attrs = @_ > 1 && ref $_[$#_] eq 'HASH' ? { %{pop(@_)} } : {};
    my $query = ref $_[0] eq 'HASH' ? $_[0] : {@_};
    $rsrc->resultset->search(@_)->delete;
  }
  return $self;
}

# True if any relationship on this row's source has cascade_delete set --
# mirrors DBIO::Relationship::CascadeActions::delete's own gate. Shared by
# delete_async's punt check, below.
sub _has_cascade_delete_relateds {
  my $self = shift;
  my $source = $self->result_source;
  my %rels = map { $_ => $source->relationship_info($_) } $source->relationships;
  return !! grep { $rels{$_}{attrs}{cascade_delete} } keys %rels;
}


sub delete_async {
  my $self = shift;

  return $self->_row_run_async('delete',
    sub {
      my ($backend, $fc) = @_;

      $self->throw_exception( "Not in database" ) unless $self->in_storage;

      if (my $pkg = $self->_async_override_gap('delete')) {
        return $self->_async_ctx_or_sync_punt($fc, 'delete',
          'an override of delete', sub { $self->delete },
          $self->_async_override_gap_lead($pkg, 'delete'));
      }

      if ($self->_has_cascade_delete_relateds) {
        return $self->_async_ctx_or_sync_punt($fc, 'delete',
          'a cascade_delete relationship makes this a multi-statement delete',
          sub { $self->delete });
      }

      # delete() calls it at this point as well; the punts above run the
      # full delete(), which calls it itself.
      $self->prepare_delete;

      my $rsrc = $self->result_source;
      return $backend->delete_async($rsrc, $self->_storage_ident_condition)->then(sub {
        delete $self->{_column_data_in_storage};
        $self->in_storage(0);
        return $self;
      });
    },
    sub { $self->delete },
  );
}


sub prepare_insert { }
sub prepare_update { }
sub prepare_delete { }


sub get_column {
  my ($self, $column) = @_;
  $self->throw_exception( "Can't fetch data as class method" ) unless ref $self;

  return $self->{_column_data}{$column}
    if exists $self->{_column_data}{$column};

  if (exists $self->{_inflated_column}{$column}) {
    # deflate+return cycle
    return $self->store_column($column, $self->_deflated_column(
      $column, $self->{_inflated_column}{$column}
    ));
  }

  $self->throw_exception( "No such column '${column}' on " . ref $self )
    unless $self->result_source->has_column($column);

  return undef;
}


sub has_column_loaded {
  my ($self, $column) = @_;
  $self->throw_exception( "Can't call has_column data as class method" ) unless ref $self;

  return (
    exists $self->{_inflated_column}{$column}
      or
    exists $self->{_column_data}{$column}
  ) ? 1 : 0;
}


sub get_columns {
  my $self = shift;
  if (exists $self->{_inflated_column}) {
    # deflate cycle for each inflation, including filter rels
    foreach my $col (keys %{$self->{_inflated_column}}) {
      unless (exists $self->{_column_data}{$col}) {

        # if cached related_resultset is present assume this was a prefetch
        carp_unique(
          "Returning primary keys of prefetched 'filter' rels as part of get_columns() is deprecated and will "
        . 'eventually be removed entirely (set DBIO_COLUMNS_INCLUDE_FILTER_RELS to disable this warning)'
        ) if (
          ! $ENV{DBIO_COLUMNS_INCLUDE_FILTER_RELS}
            and
          defined $self->{related_resultsets}{$col}
            and
          defined $self->{related_resultsets}{$col}->get_cache
        );

        $self->store_column($col, $self->_deflated_column($col, $self->{_inflated_column}{$col}));
      }
    }
  }
  return %{$self->{_column_data}};
}


sub get_dirty_columns {
  my $self = shift;
  return map { $_ => $self->{_column_data}{$_} }
           keys %{$self->{_dirty_columns}};
}


sub make_column_dirty {
  my ($self, $column) = @_;

  $self->throw_exception( "No such column '${column}' on " . ref $self )
    unless exists $self->{_column_data}{$column} || $self->result_source->has_column($column);

  # the entire clean/dirty code relies on exists, not on true/false
  return 1 if exists $self->{_dirty_columns}{$column};

  $self->{_dirty_columns}{$column} = 1;

  # if we are just now making the column dirty, and if there is an inflated
  # value, force it over the deflated one
  if (exists $self->{_inflated_column}{$column}) {
    $self->store_column($column,
      $self->_deflated_column(
        $column, $self->{_inflated_column}{$column}
      )
    );
  }
}


sub get_inflated_columns {
  my $self = shift;

  my $loaded_colinfo = $self->result_source->columns_info;
  $self->has_column_loaded($_) or delete $loaded_colinfo->{$_}
    for keys %$loaded_colinfo;

  my %cols_to_return = ( %{$self->{_column_data}}, %$loaded_colinfo );

  unless ($ENV{DBIO_COLUMNS_INCLUDE_FILTER_RELS}) {
    for (keys %$loaded_colinfo) {
      # if cached related_resultset is present assume this was a prefetch
      if (
        $loaded_colinfo->{$_}{_inflate_info}
          and
        defined $self->{related_resultsets}{$_}
          and
        defined $self->{related_resultsets}{$_}->get_cache
      ) {
        carp_unique(
          "Returning prefetched 'filter' rels as part of get_inflated_columns() is deprecated and will "
        . 'eventually be removed entirely (set DBIO_COLUMNS_INCLUDE_FILTER_RELS to disable this warning)'
        );
        last;
      }
    }
  }

  map { $_ => (
  (
    ! exists $loaded_colinfo->{$_}
      or
    (
      exists $loaded_colinfo->{$_}{accessor}
        and
      ! defined $loaded_colinfo->{$_}{accessor}
    )
  ) ? $self->get_column($_)
    : $self->${ \(
      defined $loaded_colinfo->{$_}{accessor}
        ? $loaded_colinfo->{$_}{accessor}
        : $_
      )}
  )} keys %cols_to_return;
}

sub _is_column_numeric {
    my ($self, $column) = @_;

    return undef unless $self->result_source->has_column($column);

    my $colinfo = $self->result_source->column_info ($column);

    # cache for speed (the object may *not* have a resultsource instance)
    if (
      ! defined $colinfo->{is_numeric}
        and
      my $storage = try { $self->result_source->schema->storage }
    ) {
      $colinfo->{is_numeric} =
        $storage->is_datatype_numeric ($colinfo->{data_type})
          ? 1
          : 0
        ;
    }

    return $colinfo->{is_numeric};
}


sub set_column {
  my ($self, $column, $new_value) = @_;

  my $had_value = $self->has_column_loaded($column);
  my $old_value = $self->get_column($column);

  $new_value = $self->store_column($column, $new_value);

  my $dirty =
    $self->{_dirty_columns}{$column}
      ||
    ( $self->in_storage # no point tracking dirtyness on uninserted data
      ? ! $self->_eq_column_values ($column, $old_value, $new_value)
      : 1
    )
  ;

  if ($dirty) {
    # FIXME sadly the update code just checks for keys, not for their value
    $self->{_dirty_columns}{$column} = 1;

    # Clear out the relation/inflation cache related to this column
    #
    # FIXME - this is a quick *largely incorrect* hack, pending a more
    # serious rework during the merge of single and filter rels
    my $rel_names = $self->result_source->{_relationships};
    for my $rel_name (keys %$rel_names) {

      my $acc = $rel_names->{$rel_name}{attrs}{accessor} || '';

      if ( $acc eq 'single' and $rel_names->{$rel_name}{attrs}{fk_columns}{$column} ) {
        delete $self->{related_resultsets}{$rel_name};
        delete $self->{_relationship_data}{$rel_name};
        #delete $self->{_inflated_column}{$rel_name};
      }
      elsif ( $acc eq 'filter' and $rel_name eq $column) {
        delete $self->{related_resultsets}{$rel_name};
        #delete $self->{_relationship_data}{$rel_name};
        delete $self->{_inflated_column}{$rel_name};
      }
    }
    delete $self->{_inflated_column}{$column};

    if (
      # value change from something (even if NULL)
      $had_value
        and
      # no storage - no storage-value
      $self->in_storage
        and
      # no value already stored (multiple changes before commit to storage)
      ! exists $self->{_column_data_in_storage}{$column}
        and
      $self->_track_storage_value($column)
    ) {
      $self->{_column_data_in_storage}{$column} = $old_value;
    }
  }

  return $new_value;
}

sub _eq_column_values {
  my ($self, $col, $old, $new) = @_;

  if (defined $old xor defined $new) {
    return 0;
  }
  elsif (not defined $old) {  # both undef
    return 1;
  }
  elsif (
    is_literal_value $old
      or
    is_literal_value $new
  ) {
    return 0;
  }
  elsif ($old eq $new) {
    return 1;
  }
  elsif ($self->_is_column_numeric($col)) {  # do a numeric comparison if datatype allows it
    return $old == $new;
  }
  else {
    return 0;
  }
}

# returns a boolean indicating if the passed column should have its original
# value tracked between column changes and commitment to storage
sub _track_storage_value {
  my ($self, $col) = @_;

  my @pri = $self->result_source->primary_columns;

  # Without a primary key the row's identity is whatever get_from_storage's
  # fallback builds it from, and that is *every* loaded column: find()'s
  # heuristics narrow down to a unique constraint when one matches, but a
  # source declaring none at all ends up in _non_unique_find_fallback, which
  # uses the lot. Tracking only the unique-constraint columns would therefore
  # leave exactly those sources unable to identify a dirty row, so track
  # everything -- the map still only ever holds columns that actually changed.
  return 1 unless @pri;

  return scalar grep { $col eq $_ } @pri;
}


sub set_columns {
  my ($self, $values) = @_;
  $self->set_column( $_, $values->{$_} ) for keys %$values;
  return $self;
}


sub set_inflated_columns {
  my ( $self, $upd ) = @_;
  my $rsrc;
  foreach my $key (keys %$upd) {
    if (!defined $upd->{$key} || ref $upd->{$key}) {
      $rsrc ||= $self->result_source;
      my $info = $rsrc->relationship_info($key);
      my $acc_type = $info->{attrs}{accessor} || '';

      # A plain hashref for a to-one relationship is column values of the
      # related row, not a related object: set_from_related reduces it to
      # this row's own columns or refuses it (ADR 0034), whichever accessor
      # the relationship has. There is no object in it to deflate or to keep
      # -- what the row held for the relationship goes or stays with those
      # columns, as for any other set_column.
      if (
        ref $upd->{$key} eq 'HASH'
          and
        ( $acc_type eq 'single' or $acc_type eq 'filter' )
      ) {
        $self->set_from_related($key => delete $upd->{$key});
      }
      elsif ($acc_type eq 'single') {
        my $rel_obj = delete $upd->{$key};
        $self->set_from_related($key => $rel_obj);
        $self->{_relationship_data}{$key} = $rel_obj;
      }
      elsif ($acc_type eq 'multi') {
        $self->throw_exception(
          "Recursive update is not supported over relationships of type '$acc_type' ($key)"
        );
      }
      elsif (
        $rsrc->has_column($key)
          and
        exists $rsrc->column_info($key)->{_inflate_info}
      ) {
        $self->set_inflated_column($key, delete $upd->{$key});
      }
    }
  }
  $self->set_columns($upd);
}


sub copy {
  my ($self, $changes) = @_;

  # ProxyResultSetMethod (integrated helper): proxied values are not
  # real columns and must not be carried into the copy.
  delete local @{$self->{_column_data}}{@{$self->_proxy_slots||[]}};

  $changes ||= {};
  my $col_data = { $self->get_columns };

  my $rsrc = $self->result_source;

  my $colinfo = $rsrc->columns_info;
  foreach my $col (keys %$col_data) {
    delete $col_data->{$col}
      if ( ! $colinfo->{$col} or $colinfo->{$col}{is_auto_increment} );
  }

  my $new = { _column_data => $col_data };
  bless $new, ref $self;

  $new->result_source($rsrc);
  $new->set_inflated_columns($changes);

  # ADR 0045 / karr k325: the copy of a context-bound row keeps the pin, as the
  # one copy_async builds does. The insert below is synchronous and does not
  # read it.
  $new->{_async_context} = $self->{_async_context} if $self->{_async_context};

  $new->insert;

  # Its possible we'll have 2 relations to the same Source. We need to make
  # sure we don't try to insert the same row twice else we'll violate unique
  # constraints
  my $rel_names_copied = {};

  foreach my $rel_name ($rsrc->relationships) {
    my $rel_info = $rsrc->relationship_info($rel_name);

    next unless $rel_info->{attrs}{cascade_copy};

    my $resolved = $rsrc->_resolve_condition(
      $rel_info->{cond}, $rel_name, $new, $rel_name
    );

    my $copied = $rel_names_copied->{ $rel_info->{source} } ||= {};
    foreach my $related ($self->search_related($rel_name)->all) {
      $related->copy($resolved)
        unless $copied->{$related->ID}++;
    }

  }
  return $new;
}

# True if any relationship on this row's source has cascade_copy set --
# mirrors copy()'s own gate (`next unless $rel_info->{attrs}{cascade_copy}`,
# above). Shared by copy_async's punt check, below.
sub _has_cascade_copy_relateds {
  my $self = shift;
  my $source = $self->result_source;
  my %rels = map { $_ => $source->relationship_info($_) } $source->relationships;
  return !! grep { $rels{$_}{attrs}{cascade_copy} } keys %rels;
}


sub copy_async {
  my ($self, $changes) = @_;

  return $self->_row_run_async('copy',
    sub {
      my ($backend, $fc) = @_;

      if ($self->_has_cascade_copy_relateds) {
        return $self->_async_ctx_or_sync_punt($fc, 'copy',
          'copy with a cascade_copy relationship is a multi-row cascade',
          sub { $self->copy($changes) });
      }

      # ProxyResultSetMethod (integrated helper): proxied values are not
      # real columns and must not be carried into the copy.
      delete local @{$self->{_column_data}}{@{$self->_proxy_slots||[]}};

      my $applied_changes = $changes || {};
      my $col_data = { $self->get_columns };

      my $rsrc = $self->result_source;

      my $colinfo = $rsrc->columns_info;
      foreach my $col (keys %$col_data) {
        delete $col_data->{$col}
          if ( ! $colinfo->{$col} or $colinfo->{$col}{is_auto_increment} );
      }

      my $new = { _column_data => $col_data };
      bless $new, ref $self;

      $new->result_source($rsrc);
      $new->set_inflated_columns($applied_changes);

      # ADR 0045 / karr k195: the copy inherits the pin so its insert runs on the
      # pinned connection instead of a sibling pool connection outside the txn.
      $new->{_async_context} = $self->{_async_context} if $self->{_async_context};

      return $new->insert_async;
    },
    sub { $self->copy($changes) },
  );
}


sub store_column {
  my ($self, $column, $value) = @_;
  $self->throw_exception( "No such column '${column}' on " . ref $self )
    unless exists $self->{_column_data}{$column} || $self->result_source->has_column($column);
  $self->throw_exception( "set_column called for ${column} without value" )
    if @_ < 3;
  # a raw value, or the value a deflate / filter / encode handed on
  assert_column_value($column, $value);
  return $self->{_column_data}{$column} = $value;
}


sub inflate_result {
  my ($class, $rsrc, $me, $prefetch) = @_;

  my $new = bless
    { _column_data => $me, _result_source => $rsrc },
    ref $class || $class
  ;

  if ($prefetch) {
    for my $rel_name ( keys %$prefetch ) {

      my $relinfo = $rsrc->relationship_info($rel_name) or do {
        my $err = sprintf
          "Inflation into non-existent relationship '%s' of '%s' requested",
          $rel_name,
          $rsrc->source_name,
        ;
        if (my ($colname) = sort { length($a) <=> length ($b) } keys %{$prefetch->{$rel_name}[0] || {}} ) {
          $err .= sprintf ", check the inflation specification (columns/as) ending in '...%s.%s'",
          $rel_name,
          $colname,
        }

        $rsrc->throw_exception($err);
      };

      $class->throw_exception("No accessor type declared for prefetched relationship '$rel_name'")
        unless $relinfo->{attrs}{accessor};

      my $rel_rs = $new->related_resultset($rel_name);

      my @rel_objects;
      if (
        @{ $prefetch->{$rel_name} || [] }
          and
        ref($prefetch->{$rel_name}) ne $DBIO::ResultSource::RowParser::Util::null_branch_class
      ) {

        if (ref $prefetch->{$rel_name}[0] eq 'ARRAY') {
          my $rel_rsrc = $rel_rs->result_source;
          my $rel_class = $rel_rs->result_class;
          my $rel_inflator = $rel_class->can('inflate_result');
          @rel_objects = map
            { $rel_class->$rel_inflator ( $rel_rsrc, @$_ ) }
            @{$prefetch->{$rel_name}}
          ;
        }
        else {
          @rel_objects = $rel_rs->result_class->inflate_result(
            $rel_rs->result_source, @{$prefetch->{$rel_name}}
          );
        }
      }

      if ($relinfo->{attrs}{accessor} eq 'single') {
        $new->{_relationship_data}{$rel_name} = $rel_objects[0];
      }
      elsif ($relinfo->{attrs}{accessor} eq 'filter') {
        $new->{_inflated_column}{$rel_name} = $rel_objects[0];
      }

      $rel_rs->set_cache(\@rel_objects);
    }
  }

  $new->in_storage (1);

  # StorageValues (integrated helper): snapshot freshly-inflated values.
  $new->store_storage_values if @{$new->storage_value_columns};

  return $new;
}


sub insert_or_update { shift->update_or_insert(@_) }

sub update_or_insert {
  my $self = shift;
  return ($self->in_storage ? $self->update : $self->insert);
}


sub insert_or_update_async { shift->update_or_insert_async(@_) }


sub update_or_insert_async {
  my $self = shift;
  return ($self->in_storage ? $self->update_async : $self->insert_async);
}


sub is_changed {
  return keys %{shift->{_dirty_columns} || {}};
}


sub is_column_changed {
  my( $self, $col ) = @_;
  return exists $self->{_dirty_columns}->{$col};
}


sub result_source {
  $_[0]->throw_exception( 'result_source can be called on instances only' )
    unless ref $_[0];

  @_ > 1
    ? $_[0]->{_result_source} = $_[1]

    # note this is a || not a ||=, the difference is important
    : $_[0]->{_result_source} || do {
        my $class = ref $_[0];
        $_[0]->can('result_source_instance')
          ? $_[0]->result_source_instance
          : $_[0]->throw_exception(
            "No result source instance registered for $class, did you forget to call $class->table(...) ?"
          )
      }
  ;
}


sub register_column {
  my ($class, $col, $info) = @_;
  my $acc = $col;
  if (exists $info->{accessor}) {
    return unless defined $info->{accessor};
    $acc = [ $info->{accessor}, $col ];
  }
  $class->mk_group_accessors('column' => $acc);
}


sub get_from_storage {
    my $self = shift @_;
    my $attrs = shift @_;
    my $resultset = $self->result_source->resultset;

    if(defined $attrs) {
      $resultset = $resultset->search(undef, $attrs);
    }

    # ADR 0045 / karr k325: the lookup itself is synchronous and never reads
    # the pin, but the row it returns is derived from this one and keeps it --
    # and so does this row when discard_changes refreshes it from that copy.
    $resultset->{_async_context} = $self->{_async_context}
      if $self->{_async_context};

    if ($self->result_source->primary_columns) {
      return $resultset->find($self->_storage_ident_condition, { key => 'primary' });
    }

    # No primary key defined — fall back to heuristics mode using all loaded
    # column values so find() can match against any available unique constraint.
    # Values follow the same precedence as DBIO::PK/_ident_values does for the
    # PK path: the last known in-storage value wins over a dirty in-memory one,
    # so we look the row up as it currently is in the database.
    my %cond;
    for my $col ($self->result_source->columns) {
      next unless $self->has_column_loaded($col);
      $cond{$col} = exists $self->{_column_data_in_storage}{$col}
        ? $self->{_column_data_in_storage}{$col}
        : $self->get_column($col)
      ;
    }

    # all loaded columns describe the row; a unique constraint among them
    # makes that a find, otherwise it is a plain search for that row
    return $resultset->find(\%cond)
      if $resultset->_covered_constraints(($resultset->_merge_with_rscond(\%cond))[0]);

    return $resultset->search(
      $resultset->_qualify_cond_columns(\%cond, $resultset->current_source_alias)
    )->single;
}


sub get_from_storage_async {
    my $self = shift @_;
    my $attrs = shift @_;
    my $resultset = $self->result_source->resultset;

    if(defined $attrs) {
      $resultset = $resultset->search(undef, $attrs);
    }

    # ADR 0045 / karr k195: a refetch off a context-bound row (directly or via
    # discard_changes_async) stays on the pinned connection. find_async's own
    # _rs_run_async then dispatches the lookup through the pinned context.
    $resultset->{_async_context} = $self->{_async_context}
      if $self->{_async_context};

    if ($self->result_source->primary_columns) {
      return $resultset->find_async($self->_storage_ident_condition, { key => 'primary' });
    }

    # No primary key defined — fall back to heuristics mode using all loaded
    # column values so find_async() can match against available unique constraints.
    # Same value precedence as the sync L</get_from_storage> path: in-storage
    # state wins over a dirty in-memory value.
    my %cond;
    for my $col ($self->result_source->columns) {
      next unless $self->has_column_loaded($col);
      $cond{$col} = exists $self->{_column_data_in_storage}{$col}
        ? $self->{_column_data_in_storage}{$col}
        : $self->get_column($col)
      ;
    }

    return $resultset->find_async(\%cond)
      if $resultset->_covered_constraints(($resultset->_merge_with_rscond(\%cond))[0]);

    return $resultset->search(
      $resultset->_qualify_cond_columns(\%cond, $resultset->current_source_alias)
    )->single_async;
}


sub discard_changes {
  my ($self, $attrs) = @_;
  return unless $self->in_storage; # Don't reload if we aren't real!

  # add a replication default to read from the master only
  $attrs = { force_pool => 'master', %{$attrs||{}} };

  if( my $current_storage = $self->get_from_storage($attrs)) {

    # Set $self to the current.
    %$self = %$current_storage;

    # Avoid a possible infinite loop with
    # sub DESTROY { $_[0]->discard_changes }
    bless $current_storage, 'Do::Not::Exist';

    return $self;
  }
  else {
    $self->in_storage(0);
    return $self;
  }
}


sub discard_changes_async {
  my ($self, $attrs) = @_;

  return $self->_row_run_async('discard_changes',
    sub {
      my ($backend, $fc) = @_;
      return $fc->done(undef) unless $self->in_storage; # Don't reload if we aren't real!

      # add a replication default to read from the master only
      my $merged_attrs = { force_pool => 'master', %{$attrs||{}} };

      return $self->get_from_storage_async($merged_attrs)->then(sub {
        my ($current_storage) = @_;

        if ($current_storage) {
          # Set $self to the current.
          %$self = %$current_storage;

          # Avoid a possible infinite loop with
          # sub DESTROY { $_[0]->discard_changes }
          bless $current_storage, 'Do::Not::Exist';

          return $self;
        }
        else {
          $self->in_storage(0);
          return $self;
        }
      });
    },
    sub { $self->discard_changes($attrs) },
  );
}


sub throw_exception {
  my $self=shift;

  if (ref $self && ref (my $rsrc = try { $self->result_source_instance } ) ) {
    $rsrc->throw_exception(@_)
  }
  else {
    DBIO::Exception->throw(@_);
  }
}


# ============================================================
# Integrated helper methods (from DBIx::Class::Helpers by FREW)
# ============================================================


{
  my $dont_serialize = { text => 1, ntext => 1, blob => 1 };

  sub _is_column_serializable {
    my ($self, $column) = @_;
    my $info = $self->column_info($column);
    if (!defined $info->{is_serializable}) {
      if (defined $info->{data_type} && $dont_serialize->{lc $info->{data_type}}) {
        $info->{is_serializable} = 0;
      } else {
        $info->{is_serializable} = 1;
      }
    }
    return $info->{is_serializable};
  }
}

sub serializable_columns {
  my $self = shift;
  return [
    grep { $self->_is_column_serializable($_) }
      $self->result_source->columns
  ];
}

sub TO_JSON {
  my $self = shift;
  my %all_cols = $self->get_columns;
  my @ser_cols = grep { exists $all_cols{$_} }
    @{ $self->serializable_columns };

  my %data;
  for my $col (@ser_cols) {
    my $val = $all_cols{$col};
    # numify numeric columns for correct JSON encoding
    if (defined $val && $self->_is_column_numeric($col)) {
      $val += 0;
    }
    $data{$col} = $val;
  }
  return \%data;
}


sub self_rs {
  my ($self) = @_;
  my $rs = $self->result_source->resultset;
  # ADR 0045 / karr k325: the resultset of a context-bound row keeps the pin
  # (the ->search_rs below passes it on to the returned clone).
  $rs->{_async_context} = $self->{_async_context} if $self->{_async_context};
  return $rs->search_rs($self->ident_condition($rs->current_source_alias));
}


# --- clean_rs: get unfiltered ResultSet for this row's source ---
sub clean_rs {
  my ($self) = @_;
  my $rs = $self->result_source->resultset;
  # ADR 0045 / karr k325: unfiltered, but still derived from this row -- the
  # pin of a context-bound row stays.
  $rs->{_async_context} = $self->{_async_context} if $self->{_async_context};
  return $rs;
}

# ------------------------------------------------------------
# StorageValues
# ------------------------------------------------------------


__PACKAGE__->mk_group_accessors(inherited => '_storage_value_columns');
__PACKAGE__->mk_group_accessors(inherited => '_storage_values');


sub _has_storage_value { $_[0]->column_info($_[1])->{keep_storage_value} }


sub storage_value_columns {
  my $self = shift;
  if (!$self->_storage_value_columns) {
    $self->_storage_value_columns([
      grep $self->_has_storage_value($_),
        $self->result_source->columns
    ]);
  }
  return $self->_storage_value_columns;
}


sub store_storage_values {
  my $self = shift;
  $self->_storage_values({
    map {
      my $acc = ($self->column_info($_)->{accessor} || $_);
      $_ => _clone_for_storage($self->$acc)
    } @{$self->storage_value_columns}
  });
  $self->_storage_values;
}

# Clone a value for storage snapshot. DateTime objects are cloned so
# later mutations don't corrupt the snapshot. Plain scalars/objects
# without clone are stored as-is (acceptable for numbers, strings,
# and DBIO Row objects which are inherently snapshot-like).
sub _clone_for_storage {
  my ($val) = @_;
  return $val unless defined $val;
  if (blessed($val) && $val->can('clone')) {
    return $val->clone;
  }
  return $val;
}


sub get_storage_value {
  my ($self, $col) = @_;
  return DBIO::Row::_clone_for_storage($self->_storage_values->{$col});
}

# ------------------------------------------------------------
# OnColumnChange
# ------------------------------------------------------------


__PACKAGE__->mk_group_accessors(inherited => $_)
  for qw(_before_change _around_change _after_change);

sub _register_column_change {
  my ($self, $slot, $prepend, $column, $args) = @_;
  $self->throw_exception('method is a required parameter')
    unless $args->{method};
  $args->{column}   = $column;
  $args->{txn_wrap} = !!$args->{txn_wrap};
  $self->$slot([]) unless $self->$slot;
  if ($prepend) {
    unshift @{$self->$slot}, $args;
  } else {
    push @{$self->$slot}, $args;
  }
  return;
}


sub before_column_change {
  $_[0]->throw_exception(
    'Invalid number of arguments. One $column => $args pair at a time.'
  ) unless @_ == 3;
  my ($self, $column, $args) = @_;
  $self->_register_column_change('_before_change', 0, $column, $args);
}


sub around_column_change {
  $_[0]->throw_exception(
    'Invalid number of arguments. One $column => $args pair at a time.'
  ) unless @_ == 3;
  my ($self, $column, $args) = @_;
  $self->_register_column_change('_around_change', 0, $column, $args);
}


sub after_column_change {
  $_[0]->throw_exception(
    'Invalid number of arguments. One $column => $args pair at a time.'
  ) unless @_ == 3;
  my ($self, $column, $args) = @_;
  $self->_register_column_change('_after_change', 1, $column, $args);
}


sub on_column_change_allow_override_args { 0 }

# ------------------------------------------------------------
# ProxyResultSetMethod
# ------------------------------------------------------------


__PACKAGE__->mk_group_accessors(inherited => '_proxy_slots');


sub proxy_resultset_method {
  my ($self, $name, $attr) = @_;
  $attr ||= {};

  my $rs_method = $attr->{resultset_method} || "with_$name";
  my $slot      = $attr->{slot} || $name;

  $self->_proxy_slots([]) unless $self->_proxy_slots;
  push @{$self->_proxy_slots}, $slot;

  my $fq = $self . '::' . $name;
  my $body = sub {
    my ($row) = @_;
    unless ($row->has_column_loaded($slot)) {
      $row->{_column_data}{$slot} = undef;
      $row->set_column(
        $slot,
        $row->self_rs
            ->search(undef, { columns => [] })
            ->$rs_method
            ->get_column($slot)
            ->next,
      );
    }
    return $row->get_column($slot);
  };

  no strict 'refs';
  *{$fq} = Sub::Util::set_subname($fq, $body);
  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Row - Basic row methods

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

=head1 DESCRIPTION

L<DBIO::Row> implements the basic row lifecycle for DBIO result objects:
construction, column updates, inserts, deletes, refreshes, and related-object
handling.

Result objects are returned from L<DBIO::ResultSet> instances using the
L<create|DBIO::ResultSet/create>, L<find|DBIO::ResultSet/find>,
L<next|DBIO::ResultSet/next> and L<all|DBIO::ResultSet/all> methods,
as well as invocations of 'single' (
L<belongs_to|DBIO::Relationship/belongs_to>,
L<has_one|DBIO::Relationship/has_one> or
L<might_have|DBIO::Relationship/might_have>)
relationship accessors of L<Result|DBIO::Manual::ResultClass> objects.

=head1 METHODS

=head2 new

  my $result = My::Class->new(\%attrs);

  my $result = $schema->resultset('MySource')->new(\%colsandvalues);

=over

=item Arguments: \%attrs or \%colsandvalues

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

While you can create a new result object by calling C<new> directly on
this class, you are better off calling it on a
L<DBIO::ResultSet> object.

When calling it directly, you will not get a complete, usable row
object until you pass the C<-result_source> attribute or call
L</result_source> with a
L<DBIO::ResultSource> instance that is attached to a
L<DBIO::Schema> with a valid connection.

C<$attrs> is a hashref of column name, value data. It can also contain
some other attributes such as C<-result_source>.

Passing an object, or an arrayref of objects as a value will call
L<DBIO::Relationship::Base/set_from_related> for you. When
passed a hashref or an arrayref of hashrefs as the value, these will
be turned into objects via new_related, and treated as if you had
passed objects.

For a more involved explanation, see L<DBIO::ResultSet/create>.

Passing a request hash to C<new> is mass assignment: what ends up in the
columns is what is checked. A column or relationship marked
L<is_guarded|DBIO::ResultSource/is_guarded> takes no value or data from the
hash, and neither does a relationship value that resolves to a guarded foreign
key column. A hash of related data is looked up with
L<DBIO::ResultSet/find> only for a C<belongs_to> relationship when it gives
every column of a unique constraint of the related source, any other related
data is created: being unique is no permission to link a row, so mark the
relationship or its foreign key C<is_guarded> where a caller may not link
existing rows. When the row is built by a resultset with a condition, a value
of the caller's that contradicts an equality of the condition throws, see
L<DBIO::ResultSet/create>.

Please note that if a value is not passed to new, no value will be sent
in the SQL INSERT call, and the column will therefore assume whatever
default value was specified in your database. While DBIO will retrieve the
value of autoincrement columns, it will never make an explicit database
trip to retrieve default values assigned by the RDBMS. You can explicitly
request that all values be fetched back from the database by calling
L</discard_changes>, or you can supply an explicit C<undef> to columns
with NULL as the default, and save yourself a SELECT.

 CAVEAT:

 The behavior described above will backfire if you use a foreign key column
 with a database-defined default. If you call the relationship accessor on
 an object that doesn't have a set value for the FK column, DBIO will throw
 an exception, as it has no way of knowing the PK of the related object (if
 there is one).

=head2 $column_accessor

  # Each pair does the same thing

  # (un-inflated, regular column)
  my $val = $result->get_column('first_name');
  my $val = $result->first_name;

  $result->set_column('first_name' => $val);
  $result->first_name($val);

  # (inflated column via DBIO::InflateColumn::DateTime)
  my $val = $result->get_inflated_column('last_modified');
  my $val = $result->last_modified;

  $result->set_inflated_column('last_modified' => $val);
  $result->last_modified($val);

=over

=item Arguments: $value?

=item Return Value: $value

=back

A column accessor method is created for each column, which is used for
getting/setting the value for that column.

The actual method name is based on the
L<accessor|DBIO::ResultSource/accessor> name given during the
L<Result Class|DBIO::Manual::ResultClass> L<column definition
|DBIO::ResultSource/add_columns>. Like L</set_column>, this
will not store the data in the database until L</insert> or L</update>
is called on the row.

=head2 insert

  $result->insert;

=over

=item Arguments: none

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Inserts an object previously created by L</new> into the database if
it isn't already in there. Returns the object itself. To insert an
entirely new row into the database, use L<DBIO::ResultSet/create>.

To fetch an uninserted result object, call
L<new_result|DBIO::ResultSet/new_result> on a resultset.

This will also insert any uninserted, related objects held inside this
one, see L<DBIO::ResultSet/create> for more details.

=head2 with_context

    $row->with_context($ctx)->update_async(\%changes);

Returns a clone of this row bound to a pinned async context -- the object
handed to a L<DBIO::Storage::Async/txn_do_async> or C<pipeline> coderef.
Once bound, every C<*_async> method on the clone routes onto the context's
pinned connection instead of the pool. If the row carries eagerly-prefetched
children, the pin cascades through them: the clone gets a fresh set of bound
child resultsets (and bound cached grandchildren), so a prefetched child
fetched off the clone stays pinned too, while the unbound source's rows and
related resultsets are left untouched. See L<DBIO::ResultSet/with_context>
for the full picture; a row inherits this binding automatically when it is
derived from a context-bound resultset.

What is derived from a bound row is bound as well (ADR 0045): its related
resultsets and rows (L<DBIO::Relationship::Base/related_resultset>,
L<DBIO::Relationship::Base/search_related>, the relationship accessors, the row
a many-to-many C<add_to_$rel> finds or creates), L</self_rs> and L</clean_rs>,
the row L</get_from_storage> or L</get_from_storage_async> returns, the copy
L</copy> or L</copy_async> returns, and -- with those components loaded -- the
sibling resultsets and rows of L<DBIO::Ordered> and
L<DBIO::ChangeLog/changelog>. L</discard_changes> and
L</discard_changes_async> leave the row bound.

The synchronous methods among these do their own reading and writing through
the synchronous storage, outside the pinned transaction or pipeline; it is the
object they hand back that keeps the binding for a C<*_async> called on it.

In the C<immediate> mode the context C<txn_do_async> hands its coderef is the
storage itself, and C<with_context> takes it; see
L<DBIO::ResultSet/with_context> for what is particular to that mode.

=head2 _has_storage_value

Returns true if the given column opts in via C<keep_storage_value>.
Override on a Result class to enable snapshotting by other criteria
(e.g. "all integer columns").

=head2 storage_value_columns

Arrayref of columns that will be snapshotted on this row.

=head2 store_storage_values

Refresh the snapshot from the current accessor values.

=head2 get_storage_value

  $row->get_storage_value('title')

Returns the snapshotted value for a column.

=head2 before_column_change

  __PACKAGE__->before_column_change(col => { method => ..., txn_wrap => 0 });

=head2 around_column_change

  __PACKAGE__->around_column_change(col => { method => ..., txn_wrap => 0 });

=head2 after_column_change

  __PACKAGE__->after_column_change(col => { method => ..., txn_wrap => 0 });

=head2 on_column_change_allow_override_args

Override and return true on your Result class if a C<before_column_change>
callback should be able to replace values passed to C<update($upd)>.
Defaults to false to preserve historic behaviour.

=head2 proxy_resultset_method

  __PACKAGE__->proxy_resultset_method($name, {
    slot             => $slot,             # defaults to $name
    resultset_method => $rs_method,        # defaults to "with_$name"
  });

=head1 NOTE

All row objects produced from a schema-attached L<DBIO::ResultSet> (for
example via C<< search->next >>) are actually instances of your application's
L<Result Class|DBIO::Manual::Glossary/Result Class>.

L<DBIO::Row> implements most of the row-level communication with the
underlying storage, but a Result class B<should not inherit from it directly>.
Result classes normally inherit from L<DBIO::Core>, which composes
L<DBIO::Row> together with other core behavior. Therefore, while many of the
methods available to a
L<DBIO::Core>-derived Result class are described in the following
documentation, it does not detail all of the methods available to Result
objects.  Refer to L<DBIO::Manual::ResultClass> for more info.

=head2 insert_async

  my $future = $row->insert_async;
  $future->then(sub { my $row = shift; ... });

Async variant of L</insert>. For a plain single-row insert the storage write is
routed through the backend's C<insert_async> and the returned columns are folded
back into the object in the Future's C<then> (reusing the same store-back as the
synchronous L</insert>), resolving with C<$self>.

What counts as a plain single-row insert is what L</insert> sends as one
C<INSERT>. A row may carry an object for a column with an inflator
-- it is deflated into the statement -- and a related row for a C<belongs_to>
that was already in storage when the row was built -- it lends its key as the
foreign key. Both go out as that one C<INSERT>, with the values L</insert>
writes.

An insert that involves related-object multi-create does not: a related row
that has to be looked up or inserted B<before> this one (a C<belongs_to> given
as a hashref or as a row not yet in storage), or related rows that are
inserted B<after> it (a C<has_many> given as an arrayref, a C<has_one> /
C<might_have> row). On an unbound row that is performed synchronously and the
Future is returned settled: resolved with C<$self>, or failed with what the
insert threw. On a row bound to an async context (L</with_context>, or
inherited from a bound resultset) it throws C<insert_async cannot run on a
bound async context> instead -- an exception out of C<insert_async>, not a
failed Future, naming the relationship that makes it a cascade -- since the
synchronous insert would run outside the pinned transaction or pipeline (ADR
0045).

Two edges follow L</insert> rather than what one might expect. A related row
in storage that is put on the row B<after> it was built (by accessor or
L</set_inflated_columns>) is looked up again by L</insert> before it inserts,
so it counts as a cascade here too; pass it when building the row. And a
C<belongs_to> given as a hashref is looked up while the row is B<built>, by a
synchronous statement, before C<insert_async> is reached at all -- on a bound
resultset that statement has run outside the transaction by the time the
insert is refused.

A class on whose MRO a package defines C<insert> itself without defining
C<insert_async> in that same package (a component such as L<DBIO::Ordered> or
L<DBIO::ChangeLog>, the result class itself, a Moo C<around>) has that
override run: C<insert_async> goes through the full L</insert>. On an unbound
row that is performed synchronously and the Future is returned settled, as for
a multi-create. On a row bound to an async context it throws C<insert_async
cannot run on a bound async context>, naming the class and the method, instead
-- the override would run outside the pinned transaction or pipeline. An
override whose work lies before the write moves it into L</prepare_insert>,
which C<insert_async> calls itself; one that has its own C<insert_async> in
the same package is taken as written. L<DBIO::Relationship::CascadeActions> is
not counted.

Requires an async connection; on a sync instance it croaks, and in the
C<immediate> mode it degrades to a synchronous insert wrapped in an
immediately-resolved Future. See ADR 0030/0031.

=head2 update_async

  my $future = $row->update_async(\%columns?)
  $future->then(sub { my $row = shift; ... });

Async variant of L</update>. A simple flat write -- no L<OnColumnChange>
callback registered on this class, and no C<cascade_update> relationship (see
L<DBIO::Relationship::Base/cascade_update>, on by default for
C<has_one>/C<might_have>) actually touched on this row instance -- is
B<always> genuinely async: it applies C<%columns> exactly like L</update>
(via C<set_inflated_columns>, which includes the ADR 0034 C<set_from_related>
guard) and dispatches the actual UPDATE statement through the backend's
C<update_async>, folding the same post-update bookkeeping back onto the
object (clearing dirty columns, refreshing the storage-values snapshot) in
the Future's C<then>, and resolving with C<$self>. This holds even for a row
whose I<class> has a C<has_one>/C<might_have> relationship declared -- what
matters is whether that relationship's accessor has actually been touched on
I<this> row (assigned, or fetched at least once), which is the same
condition L<DBIO::Relationship::CascadeActions>'s own C<update> wrap checks
before it does any related work.

A row whose class has an C<OnColumnChange> callback, or whose source has a
C<cascade_update> relationship that update()'s C<CascadeActions> wrap would
actually cascade to (per the paragraph above), cannot be expressed as a
single async statement: both wrap L</update> itself (a before/around/after
chain built inline in C<update>, or C<CascadeActions>'s component-composition
wrap) -- a layer C<update_async>, being a new method name, cannot reach into
without duplicating that wrapping. Such a row is updated synchronously
instead (through the full L</update>, so the callbacks and cascades still
fire correctly) and the Future resolves immediately, exactly like
L</insert_async>'s related-object multi-create punt and L</delete_async>'s
cascade-delete punt. The C<OnColumnChange> half of this check is
class-level, not per-call -- it does not attempt to predict whether a
callback registered for a specific column will actually fire for a given
C<%columns> before running C<set_inflated_columns>.

A class with an override of C<update> that has no C<update_async> in the same
package -- a component such as L<DBIO::ChangeLog> or L<DBIO::Ordered>, the
result class, a Moo C<around> -- is updated through the full L</update>, so the
override runs: on an unbound row synchronously, with the Future settled; on a
row bound to an async context C<update_async> throws C<update_async cannot run
on a bound async context>, naming the class and the method. Work that lies
before the write belongs in L</prepare_update>, which L</update> and
C<update_async> both call once. See L</insert_async>.

Requires an async connection; on a sync instance it croaks, and in the
C<immediate> mode it degrades to a synchronous update wrapped in an
immediately-resolved Future. See ADR 0030/0031.

=head2 in_storage

  $result->in_storage; # Get value
  $result->in_storage(1); # Set value

=over

=item Arguments: none or 1|0

=item Return Value: 1|0

=back

Indicates whether the object exists as a row in the database or
not. This is set to true when L<DBIO::ResultSet/find>,
L<DBIO::ResultSet/create> or L<DBIO::Row/insert>
are invoked.

Creating a result object using L<DBIO::ResultSet/new_result>, or
calling L</delete> on one, sets it to false.

=head2 update

  $result->update(\%columns?)

=over

=item Arguments: none or a hashref

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Throws an exception if the result object is not yet in the database,
according to L</in_storage>. Returns the object itself.

This method issues an SQL UPDATE query to commit any changes to the
object to the database if required (see L</get_dirty_columns>).
It throws an exception if a proper WHERE clause uniquely identifying
the database row can not be constructed (see
L<significance of primary keys|DBIO::Manual::Intro/The Significance and Importance of Primary Keys>
for more details).

Also takes an optional hashref of C<< column_name => value >> pairs
to update on the object first. Be aware that the hashref will be
passed to C<set_inflated_columns>, which might edit it in place, so
don't rely on it being the same after a call to C<update>.  If you
need to preserve the hashref, it is sufficient to pass a shallow copy
to C<update>, e.g. ( { %{ $href } } )

A column value is a value: a plain scalar, C<undef>, an object, an arrayref
(an array data type, always bound), explicit literal SQL, or what an inflated
column type deflates. A hash, code or glob reference, or a reference to a
reference, is no value and throws, naming the column and the type.

The hashref is mass assignment: a column marked
L<is_guarded|DBIO::ResultSource/is_guarded>, and a relationship value that
resolves to one as foreign key, make C<update> throw. The accessor,
L</set_column> and C<update> without a hashref set a guarded column.

If the values passed or any of the column values set on the object
contain scalar references, e.g.:

  $result->last_modified(\'NOW()')->update();
  # OR
  $result->update({ last_modified => \'NOW()' });

The update will pass the values verbatim into SQL. (See
L<SQL::Abstract> docs).  The values in your Result object will NOT
change as a result of the update call, if you want the object to be updated
with the actual values from the database, call L</discard_changes> after the
update.

  $result->update()->discard_changes();

To determine before calling this method, which column values have
changed and will be updated, call L</get_dirty_columns>.

To check if any columns will be updated, call L</is_changed>.

To force a column to be updated, call L</make_column_dirty> before
this method.

=head2 delete

  $result->delete

=over

=item Arguments: none

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Throws an exception if the object is not in the database according to
L</in_storage>. Also throws an exception if a proper WHERE clause
uniquely identifying the database row can not be constructed (see
L<significance of primary keys|DBIO::Manual::Intro/The Significance and Importance of Primary Keys>
for more details).

The object is still perfectly usable, but L</in_storage> will
now return 0 and the object must be reinserted using L</insert>
before it can be used to L</update> the row again.

If you delete an object in a class with a C<has_many> relationship, an
attempt is made to delete all the related objects as well. To turn
this behaviour off, pass C<< cascade_delete => 0 >> in the C<$attr>
hashref of the relationship, see L<DBIO::Relationship>. Any
database-level cascade or restrict will take precedence over a
DBIO-based cascading delete, since DBIO B<deletes the
main row first> and only then attempts to delete any remaining related
rows.

If you delete an object within a txn_do() (see L<DBIO::Storage/txn_do>)
and the transaction subsequently fails, the result object will remain marked as
not being in storage. If you know for a fact that the object is still in
storage (i.e. by inspecting the cause of the transaction's failure), you can
use C<< $obj->in_storage(1) >> to restore consistency between the object and
the database. This would allow a subsequent C<< $obj->delete >> to work
as expected.

Called on the class (C<< MyApp::Schema::Result::CD->delete(\%cond) >>), it
deletes the rows matching the condition through L<DBIO::ResultSet/delete>. A
class call without a condition throws (C<delete on an unrestricted resultset:
pass { all => 1 }>): the class call takes no options, so the whole table is
deleted through C<< $schema->resultset('CD')->delete({ all => 1 }) >> (ADR 0069).

See also L<DBIO::ResultSet/delete>.

=head2 delete_async

  my $future = $row->delete_async;
  $future->then(sub { my $row = shift; ... });

Async variant of L</delete>. For a flat row -- no relationship on this row's
source with C<cascade_delete> set (see
L<DBIO::Relationship::Base/cascade_delete>, on by default for
C<has_many>/C<has_one>/C<might_have>) -- deletes it through the backend's
C<delete_async>, then marks the object as no longer L</in_storage>, resolving
with C<$self> in the Future's C<then> -- exactly like sync L</delete>.

A row whose source has a C<cascade_delete> relationship cannot be expressed
as a single async statement: cascading to the related rows is itself a
further, transactional operation that L<DBIO::Relationship::CascadeActions>
performs by wrapping L</delete> at the component-composition layer, a layer
C<delete_async>, being a new method name, cannot reach into without
duplicating that wrapping. Such a row is deleted synchronously instead
(through the full L</delete>, so any cascade still fires correctly) and the
Future resolves immediately, exactly like L</insert_async>'s related-object
multi-create punt.

Unlike L</update_async>'s C<cascade_update> check, this is a per-I<class>
gate, not a per-instance one: C<CascadeActions>'s C<delete> wrap issues the
related C<delete_all> unconditionally for every C<cascade_delete>
relationship whenever it fires, with no cache to consult first (unlike
C<cascade_update>'s cached-related-object check) -- a class declaring any
C<cascade_delete> relationship is genuinely never single-table for delete,
so I<every> C<delete_async> call on that class punts, not just some.

B<Operator-facing guidance:> if your schema drives C<cascade_delete>
entirely from the database's own C<ON DELETE CASCADE> constraints rather
than from DBIO's own cascading, set C<< cascade_delete => 0 >> on those
relationships (see L<DBIO::Relationship::Base/cascade_delete>) -- this
restores fully async C<delete_async> for that class, since the database
performs the cascade for you and DBIO no longer needs to.

An override of C<delete> without a C<delete_async> in the same package (a
component such as L<DBIO::Ordered> or L<DBIO::ChangeLog>, the result class, a
Moo C<around>) is run through the full L</delete> likewise: synchronously with
the Future settled on an unbound row, refused by name (C<delete_async cannot
run on a bound async context>, with class and method) on a bound one. Work
before the write belongs in L</prepare_delete>. See L</insert_async>.

Requires an async connection; on a sync instance it croaks, and in the
C<immediate> mode it degrades to a synchronous delete wrapped in an
immediately-resolved Future. See ADR 0030/0031.

=head2 prepare_insert

  sub prepare_insert {
    my $self = shift;
    $self->created_by($self->current_user) unless defined $self->created_by;
    return $self->next::method(@_);
  }

=over

=item Arguments: none

=item Return Value: none

=back

The hook for what a component or result class has to do to a row B<before>
it is written by L</insert>: set a column, generate a key, stamp a time. It
does nothing here. L</insert> calls it once, and so does L</insert_async> when
it sends the statement itself, in both cases before the columns are read; a
row already in storage is not prepared. A component overrides it and calls
C<< $self->next::method >>.

Prefer it over overriding L</insert> where the work lies before the write: an
override of C<insert> is not on the way of L</insert_async> (see there), the
hook is. L<DBIO::Timestamp> and L<DBIO::UUIDColumns> work through it.

=head2 prepare_update

  sub prepare_update {
    my ($self, $upd) = @_;
    $self->modified_by($self->current_user);
    return $self->next::method($upd);
  }

=over

=item Arguments: \%columns or undef

=item Return Value: none

=back

The same for L</update>. It is called once, first, with the hashref given to
L</update> / L</update_async> (or C<undef>) before it is applied, and may
change it in place -- take keys out of it and set them another way, as
L<DBIO::FilterColumn> does for a filtered column and L<DBIO::Timestamp> for a
C<set_on_update> column. Whatever is left in it is applied afterwards. It does
nothing here.

=head2 prepare_delete

  sub prepare_delete {
    my $self = shift;
    # ... a row that is going away
    return $self->next::method(@_);
  }

=over

=item Arguments: none

=item Return Value: none

=back

The same for L</delete>, called once on a row in storage before the statement
is sent. It does nothing here.

Work that writes B<other> rows or reads the siblings of this one (what
L<DBIO::Ordered> and L<DBIO::ChangeLog> do) is not before-the-write work in
this sense: it needs the transaction and the synchronous reads of the
override, stays an override of C<insert> / C<update> / C<delete> and is
bound by the rule given under L</insert_async>.

=head2 get_column

  my $val = $result->get_column($col);

=over

=item Arguments: $columnname

=item Return Value: The value of the column

=back

Throws an exception if the column name given doesn't exist according
to L<has_column|DBIO::ResultSource/has_column>.

Returns a raw column value from the result object, if it has already
been fetched from the database or set by an accessor.

If an L<inflated value|DBIO::InflateColumn> has been set, it
will be deflated and returned.

Note that if you used the C<columns> or the C<select/as>
L<search attributes|DBIO::ResultSet/ATTRIBUTES> on the resultset from
which C<$result> was derived, and B<did not include> C<$columnname> in the list,
this method will return C<undef> even if the database contains some value.

To retrieve all loaded column values as a hash, use L</get_columns>.

=head2 has_column_loaded

  if ( $result->has_column_loaded($col) ) {
     print "$col has been loaded from db";
  }

=over

=item Arguments: $columnname

=item Return Value: 0|1

=back

Returns a true value if the column value has been loaded from the
database (or set locally).

=head2 get_columns

  my %data = $result->get_columns;

=over

=item Arguments: none

=item Return Value: A hash of columnname, value pairs.

=back

Returns all loaded column data as a hash, containing raw values. To
get just one value for a particular column, use L</get_column>.

See L</get_inflated_columns> to get the inflated values.

=head2 get_dirty_columns

  my %data = $result->get_dirty_columns;

=over

=item Arguments: none

=item Return Value: A hash of column, value pairs

=back

Only returns the column, value pairs for those columns that have been
changed on this object since the last L</update> or L</insert> call.

See L</get_columns> to fetch all column/value pairs.

=head2 make_column_dirty

  $result->make_column_dirty($col)

=over

=item Arguments: $columnname

=item Return Value: not defined

=back

Throws an exception if the column does not exist.

Marks a column as having been changed regardless of whether it has
really changed.

=head2 get_inflated_columns

  my %inflated_data = $obj->get_inflated_columns;

=over

=item Arguments: none

=item Return Value: A hash of column, object|value pairs

=back

Returns a hash of all column keys and associated values. Values for any
columns set to use inflation will be inflated and returns as objects.

See L</get_columns> to get the uninflated values.

See L<DBIO::InflateColumn> for how to setup inflation.

=head2 set_column

  $result->set_column($col => $val);

=over

=item Arguments: $columnname, $value

=item Return Value: $value

=back

Sets a raw column value. If the new value is different from the old one,
the column is marked as dirty for when you next call L</update>.

If passed an object or reference as a value, this method will happily
attempt to store it, and a later L</insert> or L</update> will try and
stringify/numify as appropriate. To set an object to be deflated
instead, see L</set_inflated_columns>, or better yet, use L</$column_accessor>.

=head2 set_columns

  $result->set_columns({ $col => $val, ... });

=over

=item Arguments: \%columndata

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Sets multiple column, raw value pairs at once.

Works as L</set_column>.

=head2 set_inflated_columns

  $result->set_inflated_columns({ $col => $val, $rel_name => $obj, ... });

=over

=item Arguments: \%columndata

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

Sets more than one column value at once. Any inflated values are
deflated and the raw values stored.

Any related values passed as Result objects, using the relation name as a
key, are reduced to the appropriate foreign key values and stored.

A hashref passed in place of a related result object is taken as column
values of the related row and reduced the same way, so it has to carry
the columns the relationship is keyed on:

  $cd->set_inflated_columns({ artist => { artistid => 7 } });  # sets the foreign key
  $cd->set_inflated_columns({ artist => { name => 'Ann' } });  # throws

A hashref that leaves one of this row's columns undetermined throws
C<Relationship '...' does not resolve to a concrete column condition>
and sets nothing, see L<DBIO::Relationship::Base/set_from_related>. No
related row is looked up, created or changed for it: related rows are
created along with a row only when that row is built, see
L<DBIO::ResultSet/create>.

A value passed for a L<DBIO::Relationship/has_many> key throws an
exception: recursive update is not supported over relationships of
type C<multi>.

Be aware that the input hashref might be edited in place, so don't rely
on it being the same after a call to C<set_inflated_columns>. If you
need to preserve the hashref, it is sufficient to pass a shallow copy
to C<set_inflated_columns>, e.g. ( { %{ $href } } )

See also L<DBIO::Relationship::Base/set_from_related>.

=head2 copy

  my $copy = $orig->copy({ change => $to, ... });

=over

=item Arguments: \%replacementdata

=item Return Value: L<$result|DBIO::Manual::ResultClass> copy

=back

Inserts a new row into the database, as a copy of the original
object. If a hashref of replacement data is supplied, these will take
precedence over data in the original. Also any columns which have
the L<column info attribute|DBIO::ResultSource/add_columns>
C<< is_auto_increment => 1 >> are explicitly removed before the copy,
so that the database can insert its own autoincremented values into
the new object.

Relationships will be followed by the copy procedure B<only> if the
relationship specifies a true value for its
L<cascade_copy|DBIO::Relationship::Base> attribute. C<cascade_copy>
is set by default on C<has_many> relationships and unset on all others.

=head2 copy_async

  my $future = $orig->copy_async({ change => $to, ... });
  $future->then(sub { my $copy = shift; ... });

Async variant of L</copy>. For a flat copy -- no relationship on this row's
source with C<cascade_copy> set (on by default for C<has_many>, unset on all
others) -- applies the same pre-insert work as L</copy> (proxy-slot
stripping, dropping auto-increment columns, building the new row's column
set, C<set_inflated_columns> with the supplied C<%replacementdata>) and
dispatches the insert through L</insert_async>, resolving with the new row.

A row whose source has a C<cascade_copy> relationship cannot be expressed as
a single async statement: copying the related rows is itself a recursive,
multi-row operation that L</copy> performs directly in its own loop (not a
component wrap this time, but the same "more than one statement" shape as
L</insert_async>'s related-object multi-create punt). Such a row is copied
synchronously instead (through the full L</copy>, so the cascade still runs)
and the Future resolves immediately. Like sync L</copy>, no transaction is
opened, even for the cascading case.

Requires an async connection; on a sync instance it croaks, and in the
C<immediate> mode it degrades to a synchronous copy wrapped in an
immediately-resolved Future. See ADR 0030/0031.

=head2 store_column

  $result->store_column($col => $val);

=over

=item Arguments: $columnname, $value

=item Return Value: The value sent to storage

=back

Set a raw value for a column without marking it as changed. This
method is used internally by L</set_column> which you should probably
be using.

This is the lowest level at which data is set on a result object,
extend this method to catch all data setting methods.

=head2 inflate_result

  Class->inflate_result($result_source, \%me, \%prefetch?)

=over

=item Arguments: L<$result_source|DBIO::ResultSource>, \%columndata, \%prefetcheddata

=item Return Value: L<$result|DBIO::Manual::ResultClass>

=back

All L<DBIO::ResultSet> methods that retrieve data from the
database and turn it into result objects call this method.

Extend this method in your Result classes to hook into this process,
for example to rebless the result into a different class.

Reblessing can also be done more easily by setting C<result_class> in
your Result class. See L<DBIO::ResultSource/result_class>.

Different types of results can also be created from a particular
L<DBIO::ResultSet>, see L<DBIO::ResultSet/result_class>.

=head2 update_or_insert

  $result->update_or_insert

=over

=item Arguments: none

=item Return Value: Result of update or insert operation

=back

L</update>s the object if it's already in the database, according to
L</in_storage>, else L</insert>s it.

=head2 insert_or_update

  $obj->insert_or_update

Alias for L</update_or_insert>

=head2 insert_or_update_async

  my $future = $obj->insert_or_update_async;

Alias for L</update_or_insert_async>

=head2 update_or_insert_async

  my $future = $result->update_or_insert_async;
  $future->then(sub { my $row = shift; ... });

Async variant of L</update_or_insert>. Delegates to L</update_async> for
rows already in storage, else L</insert_async> -- exactly like the sync
method, this takes no arguments. Carries whichever of the two methods' own
backend routing, immediate degrade, and croak-on-sync-instance contract
applies with no further wrapping needed here. See ADR 0030/0031.

=head2 is_changed

  my @changed_col_names = $result->is_changed();
  if ($result->is_changed()) { ... }

=over

=item Arguments: none

=item Return Value: 0|1 or @columnnames

=back

In list context returns a list of columns with uncommited changes, or
in scalar context returns a true value if there are uncommitted
changes.

=head2 is_column_changed

  if ($result->is_column_changed('col')) { ... }

=over

=item Arguments: $columname

=item Return Value: 0|1

=back

Returns a true value if the column has uncommitted changes.

=head2 result_source

  my $resultsource = $result->result_source;

=over

=item Arguments: L<$result_source?|DBIO::ResultSource>

=item Return Value: L<$result_source|DBIO::ResultSource>

=back

Accessor to the L<DBIO::ResultSource> this object was created from.

=head2 register_column

  $column_info = { .... };
  $class->register_column($column_name, $column_info);

=over

=item Arguments: $columnname, \%columninfo

=item Return Value: not defined

=back

Registers a column on the class. If the column_info has an 'accessor'
key, creates an accessor named after the value if defined; if there is
no such key, creates an accessor with the same name as the column

The column_info attributes are described in
L<DBIO::ResultSource/add_columns>

=head2 get_from_storage

  my $copy = $result->get_from_storage($attrs)

=over

=item Arguments: \%attrs

=item Return Value: A Result object

=back

Fetches a fresh copy of the Result object from the database and returns it.

On a source that declares a
L<primary key|DBIO::Manual::Intro/The Significance and Importance of Primary Keys>
the row is looked up by that primary key, and an exception is thrown if a
proper WHERE clause identifying the database row can not be constructed (i.e.
if the original object does not contain its entire primary key).

On a source B<without> a primary key the lookup falls back to
L<DBIO::ResultSet/find>'s heuristics mode: the WHERE clause is built from every
loaded column, so any unique constraint declared on the source can be matched,
and a source declaring none at all is looked up by all of its loaded columns
(in which case the first matching row is returned). This is a deliberate
extension -- prior to it C<get_from_storage> died outright on primary-keyless
sources.

Each column contributes its last known B<in-storage> value in preference to a
locally modified one, so a Result carrying unsaved changes still identifies the
row it was loaded from rather than searching for its own new values. This is the
same precedence the primary-key path applies, and it shares that path's one
limit: a column that never carried a storage-side value at all -- because it was
never loaded, or was changed while the Result was not L</in_storage> -- has no
previous value to fall back on and contributes its current one.

If passed the \%attrs argument, will first apply these attributes to
the resultset used to find the row.

This copy can then be used to compare to an existing result object, to
determine if any changes have been made in the database since it was
created.

To just update your Result object with any latest changes from the
database, use L</discard_changes> instead.

The \%attrs argument should be compatible with
L<DBIO::ResultSet/ATTRIBUTES>.

=head2 get_from_storage_async

  my $future = $result->get_from_storage_async($attrs)
  $future->then(sub { my $copy = shift; ... });

Async variant of L</get_from_storage>. Shares its exact lookup -- built on
L<DBIO::ResultSet/find_async> rather than L</get_from_storage>'s own
L<DBIO::ResultSet/find>, so it carries find_async's own backend routing,
immediate degrade, and croak-on-sync-instance contract with no further
wrapping needed here. See ADR 0030/0031.

That includes the primary-keyless fallback described under
L</get_from_storage>, with the same column-value precedence and the same limit
on columns that never carried a storage-side value.

=head2 discard_changes

  $result->discard_changes

=over

=item Arguments: none or $attrs

=item Return Value: $result (updated in-place), but only when the row is in storage

=back

Re-selects the row from the database, losing any changes that had
been made. Throws an exception if a proper C<WHERE> clause identifying
the database row can not be constructed (i.e. if the original object
does not contain its entire
L<primary key|DBIO::Manual::Intro/The Significance and Importance of Primary Keys>).

This method can also be used to refresh from storage, retrieving any
changes made since the row was last read from storage.

If the row is not in storage (C<< $result->in_storage >> is false) the method
returns immediately without re-selecting and yields nothing (an empty list, or
C<undef> in scalar context), so do not rely on it returning C<$result> for
chaining in that case.

$attrs, if supplied, is expected to be a hashref of attributes suitable for passing as the
second argument to C<< $resultset->search($cond, $attrs) >>;

Note: If you are using L<DBIO::Replicated::Storage> as your storage, a default of
C<< { force_pool => 'master' } >> is automatically set for
you.

=head2 discard_changes_async

  my $future = $result->discard_changes_async;
  $future->then(sub { my $row = shift; ... });   # $row is $self, refreshed in place

Async variant of L</discard_changes>. If the row is not L</in_storage>,
resolves with C<undef> and issues no query at all -- exactly like sync
L</discard_changes>. Otherwise re-fetches via L</get_from_storage_async> and,
in the Future's C<then>, either refreshes C<$self> in place from the fresh
copy (row still exists) or marks C<$self> no longer L</in_storage> (row has
vanished), resolving with C<$self> either way.

Requires an async connection; on a sync instance it croaks, and in the
C<immediate> mode it degrades to a synchronous refresh wrapped in an
immediately-resolved Future. See ADR 0030/0031.

=head2 throw_exception

See L<DBIO::Schema/throw_exception>.

=head2 TO_JSON

  my $hashref = $row->TO_JSON;

Returns a hashref of the row's column values suitable for JSON
serialization. Automatically excludes C<text>, C<ntext>, and C<blob>
columns unless C<< is_serializable => 1 >> is set in the column info.
Numeric columns are numified for correct JSON output.

=head2 self_rs

  my $rs = $row->self_rs;

Returns a ResultSet containing only this row, useful for applying
ResultSet methods to a single row. A binding made with L</with_context>
goes with it.

=head2 clean_rs

  my $rs = $row->clean_rs;

Returns a fresh, unsearched ResultSet for this row's result source. A binding
made with L</with_context> goes with it.

=head2 StorageValues

Per-column opt-in snapshot of the values as last seen in storage.
Mark a column with C<< keep_storage_value => 1 >> and DBIO will record
its current stored value at C<insert>, C<update> and
C<inflate_result> time. The snapshot uses the column accessor, so
inflated / filtered values are captured rather than raw storage values.

  __PACKAGE__->add_column(title => {
    data_type          => 'varchar',
    keep_storage_value => 1,
  });

  $row->title('New');
  $row->get_storage_value('title'); # the old value
  $row->update;
  $row->get_storage_value('title'); # now 'New'

=head2 OnColumnChange

Register C<before_column_change>, C<after_column_change>, and
C<around_column_change> callbacks on a Result class. Callbacks fire
from L</update> only if the named column is actually dirty. The "old"
value comes from L</get_storage_value>, so pair this with
C<< keep_storage_value => 1 >> on the column if you need a real
previous value; otherwise it will be C<undef>.

  __PACKAGE__->before_column_change(
    amount => { method => 'bank_transfer', txn_wrap => 1 },
  );

Callback signatures:

  before: $self->$method($old, $new)
  after:  $self->$method($old, $new)   # $old may now equal $new
  around: $self->$method($next, $old, $new)

C<before> callbacks fire in definition order, C<after> callbacks fire
in reverse order, C<around> callbacks wrap in definition order (the
first declared being the outermost, the last declared wrapping the
actual update). If any registered arg has
C<< txn_wrap => 1 >> the whole update is wrapped in a
C<txn_scope_guard>.

See L</on_column_change_allow_override_args> for what it controls.

=head2 ProxyResultSetMethod

Expose a C<with_foo> ResultSet method as a row accessor with a
transparent fallback: if the column was already selected via the
ResultSet method it is returned from the cached row data; otherwise
the ResultSet method is re-run for this row.

  package MyApp::Schema::ResultSet::Foo;
  sub with_friend_count { ... }

  package MyApp::Schema::Result::Foo;
  __PACKAGE__->proxy_resultset_method('friend_count');

  $foo_rs->first->friend_count;           # lazy fetch
  $foo_rs->with_friend_count->first->friend_count;  # cached

The generated accessor stores the fetched value under the slot name in
C<_column_data> as a cache. Proxied slots are excluded from C<copy>
and C<update> so they are never written as actual columns.

=head2 id

  my @pk = $result->id;

=over

=item Arguments: none

=item Returns: A list of primary key values

=back

Returns the primary key(s) for a row. Can't be called as a class method.
Actually implemented in L<DBIO::PK>

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
