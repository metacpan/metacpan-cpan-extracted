package DTL::Fast::Filter::Filesizeformat;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'filesizeformat'} = __PACKAGE__;

use Scalar::Util qw(looks_like_number);

our @SUFFIX = (
    ['KB', 1024]
);

unshift @SUFFIX, ['MB', $SUFFIX[0]->[1] * 1024];
unshift @SUFFIX, ['GB', $SUFFIX[0]->[1] * 1024];
unshift @SUFFIX, ['TB', $SUFFIX[0]->[1] * 1024];
unshift @SUFFIX, ['PB', $SUFFIX[0]->[1] * 1024];
unshift @SUFFIX, ['EB', $SUFFIX[0]->[1] * 1024];
unshift @SUFFIX, ['ZB', $SUFFIX[0]->[1] * 1024];

#@Override
sub filter
{
    shift;  # self
    shift;  # filter_manager
    my $value = shift;  # value
    shift;  # context

    if( looks_like_number($value) )
    {
        my $str_suffix = 'B';
        
        foreach my $suffix (@SUFFIX)
        {
            if( $value > $suffix->[1] )
            {
                $str_suffix = $suffix->[0];
                $value = sprintf '%.01f', $value / $suffix->[1];
                last;
            }
        }
        $value = sprintf '%s %s', $value, $str_suffix;
    }
    
    return $value;
}

1;