use Bubblegum::Wrapper::Encoder;
use Test::More;

can_ok 'Bubblegum::Wrapper::Encoder', 'new';
can_ok 'Bubblegum::Wrapper::Encoder', 'data';
can_ok 'Bubblegum::Wrapper::Encoder', 'encode';
can_ok 'Bubblegum::Wrapper::Encoder', 'decode';

my $encoder = Bubblegum::Wrapper::Encoder->new(
    data => "\x{2764}"
);

# needs tests

done_testing;
