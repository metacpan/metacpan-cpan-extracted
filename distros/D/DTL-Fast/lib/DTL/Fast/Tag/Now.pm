package DTL::Fast::Tag::Now;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Tag::Simple';  

$DTL::Fast::TAG_HANDLERS{'now'} = __PACKAGE__;

use DTL::Fast::Utils;
use DTL::Fast::Variable;

#@Override
sub parse_parameters
{
    my $self = shift;
    
    if(
        $self->{'parameter'} =~ /^
            \s*
            (.+?)
            (?:\s+as\s+(.+)\s*)?
        $/xsi
    )
    {
        @{$self}{'format', 'target_variable'} = (
            DTL::Fast::Variable->new( $1 ) 
            , $2
        );
    }
    else
    {
        die $self->get_parse_error("no time format specified") unless $self->{'parameter'};
    }
    
    return $self;
}

#@Override
sub render
{
    my ($self, $context) = @_;

    my $result = DTL::Fast::Utils::time2str_php( $self->{'format'}->render($context), time);

    if ( $self->{'target_variable'} ) {
        $context->set(
            $self->{'target_variable'} => $result
        );
        $result = '';
    }
    
    return $result;
}


1;
