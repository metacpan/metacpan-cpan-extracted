package Collection::AutoSQL;

=head1 NAME

 Collection::AutoSQL - class for collections of data, stored in database.

=head1 SYNOPSIS

  use Collection::AutoSQL;
  my $metaobj = new Collection::AutoSQL::
           dbh => $dbh,         #database connect
           table => 'metadata', #table name
           field=> 'mid',       #key field (IDs), usually primary,autoincrement
           cut_key =>1,         #delete field mid from readed records, 
                                #or delete_key=>1
           sub_ref =>
              #callback for create objects for readed records
              sub { my $id = shift; new MyObject:: shift }
 
             dbtype => 'pg' # set type of DataBase to PostgreSQL (default: mysql)

=head1 DESCRIPTION

Provide simply access to records, with unique field.

For exampe:

 HAVE mysql table:

 mysql> \u orders
 mysql> select * from beers;
 +-----+--------+-----------+
 | bid | bcount | bname     |
 +-----+--------+-----------+
 |   1 |      1 | heineken  |
 |   2 |      1 | broadside |
 |   3 |      2 | tiger     |
 |   4 |      2 | castel    |
 |   5 |      3 | karhu     |
 +-----+--------+-----------+
 5 rows in set (0.00 sec)

 my $beers = new Collection::AutoSQL::
  dbh     => $dbh,          #database connect
  table   => 'beers',       #table name
  field   => 'bid',         #key field (IDs), usually primary,autoincrement
  cut_key => 1;             #delete field 'bid' from readed records,


 my $heineken = $beers->fetch_one(1);
 #SELECT * FROM beers WHERE bid in (1)

 print Dumper($heineken);

 ...

      $VAR1 = {
             'bcount' => '1',
             'bname' => 'heineken'
              };
 ...
 
 $heineken->{bcount}++;

 my $karhu = $beers->fetch(5);
 #SELECT * FROM beers WHERE bid in (5)
 
 $karhu->{bcount}++;
 
 $beers->store;
 #UPDATE beers SET bcount='2',bname='heineken' where bid=1
 #UPDATE beers SET bcount='4',bname='karhu' where bid=5

 my $hash = $beers->fetch({bcount=>[4,1]});
 #SELECT * FROM beers WHERE  ( bcount in (4,1) )
 
 print Dumper($hash);
 
 ...

 $VAR1 = {
          '2' => {
                   'bcount' => '1',
                   'bname' => 'broadside'
                 },
          '5' => {
                   'bcount' => '4',
                   'bname' => 'karhu'
                 }
        };

  ...



=head1 METHODS

=cut

use strict;
use warnings;
use Data::Dumper;
use Carp;
use Collection;
use Collection::Utl::Base;
use Collection::Utl::ActiveRecord;
use Collection::Utl::Flow;
@Collection::AutoSQL::ISA     = qw(Collection);
$Collection::AutoSQL::VERSION = '1.1';
attributes
  qw( _dbh _table_name _key_field _is_delete_key_field _sub_ref _fields);

sub _init {
    my $self = shift;
    my %arg  = @_;
    $self->_dbh( $arg{dbh} );
    $self->_table_name( $arg{table} );
    $self->_key_field( $arg{field} );
    $self->_is_delete_key_field( $arg{delete_key} || $arg{cut_key} );
    $self->_fields( $arg{fields} || {} );
    $self->_sub_ref( $arg{sub_ref} );
    $self->SUPER::_init(@_);
}

=head2 get_dbh

 Return current $dbh.

=cut

sub get_dbh {
    return $_[0]->_dbh;
}

=head2 get_ids_where(<SQL where  expression>)

Return ref to ARRAY of readed IDs.

=cut

sub get_ids_where {
    my $self       = shift;
    my $where      = shift || return [];
    my $limit      = 0; 
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $query      = "SELECT $field FROM $table_name WHERE $where";
    if ($limit) {
       $query .= " limit $limit"; 
    }
    return ( $dbh->selectcol_arrayref($query) || [] );
}

sub after_load {
    my $self = shift;
    return $_[0];
}

sub before_save {
    my $self = shift;
    return $_[0];
}

sub _query_dbh {
    my $self  = shift;
    my $query = shift;
    my $dbh   = $self->_dbh;
    my $sth   = $dbh->prepare($query) or croak $dbh::errstr. "\nSQL: $query";
    $sth->execute(@_) or croak $dbh::errstr. "\nSQL: $query";
    return $sth;
}

