package DBIx::ObjectMapper::Metadata::Table::Column::Func;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Base);

sub as_string {
    my $self = shift;

    my @func = @{$self->{func}};
    my @param = @{$self->{func_param}};

    my $str = $self->_as_string( shift(@func), shift(@param) );
    $str = $self->_format($func[$_], $str, @{$param[$_]}) for 0 .. $#func;
    return $str;
}

sub _as_string {
    my ( $self, $func, $param ) = @_;
    $self->_format($func, $self->table . $self->sep . $self->name, @$param );
}

sub _format {
    my ( $self, $func, @param ) = @_;
    return sprintf( "%s(%s)", uc($func), join( ', ', @param ) );

}

sub new {
    my $class = shift;
    my $column_obj = shift;
    my $func  = shift;
    my @param = @_;
    my %column_param = %$column_obj;

    if( my $parent_func = delete $column_param{func} ) {
        $func = [ @$parent_func, $func ];
    }
    else {
        $func = [ $func ];
    }

    my $param;
    if( my $parent_param = delete $column_param{func_param}) {
        $param = [  @$parent_param, \@param ];
    }
    else {
        $param = [ \@param ];
    }

    my $self  = $class->SUPER::new(%column_param);
    $self->{func}       = $func;
    $self->{func_param} = $param;
    return $self;
}

sub func {
    my $self = shift;
    return ref($self)->new(
        $self,
        @_,
    );
}

1;
