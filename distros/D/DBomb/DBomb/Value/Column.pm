package DBomb::Value::Column;

=head1 NAME

DBomb::Value::Column - The value in a single colummn.


=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.7 $';

use Carp::Assert;
use Carp qw(carp croak);
use base qw(DBomb::Value);
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [ qw(column_info), ## column_info object
                 ],
    'boolean' => [ qw(has_value), ## so we can tell between undef and NULL
                   qw(is_modified), ## local value is logically different than database value
                 ],
    ;

## init($column_info)
## init($column_info,$value)
sub init
{
    my $self = shift;

    assert(UNIVERSAL::isa($_[0],'DBomb::Meta::ColumnInfo'), __PACKAGE__ .' requires column info object');

    $self->column_info(shift);
    $self->value(shift) if @_;
}

## accessor
sub value
{
    my $self = shift;
    if (@_){
        $self->is_modified(1);
        $self->{'value'} = shift;
        $self->has_value(1);
    }
    $self->{'value'};
}

sub clear
{
    my $self = shift;
    $self->value(undef);
    $self->has_value(0);
    $self->is_modified(0);
}

## set_value_from_select($value)
sub set_value_from_select
{
    my $self = shift;
        assert(@_ == 1, 'value_for_select has 1 argument');
    my $v = shift;

    my $cinfo = $self->column_info;

    if (not defined $v){
        my $swn = $cinfo->select_when_null;
        $v = $swn->[0] if scalar @$swn;
    }

    if (defined $v && $cinfo->select_trim){
            $v =~ s/^\s+//;
            $v =~ s/\s+$//;
    }

    #TODO: trigger

    $self->value($v);
    $self->is_modified(0);
    return $self->value;
}

## get_value_for_update()
sub get_value_for_update
{
    my $self = shift;
        assert(@_ == 0, 'value_for_update has no arguments');

    return undef unless $self->has_value;
    my $v = $self->value;
    my $cinfo = $self->column_info;

    ## process the value
    if (defined $v){
        if ($cinfo->update_trim){
            $v =~ s/^\s+//;
            $v =~ s/\s+$//;
        }

        if (0 == length $v){
            my $uwe = $cinfo->update_when_empty;
            $v = $uwe->[0] if scalar @$uwe;
        }
    }

    #TODO: trigger

    return $v;
}

1;
__END__