sub _store {
    my ( $self, $ref ) = @_;
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;

    while ( my ( $key, $rec_ref ) = each %$ref ) {
        my $tmp_val  = ref($rec_ref) eq 'HASH' ? $rec_ref : $rec_ref->_get_attr;
        my $prepared = $self->before_save($tmp_val);
        my @rows     = ref($prepared) eq 'ARRAY' ? @$prepared : ($prepared);
        foreach my $val (@rows) {
            my @records =
              map { [ $_, defined( $val->{$_} ) ? $val->{$_} : '' ] }
              keys %$val;
            my $query =
                "UPDATE $table_name SET "
              . join( ",", map { qq!$_->[0]=\?! } @records )
              . " where $field=?";
            $self->_query_dbh( $query, map ( $_->[1], @records ), $key );
        }    #foreach
    }    #while
}

=head2 _expand_rules ( <term1>[, <term2> ] )

convert array of terms to scructs with type field

Got 
    { test => 1, guid => $two },'key'

Return array:

    (

        {
            'values' => [1],
            'term'   => '=',
            'field'  => 'test'
        },
        {
            'values' => ['4D56A984-0B5E-11DC-8292-3DE558089BC5'],
            'term'   => '=',
            'field'  => 'guid',
            'type' => 'varchar'
        }
    )

=cut

sub _expand_rules {
    my $self  = shift;
    my @res   = ();
    my $field = $self->_key_field;

    #group { id =>'1221'}, {id=>'212'} to
    # { field=>[ '1221', '212' ] }
    my @grouped = ();
    foreach my $exp (@_) {
        if ( ref($exp) ) {

            # convert scalar values to ref
            for ( values %$exp ) {
                $_ = [$_] unless ref($_);
            }
            push @grouped, $exp;
        }
        else {

            #got key
            my $last_rec = $grouped[-1];

            #check if  previus element is key value
            if (    $last_rec
                and exists $last_rec->{$field}
                and ( keys(%$last_rec) == 1 ) )
            {
                push @{ $last_rec->{$field} }, $exp;

            }
            else {
                push @grouped, { $field => [$exp] };
            }

        }
    }

    #now convert passed hashes to special structs with type
    my @result = ();
    my $fields = $self->_fields;
    foreach my $rec (@grouped) {
        my @group = ();
        while ( my ( $field_name, $values ) = each %$rec ) {

            #fill term
            my $term = '=';    #default term value
                               #clear fielname from terms
            if ( $field_name =~ s%([<>])%% ) {
                $term = $1;
            }
            my %rule =
              ( field => $field_name, 'values' => $values, term => $term );

            #fill type
            if ( my $type = $fields->{$field_name} ) {
                $rule{type} = $type;
            }
            push @group, \%rule;
        }
        push @result, \@group;
    }
    return @result;
}

=head2 _prepare_where <query hash>

return <where>  expression or undef else

=cut

sub _prepare_where {
    my $self  = shift;
    my $dbh   = $self->_dbh();
    my $field = $self->_key_field;
    my @extra_id;
    my @docs;

    # group ids and add fill type of fields
    my @processed = $self->_expand_rules(@_);
    my @sql_or    = ();
    foreach my $group (@processed) {
        my @sql_and = ();
        foreach my $rec (@$group) {

            my $values = [ @{ $rec->{'values'} } ];
            my $type   = $rec->{'type'};
            my $term   = $rec->{'term'};
            my $field  = $rec->{'field'};

            #process varchar values
            if ( defined $type ) {
                if ( $type eq 'varchar' ) {
                    $_ = $dbh->quote($_) for @$values;
                }
            }
            else {
                for (@$values) {
                    $_ = $dbh->quote($_) if !/^\d+$/;
                }

            }

            #construct query
            my $sql_term = $term;

            #this
            #
            # check type and = or like !
            #
            #
            my $values_sql;
            if ( scalar @$values > 1 ) {
                $values_sql = "(" . join( ",", @$values ) . ")";
                $sql_term = "in" if $sql_term eq '=';
            }
            else {
                $values_sql = "@$values";
            }
            push @sql_and, "$field $sql_term $values_sql";
        }
        push @sql_or, "(" . join( " and ", @sql_and ) . ")" if @sql_and;
    }
    return join " or ", @sql_or;
}

sub _fetch {
    my $self       = shift;
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $where      = $self->_prepare_where(@_);
    return {} unless $where;
    my $str    = "SELECT * FROM $table_name WHERE $where";
    my $result = {};
    my %keys_hash;
    my $qrt = $self->_query_dbh($str);

    while ( my $rec = $qrt->fetchrow_hashref ) {
        my %hash = %$rec;
        my $id   = $hash{$field};
        delete $hash{$field} if $self->_is_delete_key_field;
        $result->{$id} = $self->after_load( \%hash );
    }
    $qrt->finish;
    return $result;
}

