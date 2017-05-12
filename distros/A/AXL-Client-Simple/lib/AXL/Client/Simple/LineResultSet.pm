package AXL::Client::Simple::LineResultSet;
use Moose;
use MooseX::Iterator;

use AXL::Client::Simple::Line;

has items => (
    is => 'ro',
    isa => 'ArrayRef[AXL::Client::Simple::Line]',
    required => 1,
);

sub BUILDARGS {
    my ($class, @rest) = @_; 
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    # promote hashes returned from CUCM into Line objects
    $params->{items} = [ map { AXL::Client::Simple::Line->new($_) }
                             @{$params->{items}} ];
    return $params;
}

sub count {
    my $self = shift;
    return scalar @{$self->items};
}

has iterator => (
    is => 'ro',
    isa => 'MooseX::Iterator::Array',
    handles => [qw/
        next
        has_next
        peek
        reset
    /],
    lazy_build => 1,
);

sub _build_iterator {
    my $self = shift;
    return MooseX::Iterator::Array->new( collection => $self->items );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
