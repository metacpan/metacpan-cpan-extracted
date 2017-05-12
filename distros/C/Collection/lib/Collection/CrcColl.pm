#===============================================================================
#
#  DESCRIPTION:  Collection with auto make crc checksum
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
=head1 NAME

 Collection::CrcColl - experimental class for collections 

=cut

package Collection::CrcColl;
use strict;
use warnings;
use String::CRC32;
use JSON::XS;
use Collection::AutoSQL;
our @ISA = qw(Collection::AutoSQL);

our $VERSION = '0.11';
sub raw2hex { lc unpack( "H*", shift ) }
sub hex2raw { pack( "H*", shift ) }

=head1 TYPES


varchar => string       strin
binary => hex2raw ( raw2hex)        BINARY
refhash => { var1=>'1', var2=>0}    string ('var1=0 , var=2')
json   => string    json serialized

=cut
sub _create {
    my ( $self, %arg ) = @_;
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $id         = $arg{$field} || die "Need key field $field when create";

    my $rec  = $self->before_save(\%arg);
    my @keys = keys %$rec;
    #prepare
    my $str =
        "INSERT INTO  $table_name ("
      . join( ",", @keys )
      . ") VALUES ("
      . join( ',' => qw/?/ x @keys ) . ")";
    $self->_query_dbh( $str, map { $rec->{$_} } @keys );
    return { $id => $self->fetch_one($id) };
}

sub _init {
    my $self = shift;
    my %args = @_;
    my $res  = $self->SUPER::_init(@_);
    return $res;
}

=head2 _expand_rules

Owerwrite method and add check _crc fields

=cut

sub _expand_rules {
    my $self     = shift;
    my @expanded = $self->SUPER::_expand_rules(@_);
    my @res      = ();
    my $fields   = $self->_fields;

    #converts mid to raws
    foreach my $group (@expanded) {
        my @group = ();
        foreach my $rec (@$group) {
            next unless ( $rec->{type} || '' ) eq 'binary';

            $_ = hex2raw($_) for @{ $rec->{values} };
        }
    }
    foreach my $group (@expanded) {
        my @group = ();
        foreach my $rec (@$group) {
            my $field_name     = $rec->{field};
            my $crc_field_name = $field_name . "_crc";
            unless ( exists $fields->{$crc_field_name} ) {
                push @group, $rec;
            }
            else {

                # expand to crc and field_name
                my $values = $rec->{'values'};
                my ($crcrec) = $self->SUPER::_expand_rules(
                    { $crc_field_name => [ map { defined($_) ? crc32($_) : 0  } @$values ] } );
                push @group, @$crcrec, $rec;
            }
        }
        push @res, \@group;
    }
    @res;
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
    my @values    = ();
    foreach my $group (@processed) {
        my @sql_and = ();
        foreach my $rec (@$group) {

            my $values = [ @{ $rec->{'values'} } ];
            my $type   = $rec->{'type'};
            my $term   = $rec->{'term'};
            my $field  = $rec->{'field'};

            #construct query
            my $sql_term = $term;

            #this
            #
            # check type and = or like !
            #
            #
            my $values_sql;
            if ( scalar @$values > 1 ) {
                $values_sql = "(" . join( ',' => qw/?/ x @$values ) . ")";
                $sql_term = "in" if $sql_term eq '=';
            }
            else {
                $values_sql = "?";
            }
            push @values,  @$values;
            push @sql_and, "$field $sql_term $values_sql";
        }
        push @sql_or, "(" . join( " and ", @sql_and ) . ")";
    }
    return join( " or ", @sql_or ), @values;
}

sub after_load {
    my $self   = shift;
    my $fields = $self->_fields;
    my $rec = $_[0];
    my %res;
    while ( my ($key, $val)  =each %$rec)  {
        #key without type
        unless (exists $fields->{$key}) {
            $res{$key} = $val;
            next;
        }
        my $type = $fields->{$key};

        if ( $type eq 'binary' ) {
            $val = raw2hex( $val );
        }
        if ($type eq 'refhash' ) {
        # unpack string 'test_val=1,mod=0'
            $val ={ map { split/=/,$_ } split /,/, $val }; 
        }
         if ($type eq 'json' ) {
            unless ($val) {
                $val = {}
            } else {
                #clear UTF-X bit
                utf8::encode($val) if utf8::is_utf8($val);
                $val = decode_json($val)
            }
        }
       $res{$key} = $val;
    
    }
    return \%res;
}

