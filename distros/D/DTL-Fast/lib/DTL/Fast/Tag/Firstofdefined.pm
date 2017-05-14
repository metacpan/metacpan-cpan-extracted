package DTL::Fast::Tag::Firstofdefined;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag::Firstof';

$DTL::Fast::TAG_HANDLERS{firstofdefined} = __PACKAGE__;

# conditional rendering
sub render
{
    my ( $self, $context, $global_safe) = @_;
    my $result = '';

    foreach my $source (@{$self->{sources}})
    {
        if (defined ($result = $source->render($context, $global_safe)))
        {
            last;
        }
    }
    return $result;
}

1;