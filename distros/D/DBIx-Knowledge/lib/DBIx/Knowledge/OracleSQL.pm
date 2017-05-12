#
# $Id: OracleSQL.pm,v 1.1 2005/06/30 02:01:39 rsandberg Exp $
#


package DBIx::Knowledge::OracleSQL;

use strict;

use vars qw( $REPORT_TOTAL_KEY );

use DBIx::Knowledge qw( $REPORT_TOTAL_KEY );
use DBIx::Knowledge::SQL;

@DBIx::Knowledge::OracleSQL::ISA = qw( DBIx::Knowledge::SQL );

=head1 NAME

DBIx::Knowledge::OracleSQL - Oracle-specific SQL generator

=cut

##at add functionality for cross tab reports using Oracle CUBE() and Math::BaseCalc to convert binary -> decimal

# return sql string or undef if error
sub sql_rollup
{
    my ($self,$table_name,$select,$where_clause,$aggr_summary_fields,$order,$want_aggr_grouping_ids) = @_;
    $want_aggr_grouping_ids ||= {};

    (($self->{errstr} = "No fields to select for report"),return undef) unless ref($select) && @$select;

    my $sql = 'SELECT ' . join(',',map($_->{select_sql},@$select)) . ' ';

    my %select_position = ();
    my $sel_idx = 0;
    foreach my $s (@$select)
    {
        $select_position{$s->{ID}} = $sel_idx++;
    }

    my @group_by = ();
    my %group_by = ();
    map { (push(@group_by,$_),$group_by{lc($_->{select_sql})} = 1) if !$_->{group_by_expr} && !exists($group_by{lc($_->{select_sql})}) } @$select;

    my $aggr_summary_fields_count_less_report_total = @$aggr_summary_fields - scalar($aggr_summary_fields->[$#$aggr_summary_fields] eq $REPORT_TOTAL_KEY)
        if @$aggr_summary_fields;

    # If $aggr_summary_fields is given then @group_by must have at least one value
    # Should simply be a list of ID values
    ref($aggr_summary_fields) or $aggr_summary_fields = [];

    # Should be in order of decreasing record characterization specificity (normally the reverse order of the sort order (or select order))
    # if $REPORT_TOTAL_KEY is used it should always be the last in the list
    my $invalid_groupings = 0;
    for (my $i = 0; $i < @$aggr_summary_fields; $i++)
    {
        my $id = $aggr_summary_fields->[$i];

        my $grouping_id = 0;
        if ($id eq $REPORT_TOTAL_KEY)
        {
            $grouping_id = (1 << @group_by) - 1;
        }
        else
        {
            my $j = 0;
            foreach my $f (reverse @group_by)
            {
                if ($f->{ID} eq $id)
                {
                    $grouping_id = (1 << $j) - 1 if $j;
                    last;
                }
                $j++;
            }
            ($self->{errstr} = "Unable to summarize by $id in this report") unless $grouping_id;
        }

        # SUBTOTAL_RANK could get screwed up here if there is an invalid entry in $aggr_summary_fields ($grouping_id is false) despite $invalid_groupings
        # Perhaps best to return undef after setting {errstr} above.
        # POSITION of undef is the REPORT TOTAL field (equivalent to 0 if need be)
        $want_aggr_grouping_ids->{$grouping_id} = { FIELD_ID => $id, SUBTOTAL_RANK =>
            abs(scalar(keys(%$want_aggr_grouping_ids)) - ($aggr_summary_fields_count_less_report_total - $invalid_groupings)),
            POSITION => $select_position{$id} } if $grouping_id;

        $invalid_groupings++ unless $grouping_id;
    }
    
    my $init_group_by = '';
    $init_group_by = (%$want_aggr_grouping_ids ? "ROLLUP(" : '') . join(',',map($_->{select_sql},@group_by)) . (%$want_aggr_grouping_ids ? ")" : '') if @group_by;

    my $grouping_id_sql = '';
    $sql .= "," . ($grouping_id_sql = "GROUPING_ID(" . join(',',map($_->{select_sql},@group_by)) . ")") . ' ' if @group_by && %$want_aggr_grouping_ids;
    my $default_order_by_sql = '';
    my @default_order_expr = ();

    # If the column has a {group_by_sql} it is added after GROUP BY ROLLUP(...), below and screws up the ROLLUP summary columns
    map { push(@default_order_expr,length($_->{order_by_sql}) ? $_->{order_by_sql} : $_->{select_sql}) . ($_->{descending_order} ? ' DESC' : '')
        unless $_->{no_default_order_by} } @group_by;
    $default_order_by_sql = join(',',@default_order_expr);

    $sql .= "FROM $table_name ";
    $sql .= "$where_clause " if $where_clause;

    my $add_group_by = '';
    foreach my $select_field (@$select)
    {
        # {group_by_sql} attr must be an array ref if specified, {group_by_expr} must be true
        my $gr = $select_field->{group_by_sql} or next;
        (($self->{errstr} = "{group_by_expr} or {order_by_sql} must be true for $select_field->{ID} because {group_by_sql} is specified"),return undef)
            unless $select_field->{group_by_expr} || length($select_field->{order_by_sql});

        foreach my $g (@$gr)
        {
            $add_group_by .= "$g," unless $group_by{lc($g)};
            $group_by{lc($g)} = 1;
        }
    }
    chop($add_group_by);

    # order of terms that appear in ROLLUP() is important! Must be same order as select list
    $sql .= "GROUP BY " . ($init_group_by ? "$init_group_by ," : '') . ($add_group_by ? "$add_group_by  " : '') if $add_group_by || $init_group_by;
    chop($sql) if $add_group_by || $init_group_by;

    # Could optimize away if all groups are wanted
    $sql .= "HAVING $grouping_id_sql IN (" . join(',',keys(%$want_aggr_grouping_ids),0) . ") " if %$want_aggr_grouping_ids;

    # $order should be an array ref to field hashes
    if (ref($order) && @$order)
    {
        $sql .= "ORDER BY " . join(',',map((length($_->{order_by_sql}) ? $_->{order_by_sql} : $_->{select_sql})
            . ($_->{descending_order} ? ' DESC' : ''),@$order))
            . ($grouping_id_sql ? ",$grouping_id_sql" : '');
    }
    elsif ($default_order_by_sql)
    {
        $sql .= "ORDER BY $default_order_by_sql" . ($grouping_id_sql ? ",$grouping_id_sql" : '');
    }

    return $sql;
}

1;

__END__


=head1 SEE ALSO

L<DBIx::Knowledge::Report>, SmartCruddy! L<http://www.thesmbexchange.com/smartcruddy/index.html>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

