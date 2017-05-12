package DTL::Fast::Tag::Verbatim;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Tag';  
$DTL::Fast::TAG_HANDLERS{'verbatim'} = __PACKAGE__;

use DTL::Fast::Text;

#@Override
sub get_close_tag{return 'endverbatim';}

#@Override
sub parse_parameters
{
    my $self = shift;
    $self->{'contents'} = DTL::Fast::Text->new();
    $self->{'last_tag'} = $self->{'parameter'} ?
        qr/\Qendverbatim\E\s+\Q$self->{'parameter'}\E/
        : 'endverbatim';
    return $self;
}

#@Override
sub parse_next_chunk
{
    my $self = shift;
    my $chunk = shift @{$self->{'raw_chunks'}};
    my $chunk_lines = scalar (my @tmp = $chunk =~ /(\n)/g ) || 0;
    
    if( $chunk =~ /^\{\%\s*$self->{'last_tag'}\s*\%\}$/six )
    {
        $self->{'raw_chunks'} = []; # this stops parsing
    }
    else
    {
        $self->{'contents'}->append($chunk);
    }

    $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines;
    
    return;
}

#@Override
sub render
{
    return shift->{'contents'}->render(shift);
}

1;