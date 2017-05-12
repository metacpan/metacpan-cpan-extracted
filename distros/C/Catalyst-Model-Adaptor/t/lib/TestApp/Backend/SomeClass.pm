package TestApp::Backend::SomeClass;
use Moose;

my $id = 0;

sub BUILD { $id++; }

has _count => ( is => 'rw', isa => 'Int', default => 0 );
sub count {
    my $self = shift;
    return $self->_count($self->_count+1);
}

sub id {
    return $id;
}

has foo => ( is => 'ro' );

1;
