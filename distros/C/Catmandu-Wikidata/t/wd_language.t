use strict;
use Test::More;

use Catmandu::Fix::wd_language as => 'wd_language';

my $data = {
    labels => {
        xx => { language => "xx", value => "foo" },
        yy => { language => "yy", value => "bar" },
    },
    id => 1
};
wd_language($data, 'yy');
is_deeply $data, { label => 'bar', id => 1 }, 'wd_language';

done_testing;
