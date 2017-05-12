use Bubblegum::Wrapper::Yaml;
use Test::More;

can_ok 'Bubblegum::Wrapper::Yaml', 'new';
can_ok 'Bubblegum::Wrapper::Yaml', 'data';
can_ok 'Bubblegum::Wrapper::Yaml', 'encode';
can_ok 'Bubblegum::Wrapper::Yaml', 'decode';

my $yaml = Bubblegum::Wrapper::Yaml->new(
    data => "\x{2764}"
);

# needs tests

done_testing;
