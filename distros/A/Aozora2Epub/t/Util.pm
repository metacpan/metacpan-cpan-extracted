package t::Util;
use strict;
use warnings;
use utf8;
use Path::Tiny;
use File::ShareDir;
use Test::More;

$File::ShareDir::DIST_SHARE{'Aozora2Epub'} = path('share')->absolute;

{
    # utf8 hack from Amon2
    binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;
    no warnings 'redefine';
    my $code = \&Test::Builder::child;
    *Test::Builder::child = sub {
        my $builder = $code->(@_);
        binmode $builder->output,         ":utf8";
        binmode $builder->failure_output, ":utf8";
        binmode $builder->todo_output,    ":utf8";
        return $builder;
    };
}

1;
