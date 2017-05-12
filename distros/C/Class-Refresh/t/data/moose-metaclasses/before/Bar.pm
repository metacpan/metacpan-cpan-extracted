package Bar;
use Moose;

$::reloaded{bar}++;


__PACKAGE__->meta->make_immutable;
no Moose;

1;
