use strict;
use warnings;
use utf8;
use AozoraBunko::Checkerkun;
use Test::More;
binmode Test::More->builder->$_ => ':utf8' for qw/output failure_output todo_output/;

subtest 'JIS X 0208-1983' => sub {
    ok( ! AozoraBunko::Checkerkun::_is_gaiji('鴎') );
    ok(   AozoraBunko::Checkerkun::_is_gaiji('鷗') );
};

subtest 'JIS X 0208:1990' => sub {
    ok( ! AozoraBunko::Checkerkun::_is_gaiji('熙') );
    ok( ! AozoraBunko::Checkerkun::_is_gaiji('凜') );
};

done_testing;
