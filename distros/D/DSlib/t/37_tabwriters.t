#!/usr/bin/perl

# ########################################################################## #
# Title:         Build time tests of DS/Transformer/Tab*Writer.pm
# Creation date: 2007-04-16
# Author:        Michael Zedeler
# Description:   Runs tests of DS/Transformer/Tab*Writer.pm
# File:          $Source: /data/cvs/lib/DSlib/t/37_tabwriters.t,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
        $|  = 1;
        $^W = 1;
}


use DS::TypeSpec;
use DS::TypeSpec::Field;
use DS::Target::Sink;
use IO::File;

my $typespec = new DS::TypeSpec('mytype', 
    [   new DS::TypeSpec::Field( 'count' ),
        new DS::TypeSpec::Field( 'modulo_3' )]
);

use_ok( 'DS::Transformer::TabStreamWriter' );
use_ok( 'DS::Transformer::TabFileWriter' );

my $importer;
my $stream_writer;
my $fh;
my $contents;

# my( $class, $typespec, $fh, $source, $target, $field_order ) = @_;

$importer = new ImporterTest( 10 ) or diag( "Test error. Can't instantiate auxillary class ImporterTest" );
ok( $importer );
$fh = new_tmpfile IO::File();
$stream_writer = new DS::Transformer::TabStreamWriter( $fh, ['count', 'modulo_3'], $importer );
$stream_writer->attach_target( my $sink = new DS::Target::Sink );
$stream_writer->write_header();
$importer->execute();
$fh->flush();
$fh->seek(0,0);
$contents = join("", $fh->getlines());
$contents =~ s/\t/|/g;
$contents =~ s/\r//g;
is($contents, <<'EOM');
count|modulo_3
1|1
2|2
3|0
4|1
5|2
6|0
7|1
8|2
9|0
10|1
11|2
EOM

#TODO Empty file generation (first row event is eond of stream and no headers) using bot stream and file class
#TODO Overwriting existing files (should not be allowed)

my $tmpfilename = "tmp.$$";
$importer = new ImporterTest( 10 );
my $file_writer = new DS::Transformer::TabFileWriter( $tmpfilename, ['count', 'modulo_3'], $importer );
$file_writer->attach_target( new DS::Target::Sink );
$importer->execute();
$fh = new IO::File;
$fh->open($tmpfilename, "r");
$contents = join("", $fh->getlines());
$fh->close();
unlink($tmpfilename);
$contents =~ s/\t/|/g;
$contents =~ s/\r//g;
is($contents, <<'EOM');
count|modulo_3
1|1
2|2
3|0
4|1
5|2
6|0
7|1
8|2
9|0
10|1
11|2
EOM


package ImporterTest;

use base qw{ DS::Importer };

sub new {
    my( $class, $max ) = @_;
    my $typespec = new DS::TypeSpec('mytype', 
        [   new DS::TypeSpec::Field( 'count' ),
            new DS::TypeSpec::Field( 'modulo_3' )]
    );
    my $self = $class->SUPER::new( $typespec );
    $self->{counter} = 0;
    $self->{max} = $max;
    return $self;
}

sub _fetch {
    my( $self ) = @_;
    if( $self->{counter} > $self->{max} ) {
        return undef;
    } else {
        $self->{counter}++;
        return {count => $self->{counter}, modulo_3 => $self->{counter} % 3};
    }
}

1;
