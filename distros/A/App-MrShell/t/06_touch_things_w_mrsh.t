
use strict;
use warnings;
use Test;
use App::MrShell;

plan tests => 3;

my $res = eval {
    system($^X,
        "blib/script/mrsh",
        "-s" => qq|$^X "-e" '\$"="."; open TOUCH, ">test_file.\@ARGV"' '\%h' '\%n'|,
        "-l" => "05_touch.log", '--trunc',
        "-H" => 'a',
        "-H" => 'b',
        'c3'
    )
    == 0
};

ok( $res );
ok( -f "test_file.a.1.c3" );
ok( -f "test_file.b.1.c3" );
