#!/usr/bin/env perl
use v5.16.3;
use strict;
use warnings;

use Path::Class qw/ file /;

use Data::AnyXfer::Elastic::Import::DataFile;

use lib 't/lib';
use Employee::IndexInfo;

my $file = file('t/data/employees.datafile');

if ( -e $file ) {
    say 'File already exists at: ' . $file->stringify;
    exit;
}

my $index_info = Employee::IndexInfo->new;

# create datafile
my $datafile = Data::AnyXfer::Elastic::Import::DataFile->new(
    file       => $file,
    index_info => $index_info,
);

# add documents
for ( $index_info->sample_documents ) {

    $datafile->add_document($_);

}

# write to disk
$datafile->write;
