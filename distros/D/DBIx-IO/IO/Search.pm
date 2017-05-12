#
# $Id$
#

package DBIx::IO::Search;

use strict;

use DBIx::IO::Table;

=head1 NAME

DBIx::IO::Search - query a database and generate SQL


=head1 SYNOPSIS

 use DBIx::IO::Search;

 $searcher = DBIx::IO::Search->new($dbh,$table_name,[$critlist,$sortlist,$parent_id_name,$connect_by,$start_with]);

 $critlist = $searcher->critlist();
 $critlist = $searcher->critlist($critlist);

 $sortlist = $searcher->sortlist();
 $sortlist = $searcher->sortlist($sortlist);

 $criteria = $searcher->add_crit($criteria);

 $criteria =  $searcher->build_range_crit($field_name,$range_start,$range_end,[$logical_not]);

 $crit = $searcher->build_scalar_crit($field_name,$operator,$value);

 $crit = $searcher->build_list_crit($field_name,$value_list,[$logical_not]);

 $sth = $searcher->execute();

 $results = $searcher->results();

 $results = $searcher->fetchall();

 $results = $searcher->search([$critlist],[$sortlist]); # combines execute(), and fetchall()



=head1 DESCRIPTION

This class enables reports to be run on a particular table or view based on a set of criteria.
The criteria are stored in an array - $critlist where each criterion is one of 3 types depending on the operator:

scalar - This type supports the <=, >=, =, !=, <, > and (NOT) LIKE operators; 1 scalar value is required for comparison.
A special value, NULL is recognized as meaning a NULL value. In this case, the operators '=' and '!='
are mapped to 'IS' and 'IS NOT' respectively. This criterion is represented as a hash ref with keys: COLUMN, OPERATOR, and VALUE,
which mean just what you'd think. The (NOT) LIKE operator allows wildcards `%' in the comparison value.

range - This type is used for camparison of ranges using the 'BETWEEN' operator. It is represented as a hash ref with keys:
COLUMN, OPERATOR, START, END, which mean just what you'd think. OPERATOR has 2 allowed values: 'BETWEEN' and 'NOT BETWEEN'.

list - This type is used for comparison with a list of values where any of the values can match for the criteria to be met.
The IN operator is used and the criterion is represented as a hash ref with keys: COLUMN, OPERATOR, LIST, which mean just what
you'd think. OPERATOR has 2 allowed values: 'IN' and 'NOT IN'. LIST must be an array ref of the values intended for
comparison.

The result set is returned via results() or search(). The result set is an array ref where each element is a record represented by a hash ref
of column => value pairs (see fetchall_arrayref({}) in DBI); all columns are returned. If sorting is desired then
populate the sortlist attribute via new(), sortlist() or search(). $sortlist is an array ref of column_names where the
result set is returned sorted by these columns in order.

For tables with a hierarchical relationship, START WITH and CONNECT BY clauses are required in the constructor
in order to reveal that relationship (review SELECT statements in an SQL reference). Normally SQL does not
support additional sorting of the results when these clauses are given. However,
if these clauses are given and sorting is desired, then sorting will be done at the top level of the hierarchy only.
In order for this to work, the table has to have a single column primary key.

The criteria list can be given on construction, or through the crit_list() or search() methods. The list can be
built with individual criterion with add_crit(). Also, just to make things easier, there is a builder method for each type of criterion, which helps
to assemble the data into the required record format: build_scalar_crit(),
build_list_crit() and build_range_crit().

The values in each criterion that are used for comparison are qualified automagically (see DBIx::IO::qualify()) and dates are assumed to
be normalized (see DBIx::IO::GenLib). This lets you build searches without having to worry about quoting text vs numbers.

Some special values are recognized for dates: <int> hours, <int> days, <int> weeks, <int> months where <int> should be an appropriate
integer. These date formats allow values to be specified relative to now, e.g. an operator of '<' and a value of '2 weeks'
infer a value of any date less than 2 weeks from now.

If a single table or view is not enough for reporting purposes, like needing to do a join with 2 or more tables, then ask your
friendly neighborhood DBA to create another view. If that doesn't work then write your own damn SQL! :<>

Oracle users:
LOB columns won't be retreived because they aren't supported in DBD::Oracle (as of v1.19). LONG columns seem to work
fine though so if you can get away with using a LONG over a LOB, do that.
$DBIx::IO::GenLib::LONG_READ_LENGTH gives the limit size of a long that will be returned.

