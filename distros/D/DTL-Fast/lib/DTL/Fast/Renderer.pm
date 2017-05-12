package DTL::Fast::Renderer;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Replacer';

use DTL::Fast::Context;

sub new
{
    my( $proto, %kwargs ) = @_;

    $kwargs{'chunks'} = [];
    
    return $proto->SUPER::new(%kwargs);
}

sub add_chunk
{
    my( $self, $chunk ) = @_;
    
    push @{$self->{'chunks'}}, $chunk if defined $chunk;
    return $self;
}

sub render
{
    my( $self, $context, $global_safe ) = @_;

    $global_safe ||= $context->{'ns'}->[-1]->{'_dtl_safe'};
  
    my $result = [];
    
    foreach my $chunk (@{$self->{'chunks'}})
    {
        push @$result, $chunk->render($context, $global_safe) // '';
    }
        
    return join '', @$result;
}

1;