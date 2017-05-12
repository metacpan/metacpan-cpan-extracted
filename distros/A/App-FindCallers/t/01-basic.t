use Test::More;
use App::FindCallers;

my @expected = (
    ['foo'   , 3],
    ['baz'   , 9],
    ['bar'   , 8],
    ['nested', 7],
);

App::FindCallers::find_in_file('dupa', 't/testfiles/simple/test.pl', sub {
        my $f = @_[1];
        my $exp = shift @expected;
        is $f->name, $exp->[0];
        is $f->line_number, $exp->[1];
});
is @expected, 0;

done_testing;