=head1 METHOD DETAILS


=over 4

=item C<new (constructer)>

 $searcher = DBIx::IO::Search->new($dbh,$table_name,[$critlist,$sortlist,$parent_id_name,$connect_by,$start_with]);

Create a new $searcher based on $table_name. $critlist and/or $sortlist can be given on construction as well.
To express hierarchical relationships, include $parent_id_name or ($connect_by and/or $start_with).
The START WITH clause defaults to 'START WITH $parent_id_name IS NULL'.
The CONNECT BY clause defaults to 'CONNECT BY PRIOR ${table_name}_ID = $parent_id_name'.

Return undef if error, return 0 if $table_name does not exist.

=cut

sub new
{
    my ($caller,$dbh,$table_name,$critlist,$sortlist,$parent_id_name,$connect_by,$start_with) = @_;
    my $class = ref($caller) || $caller;
    $table_name || (warn("\$table_name not defined!"), return undef);
    ref($dbh) || (warn("\$dbh doesn't appear to be valid"), return undef);
    my $table;
    unless ($table = new DBIx::IO::Table($dbh,undef,undef,$table_name))
    {
        defined($table) || (warn("Error getting column attributes for $table_name"),return undef);
        #warn("No attributes found for $table_name");
        return $table;
    }
    my $key_name = $table->key_name();
    if ($parent_id_name)
    {
        $connect_by ||= "CONNECT BY PRIOR $key_name = $parent_id_name";
        $start_with ||= "START WITH $parent_id_name IS NULL";
    }

    my $self = 
    {
        table_name      => $table->name(),
        key_name        => $key_name,
        dbh             => $dbh,
        critlist        => $critlist,
        sortlist        => $sortlist,
        parent_id_name  => $parent_id_name,
        connect_by      => $connect_by,
        start_with      => $start_with,
        column_types    => $table->column_types(),
        io              => $table->{io},
        pk              => $table->pk(),
    };
    return bless($self,$class);
}

=pod

=item C<critlist>

 $critlist = $searcher->critlist();
 $critlist = $searcher->critlist($critlist);

Get or set $critlist.

=cut
sub critlist
{
    my ($self,$critlist) = @_;
    return $self->{critlist} unless defined($critlist);
    return $self->{critlist} = $critlist;
}

=pod

=item C<sortlist>

 $sortlist = $searcher->sortlist();
 $sortlist = $searcher->sortlist($sortlist);

Get or set $sortlist.


=cut
sub sortlist
{
    my ($self,$sortlist) = @_;
    return $self->{sortlist} unless defined($sortlist);
    return $self->{sortlist} = $sortlist;
}

=pod

=item C<add_crit>

 $criteria = $searcher->add_crit($criteria);

Add an assembled criterion to the criteria list.

=cut
sub add_crit
{
    my ($self,$crit) = @_;
    $crit || ($self->{io}->_alert("\$crit not defined!"),return undef);
    push(@{$self->{critlist}}, { %$crit });
    return $crit;
}

=pod

=item C<build_range_crit>

 $criteria =  $searcher->build_range_crit($field_name,$range_start,$range_end,[$logical_not]);

Build a range criterion (for use with the 'BETWEEN' operator) by supplying the following arguments:

 $field_name                    -> name of the column that is restricted to the specified range.
 $range_start                   -> scalar repesenting the beginning of the range.
 $range_end                     -> scalar repesenting the ending of the range.
 $logical_not                   -> if this is true the SQL expression looks like 'AND NOT BETWEEN ...'
                                   (a little confusing since the default, undef is true).

Returns the assembled criterion and adds it to $searcher.

=cut
sub build_range_crit
{
    my ($self,$field,$start,$end,$not) = @_;
    return $self->add_crit({ COLUMN => $field, OPERATOR => ($not ? 'NOT ' : '') . 'BETWEEN', START => $start, END => $end });
}

=pod

=item C<build_scalar_crit>

 $crit = $searcher->build_scalar_crit($field_name,$operator,$value);

Build a scalar criterion (for use with the <=, >=, =, !=, <, > operators) by providing the $field_name, an $operator and a single scalar $value.

Returns the assembled criterion and adds it to $searcher.
 
=cut
sub build_scalar_crit
{
    my ($self,$field,$operator,$value) = @_;
    return $self->add_crit({ COLUMN => $field, OPERATOR => $operator, VALUE => $value });
}

