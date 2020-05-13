use strict;
use warnings;

package DBIx::Class::ResultSet::RecursiveUpdate;
$DBIx::Class::ResultSet::RecursiveUpdate::VERSION = '0.41';
# ABSTRACT: like update_or_create - but recursive

use base qw(DBIx::Class::ResultSet);

sub recursive_update {
    my ( $self, $updates, $attrs ) = @_;

    my $fixed_fields;
    my $unknown_params_ok;
    my $m2m_force_set_rel;

    # 0.21+ api
    if ( defined $attrs && ref $attrs eq 'HASH' ) {
        $fixed_fields      = $attrs->{fixed_fields};
        $unknown_params_ok = $attrs->{unknown_params_ok};
        $m2m_force_set_rel = $attrs->{m2m_force_set_rel};
    }

    # pre 0.21 api
    elsif ( defined $attrs && ref $attrs eq 'ARRAY' ) {
        $fixed_fields = $attrs;
    }

    return DBIx::Class::ResultSet::RecursiveUpdate::Functions::recursive_update(
        resultset         => $self,
        updates           => $updates,
        fixed_fields      => $fixed_fields,
        unknown_params_ok => $unknown_params_ok,
        m2m_force_set_rel => $m2m_force_set_rel,
    );
}

package DBIx::Class::ResultSet::RecursiveUpdate::Functions;
$DBIx::Class::ResultSet::RecursiveUpdate::Functions::VERSION = '0.41';
use Carp::Clan qw/^DBIx::Class|^HTML::FormHandler|^Try::Tiny/;
use Scalar::Util qw( blessed );
use List::MoreUtils qw/ any all none /;
use Try::Tiny;
use Data::Dumper::Concise;

use constant DEBUG => 0;

