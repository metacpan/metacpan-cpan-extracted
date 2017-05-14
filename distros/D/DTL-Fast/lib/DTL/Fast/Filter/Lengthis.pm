package DTL::Fast::Filter::Lengthis;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter::Length';

$DTL::Fast::FILTER_HANDLERS{length_is} = __PACKAGE__;


#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no length value specified")
        if (not scalar @{$self->{parameter}});
    $self->{length} = $self->{parameter}->[0];
    return $self;
}

#@Override
sub filter
{
    my ( $self, $filter_manager, $value, $context ) = @_;

    my $length = $self->SUPER::filter($filter_manager, $value, $context);
    return $length == $self->{length}->render($context) ?
        1
                                                        : 0;
}

1;