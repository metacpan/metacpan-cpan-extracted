use strict;
use warnings;
use utf8;
use AozoraBunko::Checkerkun;
use Test::More;
binmode Test::More->builder->$_ => ':utf8' for qw/output failure_output todo_output/;

my @codepoint_list = (
      hex('0000') .. hex('0009')
    , hex('000B') .. hex('000C')
    , hex('000E') .. hex('001F')
    , hex('007F') .. hex('009F')
);

subtest 'check gaiji' => sub {
    plan skip_all => 'control chars are allowd since they are marked as "ctrl"';

    for my $codepoint (@codepoint_list)
    {
        my $char = chr $codepoint;
        ok( AozoraBunko::Checkerkun::_is_gaiji($char), sprintf("U+%04X", ord $char) );
    }
};

done_testing;