sub before_save {
    my $self = shift;
    my $ref  = shift;

    my $fields = $self->_fields;
    my %res    = ();
    my %crced  = ();
    while ( my ( $key, $val ) = each %$ref ) {

        #skip crced
        next if exists $crced{$key};
        #key without type
        unless (exists $fields->{$key}) {
            $res{$key} = $val;
            next;
        }

        $val = hex2raw($val)
          if exists $fields->{$key} and $fields->{$key} eq 'binary';
        my $crc_field_name = $key . "_crc";
        if ( exists $fields->{$crc_field_name} ) {
            $crced{$crc_field_name} = $res{$crc_field_name} = defined($val) ? crc32($val) : 0;
        }
        if ($fields->{$key} eq 'refhash' ) {
            $val={} unless ref($val);
            #serialize
            $val = join ","=> map {"$_=".$val->{$_}} keys %$val;
        }
        if ($fields->{$key} eq 'json' ) {
            $val={} unless ref($val);
            $val = JSON::XS->new->utf8->pretty->encode($val);
        }
        $res{$key} = $val;
    }
    return \%res;
}

sub sub_ref {
    my $self = shift;
    if ( my $val = shift ) {
        $self->_sub_ref($val);
    }
    return $self->_sub_ref();
}

sub _fetch {
    my $self       = shift;
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my ( $where, @values ) = $self->_prepare_where(@_);
    return {} unless $where;
    my $str    = "SELECT * FROM $table_name WHERE $where";
    my $result = {};
    my %keys_hash;
    my $qrt = $self->_query_dbh( $str, @values );

    while ( my $rec = $qrt->fetchrow_hashref ) {
        my %hash = %{ $self->after_load($rec) };
        my $id   = $hash{$field};
        delete $hash{$field} if $self->_is_delete_key_field;
        $result->{$id} = \%hash;
    }
    $qrt->finish;
    return $result;
}

sub _delete {
    my $self = shift;
    return [] unless scalar @_;
    my @ids = @_;
    #add support for user defined query
    # $col->delete({field=>[232323]})

    my $user_query = ref($ids[0]) eq 'HASH' ? $ids[0] : '';
    #where
    my ( $where, @values ) =
      $self->_prepare_where( $user_query ? $user_query : { $self->_key_field => \@ids } );
    my $table_name = $self->_table_name();
    my $str        = "DELETE FROM $table_name WHERE $where";
    $self->_query_dbh( $str, @values );
    return \@_;
}

sub _store {
    my ( $self, $ref ) = @_;
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    while ( my ( $key, $rec_ref ) = each %$ref ) {
        my $tmp_val  = ref($rec_ref) eq 'HASH' ? $rec_ref : $rec_ref->_get_attr;
        my $prepared = $self->before_save($tmp_val);
        my @rows     = ref($prepared) eq 'ARRAY' ? @$prepared : ($prepared);

        #where
        my ( $where, @values ) = $self->_prepare_where( { $field => $key } );
        foreach my $val (@rows) {
            my @records =
              map { [ $_, defined( $val->{$_} ) ? $val->{$_} : '' ] }
              keys %$val;
            my $query =
                "UPDATE $table_name SET "
              . join( ",", map { qq!$_->[0]=\?! } @records )
              . " where $where";
            $self->_query_dbh( $query, map ( $_->[1], @records ), @values );
        }    #foreach
    }    #while
}

sub _fetch_ids {
    my $self       = shift;
    my $dbh        = $self->_dbh();
    my $table_name = $self->_table_name();
    my $field      = $self->_key_field;
    my $query      = "SELECT $field FROM $table_name";
    my $res = $dbh->selectcol_arrayref($query);
    if ( my $type = $self->_fields->{$field} ) {
        #convert binary to string
        if ($type eq 'binary') {
            $_ = raw2hex($_) for @$res ;
        }
    }
    return $res;
}

1;

