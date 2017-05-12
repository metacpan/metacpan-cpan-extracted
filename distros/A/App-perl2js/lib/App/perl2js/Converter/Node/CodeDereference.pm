package App::perl2js::Converter::Node::CodeDereference;
use strict;
use warnings;
use parent 'App::perl2js::Converter::Node';

sub name { shift->{name} }
sub args { shift->{args} }

1;

__END__