=pod

=item C<build_list_crit>

 $crit = $searcher->build_list_crit($field_name,$value_list,$logical_not);

Build a list criterion (for use with the IN operator) by providing:

 $field_name                    -> name of the column that is restricted to the specified $value_list
 $value_list                    -> an array ref of values that the criterion is restricted to.
 $logical_not                   -> if this is true the SQL expression looks like 'AND NOT IN ...'
                                   (a little confusing since the default, undef is true).

Returns the assembled criterion and adds it to $searcher.

=cut
sub build_list_crit
{
    my ($self,$field,$val_list,$not) = @_;
    return $self->add_crit({ COLUMN => $field, OPERATOR => ($not ? 'NOT ' : '') . 'IN', LISTVALS => $val_list });
}

=pod

=item C<execute>

 $sth = $searcher->execute();

Build an SQL statement from the list of criteria in $searcher and execute it.
Return the resulting statement handle (see DBI) or false if error.
Also see search() explained elsewhere.

=cut
sub execute
{
    my $self = shift;
    if ($self->{connect_by})
    {
        # Hierarchical query
        if (ref($self->{sortlist}))
        {
            # Hierarchical query needs sorting (which can only be done at the top level) so get the top level
            # records and then pursue children in fetchall
            if ($self->{second_pass})
            {
                $self->_build_sql($self->{start_with2},$self->{connect_by}) || ($self->{io}->_alert("Can't build SQL statement"), return undef);
            }
            else
            {
                $self->{first_pass} = 1;
                $self->_build_sql($self->{start_with}) || ($self->{io}->_alert("Can't build SQL statement"), return undef);
            }
        }
        else
        {
            $self->_build_sql($self->{start_with},$self->{connect_by})  || ($self->{io}->_alert("Can't build SQL statement"), return undef);
        }
    }
    else
    {
        $self->_build_sql() || ($self->{io}->_alert("Can't build SQL statement"), return undef);
    }
    return $self->{sth} = $self->{io}->make_cursor($self->{sql});
}

=pod

=item C<results>

 $results = $searcher->results();

After search() or fetchall() is called, an array of hashes representing the result set is stored in the object. This
method returns that result set.

=cut
sub results
{
    my $self = shift;
    return $self->{results};
}

=pod

=item C<search>

 $results = $searcher->search([$critlist],[$sortlist]);

Generate SQL, execute, and return the result set.
$critlist and $sortlist will override those already assigned to $searcher.

Return false if error.
NOTE: The returned value could be true but also be an emtpy array ref with no rows returned.

=cut
sub search
{
    my ($self,$critlist,$sortlist) = @_;
    $critlist && $self->critlist($critlist);
    $sortlist && $self->sortlist($sortlist);
    $self->execute() || ($self->{io}->_alert("execute() failed"), return undef);
    return $self->fetchall();
}

=pod

=item C<fetchall>

 $results = $searcher->fetchall();

After execute() is called, $searcher will contain a loaded statement handle. This method gets the result set,
stores it and returns it (see also the results() and search methods elsewhere).
Return false if error.
NOTE: The returned value could be true but also be an emtpy array ref with no rows returned.

=cut

sub fetchall
{
    my $self = shift;
    ref($self->{sth}) || ($self->{io}->_alert("statement handle not defined, did you call execute()?"), return undef);
    my $results = $self->{sth}->fetchall_arrayref({});
    $self->{sth}->err && ($self->{io}->_alert("Error in DBI fetching the results"), return undef);
    my @fresults;
    if ($self->{first_pass})
    {
        undef $self->{first_pass};
        $self->{second_pass} = 1;
        # Sorted hierarchical query: first pass (already done at this point) gets all (sorted) top level rows, now recurse into children (not sorted)
        foreach my $result (@$results)
        {
            my $key_name = $self->{key_name};
            $self->{start_with2} = "START WITH $key_name = " . $self->{io}->qualify($result->{$key_name},$key_name);
            my $rv = $self->search() || ($self->{io}->_alert("Error in recursive hierarchy search()"), return undef);
            push @fresults, @$rv;
        }
        undef $self->{second_pass};
        $results = \@fresults;
    }
    return ($self->{results} = $results);
}

