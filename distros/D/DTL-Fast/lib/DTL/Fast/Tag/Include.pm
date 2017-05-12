package DTL::Fast::Tag::Include;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Tag::Simple';

$DTL::Fast::TAG_HANDLERS{'include'} = __PACKAGE__;

use DTL::Fast::Expression;

#@Override
sub new
{
    my( $proto, $parameter, %kwargs ) = @_;
    $parameter //= '';

    my @parameter = split /\s+with\s+/, $parameter;
    
    my $self = $proto->SUPER::new( $parameter[0], %kwargs );
    
    if( scalar @parameter > 1 ) # with used
    {
        $kwargs{'raw_chunks'} = [];
        require DTL::Fast::Tag::With;
        $self = DTL::Fast::Tag::With->new($parameter[1], %kwargs)->add_chunk($self);
    }
    return $self;   
}


#@Override
sub parse_parameters
{
    my $self = shift;
    $self->{'template'} = DTL::Fast::Expression->new($self->{'parameter'});
    return $self;
}

#@Override
sub render
{
    my ($self, $context) = @_;
    
    my $template_name = $self->{'template'}->render($context);
    
    my $result = DTL::Fast::get_template(
        $template_name
        , 'dirs' => $self->{'dirs'}
    );
  
    die $self->get_render_error(
        $context,
        sprintf(
            "Couldn't find included template %s in directories %s"
            , $template_name // 'undef'
            , join(', ', @{$self->{'dirs'}})
        )
    ) if not defined $result;
  
    return $result->render($context);
}

1;