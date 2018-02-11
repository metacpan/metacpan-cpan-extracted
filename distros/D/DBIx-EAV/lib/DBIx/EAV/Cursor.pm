package DBIx::EAV::Cursor;

use Moo;
use Carp qw/ croak confess /;
use Data::Dumper;
use SQL::Abstract;
use Scalar::Util qw/ blessed /;

my $sql = SQL::Abstract->new();

has 'eav',  is => 'ro', required => 1;
has 'type', is => 'ro', required => 1;

has 'query',   is => 'ro', default => sub { {} };
has 'options', is => 'ro', default => sub { {} };

has '_sth', is => 'ro', lazy => 1, builder => 1, predicate => '_has_sth', clearer => '_reset_sth';


sub _check_query_already_executed {
    my $self = shift;
    croak "Query already executed!" if defined $self->_sth;
}


sub _build__sth {
    my $self = shift;
    my ($sql_query, $bind) = $self->_build_sql_query();
    my ($rv, $sth) = $self->eav->table('entities')->_do($sql_query, $bind);
    $sth;
}


sub _build_sql_query {
    my $self = shift;

    my $opts = $self->options;
    my $eav  = $self->eav;
    my $type = $self->type;
    my $entities_table = $eav->table('entities');
    my ($order_by, $group_by, $having, %parser_data, %replacements);

    # selected field
    my @select_fields = $opts->{select} ? @{$opts->{select}}
                                        : @{$entities_table->columns};

    # distinct (before normalizing @select_fields)
    if ($opts->{distinct}) {

        # if has group_by, warn and ignore distinct
        if ($opts->{group_by}) {

        }
        else {
            # exclude id from group by to make the distinct effect
            $opts->{group_by} = [grep { !ref && $_ !~ /^(me\.|)id$/ } @select_fields];
        }
    }

    # normalize select fields
    for (my $i = 0; $i < @select_fields; $i++) {

        # literal, dont touch
        next if ref $select_fields[$i] eq 'SCALAR';

        my $ident = $select_fields[$i];
        my ($fn, $as);

        # sql function
        if (ref $ident) {

            $as = delete $ident->{'-as'};
            ($fn, $ident) = each %$ident;

            unless ($as) {
                $as = lc($fn.'_'.$ident);
                $as =~ s/\./_/g;
            }

            $parser_data{aliases}{$as} = 1;
        }

        my $info = $self->_parse_clause_identifier($ident, \%parser_data);

        $select_fields[$i] = $fn ? \(sprintf "%s( %s ) AS %s", uc $fn, $info->{replacement}, $as)
                                 : $info->{replacement};
    }

    # add type criteria unless we have a subselect ('from' option)
    my $type_criteria = $opts->{from} ? [] : [ entity_type_id => $type->id ];

    if ($opts->{subtype_depth}) {
        push @$type_criteria, [ '_parent_type_'.$_, $type->id ]
            for 1 .. $opts->{subtype_depth};
    }

    # parse WHERE
    my ($where, @bind) = $sql->where({ -and => [ $type_criteria, $self->query] });
    my $i = 0;

    my $where_re = qr/ ([\w._]+) (?:=|!=|<>|>|<|>=|<=|IN|IS NULL|LIKE|NOT LIKE) \?/;
    while ($where =~ /$where_re/g) {

        my $ident = $1;
        my $info = $self->_parse_clause_identifier($ident, \%parser_data, $bind[$i]);

        $bind[$i] = $info->{bind}
            if exists $info->{bind};

        $replacements{$ident} = $info->{replacement};

        $i++;
    }

    # replace identifiers in WHERE
    while (my ($string, $replacement) = each %replacements) {
        $where =~ s/\b$string\b/$replacement/g;
    }

    # parse ORDER BY
    if (defined $opts->{order_by}) {

        %replacements = ();
        $order_by = $sql->where(undef, $opts->{order_by});

        while ($order_by =~ / ([\w._]+)(?: ASC| DESC|,|$)/g) {

            my $ident = $1;
            my $info = $self->_parse_clause_identifier($ident, \%parser_data);

            die "Cursor: query error: can't order by relationship! ($ident)'"
                if $info->{is_relationship};

            $replacements{$ident} = $info->{replacement};
        }

        # replace identifiers
        while (my ($string, $replacement) = each %replacements) {
            $order_by =~ s/\b$string\b/$replacement/g;
        }
    }

    # prepare prefetch attributes
    # if ($opts->{prefetch}) {
        # foreach my $attr (ref $opts->{prefetch} eq 'ARRAY' ? @{$opts->{prefetch}} : ($opts->{prefetch})) {
        #     die "unknown attribute given to prefetch: '$attr'"
        #         unless $attr =~ /^(?:$possible_attrs)$/;
        #
        #     $join_attr{$attr} = 1;
        #     push @select_fields, "$attr.value AS $attr";
        # }
    # }

    # parse ORDER BY
    if (defined $opts->{group_by}) {

        my @fields;

        foreach my $ident (ref $opts->{group_by} eq 'ARRAY' ? @{$opts->{group_by}} : $opts->{group_by}) {

            my $info = $self->_parse_clause_identifier($ident, \%parser_data);

            die "Cursor: query error: can't group by a relationship! ($ident)'"
                if $info->{is_relationship};

            push @fields, $info->{replacement};
        }

        $group_by .= 'GROUP BY '. join(', ', @fields);
    }

    # parse HAVING
    if (defined $opts->{having}) {

        my @having_bind;
        ($having, @having_bind) = $sql->where($opts->{having});

        push @bind, @having_bind;
        $having =~ s/^\s*WHERE/HAVING/;

        %replacements = ();
        while ($having =~ /$where_re/g) {

            my $ident = $1;
            my $info = $self->_parse_clause_identifier($ident, \%parser_data);

            $replacements{$ident} = $info->{replacement};
        }

        # replace identifiers
        while (my ($string, $replacement) = each %replacements) {
            $having =~ s/\b$string\b/$replacement/g;
        }
    }

    # build sql statement

    # SELECT ... FROM

    # from subselect
    my $from = $entities_table->name;
    if (my $subquery = $opts->{from}) {

        my ($sub_select, $sub_bind) = @$$subquery;
        $from = "($sub_select)";
        push @bind, @$sub_bind;
    }

    my $sql_query = $sql->select("$from AS me", \@select_fields);

    # JOINs
    if (my $depth = $opts->{subtype_depth}) {

        my $hierarchy_table = $eav->table("type_hierarchy")->name;
        $sql_query .= " LEFT JOIN $hierarchy_table AS _parent_type_1 ON (_parent_type_1.child_type_id = me.entity_type_id)";
        my $i = 2;
        while ($depth > 1) {
            $sql_query .= sprintf(" LEFT JOIN $hierarchy_table AS _parent_type_%d ON (_parent_type_%d.child_type_id = _parent_type_%d.parent_type_id)",
                $i, $i, $i - 1);
            $depth--;
            $i++;
        }
    }

    $sql_query .= " $_" for @{$parser_data{joins} || []};

    # WHERE, GROUP BY, HAVING, ORDER BY
    $sql_query .= " $where";
    $sql_query .= " $group_by" if defined $group_by;
    $sql_query .= " $having" if defined $having;
    $sql_query .= " $order_by" if defined $order_by;

    # LIMIT / OFFSET
    if ($opts->{limit}) {
        die "invalid limit" unless $opts->{limit} =~ /^\d+$/;
        $sql_query .= " LIMIT $opts->{limit}";

        if (defined $opts->{offset}) {
            die "invalid offset" unless $opts->{offset} =~ /^\d+$/;
            $sql_query .= " OFFSET $opts->{offset}";
        }
    }

    # return query and bind values
    ($sql_query, \@bind);
}

