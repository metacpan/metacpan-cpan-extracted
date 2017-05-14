package DTL::Fast::Tag::Firstof;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag::Simple';

$DTL::Fast::TAG_HANDLERS{firstof} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;
    $self->{sources} = $self->parse_sources($self->{parameter});
    return $self;
}

#@Override
sub render
{
    my ( $self, $context, $global_safe) = @_;
    my $result = '';

    foreach my $source (@{$self->{sources}})
    {
        if ($result = $source->render($context, $global_safe))
        {
            last;
        }
    }
    return $result;
}

1;