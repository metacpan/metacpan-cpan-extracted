use Test::Most tests => 2;

BEGIN {
    use_ok 'DateTime::Format::Czech';
    isa_ok DateTime::Format::Czech->new, 'DateTime::Format::Czech';
}