sub _create {
    my ( $self, %arg ) = @_;
    my $table_name = $self->_table_name();
    my $id;
    my $field = $self->_key_field;
    if ( $self->_is_delete_key_field ) {
        $id = $arg{$field};
        delete $arg{$field};
    }
    my @keys = keys %arg;
    my $str =
        "INSERT INTO  $table_name (" 
      . join( ",", @keys ) 
      . ") VALUES ("
      . join( ",",
        map { $self->_dbh()->quote( defined($_) ? $_ : '' ) }
        map { $arg{$_} } @keys )
      . ")";
    $self->_query_dbh($str);
    my $inserted_id;
    if ( !$self->_is_delete_key_field && exists $arg{$field} ) {
        $inserted_id = $arg{$field};
    }
    else {
        $inserted_id =
             $self->_dbh->last_insert_id( '', '', $table_name, $field )
          || $self->GetLastID();
    }
    return { $inserted_id => $self->fetch_one($inserted_id) };
}

sub _delete {
    my $self       = shift;
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    return [] unless scalar @_;
    my $str = "DELETE FROM $table_name WHERE $field IN ("
      . join( ",", qw/?/ x @_ ) . ")";
    $self->_query_dbh( $str, @_ );
    return \@_;
}

sub _fetch_ids {
    my $self       = shift;
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $query      = "SELECT $field FROM $table_name";
    return $dbh->selectcol_arrayref($query);
}

#__flow_sql__ $sql_query,[values for sql_query], $on_page_count, $page_num
sub __flow_sql__ {
    my $self     = shift;
    my $flow     = shift;
    my $query    = shift;
    my $params   = shift;    #[array]
    my $bulk     = shift;
    my $one_page = shift;
    my $dbh   = $self->_dbh();
    my $field = $self->_key_field;
    my $page  = $one_page || 0;
    my $count = 0;
    my $flow_res;
    do {
        my $query_limit = 
                    ( ($self->{dbtype}|| '' ) eq  'pg') 
                    ? "$query limit $bulk offset " . ( $page * $bulk )
                    : "$query limit " . ( $page * $bulk ) . ", $bulk";
        my $res = $dbh->selectcol_arrayref( $query_limit, {}, @$params );
        $count = scalar(@$res);
        $flow_res =
          $flow->_flow( map { $self->after_load( { $field => $_ } )->{$field} }
              @$res );
        $page++;

    } until $count < $bulk or defined($one_page) or $flow_res;
    return undef;

}

=head2 list_ids [ flow=>$Flow],

Return list of ids


params:

 flow - Flow:: object for streaming results
 onpage - [pagination] count of ids on page
 page - [pagination] requested page ( depend on onpage)
 exp - ref to expression for select
 desc - revert sorting ([1,0])
 where -  custom where if needed, instead expr ['where sring', $query_param1,..]
 query - custom query
 uniq - set uniq flag ( eq GROUP BY (key) )
 order - ORDER BY field

return:
    [array] - array of ids

if used C<flow> param:
    "string" - if error
    undef  - ok

expamles:

    $c->list_ids() #return [array of ids]

    $c->list_ids(flow=>$flow, exp=>{ type=>"t1", "date<"=>12341241 },
        page=>2, onpage=>10, desc=>1  )

=cut

sub list_ids {
    my $self = shift;
    my %args = @_;

    # return array ref by default
    return $self->_fetch_ids unless scalar(@_);
    my @query_param = ();
    my $where;
    if ( my $custom_where = $args{'where'} ) {
        ( $where, @query_param ) = @{$custom_where};
    }
    elsif ( my $exp = $args{'expr'} ) {
        ( $where, @query_param ) = $self->_prepare_where($exp);
    }

    #make query
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $query      = $args{query} || "SELECT $field FROM $table_name";
    $query .= " where $where" if $where;
    if ($args{uniq}) {
      #strip dups
      $query .= " group by $field";
    }
    my $onpage = $args{onpage} || 10000;

    #add order by
    if ( my $orderby = $args{order} ) {
        $query .= " ORDER BY $orderby";
    }

    #change sorting
    $query .= " DESC" if $args{desc};

    if ( my $flow = $args{flow} ) {
        my $fparser = $flow->parser;
        $fparser->begin;
        $self->__flow_sql__( $fparser, $query, \@query_param, $onpage,
            $args{page} );
        $fparser->end;
    } else {
        #return flow
        new Collection::Utl::Flow:: __flow_sql__=>[
            $query, \@query_param, $onpage,
            $args{page}],
            __collection__ => $self
    }
}

sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
    my %hash;
    tie %hash, 'Collection::Utl::ActiveRecord', hash => $ref;
    if ( ref( $self->_sub_ref ) eq 'CODE' ) {
        return $self->_sub_ref()->( $key, \%hash );
    }
    return \%hash;
}

# overlap for support get by query
sub fetch_one {
    my $self = shift;
    my ($obj) = values %{ $self->fetch(@_) };
    $obj;
}

sub GetLastID {
    my $self       = shift;
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $res =
      $self->_query_dbh("select max($field)as res from $table_name")
      ->fetchrow_hashref;
    return $res->{res};
}

1;
__END__


=head1 SEE ALSO

Collection::ActiveRecord, Collection, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