sub _parse_clause_identifier {
    my ($self, $identifier, $parser_data, $bind_value) = @_;

    # cached
    return $parser_data->{cache}->{$identifier}
        if exists $parser_data->{cache}->{$identifier};

    my $type = $self->type;
    my $eav = $self->eav;

    # special case: parent_type
    return $parser_data->{cache}->{$identifier} = { replacement => $identifier.'.parent_type_id' }
        if $identifier =~ /^_parent_type_\d+$/;

    # special case: alias
    return { replacement => $identifier }
        if exists $parser_data->{aliases}{$identifier};

    # remove me.
    $identifier =~ s/^me\.//;

    # parse possibly deep related identifier
    # valid formats:
    # - <attr>
    # - <rel>
    # - <rel>+.<attr>

    my @parts = split /\./, $identifier;
    my @joins;
    my $current_type = $type;
    my $current_entity_alias = 'me';
    my @rels;

    for (my $i = 0; $i < @parts; $i++) {

        my $id_part = $parts[$i];

        if ($current_type->has_relationship($id_part)) {

            my $rel = $current_type->relationship($id_part);
            my ($our_side, $their_side) = $rel->{is_right_entity} ? qw/ right left / : qw/ left right /;
            my $related_type = $self->eav->type_by_id($rel->{"${their_side}_entity_type_id"});
            push @rels, $rel->{name};
            my $current_rel_alias = join '_', @rels, 'link';

            # join relationship table
            unless ($parser_data->{joined}{$current_rel_alias}) {

                push @{$parser_data->{joins}}, sprintf "INNER JOIN %sentity_relationships AS %s ON %s.id = %s.%s_entity_id AND %s.relationship_id = %d",
                    $eav->schema->table_prefix,
                    $current_rel_alias,
                    $current_entity_alias,
                    $current_rel_alias,
                    $our_side,
                    $current_rel_alias,
                    $rel->{id};

                $parser_data->{joined}{$current_rel_alias} = 1;
            }

            # endpart is the relationship itself
            if ($i == $#parts) {

                if (defined $bind_value) {

                    die sprintf('Cursor: query error: the entity given to "%s" is not an entity of type %s.', $identifier, $related_type->name)
                        unless blessed $bind_value
                                && $bind_value->isa('DBIx::EAV::Entity')
                                && $bind_value->is_type($related_type->name);

                    die "Cursor: query error: the '".$related_type->name."' instance given to '$identifier' is not in storage."
                        unless $bind_value->in_storage;
                }

                # set replacement for WHERE, and change bind value to the entity id
                # note: dont cache this result because bindvalue can change
                return {
                    replacement => $current_rel_alias .'.'. $their_side.'_entity_id',
                    bind        => $bind_value ? $bind_value->id : '',
                    is_relationship => 1
                }
            }
            # step into the related type
            else {

                $current_type = $related_type;
                $current_entity_alias = $current_entity_alias eq 'me' ? $rel->{name}
                                                                      : $current_entity_alias.'_'.$rel->{name};

                unless ($parser_data->{joined}{$current_entity_alias}) {

                    push @{$parser_data->{joins}}, sprintf "INNER JOIN %sentities AS %s ON %s.id = %s.%s_entity_id",
                        $eav->schema->table_prefix,
                        $current_entity_alias,
                        $current_entity_alias,
                        $current_rel_alias,
                        $their_side;

                    $parser_data->{joined}{$current_entity_alias} = 1;
                }
            }

        }
        elsif ($current_type->has_static_attribute($id_part)) {

            # attribute allowed only at the and
            confess "Cursor: query error: invalid identifier '$identifier': attribute only allowed at the and of identifier."
                if $i < $#parts;

            return $parser_data->{cache}->{$identifier} = {
                replacement => $current_entity_alias.'.'.$id_part,
            };

        }
        elsif ($current_type->has_attribute($id_part)) {

            # attribute allowed only at the and
            confess "Cursor: query error: invalid identifier '$identifier': attribute only allowed at the and of identifier."
                if $i < $#parts;

            my $attr = $current_type->attribute($id_part);
            my $join_alias = $current_entity_alias eq 'me' ? $attr->{name}
                                                           : $current_entity_alias.'_'.$attr->{name};

            unless ($parser_data->{joined}{$join_alias}) {
                push @{$parser_data->{joins}}, sprintf "LEFT JOIN %svalue_%s AS %s ON (%s.entity_id = %s.id AND %s.attribute_id = %s)",
                    $eav->schema->table_prefix,
                    $attr->{data_type},
                    $join_alias,
                    $join_alias,
                    $current_entity_alias,
                    $join_alias,
                    $attr->{id};

                $parser_data->{joined}{$join_alias} = 1;
            }

            return { replacement => $join_alias.'.value' }
        }
        else {
            die sprintf "Cursor: query error: invalid identifier '%s': '%s' is not a valid attribute/relationship for '%s'\n",
                $identifier,
                $id_part,
                $current_type->name;
        }
    }

}

