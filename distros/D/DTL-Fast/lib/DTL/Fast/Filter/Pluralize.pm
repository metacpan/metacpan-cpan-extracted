package DTL::Fast::Filter::Pluralize;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{pluralize} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;
    push @{$self->{parameter}}, DTL::Fast::Variable->new('"s"')
        if (not scalar @{$self->{parameter}});
    $self->{suffix} = $self->{parameter}->[0];
    return $self;
}

#@Override
#@todo this method should be locale-specific
sub filter
{
    my $self = shift;  # self
    shift;  # filter_manager
    my $value = shift;
    my $context = shift;

    return $self->pluralize($value, [
            split /\s*,\s*/, $self->{suffix}->render($context)
        ]);
}

sub pluralize
{
    my $self = shift;
    my $value = shift // 0;
    my $suffix = shift;

    my $suffix_one = scalar @$suffix > 1 ?
            shift @$suffix
                                         : '';

    my $suffix_more = shift @$suffix;

    if ($value != 1)
    {
        $value = $suffix_more;
    }
    else
    {
        $value = $suffix_one;
    }

    return $value;

}

1;
