package DTL::Fast::Tag::DumpHTML;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Tag::Dump';  

$DTL::Fast::TAG_HANDLERS{'dump_html'} = __PACKAGE__;
use DTL::Fast;

#@Override
sub render
{
    my ($self, $context) = @_;

    my $result = sprintf
        '<textarea class="dtl_fast_dump_area" style="display:block;height:100px;width:100%%;">%s</textarea>'
        , DTL::Fast::html_protect($self->SUPER::render($context));
    
    return $result;
}

1;