sub as_query {
    \[shift->_build_sql_query];
}


sub reset {
    my $self = shift;
    $self->_reset_sth;
    $self;
}


sub first {
    $_[0]->reset->next;
}


sub next {
    my $self = shift;
    $self->_sth->fetchrow_hashref;
}


sub all {
    my $self = shift;
    my @rows;

    $self->reset;

    while (my $row = $self->next) {
        push @rows, $row;
    }

    $self->reset;

    return wantarray ? @rows : \@rows;
}



1;


__END__


=head1 NAME

DBIx::EAV::Cursor - Represents a query used for fetching entities.

=head1 SYNOPSIS

    # get cursor from resultset
    my $cursor = $eav->resultset('CD')->search(\%query)->cursor;

    while (my $cd = $cursor->next) {

        # $cd is the raw hashref returned from database
        printf "CD id: %d\n", $cd->{id};
    }


=head1 DESCRIPTION

A cursor is used to build, execute and iterate over a SQL query for the entities
table. A a cursor instance is returned from L<find|DBIx::EAV::Collection> and from
L<get|DBIx::EAV::Entity> (when you get() related data). You will never need
to create a instance of this class yourself.

=head1 METHODS

=head2 all

=over 4

=item Arguments: none

=item Return Value: L<@entities|DBIx::EAV::Entity>

=back

Returns all entities in the result.

=head2 next

=over 4

=item Arguments: none

=item Return Value: L<$result|DBIx::EAV::Entity> | undef

=back

Returns the next element in the resultset (C<undef> if there is none).

Can be used to efficiently iterate over records in the resultset:

  my $cursor = $eav->resultset('CD')->find;
  while (my $cd = $cursor->next) {
    print $cd->get('title');
  }

Note that you need to store the cursor object, and call C<next> on it.
Calling C<< resultset('CD')->next >> repeatedly will always return the
first record from the cursor.

=head2 first

=over 4

=item Arguments: none

=item Return Value: L<$result|DBIx::EAV::Entity> | undef

=back

L<Resets|/reset> the cursor (causing a fresh query to storage) and returns
an object for the first result (or C<undef> if the resultset is empty).

=head2 reset

Deletes the current statement handle, if any. Next data fetching will trigger a
new database query.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
