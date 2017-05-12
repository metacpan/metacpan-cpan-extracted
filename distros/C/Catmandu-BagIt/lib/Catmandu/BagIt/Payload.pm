package Catmandu::BagIt::Payload;
use Moo;
use IO::String;

our $VERSION = '0.12';

has 'filename' => (is => 'ro');
has 'data' => (is => 'ro');
has 'flag' => (is => 'rw', default => 0);

sub is_io {
    my $self = shift;
    ref($self->data) =~ /^IO/ ? 1 : 0;
}

sub fh {
    my $self = shift;
    $self->is_io ? $self->data : IO::String->new($self->data);
}

1;

__END__