sub recursive_update {
    my %params = @_;
    my ( $self, $updates, $fixed_fields, $object, $resolved, $if_not_submitted,
        $unknown_params_ok, $m2m_force_set_rel )
        = @params{
        qw/resultset updates fixed_fields object resolved if_not_submitted unknown_params_ok m2m_force_set_rel/
        };
    $resolved ||= {};
    $ENV{DBIC_NULLABLE_KEY_NOWARN} = 1;

    my $source = $self->result_source;

    croak "first parameter needs to be defined"
        unless defined $updates;

    croak "first parameter needs to be a hashref"
        unless ref($updates) eq 'HASH';

    croak 'fixed fields needs to be an arrayref'
        if defined $fixed_fields && ref $fixed_fields ne 'ARRAY';

    DEBUG and warn "recursive_update: " . $source->name . "\n";
    DEBUG and warn "object passed, skipping find" .
        (defined $object->id
        ? " (id " . $object->id . ")\n"
        : "\n")
        if defined $object;

    # always warn about additional parameters if storage debugging is enabled
    $unknown_params_ok = 0
        if $source->storage->debug;

    if ( blessed($updates) && $updates->isa('DBIx::Class::Row') ) {
        return $updates;
    }

    my @pks = $source->primary_columns;
    my %pk_kvs;
    for my $colname (@pks) {
        if (exists $updates->{$colname} && defined $updates->{$colname}) {
            $pk_kvs{$colname} = $updates->{$colname};
            next;
        }
        $pk_kvs{$colname} = $resolved->{$colname}
            if exists $resolved->{$colname} && defined $resolved->{$colname};
    }
    # support the special case where a method on the related row
    # populates one or more primary key columns and we don't have
    # all primary key values already
    # see DBSchema::Result::DVD relationship keysbymethod
    DEBUG and warn "pk columns so far: " . join (', ',
        sort keys %pk_kvs) . "\n";
    my @non_pk_columns = grep {
        my $colname = $_;
        none { $colname eq $_ } keys %pk_kvs
    }
        sort keys %$updates;
    DEBUG and warn "non-pk columns: " . join (', ',
        @non_pk_columns) . "\n";
    if ( scalar keys %pk_kvs != scalar @pks && @non_pk_columns) {
        DEBUG and warn "not all primary keys available, trying " .
            "object creation\n";
        # new_result throws exception if non column values are passed
        # because we want to also support e.g. a BUILDARGS method that
        # populates primary key columns from an additional value
        # filter out all relationships
        my @non_rel_columns = grep {
            !is_m2m( $self, $_ )
                && !$source->has_relationship($_)
        }
            sort keys %$updates;
        my %non_rel_updates = map {
            $_ => $updates->{$_}
        } @non_rel_columns;
        # transform columns specified by their accessor name
        my %columns_by_accessor = _get_columns_by_accessor($self);
        for my $accessor_name (sort keys %columns_by_accessor) {
            my $colname = $columns_by_accessor{$accessor_name}->{name};
            if ($accessor_name ne $colname
                && exists $non_rel_updates{$accessor_name}) {
                DEBUG and warn "renaming column accessor " .
                    "'$accessor_name' to column name '$colname'\n";
                $non_rel_updates{$colname} = delete
                    $non_rel_updates{$accessor_name};
            }
        }
        DEBUG and warn "using all non-rel updates for object " .
            "construction: " . Dumper(\%non_rel_updates);
        # the object creation might fail because of non-column and
        # non-constructor handled parameters which shouldn't break RU
        try {
            my $row = $self->new_result(\%non_rel_updates);
            for my $colname (@pks) {
                next
                    if exists $pk_kvs{$colname};

                if ($row->can($colname)
                    && defined $row->$colname) {
                    DEBUG and warn "missing pk column $colname exists " .
                        "and defined on object\n";
                    $pk_kvs{$colname} = $row->$colname;
                }
                else {
                    DEBUG and warn "missing pk column $colname doesn't "
                        . "exist or isn't defined on object, aborting\n";
                    last;
                }
            }
        }
        catch {
            DEBUG and warn "object construction failed, ignoring:
$_\n";
        };
    }

    # check if row can be found in resultset cache
    if ( !defined $object && scalar keys %pk_kvs == scalar @pks ) {
        my $cached_rows = $self->get_cache;
        if (defined $cached_rows) {
            DEBUG and warn "find in cache\n";
            $object = _get_matching_row(\%pk_kvs, $cached_rows)
        }
    }

    $updates = { %$updates, %$resolved };

    my %fixed_fields = map { $_ => 1 } @$fixed_fields;

    # add the resolved columns to the updates hashref
    my %all_pks = ( %pk_kvs, %fixed_fields );

    if ( !defined $object && scalar keys %all_pks == scalar @pks) {
        DEBUG and warn "find by pk\n";
        $object = $self->find( \%all_pks, { key => 'primary' } );
    }

    unless (defined $object) {
        DEBUG and warn "create new row\n";
        $object = $self->new_result( {} );
    }

    # direct column accessors
    my %columns;

    # relations that that should be done before the row is inserted into the
    # database like belongs_to
    my %pre_updates;

    # relations that that should be done after the row is inserted into the
    # database like has_many, might_have and has_one
    my %post_updates;
    my %other_methods;
    my %m2m_accessors;
    my %columns_by_accessor = _get_columns_by_accessor($self);

    # this section determines to what each key/value pair maps to,
    # column or relationship
    for my $name ( sort keys %$updates ) {
        DEBUG and warn "updating $name to "
            . ($updates->{$name} // '[undef]') . "\n";
        # columns
        if ( exists $columns_by_accessor{$name} &&
            !( $source->has_relationship($name) && ref( $updates->{$name} ) ) ) {
            $columns{$name} = $updates->{$name};
            next;
        }

        # relationships
        if ( $source->has_relationship($name) ) {
            if ( _master_relation_cond( $self, $name ) ) {
                $pre_updates{$name} = $updates->{$name};
                next;
            }
            else {
                $post_updates{$name} = $updates->{$name};
                next;
            }
        }

        # many-to-many helper accessors
        if ( is_m2m( $self, $name ) ) {
            DEBUG and warn "is m2m\n";
            # Transform m2m data into recursive has_many data
            # if IntrospectableM2M is in use.
            #
            # This removes the overhead related to deleting and
            # re-adding all relationships.
            if ( !$m2m_force_set_rel && $source->result_class->can('_m2m_metadata') ) {
                my $meta        = $source->result_class->_m2m_metadata->{$name};
                my $bridge_rel  = $meta->{relation};
                my $foreign_rel = $meta->{foreign_relation};

                $post_updates{$bridge_rel} = [
                    map {
                        { $foreign_rel => $_ }
                        } @{ $updates->{$name} }
                ];
                DEBUG and warn "m2m '$name' transformed to:\n$bridge_rel => " .
                    Dumper($post_updates{$bridge_rel}) . "\n";
            }
            # Fall back to set_$rel if IntrospectableM2M
            # is not available. (removing and re-adding all relationships)
            else {
                $m2m_accessors{$name} = $updates->{$name};
            }

            next;
        }

        # accessors
        if ( $object->can($name) && not $source->has_relationship($name) ) {
            $other_methods{$name} = $updates->{$name};
            next;
        }

        # unknown

        # don't throw a warning instead of an exception to give users
        # time to adapt to the new API
        carp(
            "No such column, relationship, many-to-many helper accessor or " .
            "generic accessor '$name' on '" . $source->name . "'"
        ) unless $unknown_params_ok;

    }

    # first update columns and other accessors
    # so that later related records can be found
    for my $name ( sort keys %columns ) {
        $object->$name( $columns{$name} );
    }
    for my $name ( sort keys %other_methods ) {
        $object->$name( $other_methods{$name} );
    }
    for my $name ( sort keys %pre_updates ) {
        _update_relation( $self, $name, $pre_updates{$name}, $object, $if_not_submitted, 0 );
    }

    # $self->_delete_empty_auto_increment($object);
    # don't allow insert to recurse to related objects
    # do the recursion ourselves
    # $object->{_rel_in_storage} = 1;
    # Update if %other_methods because of possible custom update method
    my $in_storage = $object->in_storage;

    # preserve related resultsets as DBIx::Class::Row->update clears them
    # yes, this directly accesses a row attribute, but no API exists and in
    # the hope to get the recursive_update feature into core DBIx::Class this
    # is the easiest solution
    my $related_resultsets = $object->{related_resultsets};

    DEBUG and warn "before update_or_insert\n";
    $object->update_or_insert if ( $object->is_changed || keys %other_methods );
    DEBUG and warn "after update_or_insert\n";

    # restore related resultsets
    $object->{related_resultsets} = $related_resultsets;

    # updating many_to_many
    for my $name ( sort keys %m2m_accessors ) {
        DEBUG and warn "updating m2m $name\n";
        my $value = $m2m_accessors{$name};

        # TODO: only first pk col is used
        my ($pk) = _get_pk_for_related( $self, $name );
        my @rows;
        my $rel_source = $object->$name->result_source;
        my @updates;
        if ( defined $value && ref $value eq 'ARRAY' ) {
            @updates = @{$value};
        }
        elsif ( defined $value && !ref $value ) {
            @updates = ($value);
        }
        elsif ( defined $value ) {
            carp "value of many-to-many rel '$name' must be an arrayref or scalar: $value";
        }
        for my $elem (@updates) {
            if ( blessed($elem) && $elem->isa('DBIx::Class::Row') ) {
                push @rows, $elem;
            }
            elsif ( ref $elem eq 'HASH' ) {
                push @rows,
                    recursive_update(
                    resultset => $rel_source->resultset,
                    updates   => $elem
                    );
            }
            else {
                push @rows, $rel_source->resultset->find( { $pk => $elem } );
            }
        }
        my $set_meth = 'set_' . $name;
        $object->$set_meth( \@rows );
    }
    for my $name ( sort keys %post_updates ) {
        _update_relation( $self, $name, $post_updates{$name}, $object, $if_not_submitted, $in_storage );
    }
    delete $ENV{DBIC_NULLABLE_KEY_NOWARN};
    return $object;
}

# returns DBIx::Class::ResultSource::column_info as a hash indexed by column accessor || name
sub _get_columns_by_accessor {
    my $self   = shift;
    my $source = $self->result_source;
    my %columns;
    for my $name ( $source->columns ) {
        my $info = $source->column_info($name);
        $info->{name} = $name;
        $columns{ $info->{accessor} || $name } = $info;
    }
    return %columns;
}

sub _get_matching_row {
    my ($kvs, $rows) = @_;

    return
        unless defined $rows;

    croak 'key/value need to be a hashref'
        unless ref $kvs eq 'HASH';

    croak 'key/value needs to have at least one pair'
        if keys %$kvs == 0;

    croak 'rows need to be an arrayref'
        unless ref $rows eq 'ARRAY';

    unless ($rows) {
        DEBUG and warn "skipping because no rows passed\n";
        return;
    }

    my $matching_row;

    my @matching_rows;
    for my $row (@$rows) {
        push @matching_rows, $row
            if all { $kvs->{$_} eq $row->get_column($_) }
                grep { !ref $kvs->{$_} }
                sort keys %$kvs;
    }
    DEBUG and warn "multiple matching rows: " . scalar @matching_rows . "\n"
        if @matching_rows > 1;
    $matching_row = $matching_rows[0]
        if scalar @matching_rows == 1;
    DEBUG and warn "matching row found for: " . Dumper($kvs) . " in " .
        Dumper([map { { $_->get_columns } } @$rows]) . "\n"
        if defined $matching_row;
    DEBUG and warn "matching row not found for: " . Dumper($kvs) . " in " .
        Dumper([map { { $_->get_columns } } @$rows]) . "\n"
        unless defined $matching_row;

    return $matching_row;
}

# Arguments: $rs, $name, $updates, $row, $if_not_submitted, $row_existed
sub _update_relation {
    my ( $self, $name, $updates, $object, $if_not_submitted, $row_existed ) = @_;

    # this should never happen because we're checking the paramters passed to
    # recursive_update, but just to be sure...
    $object->throw_exception("No such relationship '$name'")
        unless $object->has_relationship($name);

    DEBUG and warn "_update_relation: $name\n";

    my $info = $object->result_source->relationship_info($name);
    my $attrs = $info->{attrs};

    # get a related resultset without a condition
    my $related_source = $self->related_resultset($name)->result_source;
    my $related_resultset = $related_source->resultset;
    $self->throw_exception("result_source must support _resolve_condition")
        unless $self->result_source->can('_resolve_condition');
    my $resolved = $self->result_source->_resolve_condition( $info->{cond}, $name, $object, $name );

    $resolved = {}
        if defined $DBIx::Class::ResultSource::UNRESOLVABLE_CONDITION &&
            $DBIx::Class::ResultSource::UNRESOLVABLE_CONDITION == $resolved;

    # This is a hack. I'm not sure that this will handle most
    # custom code conditions yet. This needs tests.
    my @rel_cols;
    if ( ref $info->{cond} eq 'CODE' ) {
        my $new_resolved;
        # remove 'me.' from keys in returned hashref
        while ( my ( $key, $value ) = each  %$resolved ) {
            $key =~ s/^me\.//;
            $new_resolved->{$key} = $value;
            push @rel_cols, $key;
        }
        $resolved = $new_resolved;
    }
    else {
        @rel_cols = sort keys %{ $info->{cond} };
        map { s/^foreign\.// } @rel_cols;
    }

    # find out if all related columns are nullable
    my $all_fks_nullable = 1;
    for my $rel_col (@rel_cols) {
        $all_fks_nullable = 0
            unless $related_resultset->result_source->column_info($rel_col)->{is_nullable};
    }

    $if_not_submitted = $all_fks_nullable ? 'set_to_null' : 'delete'
        unless defined $if_not_submitted;

    # the only valid datatype for a has_many rels is an arrayref
    if ( $attrs->{accessor} eq 'multi' ) {
        DEBUG and warn "has_many: $name\n";

        # handle undef like empty arrayref
        $updates = []
            unless defined $updates;
        $self->throw_exception("data for has_many relationship '$name' must be an arrayref")
            unless ref $updates eq 'ARRAY';

        my @updated_objs;
        my @related_rows;
        # newly created rows can't have related rows
        if ($row_existed) {
            @related_rows = $object->$name;
            DEBUG and warn "got related rows: " . scalar @related_rows . "\n";
        }
        my $related_result_source = $related_resultset->result_source;
        my @pks = $related_result_source->primary_columns;

        for my $sub_updates ( @{$updates} ) {
            DEBUG and warn "updating related row: " . Dumper($sub_updates)
                . "\n";
            my %pk_kvs;
            # detect the special case where the primary key of a currently not
            # related row is passed in the updates hash
            # let the resolved column values fill any missing primary key
            # columns but not overwrite them
            for my $colname (@pks) {
                if (exists $sub_updates->{$colname}
                    && defined $sub_updates->{$colname}) {
                    # $sub_updates->{$colname} might be a hashref if a
                    # relationship is named the same as a foreign key column
                    if (ref $sub_updates->{$colname} eq 'HASH') {
                        if ($related_source->has_relationship($colname)) {
                            my $rel_info = $related_source
                                ->relationship_info($colname);
                            my @rel_cols = sort keys %{ $rel_info->{cond} };
                            map { s/^foreign\.// } @rel_cols;
                            $self->throw_exception("passing a hashref for " .
                                "a multi-column relationship named the " .
                                "same as a column ('$colname') is not " .
                                "implemented")
                                if scalar @rel_cols != 1;
                            DEBUG and warn "using '$rel_cols[0]' in hashref " .
                                "for primary key column '$colname'\n";
                            $pk_kvs{$colname} = $sub_updates->{$colname}
                                ->{$rel_cols[0]};
                        }
                        else {
                            $self->throw_exception(
                                "data for $colname is a hashref but no " .
                                "relationship with that name exists");
                        }
                    }
                    else {
                        $pk_kvs{$colname} = $sub_updates->{$colname};
                    }
                    next;
                }
                $pk_kvs{$colname} = $resolved->{$colname}
                    if exists $resolved->{$colname}
                        && defined $resolved->{$colname};
            }
            my $related_object;

            # support the special case where a method on the related row
            # populates one or more primary key columns and we don't have
            # all primary key values already
            # see DBSchema::Result::DVD relationship keysbymethod
            DEBUG and warn "pk columns so far: " . join (', ',
                sort keys %pk_kvs) . "\n";
            my @non_pk_columns = grep {
                    my $colname = $_;
                    none { $colname eq $_ } keys %pk_kvs
                }
                sort keys %$sub_updates;
            DEBUG and warn "non-pk columns: " . join (', ',
                @non_pk_columns) . "\n";
            if ( scalar keys %pk_kvs != scalar @pks && @non_pk_columns) {
                DEBUG and warn "not all primary keys available, trying " .
                    "object creation\n";
                # new_result throws exception if non column values are passed
                # because we want to also support e.g. a BUILDARGS method that
                # populates primary key columns from an additional value
                # filter out all relationships
                my @non_rel_columns = grep {
                        !is_m2m( $related_resultset, $_ )
                        && !$related_result_source->has_relationship($_)
                    }
                    sort keys %$sub_updates;
                my %non_rel_updates = map {
                    $_ => $sub_updates->{$_}
                } @non_rel_columns;
                # transform columns specified by their accessor name
                my %columns_by_accessor = _get_columns_by_accessor($related_resultset);
                for my $accessor_name (sort keys %columns_by_accessor) {
                    my $colname = $columns_by_accessor{$accessor_name}->{name};
                    if ($accessor_name ne $colname
                        && exists $non_rel_updates{$accessor_name}) {
                        DEBUG and warn "renaming column accessor " .
                            "'$accessor_name' to column name '$colname'\n";
                        $non_rel_updates{$colname} = delete
                            $non_rel_updates{$accessor_name};
                    }
                }
                DEBUG and warn "using all non-rel updates for object " .
                    "construction: " . Dumper(\%non_rel_updates);
                # the object creation might fail because of non-column and
                # non-constructor handled parameters which shouldn't break RU
                try {
                    my $related_row = $related_resultset
                        ->new_result(\%non_rel_updates);
                    for my $colname (@pks) {
                        next
                            if exists $pk_kvs{$colname};

                        if ($related_row->can($colname)
                            && defined $related_row->$colname) {
                            DEBUG and warn "missing pk column $colname exists " .
                                "and defined on object\n";
                            $pk_kvs{$colname} = $related_row->$colname;
                        }
                        else {
                            DEBUG and warn "missing pk column $colname doesn't "
                                . "exist or isn't defined on object, aborting\n";
                            last;
                        }
                    }
                }
                catch {
                    DEBUG and warn "object construction failed, ignoring:
$_\n";
                };
            }

            # The only reasons to let recursive_update search for an existing
            # row (= not passing a new result to it) is relinking of existing
            # rows.
            # Relinking is only possible if all primary key column values are
            # known and only required if at least one of the foreign row
            # columns, which are part of the relationship, differ between
            # current and target ones.
            # There are two different cases:
            # The foreign row columns are part of the foreign primary key.
            # An example is the dvdtags relationship of Dvd.
            # Or one or more non primary key form the relationship.
            # An example is the owned_dvds relationship of User.
            my $relink = 0;

            if ( scalar keys %pk_kvs == scalar @pks ) {
                DEBUG and warn "all primary keys available, " .
                    "searching for row in currently related rows\n";
                # the lookup can fail if the primary key of a currently not
                # related row is passed in the updates hash
                $related_object = _get_matching_row(\%pk_kvs, \@related_rows);
                # %pk_kvs contains the scalar value instead of a hashref
                # when a column and relationship are named the same so
                # overwrite the hashref in $sub_updates with that
                # don't include %$resolved as well as that contains target data
                my %current_data = (%$sub_updates, %pk_kvs);
                DEBUG and warn "current data: " . Dumper(\%current_data);
                DEBUG and warn "target data: " . Dumper($resolved);

                no warnings 'uninitialized';

                # If the row can't be found by _get_matching_row it is
                # currently not linked or doesn't even exist. In this case we
                # must execute a sql select to find it.
                $relink = 1
                    if (not defined $related_object)
                        && (any { $resolved->{$_} ne $current_data{$_} }
                            keys %$resolved);
            }
            DEBUG and warn "relink: $relink\n";

            # pass an empty object if no related row found and it's not the
            # special case where the primary key of a currently not related
            # row is passed in the updates hash to prevent the find by pk in
            # recursive_update to happen
            if ((not defined $related_object) && (not $relink)) {
                DEBUG and warn "passing empty row to prevent find by pk\n";
                $related_object = $related_resultset->new_result({});
            }

            my $sub_object = recursive_update(
                resultset => $related_resultset,
                updates   => $sub_updates,
                resolved  => $resolved,
                # pass prefetched object if found
                object    => $related_object,
            );

            push @updated_objs, $sub_object;
        }

        # determine if a removal query is required
        my @remove_rows = grep {
            my $existing_row = $_;
            none { $existing_row->ID eq $_->ID } @updated_objs
        } @related_rows;
        DEBUG and warn "rows for removal: " .  join(', ', map { $_->ID }
            @remove_rows) . "\n";

        if (scalar @remove_rows) {
            my $rs_rel_delist = $object->$name;

            # foreign table has a single pk column
            if (scalar @pks == 1) {
                DEBUG and warn "delete in not_in\n";
                $rs_rel_delist = $rs_rel_delist->search_rs(
                    {
                        $self->current_source_alias . "." .
                            $pks[0] => { -not_in => [ map ( $_->id, @updated_objs ) ] }
                    }
                );
            }

            # foreign table has multiple pk columns
            else {
                my @cond;
                for my $obj (@updated_objs) {
                    my %cond_for_obj;
                    for my $col (@pks) {
                        $cond_for_obj{ $self->current_source_alias . ".$col" } =
                            $obj->get_column($col);

                    }
                    push @cond, \%cond_for_obj;
                }

                # only limit resultset if there are related rows left
                if (scalar @cond) {
                    $rs_rel_delist = $rs_rel_delist->search_rs({ -not => [ @cond ] });
                }
            }

            if ($if_not_submitted eq 'delete') {
                $rs_rel_delist->delete;
            }
            elsif ($if_not_submitted eq 'set_to_null') {
                my %update = map {$_ => undef} @rel_cols;
                $rs_rel_delist->update(\%update);
            }
        }
    }
    elsif ( $attrs->{accessor} eq 'single' ||
        $attrs->{accessor} eq 'filter' ) {
        DEBUG and warn "has_one, might_have, belongs_to (" .
            $attrs->{accessor} . "): $name\n";

        my $sub_object;
        if ( ref $updates ) {
            my $existing_row = 0;
            my @pks = $related_resultset->result_source->primary_columns;
            if ( all { exists $updates->{$_} && defined $updates->{$_} } @pks ) {
                $existing_row = 1;
            }
            DEBUG and warn $existing_row ? "existing row\n" : "new row\n";
            # newly created rows can't have related rows
            my $related_row;
            if ($row_existed) {
                $related_row = $object->$name;
                DEBUG and warn "got related row\n";
            }
            if ( blessed($updates) && $updates->isa('DBIx::Class::Row') ) {
                $sub_object = $updates;
            }
            elsif ( $attrs->{accessor} eq 'single' && defined $related_row )
            {
                $sub_object = recursive_update(
                    resultset => $related_resultset,
                    updates   => $updates,
                    $existing_row ? () : (object => $object->$name),
                );
            }
            else {
                $sub_object = recursive_update(
                    resultset => $related_resultset,
                    updates   => $updates,
                    $existing_row ? () : (resolved => $resolved),
                );
            }
        }
        else {
            $sub_object = $related_resultset->find($updates)
                unless (
                !$updates &&
                ( exists $attrs->{join_type} &&
                    $attrs->{join_type} eq 'LEFT' )
                );
        }
        my $join_type = $attrs->{join_type} || '';
        # unmarked 'LEFT' join for belongs_to
        my $might_belong_to =
               ( $attrs->{accessor} eq 'single' || $attrs->{accessor} eq 'filter' ) &&
               $attrs->{is_foreign_key_constraint};
        # adding check for custom condition that's a coderef
        # this 'set_from_related' should probably not be called in lots of other
        # situations too, but until that's worked out, kludge it
        if ( ( $sub_object || $updates || $might_belong_to || $join_type eq 'LEFT' ) &&
             ref $info->{cond} ne 'CODE'  ) {
            $object->$name($sub_object);
        }
    }
    else {
        $self->throw_exception(
            "recursive_update doesn't now how to handle relationship '$name' with accessor " .
                $info->{attrs}{accessor} );
    }

    DEBUG and warn "_update_relation end\n";
}

sub is_m2m {
    my ( $self, $relation ) = @_;
    my $rclass = $self->result_class;

    # DBIx::Class::IntrospectableM2M
    if ( $rclass->can('_m2m_metadata') ) {
        return $rclass->_m2m_metadata->{$relation};
    }
    my $object = $self->new_result( {} );
    if ( $object->can($relation) and
        !$self->result_source->has_relationship($relation) and
        $object->can( 'set_' . $relation ) ) {
        return 1;
    }
    return;
}

sub get_m2m_source {
    my ( $self, $relation ) = @_;
    my $rclass = $self->result_class;

    # DBIx::Class::IntrospectableM2M
    if ( $rclass->can('_m2m_metadata') ) {
        return $self->result_source->related_source(
            $rclass->_m2m_metadata->{$relation}{relation} )
            ->related_source( $rclass->_m2m_metadata->{$relation}{foreign_relation} );
    }
    my $object = $self->new_result( {} );
    my $r = $object->$relation;
    return $r->result_source;
}

sub _delete_empty_auto_increment {
    my ( $self, $object ) = @_;
    for my $col ( sort keys %{ $object->{_column_data} } ) {
        if (
            $object->result_source->column_info($col)->{is_auto_increment} and
            ( !defined $object->{_column_data}{$col} or
                $object->{_column_data}{$col} eq '' )
            ) {
            delete $object->{_column_data}{$col};
        }
    }
}

sub _get_pk_for_related {
    my ( $self, $relation ) = @_;
    my $source;
    if ( $self->result_source->has_relationship($relation) ) {
        $source = $self->result_source->related_source($relation);
    }

    # many to many case
    if ( is_m2m( $self, $relation ) ) {
        $source = get_m2m_source( $self, $relation );
    }
    return $source->primary_columns;
}

# This function determines whether a relationship should be done before or
# after the row is inserted into the database
# relationships before: belongs_to
# relationships after: has_many, might_have and has_one
# true means before, false after
sub _master_relation_cond {
    my ( $self, $name ) = @_;

    my $source = $self->result_source;
    my $info   = $source->relationship_info($name);

    # has_many rels are always after
    return 0
        if $info->{attrs}->{accessor} eq 'multi';

    my @foreign_ids = _get_pk_for_related( $self, $name );

    my $cond = $info->{cond};

    sub _inner {
        my ( $source, $cond, @foreign_ids ) = @_;

        while ( my ( $f_key, $col ) = each %{$cond} ) {

            # might_have is not master
            $col   =~ s/^self\.//;
            $f_key =~ s/^foreign\.//;
            if ( $source->column_info($col)->{is_auto_increment} ) {
                return 0;
            }
            if ( any { $_ eq $f_key } @foreign_ids ) {
                return 1;
            }
        }
        return 0;
    }

    if ( ref $cond eq 'HASH' ) {
        return _inner( $source, $cond, @foreign_ids );
    }

    # arrayref of hashrefs
    elsif ( ref $cond eq 'ARRAY' ) {
        for my $new_cond (@$cond) {
            return _inner( $source, $new_cond, @foreign_ids );
        }
    }

    # we have a custom join condition, so update afterward
    elsif ( ref $cond eq 'CODE' ) {
        return 0;
    }

    else {
        $source->throw_exception( "unhandled relation condition " . ref($cond) );
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::ResultSet::RecursiveUpdate - like update_or_create - but recursive

=head1 VERSION

version 0.41

=head1 SYNOPSIS

    # The functional interface:

    my $schema = MyDB::Schema->connect();
    my $new_item = DBIx::Class::ResultSet::RecursiveUpdate::Functions::recursive_update(
        resultset => $schema->resultset('User'),
        updates => {
            id => 1,
            owned_dvds => [
                {
                    title => "One Flew Over the Cuckoo's Nest"
                }
            ]
        },
        unknown_params_ok => 1,
    );


    # As ResultSet subclass:

    __PACKAGE__->load_namespaces( default_resultset_class => '+DBIx::Class::ResultSet::RecursiveUpdate' );

    # in the Schema file (see t/lib/DBSchema.pm).  Or appropriate 'use base' in the ResultSet classes.

    my $user = $schema->resultset('User')->recursive_update({
        id => 1,
        owned_dvds => [
            {
                title => "One Flew Over the Cuckoo's Nest"
            }
        ]
    }, {
        unknown_params_ok => 1,
    });

    # You'll get a warning if you pass non-result specific data to
    # recursive_update. See L</"Additional data in the updates hashref">
    # for more information how to prevent this.

=head1 DESCRIPTION

You can feed the ->create method of DBIx::Class with a recursive datastructure
and have the related records created. Unfortunately you cannot do a similar
thing with update_or_create. This module tries to fill that void until
L<DBIx::Class> has an api itself.

The functional interface can be used without modifications of the model,
for example by form processors like L<HTML::FormHandler::Model::DBIC>.

It is a base class for L<DBIx::Class::ResultSet>s providing the method
recursive_update which works just like update_or_create but can recursively
update or create result objects composed of multiple rows. All rows need to be
identified by primary keys so you need to provide them in the update structure
(unless they can be deduced from the parent row. For example a related row of
a belongs_to relationship). If any of the primary key columns are missing,
a new row will be created, with the expectation that the missing columns will
be filled by it (as in the case of auto_increment primary keys).

If the resultset itself stores an assignment for the primary key,
like in the case of:

    my $restricted_rs = $user_rs->search( { id => 1 } );

you need to inform recursive_update about the additional predicate with the fixed_fields attribute:

    my $user = $restricted_rs->recursive_update( {
            owned_dvds => [
            {
                title => 'One Flew Over the Cuckoo's Nest'
            }
            ]
        },
        {
            fixed_fields => [ 'id' ],
        }
    );

For a many_to_many (pseudo) relation you can supply a list of primary keys
from the other table and it will link the record at hand to those and
only those records identified by them. This is convenient for handling web
forms with check boxes (or a select field with multiple choice) that lets you
update such (pseudo) relations.

For a description how to set up base classes for ResultSets see
L<DBIx::Class::Schema/load_namespaces>.

=head2 Additional data in the updates hashref

If you pass additional data to recursive_update which doesn't match a column
name, column accessor, relationship or many-to-many helper accessor, it will
throw a warning by default. To disable this behaviour you can set the
unknown_params_ok attribute to a true value.

The warning thrown is:
"No such column, relationship, many-to-many helper accessor or generic accessor '$key'"

When used by L<HTML::FormHandler::Model::DBIC> this can happen if you have
additional form fields that aren't relevant to the database but don't have the
noupdate attribute set to a true value.

NOTE: in a future version this behaviour will change and throw an exception
instead of a warning!

=head1 DESIGN CHOICES

Columns and relationships which are excluded from the updates hashref aren't
touched at all.

=head2 Treatment of belongs_to relations

In case the relationship is included but undefined in the updates hashref,
all columns forming the relationship will be set to null.
If not all of them are nullable, DBIx::Class will throw an error.

Updating the relationship:

    my $dvd = $dvd_rs->recursive_update( {
        id    => 1,
        owner => $user->id,
    });

Clearing the relationship (only works if cols are nullable!):

    my $dvd = $dvd_rs->recursive_update( {
        id    => 1,
        owner => undef,
    });

Updating a relationship including its (full) primary key:

    my $dvd = $dvd_rs->recursive_update( {
        id    => 1,
        owner => {
            id   => 2,
            name => "George",
        },
    });

=head2 Treatment of might_have relationships

In case the relationship is included but undefined in the updates hashref,
all columns forming the relationship will be set to null.

Updating the relationship:

    my $user = $user_rs->recursive_update( {
        id => 1,
        address => {
            street => "101 Main Street",
            city   => "Podunk",
            state  => "New York",
        }
    });

Clearing the relationship:

    my $user = $user_rs->recursive_update( {
        id => 1,
        address => undef,
    });

=head2 Treatment of has_many relations

If a relationship key is included in the data structure with a value of undef
or an empty array, all existing related rows will be deleted, or their foreign
key columns will be set to null.

The exact behaviour depends on the nullability of the foreign key columns and
the value of the "if_not_submitted" parameter. The parameter defaults to
undefined which neither nullifies nor deletes.

When the array contains elements they are updated if they exist, created when
not and deleted if not included.

=head3 All foreign table columns are nullable

In this case recursive_update defaults to nullifying the foreign columns.

=head3 Not all foreign table columns are nullable

In this case recursive_update deletes the foreign rows.

Updating the relationship:

    Passing ids:

    my $user = $user_rs->recursive_update( {
        id         => 1,
        owned_dvds => [1, 2],
    });

    Passing hashrefs:

    my $user = $user_rs->recursive_update( {
        id         => 1,
        owned_dvds => [
            {
                name => 'temp name 1',
            },
            {
                name => 'temp name 2',
            },
        ],
    });

    Passing objects:

    my $user = $user_rs->recursive_update( {
        id         => 1,
        owned_dvds => [ $dvd1, $dvd2 ],
    });

    You can even mix them:

    my $user = $user_rs->recursive_update( {
        id         => 1,
        owned_dvds => [ 1, { id => 2 } ],
    });

Clearing the relationship:

    my $user = $user_rs->recursive_update( {
        id         => 1,
        owned_dvds => undef,
    });

    This is the same as passing an empty array:

    my $user = $user_rs->recursive_update( {
        id         => 1,
        owned_dvds => [],
    });

=head2 Treatment of many-to-many pseudo relations

If a many-to-many accessor key is included in the data structure with a value
of undef or an empty array, all existing related rows are unlinked.

When the array contains elements they are updated if they exist, created when
not and deleted if not included.

RecursiveUpdate defaults to
calling 'set_$rel' to update many-to-many relationships.
See L<DBIx::Class::Relationship/many_to_many> for details.
set_$rel effectively removes and re-adds all relationship data,
even if the set of related items did not change at all.

If L<DBIx::Class::IntrospectableM2M> is in use, RecursiveUpdate will
look up the corresponding has_many relationship and use this to recursively
update the many-to-many relationship.

While both mechanisms have the same final result, deleting and re-adding
all relationship data can have unwanted consequences if triggers or
method modifiers are defined or logging modules like L<DBIx::Class::AuditLog>
are in use.

The traditional "set_$rel" behaviour can be forced by passing
"m2m_force_set_rel => 1" to recursive_update.

See L</is_m2m> for many-to-many pseudo relationship detection.

Updating the relationship:

    Passing ids:

    my $dvd = $dvd_rs->recursive_update( {
        id   => 1,
        tags => [1, 2],
    });

    Passing hashrefs:

    my $dvd = $dvd_rs->recursive_update( {
        id   => 1,
        tags => [
            {
                id   => 1,
                file => 'file0'
            },
            {
                id   => 2,
                file => 'file1',
            },
        ],
    });

    Passing objects:

    my $dvd = $dvd_rs->recursive_update( {
        id   => 1,
        tags => [ $tag1, $tag2 ],
    });

    You can even mix them:

    my $dvd = $dvd_rs->recursive_update( {
        id   => 1,
        tags => [ 2, { id => 3 } ],
    });

Clearing the relationship:

    my $dvd = $dvd_rs->recursive_update( {
        id   => 1,
        tags => undef,
    });

    This is the same as passing an empty array:

    my $dvd = $dvd_rs->recursive_update( {
        id   => 1,
        tags => [],
    });

Make sure that set_$rel used to update many-to-many relationships
even if IntrospectableM2M is loaded:

    my $dvd = $dvd_rs->recursive_update( {
        id   => 1,
        tags => [1, 2],
    },
    { m2m_force_set_rel => 1 },
    );

=head1 INTERFACE

=head1 METHODS

=head2 recursive_update

The method that does the work here.

=head2 is_m2m

=over 4

=item Arguments: $name

=item Return Value: true, if $name is a many to many pseudo-relationship

=back

The function gets the information about m2m relations from
L<DBIx::Class::IntrospectableM2M>. If it isn't loaded in the ResultSource
class, the code relies on the fact:

    if($object->can($name) and
             !$object->result_source->has_relationship($name) and
             $object->can( 'set_' . $name )
         )

to identify a many to many pseudo relationship. In a similar ugly way the
ResultSource of that many to many pseudo relationship is detected.

So if you need many to many pseudo relationship support, it's strongly
recommended to load L<DBIx::Class::IntrospectableM2M> in your ResultSource
class!

=head2 get_m2m_source

=over 4

=item Arguments: $name

=item Return Value: $result_source

=back

=head1 CONFIGURATION AND ENVIRONMENT

DBIx::Class::RecursiveUpdate requires no configuration files or environment variables.

=head1 DEPENDENCIES

    DBIx::Class

optional but recommended:
    DBIx::Class::IntrospectableM2M

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

The list of reported bugs can be viewed at L<http://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Class-ResultSet-RecursiveUpdate>.

Please report any bugs or feature requests to
C<bug-DBIx-Class-ResultSet-RecursiveUpdate@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHORS

=over 4

=item *

Zbigniew Lukasiak <zby@cpan.org>

=item *

John Napiorkowski <jjnapiork@cpan.org>

=item *

Alexander Hartmaier <abraxxa@cpan.org>

=item *

Gerda Shank <gshank@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Zbigniew Lukasiak, John Napiorkowski, Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
