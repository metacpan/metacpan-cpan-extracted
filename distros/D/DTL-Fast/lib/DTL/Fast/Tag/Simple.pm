package DTL::Fast::Tag::Simple;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag';

sub new
{
    my ( $proto, $parameter, %kwargs ) = @_;
    $kwargs{raw_chunks} = [ ]; # no chunks parsing
    return $proto->SUPER::new($parameter, %kwargs);
}

1;
