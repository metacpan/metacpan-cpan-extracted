package DTL::Fast::Tag::BlockSuper;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag::Simple';

$DTL::Fast::TAG_HANDLERS{block_super} = __PACKAGE__;

#@Override
sub render
{
    my ( $self, $context ) = @_;
    my $result = '';

    my $ns = $context->{ns}->[- 1];

    if (# there is an inheritance and we are in block
        my $descendants = $ns->{_dtl_descendants}
            and exists $ns->{_dtl_rendering_block}
    )
    {
        my $current_template = $ns->{_dtl_rendering_template};
        my $current_block_name = $ns->{_dtl_rendering_block}->{block_name};

        for (my $i = 0; $i < scalar @$descendants; $i++)
        {
            if ($descendants->[$i] == $current_template) # found self
            {
                for (my $j = $i + 1; $j < scalar @$descendants; $j++)
                {
                    if ($descendants->[$j]->{blocks}->{$current_block_name}) # found parent block
                    {
                        $context->push_scope();
                        $ns->{_dtl_rendering_template} = $descendants->[$j];
                        $ns->{_dtl_rendering_block} = $descendants->[$j]->{blocks}->{$current_block_name};

                        $result = $descendants->[$j]->{blocks}->{$current_block_name}->SUPER::render($context);

                        $context->pop_scope();
                        last;
                    }

                }
                last;
            }

        }
    }

    return $result;
}

1;