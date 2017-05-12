package DTL::Fast::Tags;
use strict; use utf8; use warnings FATAL => 'all'; 

use DTL::Fast qw(register_tag);

# built in tags
register_tag(qw(
    autoescape  DTL::Fast::Tag::Autoescape
    block       DTL::Fast::Tag::Block
    comment     DTL::Fast::Tag::Comment
    cycle       DTL::Fast::Tag::Cycle
    debug       DTL::Fast::Tag::Debug
    extends     DTL::Fast::Tag::Extends
    filter      DTL::Fast::Tag::Filter
    firstof     DTL::Fast::Tag::Firstof
    for         DTL::Fast::Tag::For
    include     DTL::Fast::Tag::Include
    if          DTL::Fast::Tag::If
    ifchanged   DTL::Fast::Tag::Ifchanged
    ifequal     DTL::Fast::Tag::Ifequal
    ifnotequal  DTL::Fast::Tag::Ifnotequal
    load        DTL::Fast::Tag::Load
    now         DTL::Fast::Tag::Now
    regroup     DTL::Fast::Tag::Regroup
    spaceless   DTL::Fast::Tag::Spaceless
    ssi         DTL::Fast::Tag::Ssi
    templatetag DTL::Fast::Tag::Templatetag
    url         DTL::Fast::Tag::Url
    verbatim    DTL::Fast::Tag::Verbatim
    widthratio  DTL::Fast::Tag::Widthratio
    with        DTL::Fast::Tag::With
));

# not from Django
register_tag(qw(
    firstofdefined  DTL::Fast::Tag::Firstofdefined
    sprintf         DTL::Fast::Tag::Sprintf
    block_super     DTL::Fast::Tag::BlockSuper
    dump            DTL::Fast::Tag::Dump
    dump_html       DTL::Fast::Tag::DumpHTML
    dump_warn       DTL::Fast::Tag::DumpWarn
));

1;
