package DTL::Fast::Tag::Sprintf;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag::Simple';

$DTL::Fast::TAG_HANDLERS{sprintf} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;
    $self->{parameters} = $self->parse_sources($self->{parameter});
    return $self;
}

#@Override
sub render
{
    my ( $self, $context, $global_safe) = @_;
    my $result = '';

    my @parameters = ();

    foreach my $parameter (@{$self->{parameters}})
    {
        push @parameters, $parameter->render($context) // '';
    }

    return sprintf shift @parameters, @parameters;
}

1;