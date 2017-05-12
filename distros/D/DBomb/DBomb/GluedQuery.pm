package DBomb::GluedQuery;

=head1 NAME

DBomb::GluedQuery - A query that is glued to a DBomb meta object by primary key.

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.13 $';

use Carp::Assert;
use Carp qw(carp croak);
use DBomb;
use DBomb::Value::Key;
use base qw(DBomb::Query);
use Class::MethodMaker
    'get_set' => [ qw(columns_list),     # [ column_info, ... ]
                   qw(peer),        # a DBomb::Base object
                   qw(primary_key_idx), # [ index, index ]
                  ],
    ;

## new DBomb::GluedQuery($dbh,$columns_list)
## new DBomb::GluedQuery($dbh,$peer,$columns_list)
## new DBomb::GluedQuery($peer,$columns_list)
## new DBomb::GluedQuery($columns_list)
sub init
{
    my $self = shift;
    my $columns;
    $self->columns_list([]);
    $self->primary_key_idx([]);

    ## First argument might be a dbh or peer object
    for(@_){

        if (UNIVERSAL::isa($_,'DBI::db')){
            $self->dbh($_);
        }
        elsif (UNIVERSAL::isa($_,'DBomb::Base')){
            $self->peer($_);
        }
        elsif (UNIVERSAL::isa($_, 'ARRAY')){
            $columns = $_;
        }
        else{
            croak "invalid paramter to GluedQuery->new()";
        }
    }

    ## verify args
    assert(defined($columns),        'GluedQuery requires a [columns_list]');
    assert(UNIVERSAL::isa($columns,'ARRAY'), 'GluedQuery requires a [columns_list]');
    for(@$columns){
        assert(UNIVERSAL::isa($_,'DBomb::Meta::ColumnInfo'), 'GluedQuery requires columninfo objs')
    }

    ## Save the indexes of the primary key columns.
    my %unseen_pk_columns = map { $_->name => $_ } @{$columns->[0]->table_info->primary_key->columns_list};
    for my $i (0..$#$columns) {
        if ( $columns->[$i]->is_in_primary_key ){
            push @{$self->primary_key_idx},  $i;
            delete $unseen_pk_columns{$columns->[$i]->name};
        }
    }

    ## Add the primary key columns that were not in the column list.
    ## Only do this for peerless queries
    if (not defined $self->peer){

        for (values %unseen_pk_columns){
            push @$columns, $_;
            push @{$self->primary_key_idx}, $#$columns;
        }
    }


    for (@$columns){
        push @{$self->columns_list}, $_;
    }

    $self->SUPER::init(map {$_->fq_name} @{$self->columns_list});

}

sub from
{
    my ($self, $table_info) = @_;
    assert(UNIVERSAL::isa($table_info,'DBomb::Meta::TableInfo'), 'valid parameters');
    return $self->SUPER::from($table_info->name);
}

sub join       { die "not implemented" }
sub on         { die "not implemented" }
sub right_join { die "not implemented" }
sub left_join  { die "not implemented" }


sub fetchrow_arrayref
{
    my $self = shift;
    return $self->SUPER::fetchrow_arrayref(@_);
}

sub fetchall_arrayref
{
    my $self = shift;
    my $a = [];
    while (my $obj = $self->fetchrow_objectref){
        push @$a, $obj;
    }
    return $a;
}

sub fetch
{
    fetchrow_objectref(@_);
}

sub fetchrow_objectref
{
    my $self = shift;

    my $row = $self->SUPER::fetchrow_arrayref;
    return undef unless $row && @$row;

    my $columns = $self->columns_list;
    my $tinfo = $columns->[0]->table_info;
    my $class = $tinfo->class;

    my $obj = $self->peer;

    if (not $obj) {

        # pluck the primary keys first.
        my $pkv = new DBomb::Value::Key($tinfo->primary_key,
                [ map { $row->[$_] }  @{$self->primary_key_idx} ]);

        $obj = $class->new($pkv);
        $obj->dbh($self->dbh);
    }

    assert($obj, 'has a peer, or, PK is in query');

    my $values = $obj->_dbo_values;
    for my $i (0..$#$row){
        next if $columns->[$i]->is_in_primary_key; # skip pks.

        #my $accessor = $columns->[$i]->accessor;
        #$obj->$accessor($row->[$i]);
        $values->{$columns->[$i]->name}->set_value_from_select($row->[$i]);
    }

    return $obj;
}

## selectall_arrayref()
## selectall_arrayref($dbh,@bind_values)
## selectall_arrayref(@bind_values)
sub selectall_arrayref
{
    my $self = shift;
    my (@bind_values) = @_;
    my $dbh = $self->dbh;

    if (UNIVERSAL::isa($bind_values[0],'DBI::db')){
        $dbh = $self->dbh(shift @bind_values);
    }

        assert(defined($dbh), 'selectall_arrayref requires a $dbh');

    $self->prepare($dbh);
    $self->execute(@bind_values);
    return $self->fetchall_arrayref;
}


1;
__END__

