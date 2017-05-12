package App::perl2js::Converter::Node::Handle;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

sub expr { shift->{expr} }

1;
