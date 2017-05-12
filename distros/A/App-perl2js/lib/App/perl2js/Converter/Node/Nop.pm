package App::perl2js::Converter::Node::Nop;

use strict;
use warnings;
use parent qw(App::perl2js::Converter::Node);

use App::perl2js::Node::Nop;

sub to_js_ast {
    return App::perl2js::Node::Nop->new;
}

1;
