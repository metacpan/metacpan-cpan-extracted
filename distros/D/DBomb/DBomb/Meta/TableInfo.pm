package DBomb::Meta::TableInfo;

=head1 NAME

DBomb::Meta::TableInfo -

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.16 $';

use DBomb;
use DBomb::Meta::OneToMany;
use Carp::Assert;
use Carp qw(carp);

use Class::MethodMaker
    'new_with_init' => 'new_internal',
    'get_set'       => [qw(name),
                        qw(columns), ## Tie::IxHash {name => column_info}
                        qw(select_groups),  ## {group_name => +{columns=>1} }
                        qw(primary_key), ## Key object
                        qw(keys),         ## [ Keys.... ]
                        qw(has_manys), ## [ HasMany,...]
                        qw(has_queries), ## [ HasQuery,...]
                        qw(has_as), ## [ HasA,...]
                        qw(class)],   ## perl package
    'boolean'       =>  qw(is_resolved),
    ;


## TableInfo->factor_new($table_name,$class)
sub factory_new
{
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $table = shift;

    return exists(DBomb->tables->{$table})
            ?     DBomb->tables->{$table}
            : $class->new_internal($table, @_);
}

## new TableInfo($table_name,$class)
sub init
{
    my $self = shift;
    $self->name    ( shift);
    $self->class   ( shift);
    my %h = ();
    tie %h, 'Tie::IxHash';
    $self->columns ( \%h );
    $self->select_groups  ( +{ ':all' => +{}} );
    $self->keys    (  [] );
    $self->has_queries (  [] );
    $self->has_manys (  [] );
    $self->has_as (  [] );

    assert(defined($self->name), 'name defined');
    assert(defined($self->class), 'class defined');

    DBomb->tables->{$self->name} = $self;
}

## return columns
sub columns_list
{
    my $self = shift;
    return [ values %{$self->columns} ];
}

sub resolve
{
    my $self = shift;

    if ( not defined $self->class ){
        my $name = $self->name || '';
        die "Table '$name' could resolve the associated class. Did you call dbo_def_data_source?";
    }

    for ( values(%{$self->columns}),
                   $self->primary_key,
                   @{$self->keys},
                   @{$self->has_manys},
                   @{$self->has_as},
                   @{$self->has_queries}){
        $_->resolve;
    }

}

sub add_column
{
    my ($self, $column) = @_;
    assert(ref $self);
    assert(defined $column);
    $self->columns->{$column->name} = $column;

    ## Add it to the ':all' select group
    $self->select_groups->{':all'}->{$column->name} = $column;
}

## add_select_group($group,$column_list)
sub add_select_group
{
    my ($self,$group,$column_list) = @_;

        assert(UNIVERSAL::isa($self,__PACKAGE__));
        assert(UNIVERSAL::isa($column_list,'ARRAY'));
        for (@$column_list){
            assert(UNIVERSAL::isa($_,'DBomb::Meta::ColumnInfo'));
        }

    $group = "group-" . scalar keys %{$self->select_groups};

    if (exists $self->select_groups->{$group}){
        carp "select group '$group' redefined for table @{[$self->name]}"
    }else{
        $self->select_groups->{$group} = +{};
    }

    for (@$column_list){
        $self->select_groups->{$group}->{$_->name} = $_;
    }
    return $self->select_groups->{$group}
}

## return a OneToMany object.
## self is the 'one' end of the relationship.
## $foreign_table is the 'many' end.
## guess_one_to_many($foreign_table)
sub guess_one_to_many
{
    my ($self, $f_table) = @_;
        assert(UNIVERSAL::isa($f_table,'DBomb::Meta::TableInfo'), 'guess_one_to_many requires a table info');

    my $many_pk = $f_table->primary_key;
    my @try_keys = grep { $_ != $many_pk } @{$f_table->keys};
    my @ok;

    ## Try every combination of keys, starting with the primary key
    ## A match has the same column count.,
    ## But a good match has the same column names.
    for my $one_key ($self->primary_key, @{$self->keys}) {

        for my $many_key (@try_keys){
            next unless $one_key->column_count == $many_key->column_count;
            push @ok, [ $one_key, $many_key ];
            last; ## TODO: instead of last, compare column names.
        }
    }

    return undef unless @ok;
    return new DBomb::Meta::OneToMany(@{$ok[0]});
}

## find a key that matches a column list
## find_key([column_name_or_info,...])
sub find_key
{
    my ($self, $columns_list) = @_;
        assert(UNIVERSAL::isa($self,__PACKAGE__));
        assert(UNIVERSAL::isa($columns_list,'ARRAY'));
        assert(@$columns_list > 0);

KEY: for my $key (@{$self->keys}){
        next unless $key->column_count == @$columns_list;

        my $ix=0;
        for my $cinfo (values %{$key->columns}){

            my $col_name = ref($columns_list->[$ix]) ? $columns_list->[$ix]->name : $columns_list->[$ix];
            next KEY unless $col_name eq $cinfo->name;
        }
        continue{ $ix++ }

        ## If we got here, all names matched.
        return $key;
    }

    undef; ## no key found
}

1;
__END__

