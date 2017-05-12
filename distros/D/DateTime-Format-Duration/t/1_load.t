use Test::More tests => 2;
BEGIN { use_ok('DateTime::Format::Duration') };

$strf = DateTime::Format::Duration->new(
    normalise => 0,
    pattern => '%F %r',
);

isa_ok($strf, 'DateTime::Format::Duration');

