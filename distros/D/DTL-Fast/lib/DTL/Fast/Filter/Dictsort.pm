package DTL::Fast::Filter::Dictsort;
use strict; use utf8; use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'dictsort'} = __PACKAGE__;

use Scalar::Util qw(looks_like_number);
use locale;

#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no sorting key specified")
        if not scalar @{$self->{'parameter'}};
    $self->{'key'} = [split /\./, $self->{'parameter'}->[0]->render()]; # do we need to backup strings here ?
    return $self;
}

#@Override
sub filter
{
    my ($self, $filter_manager, $value, $context) = @_;

    die $self->get_render_error("dictsort works only with array of hashes")
        if ref $value ne 'ARRAY';

    return [(
        sort{
            $self->sort_function(
                $context->traverse($a, $self->{'key'}, $self)
                , $context->traverse($b, $self->{'key'}, $self)
            )
        } @$value
    )];
}

sub sort_function
{
    my ($self, $val1, $val2) = @_;
    my $result;

    if( looks_like_number($val1) and looks_like_number($val2))
    {
        $result = ($val1 <=> $val2);
    }
    elsif( UNIVERSAL::can($val1, 'compare'))
    {
        $result = $val1->compare($val2);
    }
    else
    {
        $result = ($val1 cmp $val2);
    }

    return $result;
}

1;
