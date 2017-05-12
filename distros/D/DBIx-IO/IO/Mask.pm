#
# $Id: Mask.pm,v 1.2 2002/01/24 02:13:05 rsandberg Exp $
#

package DBIx::IO::Mask;

use strict;
use DBIx::IO::Search;


my $DEF_MASKED_COL_NAME = 'USER_MASK';

my $cached_by_name;
my $cached_by_id;
my $sorted_masks;


=head1 NAME

DBIx::IO::Mask - Help make id values more meaningful to humans


=head1 SYNOPSIS

 use DBIx::IO::Mask;

 
 $masker = new DBIx::IO::Mask($dbh,$field_name);
 $masker = new DBIx::IO::Mask($dbh,undef,$table_name,$masked_col_name,$id_col_name,$no_cache);

 $valid_values = $masker->pick_list();

 $masked_value = $masker->mask($id_val);

 $id = $masker->unmask($masked_value);

 $ids_to_mask_hash = $masker->ids_to_mask();



=head1 DESCRIPTION

For applications that interface a human to a database, e.g. CGI, this class makes
database numeric ID values more meaningful to humans. It can also present a sorted list of valid
values to use in pop-up lists, where only certain values are allowed in the database.
It does this in conjunction with DBIx::IO::Search.

The general strategy is that any column you want masked or that has a discrete set of values, should have
a corresponding table with those set of values. The table name should be the same as the ID column name except
with no _ID at the end. The table should have at least 2 columns in it:

 <COLUMN_NAME> - The name of the column you want masked,
 it stores the ID values, and does not necessarily have
 to be a numeric datatype.
 USER_MASK - This column stores values that describe the id values

This way a new $masker object can be created by just knowing the name of the column you want masked. Example:

To get a sorted list of valid values for a column named STATE, create a table named STATE with
2 columns, STATE and USER_MASK with all states represented therein. Then:

 $masker = new DBIx::IO::Mask($dbh,'STATE');
 $states = $masker->pick_list();

This is the easy way, however if you have a table with a set of IDs and descriptions that doesn't conform to the guidelines above (or you just think the
whole scenario is dumb), you can specify the table name and desired column names in the constructor.

All tables read are cached in class variables for efficiency. This may be significant
if you're using persistent objects/classes with such environments as mod_perl.


Happy Halloween


=head1 METHOD DETAILS

=over 4


=item C<new (constructor)>

 $masker = new DBIx::IO::Mask($dbh,$field_name);
 $masker = new DBIx::IO::Mask($dbh,undef,$table_name,$masked_col_name,$id_col_name,$no_cache);

Create a new $masker object for all your masking pleasures with a
db handle, $dbh from DBI (or DBIAccess). The rest of the arguments are optional:
$table_name contains all the valid values; it defaults to $field_name minus '_ID', which may or may not be present.
$id_col_name is the name of the column that contains the id values in $table_name that are masked;
it defaults to $field_name. 
$masked_col_name is the column in $table_name that has the meaningful values
the ids refer to; it defaults to 'USER_MASK'.
If $no_cache is true, then the cache will be refreshed (data will be pulled from the db, not the cache).

Return 0 if $table_name doesn't exist, or no values to mask were found.
Return undef if error.

=cut
sub new
{
    my ($caller,$dbh,$field_name,$table_name,$masked_col_name,$id_col_name,$no_cache) = @_;
    ref($dbh) || (warn("\$dbh doesn't appear to be valid"), return undef);
    my $class = ref($caller) || $caller;
    my $orig_table_name = $table_name || _strip_id($field_name);
    $field_name = uc($field_name);
    $table_name = uc($table_name) || _strip_id($field_name);
    $orig_table_name ||= $table_name;
    $masked_col_name = uc($masked_col_name) || $DEF_MASKED_COL_NAME;
    $id_col_name = uc($id_col_name) || $field_name;
    unless (exists($cached_by_name->{$table_name}{$masked_col_name}{$id_col_name}) && !$no_cache)
    {
        my $ret = $caller->_cache_table($dbh,$table_name,$masked_col_name,$id_col_name,$orig_table_name);
        $ret || return $ret;
    }
    my $self = { 
                 dbh => $dbh,
                 ids_by_mask => $cached_by_name->{$table_name}{$masked_col_name}{$id_col_name},
                 masks_by_id => $cached_by_id->{$table_name}{$masked_col_name}{$id_col_name},
                 sorted_mask_list => $sorted_masks->{$table_name}{$masked_col_name}{$id_col_name},
    };
    return bless($self,$class);
}

