package DTL::Fast::Filter::Timesince;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'timesince'} = __PACKAGE__;

our $MAXSTEPS = 2;

our @LAPSE = (
    ['minute', 60]
);

unshift @LAPSE, ['hour', $LAPSE[0]->[1] * 60];
unshift @LAPSE, ['day', $LAPSE[0]->[1] * 24];
unshift @LAPSE, ['week', $LAPSE[0]->[1] * 7];
unshift @LAPSE, ['month', $LAPSE[1]->[1] * 30];
unshift @LAPSE, ['year', $LAPSE[2]->[1] * 365];


#@Override
#@todo make pre-defined formats from Django
sub parse_parameters
{
    my $self = shift;
    push @{$self->{'parameter'}}, DTL::Fast::Variable->new(time)
        if not scalar @{$self->{'parameter'}};
    $self->{'time'} = $self->{'parameter'}->[0];
    $self->{'suffix'} = DTL::Fast::Variable->new('s');    # this is pluralize related
    
    return $self;
}

#@Override
sub filter
{
    my $self = shift;  # self
    shift;  # filter_manager
    my $value = shift;
    my $context = shift;
    
    my $time = $self->{'time'}->render($context);
    
    return $self->time_diff($time - $value);
}

sub time_diff
{
    my $self = shift;
    my $diff = shift;
    my @diffs = ();
    
    if( $diff )
    {
        foreach my $lapse (@LAPSE)
        {
            if( $diff >= $lapse->[1] )
            {
                my $val = int( $diff / $lapse->[1]);
                $diff = $diff % $lapse->[1];
                push @diffs, sprintf( '%d %s%s'
                    , $val // 'undef'
                    , $lapse->[0] // 'undef'
                    , ($DTL::Fast::FILTER_HANDLERS{'pluralize'} // require DTL::Fast::Filter::Pluralize && 'DTL::Fast::Filter::Pluralize')->pluralize($val, ['s'])
                );
                
                if( scalar @diffs == $MAXSTEPS )
                {
                    last;
                }
            }
        }
    }

    return join ', ', @diffs;
}

1;