package DTL::Fast::Filter::Slice;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{slice} = __PACKAGE__;

use Scalar::Util qw(reftype);

#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no slicing settings specified")
        if (not scalar @{$self->{parameter}});
    $self->{settings} = $self->{parameter}->[0];
    return $self;
}

#@Override
sub filter
{
    my ($self, $filter_manager, $value, $context) = @_;

    my $settings = $self->{settings}->render($context);

    die $self->get_render_error( $context, 'slicing format is not defined in current context')
        if (not defined $settings);

    my $value_type = reftype $value;

    if (not defined $value_type)
    {
        if (defined $value)
        {
            eval {
                $value = $self->slice_scalar($value, $settings);
            };
            die $self->get_render_error($context, $@) if ($@);
        }
        else
        {
            die $self->get_render_error( $context, 'unable to slice undef value');
        }
    }
    elsif ($value_type eq 'ARRAY')
    {
        eval
        {
            $value = $self->slice_array($value, $settings);
        };
        die $self->get_render_error($context, $@) if ($@);
    }
    elsif ($value_type eq 'HASH')
    {
        $value = $self->slice_hash($value, $settings);
    }
    elsif ($value_type eq 'SCALAR')
    {
        $value = $self->slice_scalar($$value, $settings);
    }
    else
    {
        die $self->get_render_error(
                $context
                , sprintf(
                    "can slice only HASH, ARRAY or SCALAR values, not %s (%s)"
                    , $value_type
                    , ref $value || 'SCALAR'
                )
            );
    }

    return $value;
}

sub slice_scalar
{
    my ($self, $scalar, $settings ) = @_;

    my ($start, $end) = $self->parse_indexes($settings, length($scalar) - 1 );

    return substr $scalar, $start, $end - $start + 1;
}

sub slice_array
{
    my ($self, $array, $settings ) = @_;

    my ($start, $end) = $self->parse_indexes($settings, $#$array);

    return [ @{$array}[$start .. $end] ];
}


sub slice_hash
{
    my ($self, $hash, $settings) = @_;
    return [ @{$hash}{(split /\s*,\s*/, $settings)} ];
}

sub parse_indexes
{
    my ($self, $settings, $last_index) = @_;

    my $start = 0;
    my $end;

    if ($settings =~ /^([-\d]+)?\:([-\d]+)?$/) # python's format
    {
        $start = $self->python_index_map($1, $last_index) // $start;
        $end = defined $2 ?
            $self->python_index_map($2, $last_index) - 1
                          : $last_index;
    }
    elsif ($settings =~ /^([-\d]+)?\s*\.\.\s*([-\d]+)?$/) # perl's format
    {
        $start = $1 // $start;
        $end = $2 // $last_index;
    }
    else
    {
        die sprintf(
                "array slicing option may be specified in one of the following formats:\npython: [from_index]:[to_index+1]\n  perl: [from_index]..[to_index]\ngot `%s` instead.\n"
                , $settings // undef
            );
    }

    $start = $last_index if ($start > $last_index);
    $end = $last_index if ($end > $last_index);

    if ($start > $end) {
        my $var = $start;
        $start = $end;
        $end = $var;
    }

    return ($start, $end);
}

sub python_index_map
{
    my ( $self, $pyvalue, $lastindex ) = @_;

    return $pyvalue if (not defined $pyvalue);

    return $pyvalue < 0 ?
        $lastindex + $pyvalue + 1
        : $pyvalue;
}

1;