# for each crit in $critlist, build an SQL statement based on the table and criteria.
sub _build_sql
{
    my $self = shift;
    return $self->{sql} if $self->{sql};
    my ($start_with,$connect_by) = @_;
    my $where;
    my $level;
    my $crit_num = 0;
    if ($start_with)
    {
        if ($connect_by)
        {
            $level = 'LEVEL,';
        }
        else
        {
            # Hierarchical query that needs sorting so this is a first pass
            $start_with =~ s/START WITH/WHERE/i;
            $where .= "$start_with ";
            $crit_num++;
        }
    }
    if (ref($self->{critlist}))
    {
        foreach my $crit (@{$self->{critlist}})
        {
            $where .= ($crit_num ? "AND " : "WHERE ") . $self->_crit_sql($crit) . " ";
            $crit_num++;
        }
    }
    my $cols = $self->{io}->{select_cols} . ',';
    $cols .= $level;
    chop $cols;
    $self->{sql} = "SELECT $cols FROM $self->{table_name} $self->{table_name} $where" ;
    if ($connect_by)
    {
        $self->{sql} .= "$start_with $connect_by ";
    }
    else
    {
        $self->{sql} .= $self->{order_by} = ( ref($self->{sortlist}) ? " ORDER BY " . join(',', map("$self->{table_name}.$_",@{$self->{sortlist}})) : '');
    }
    $self->{where} = $where;
    return $self->{sql};
}


# build SQL for an individual criterion.
sub _crit_sql
{
    my ($self,$crit) = @_;
    my $column = uc($crit->{COLUMN});
    my $table_name = $self->{table_name};
##at could remove whitespace
    #$column =~ s/^\s*|\s*$//g; # remove leading and trailing whitespace
    my $op = uc($crit->{OPERATOR});
    if ($op =~ /BETWEEN/i)
    {
##at could parse dates
        my $start = $self->{io}->qualify($crit->{START},$column); #,$UNKNOWN_DATE_FORMAT);
##at could parse dates
        my $end = $self->{io}->qualify($crit->{END},$column); #,$UNKNOWN_DATE_FORMAT);
        return "$table_name.$column $op $start AND $end";
    }
    elsif ($op =~ /IN/i)
    {
        my $val_list;
        foreach my $val (@{$crit->{LISTVALS}})
        {
##at could parse dates
            $val_list .= $self->{io}->qualify($val,$column) . ","; # $UNKNOWN_DATE_FORMAT
        }
        chop $val_list;
        return "$table_name.$column $op ($val_list)";
    }
    else
    {
        my $val = $crit->{VALUE};
        my $isnull;
        if ($val =~ /^NULL$/i)
        {
            if ($op =~ /\!\=/)
            {
                $op = 'IS NOT';
            }
            elsif ($op =~ /\=/)
            {
                $op = 'IS';
            }
            $isnull++;
        }
        elsif ($op =~ /LIKE/i)
        {
            $val = "\%\L$val\%" unless $val =~ /\%/;
##at could parse dates
            $val = $self->{io}->qualify($val,$column); # $UNKNOWN_DATE_FORMAT
            $column = $self->{io}->lc_func("$table_name.$column");
            return "$column $op $val";
        }
##at more flexibility for other date types??
        if ($self->{io}->is_datetime($column))
        {
            if ($val =~ /(\d+)\s*hour/i)
            {
                my $offset = $1/24;
                return "$table_name.$column $op SYSDATE - $offset";
            }
            elsif ($val =~ /(\d+)\s*day/i)
            {
                my $offset = $1;
                return "$table_name.$column $op SYSDATE - $offset";
            }
            elsif ($val =~ /(\d+)\s*week/i)
            {
                my $offset = $1 * 7;
                return "$table_name.$column $op SYSDATE - $offset";
            }
            elsif ($val =~ /(\d+)\s*month/i)
            {
                my $offset = $1 * 30;
                return "$table_name.$column $op SYSDATE - $offset";
            }
        }
##at could parse dates
        $val = $self->{io}->qualify($val,$column) unless $isnull; # $UNKNOWN_DATE_FORMAT
        return "$table_name.$column $op $val";
    }
}

=pod

=back

=cut

1;

__END__

=head1 TODO

Doesn't strip leading or trailing spaces from criteria values. This should be done because CGI UI's were the intention for this module.

=head1 BUGS

No known bugs.


=head1 SEE ALSO

L<DBIx::IO::Table>, L<DBIx::IO>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

