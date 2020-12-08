#!/usr/bin/perl

use strict;
use warnings;

use Mojo::File qw(curfile);
use Mojo::JSON qw(encode_json);
use Data::Printer;
use CPANfile::Parse::PPI;

my @data;
my $files = curfile->dirname->child(qw(.. t data))->list;
$files->each( sub {
    my $parser = CPANfile::Parse::PPI->new( $_->to_string );
    push @data, {
        file    => $_->basename,
        results => $parser->modules,
    };
});

print( encode_json \@data );
