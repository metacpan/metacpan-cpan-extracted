package TestApp;
use Dancer ':syntax';

our $VERSION = '0.1';

set serializer => 'JSONPP';
get '/' => sub {
    var jsonpp_sort_by => sub { $JSON::PP::a cmp $JSON::PP::b };

    { 'a' => 1, 'b' => 2, 'aa' => 3, '1' => 4 };
};

true;
