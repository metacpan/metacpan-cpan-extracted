package DTL::Fast::Tag::DumpWarn;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag::Dump';

use DTL::Fast::Template;
$DTL::Fast::TAG_HANDLERS{dump_warn} = __PACKAGE__;

sub render
{
    my ( $self, $context ) = @_;

    warn $self->SUPER::render($context);
}

1;
