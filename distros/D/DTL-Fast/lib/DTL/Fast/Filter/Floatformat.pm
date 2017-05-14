package DTL::Fast::Filter::Floatformat;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{floatformat} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;
    $self->{digits} = $self->{parameter}->[0]
        if (scalar @{$self->{parameter}});
    return $self;
}

#@Override
sub filter
{
    my $self = shift;  # self
    shift;  # filter_manager
    my $value = shift;
    my $context = shift;

    my $digits = defined $self->{digits} ? $self->{digits}->render($context) : undef;

    if (
        defined $digits
            and $digits =~ /^\d+$/
    )
    {
        $value = sprintf "%.0${digits}f", $value;
    }

    return $value;
}

1;