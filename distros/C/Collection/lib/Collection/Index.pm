#===============================================================================
#
#  DESCRIPTION:  Class for index collections
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
package Collection::Index;
use strict;
use warnings;
use Collection::CrcColl;
use Collection::AutoSQLnotUnique;
use base 'Collection::CrcColl';
our $VERSION = '0.02';
#store records immediately
=head2 

    $col->put( id=>{record} )

=cut

sub put {
    my $self = shift;
    my %recs = @_;
    $self->_store(\%recs);
}

sub before_save {
    my $self                   = shift;
    my $attr                   = shift;
    my $fields                 = $self->_fields;
    my $rec                    = {};
    my $exists_array_in_values = 0;
    my $max_array_size         = 1;

    #strip unknown records
    #for arrays in values calc max size
    while ( my ( $key, $val ) = each %$attr ) {
        next unless exists $fields->{$key};
        $rec->{$key} = $val;
        if ( ref($val) eq 'ARRAY' ) {
            ++$exists_array_in_values;
            my $size = scalar(@$val);

            #set max of arrays
            $max_array_size = $size if $max_array_size < $size;
        }
    }

    #if simple record just save
    unless ($exists_array_in_values) {  
        return $self->SUPER::before_save($rec);
    }
    else {

        # for record { item1=>1, item2=[1,2]}
        # make [  {item1=>1, item2=>1}, {item1=>1, item2=>2} ]
        my @records_for_save;

        #convert values to arrays refs
        while ( my ( $key, $val ) = each %$rec ) {

            #convert scalar value to array
            my @values = ref($val) ? @$val : ($val);

            #enlarge to max size
            if ( my $diff = $max_array_size - scalar(@values) ) {
                push @values, ( $values[-1] ) x $diff;
            }
            $rec->{$key} = \@values;

            #also autovivificate
            for ( 0 .. $max_array_size - 1 ) {
                $records_for_save[$_]->{$key} = $values[$_];
            }
        }
        my @res = ();
        foreach my $record (@records_for_save) {
            push @res, $self->SUPER::before_save($record);
        }
        return \@res

    }

}

sub fetch {
    my $self     = shift;
    my @ids      = ();
    my $coll_ref = $self->_obj_cache();
    my @fetch    = ();
    foreach my $id (@_) {
        next
          unless defined $id;

        push @fetch, $id;
    }
    my %result = ();
    if ( scalar(@fetch)
        && ( my $results = $self->_fetch(@fetch) ) )
    {
        while ( my ( $key, $val ) = each %{$results} ) {
            #bless for loaded
            my $ref = $self->_prepare_record( $key, $results->{$key} );
            if ( ref($ref) ) {
                $result{$key} = $ref;
            } else {
                warn "Fail prepare for $key";
            }
        }
    }
    return \%result;
}

#no any ActiveRecord
sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
    if ( ref( $self->_sub_ref ) eq 'CODE' ) {
        return $self->_sub_ref()->( $key, $ref );
    }
     return $ref;
}

sub _store {
    my $self = shift;
    return $self->Collection::AutoSQLnotUnique::_store(@_)
}
sub store {
    die "not implemented";
}
sub list_ids {
    my $self = shift;
    return $self->Collection::AutoSQLnotUnique::list_ids(@_)
}

1;


