#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use DBIx::Class::Schema::Loader qw(make_schema_at);

die unless @ARGV;

make_schema_at(
    'DBIC::Test::Schema',
    {
        components => [qw/ResultSetManager UTF8Columns InflateColumn::DateTime TimeStamp/],
        dump_directory => File::Spec->catfile($FindBin::Bin, qw/lib/),
        debug => 1,
        really_erase_my_files => 0,
    },
    \@ARGV,
);
