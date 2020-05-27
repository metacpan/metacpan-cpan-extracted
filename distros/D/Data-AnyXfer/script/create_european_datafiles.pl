#!/usr/bin/env perl

use v5.16.3;
use strict;
use warnings;

use Path::Class qw/ /;

use Data::AnyXfer::Elastic::IndexInfo;
use Data::AnyXfer::Elastic::Import::DataFile;

foreach my $area (qw/ western eastern /) {

    my $info = Data::AnyXfer::Elastic::IndexInfo->new(
        generic_index_info(), alias => $area, );

    my $file = Path::Class::file("t/data/${area}.datafile");

    if ( -e $file ) {
        say 'File already exists at: ' . $file->stringify;
        exit 0;
    }

    # create datafile
    my $datafile = Data::AnyXfer::Elastic::Import::DataFile->new(
        file       => $file,
        index_info => $info,
    );

    my $method = "${area}_europe_documents";

    for ( __PACKAGE__->$method ) {

        $datafile->add_document($_)

    }

    $datafile->write;

}

sub generic_index_info {
    return (
        aliases  => { 'europe' => {}, },
        silo     => 'private_data',
        type     => 'country',
        mappings => {
            country => {
                properties => {
                    name => { type => "text" },
                    id   => { type => "integer", },
                }
            }
        },
    );
}

sub western_europe_documents {
    return (
        { id => 1, name => 'United Kingdom' },
        { id => 2, name => 'France' },
        { id => 3, name => 'Germany' },
        { id => 4, name => 'The Netherlands' },
        { id => 5, name => 'Spain' },
        { id => 6, name => 'Ireland' },
    );
}

sub eastern_europe_documents {
    return (
        { id => 1, name => 'Poland' },
        { id => 2, name => 'Slovenia' },
        { id => 3, name => 'Czech Republic' },
        { id => 4, name => 'Slovakia' },
        { id => 5, name => 'Croatia' },
        { id => 6, name => 'Moldova' },
    );
}