=pod

=item C<pick_list>

 $valid_values = $masker->pick_list();

Return a machine sorted list of masks and ids where each element
is a hash with keys:

 ID => the id value
 MASK => a meaningful indicator of what ID refers to


=cut
sub pick_list
{
    my $self = shift;
    return [ @{$self->{sorted_mask_list}} ];
}

#=pod
#
#=item C<ids_by_mask>
#
# $masked_values = $masker->ids_by_mask();
#
#Return a hash of masked values where the keys are all the masked
#values and the values of the hash are the ids. This hash only makes
#sense where the table has a unique constraint on the masked values.
#If you're looking for a sorted list of all mask, id value pairs, use
#pick_list().
#
#=cut
sub ids_by_mask
{
    my ($self) = @_;
    return { %{$self->{ids_by_mask}} };
}

=pod

=item C<ids_to_mask>

 $ids_to_mask_hash = $masker->ids_to_mask();

Return a hash ref of id => mask_value pairs where each key is
an id value and each value is meaningful to a human.

=cut
sub ids_to_mask
{
    my $self = shift;
    return { %{$self->{masks_by_id}} };
}

sub _strip_id
{
    my $id = shift;
    $id =~ s/_ID$//i;
    return $id;
}

sub _mask_search
{
    my ($self,$dbh,$masked_col_name,$orig_table_name) = @_;
    return new DBIx::IO::Search($dbh,$orig_table_name,undef,[ $masked_col_name ]);
}

sub _cache_table
{
    my ($self,$dbh,$table_name,$masked_col_name,$id_col_name,$orig_table_name) = @_;
    my $mask_search;
    unless ($mask_search = $self->_mask_search($dbh,$masked_col_name,$orig_table_name))
    {
        return $mask_search;
    }
    my $results = $mask_search->search() || return undef;
    my %cached_by_name;
    my %cached_by_id;
    my @mask_list;
    foreach my $result (@$results)
    {
        exists($cached_by_id{$result->{$id_col_name}}) && next;
        $cached_by_name{$result->{$masked_col_name}} = $result->{$id_col_name};
        $cached_by_id{$result->{$id_col_name}} = $result->{$masked_col_name};
        push @mask_list, { ID => $result->{$id_col_name}, MASK => $result->{$masked_col_name} };
    }
    $cached_by_name->{$table_name}{$masked_col_name}{$id_col_name} = \%cached_by_name;
    $cached_by_id->{$table_name}{$masked_col_name}{$id_col_name} = \%cached_by_id;
##at for some reason the degugger shows that the $sorted_masks address is not being reused between pick_list() invocations, $cached_by_id is, however
    $sorted_masks->{$table_name}{$masked_col_name}{$id_col_name} = \@mask_list;
    return 1;
}

sub _sort_format
{
    my $ids_by_mask = shift;
    my @sorted_hash;
    foreach my $mask (sort(keys(%$ids_by_mask)))
    {
        push @sorted_hash, { ID => $ids_by_mask->{$mask}, MASK => $mask };
    }
    return \@sorted_hash;
}

=pod

=item C<mask>

 $masked_value = $masker->mask($id_val);

Return the $masked_value of $id_val.

=cut
sub mask
{
    my ($self,$id_val) = @_;
    return $self->{masks_by_id}{$id_val};
#If there is no mask, return $id_val.
#    my $ret = $self->{masks_by_id}{$id_val};
#    return (length($ret) ? $ret : $id_val);
}

=pod

=item C<unmask>

 $id = $masker->unmask($masked_value);

Return the $id of a $masked_value.
CAUTION: Use ONLY if the masked value column has a unique constraint on it.

=back

=cut
sub unmask
{
    my ($self,$masked_val) = @_;
    return $self->{ids_by_mask}{$masked_val};
#If there is no id, return $masked_value.
#    my $ret = $self->{ids_by_mask}{$masked_val};
#    return (length($ret) ? $ret : $masked_val);
}


1;

__END__

=head1 BUGS

No known bugs.

=head1 SEE ALSO

L<DBIx::IO::Table>, L<DBIx::IO::Search>, L<DBIx::IO>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

