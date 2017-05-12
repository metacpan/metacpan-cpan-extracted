#!/usr/bin/perl

use strict;
use warnings;
use File::Temp qw(tempdir);
use Path::Class;
use Test::More tests => 10;

BEGIN { use_ok('Dackup'); }

my $source_dir      = dir( File::Temp->newdir() );
my $destination_dir = dir( File::Temp->newdir() );

$source_dir->mkpath();
$destination_dir->mkpath();

ok( -d "$source_dir",      "source_dir exists" );
ok( -d "$destination_dir", "destination_dir exists" );

my $TESTFILES = 3;

# create some test files
for ( my $i = 1; $i <= $TESTFILES; $i++ ) {
    my $file = $source_dir->file("test$i.txt");
    my $fh   = $file->openw();
    $fh->print("File to backup $i");
    $fh->close();
}

my $source = Dackup::Target::Filesystem->new( prefix => $source_dir );

my $destination
    = Dackup::Target::Filesystem->new( prefix => $destination_dir );

my $dackup = Dackup->new(
    directory   => $source_dir,    # So we can test the db being here
    source      => $source,
    destination => $destination,
    delete      => 0,
);

my $num_backedup_first = $dackup->backup;

is( $num_backedup_first, $TESTFILES,
    "We backed up the correct number of files" );

ok( -r $dackup->cache->filename(), "Cache exists in source" );

my $dest_cache
    = file( $destination_dir, $dackup->cache->filename()->basename() );

ok( !-r $dest_cache, "Cache does not exist on destination" );

# check test files
for ( my $i = 1; $i <= $TESTFILES; $i++ ) {
    my $file     = $destination_dir->file("test$i.txt");
    my $content  = $file->slurp();
    my $to_match = "File to backup $i";
    is( $content, $to_match, "Got matching content for file $i" );
}

my $num_backedup_second = $dackup->backup;

is( $num_backedup_second, 0, "We didn't need to backup anything" );

