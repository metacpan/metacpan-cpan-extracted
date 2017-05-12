use Test::More tests => 2;

use Data::Pipeline qw(Pipeline UrlBuilder);

use Data::Pipeline::Types qw(Iterator);

my $uris = UrlBuilder(
    base => 'http://www.example.com/query',
    query => {
       foo => '1',
       bar => [ qw(1 2 3) ],
       baz => [ qw(a b) ]
    }
);

my $it = Pipeline() -> transform( $uris );

my %urls;

$urls{$it -> next}++ until $it -> finished;

is( scalar(keys %urls), 6, "Six different URLs" );

my %slru = reverse %urls;

is( scalar(keys %slru), 1, "Each one the same number of times" );
