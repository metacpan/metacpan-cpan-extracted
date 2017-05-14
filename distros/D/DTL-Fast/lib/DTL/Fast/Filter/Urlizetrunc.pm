package DTL::Fast::Filter::Urlizetrunc;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter::Urlize';

$DTL::Fast::FILTER_HANDLERS{urlizetrunc} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no max size specified")
        if (not scalar @{$self->{parameter}});
    $self->{maxsize} = $self->{parameter}->[0];
    return $self;
}

#@Override
sub filter
{
    my ($self, $filter_manager, $value, $context ) = @_;

    $self->{size} = $self->{maxsize}->render($context);
    return $self->SUPER::filter($filter_manager, $value, $context);
}

#@Override
sub normalize_text
{
    my ($self, $text) = @_;

    if (length $text > $self->{size})
    {
        $text = substr $text, 0, $self->{size};
        $text =~ s/\s*$/.../s;
    }

    return $text;
}

1;