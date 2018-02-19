#!/usr/bin/perl

use strict;
use warnings;

use Path::Class 'file';

BEGIN {
    my $root = file(__FILE__)->dir->parent;
    unshift( @INC, $root->subdir('lib')->stringify, $root->subdir(qw<t lib>)->stringify );
};

use DBIx::BatchChunker;
use CDTest;

############################################################

my $schema   = CDTest->init_schema;
my $track_rs = $schema->resultset('Track');

my $batch_chunker = DBIx::BatchChunker->construct_and_execute(
    chunk_size  => 3,
    target_time => 5,
    sleep       => 1,

    rs          => $track_rs,
    coderef     => sub { $_[1]->delete },

    progress_name => 'Deleting tracks',
    debug => 1,
);

print "No more tracks!\n";

