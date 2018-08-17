#!/usr/bin/perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Require::AuthorTesting;
use Test::CPAN::Changes;

use Module::Metadata;

my $info = Module::Metadata->new_from_file("lib/DBIx/BatchChunker.pm");
changes_file_ok( 'CHANGES', { version => $info->version->stringify } );

done_testing;
