use Bubblegum::Wrapper::Json;
use Test::More;

can_ok 'Bubblegum::Wrapper::Json', 'new';
can_ok 'Bubblegum::Wrapper::Json', 'data';
can_ok 'Bubblegum::Wrapper::Json', 'encode';
can_ok 'Bubblegum::Wrapper::Json', 'decode';

my $json = Bubblegum::Wrapper::Json->new(
    data => "\x{2764}"
);

# needs tests

done_testing;
