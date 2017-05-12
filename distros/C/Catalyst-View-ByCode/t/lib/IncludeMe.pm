package IncludeMe;
use strict;
use warnings;

use base 'Exporter';

use Catalyst::View::ByCode::Renderer qw(:default);

# our @EXPORT = qw(includable); -- will be defined implicitly by &block directive

block includable {
    my $xxx = attr('xxx');
    
    div includable_block {
        block_content;
        span { $xxx || 'xxx unknown' };
    };
    
};

1;
