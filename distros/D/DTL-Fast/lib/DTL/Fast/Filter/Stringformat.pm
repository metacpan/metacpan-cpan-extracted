package DTL::Fast::Filter::Stringformat;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{stringformat} = __PACKAGE__;

use DTL::Fast::Variable;

#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no format string specified")
        if (not scalar @{$self->{parameter}});
    $self->{format} = $self->{parameter}->[0];
    return $self;
}

#@Override
sub filter
{
    my ($self, $filter_manager, $value, $context ) = @_;

    my $format = $self->{format}->render($context);

    die $self->get_render_error($context, 'unable to format string with undef value')
        if (not defined $value);

    die $self->get_render_error($context, 'unable to format string with undef format')
        if (not defined $format);

    return sprintf '%'.$format, $value;
}

1;