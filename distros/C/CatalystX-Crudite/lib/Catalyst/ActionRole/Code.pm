package Catalyst::ActionRole::Code;
use Moose::Role;
use namespace::autoclean;
around 'execute' => sub {
    my $orig = shift;
    my $self = shift;
    for my $code (@{ $self->attributes->{Code} }) {
        $code->($orig, $self, @_);
    }
};
1;
