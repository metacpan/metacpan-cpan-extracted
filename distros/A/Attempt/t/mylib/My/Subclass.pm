package My::Subclass;
use base qw(My::Package);
use Test::Exception;
use Sub::Attempts;

attempts("foo", method => 1);

1;

