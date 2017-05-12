package App::TailRabbit::Convertor::Null;
use Moose;

sub convert {
    my ($self, $blob) = @_;
    return $blob;
}

__PACKAGE__->meta->make_immutable;
1;

