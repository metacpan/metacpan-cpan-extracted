package DTL::Fast::Expression::Operator::Binary::Plus;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Expression::Operator::Binary';

$DTL::Fast::OPS_HANDLERS{'+'} = __PACKAGE__;

use Scalar::Util qw(looks_like_number);

sub dispatch
{
    my ( $self, $arg1, $arg2, $context) = @_;
    my ($arg1_type, $arg2_type) = (ref $arg1, ref $arg2);

    if (looks_like_number($arg1) and looks_like_number($arg2))
    {
        return $arg1 + $arg2;
    }
    elsif ($arg1_type eq 'ARRAY')
    {
        if ($arg2_type eq 'ARRAY')
        {
            return [ @$arg1, @$arg2 ];
        }
        elsif ($arg2_type eq 'HASH')
        {
            return [ @$arg1, %$arg2 ];
        }
        elsif (UNIVERSAL::can($arg2, 'as_array'))
        {
            return [ @$arg1, @{$arg2->as_array($context)} ];
        }
        else
        {
            return [ @$arg1, $arg2 ];
        }
    }
    elsif ($arg1_type eq 'HASH')
    {
        if ($arg2_type eq 'ARRAY')
        {
            return { %$arg1, @$arg2 };
        }
        elsif ($arg2_type eq 'HASH')
        {
            return { %$arg1, %$arg2 };
        }
        elsif (UNIVERSAL::can($arg2, 'as_hash'))
        {
            return { %$arg1, %{$arg2->as_hash($context)} };
        }
        else
        {
            die $self->get_render_error(
                    $context,
                    sprintf("don't know how to add %s (%s) to a HASH"
                        , $arg2 // 'undef'
                        , $arg2_type || 'SCALAR'
                    )
                );
        }
    }
    elsif (UNIVERSAL::can($arg1, 'plus'))
    {
        return $arg1->plus($arg2, $context);
    }
    elsif (
        defined $arg1
            and defined $arg2
    )
    {
        return $arg1.$arg2;
    }
    else
    {
        die $self->get_render_error(
                $context,
                sprintf("don't know how to add %s (%s) to %s (%s)"
                    , $arg1 // 'undef'
                    , $arg1_type || 'SCALAR'
                    , $arg2 // 'undef'
                    , $arg2_type || 'SCALAR'
                )
            );
    }
}

1;
