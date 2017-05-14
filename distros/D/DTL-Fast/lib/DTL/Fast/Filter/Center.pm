package DTL::Fast::Filter::Center;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{center} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no width specified for adjusting")
        if (not scalar @{$self->{parameter}});
    $self->{width} = $self->{parameter}->[0];
    return $self;
}

#@Override
sub filter
{
    my ($self, $filter_manager, $value, $context) = @_;

    my $width = $self->{width}->render($context);

    if ($width =~ /^\d+$/)
    {
        my $adjustment = ($width - length $value);
        if ($adjustment > 0)
        {
            $value = $self->adjust($value, $adjustment);
        }
    }
    else
    {
        die $self->get_render_error("Argument must be a positive number, not '$width'");
    }
    return $value;
}

sub adjust
{
    my ($self, $value, $adjustment) = @_;
    return (' 'x int($adjustment / 2)).$value;
}

1;