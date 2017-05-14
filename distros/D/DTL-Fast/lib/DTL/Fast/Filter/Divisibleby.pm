package DTL::Fast::Filter::Divisibleby;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{divisibleby} = __PACKAGE__;

use Scalar::Util qw(looks_like_number);

#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no divider specified")
        if (not scalar @{$self->{parameter}});
    $self->{divider} = $self->{parameter}->[0];
    return $self;
}

#@Override
sub filter
{
    my ($self, $filter_manager, $value, $context) = @_;

    my $divider = $self->{divider}->render($context);

    return (
            looks_like_number($value)
                and looks_like_number($divider)
                and $divider != 0
                and not $value % $divider
        ) ? 1 : 0;
}

1;