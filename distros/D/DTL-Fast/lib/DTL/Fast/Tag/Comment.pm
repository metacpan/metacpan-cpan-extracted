package DTL::Fast::Tag::Comment;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag';

$DTL::Fast::TAG_HANDLERS{comment} = __PACKAGE__;

use DTL::Fast::Text;

#@Override
sub get_close_tag {return 'endcomment';}

#@Override
sub parse_next_chunk
{
    my $self = shift;
    my $chunk = shift @{$self->{raw_chunks}};
    my $chunk_lines = scalar (my @tmp = $chunk =~ /(\n)/g ) || 0;

    if ($chunk =~ /^\{\%\s*endcomment\s*\%\}$/six)
    {
        $self->{raw_chunks} = [ ]; # this stops parsing
    }

    $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines;

    return;
}

#@Override
sub render
{
    return '';
}

1;