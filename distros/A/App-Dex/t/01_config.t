#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use App::Dex;
use File::Temp;
use Cwd;

my $tests = [
    {
        make_files  => [ qw( .dex.yaml ) ],
        constructor => {

        },
        config_file => '.dex.yaml',
        title       => 'Test defaults with .dex.yaml',
        line        => __LINE__,
    },
    {
        make_files  => [ qw( dex.yaml  ) ],
        constructor => {

        },
        config_file => 'dex.yaml',
        title       => 'Test defaults with dex.yaml',
        line        => __LINE__,
    },
    {
        make_files  => [ qw( .dex.yaml dex.yaml ) ],
        constructor => {

        },
        config_file => 'dex.yaml',
        title       => 'Tests when both files are present. Expects to use the non-hidden file.',
        line        => __LINE__,
    },
    {
        make_files  => [ qw( customfile.yaml  ) ],
        constructor => {
            config_file_names => [ qw( customfile.yaml ) ]
        },
        config_file => 'customfile.yaml',
        title       => 'Use a custom file name',
        line        => __LINE__,
    },
    {
        make_files  => [ qw( file_three ) ],
        constructor => {
            config_file_names => [ qw( file_one file_two file_three file_four ) ]
        },
        config_file => 'file_three',
        title       => 'Ensure we choose the correct file with many custom config_file_names.',
        line        => __LINE__,
    },

];

foreach my $test ( @{$tests} ) {
    my $cwd = getcwd();
    my $dir = File::Temp->newdir;
    chdir $dir->dirname;

    foreach my $filename ( @{$test->{make_files}} ) {
        BAIL_OUT "Error: File $filename is created by the test on line " . $test->{line} . " but exists already."
            if -e $filename;
        open my $sf, ">", $filename
            or die "Failed to open $filename for writing: $!";
        close $sf;
    }
    ok my $app = App::Dex->new( $test->{constructor} ), sprintf( "line %d: %s", $test->{line}, "Object Construction" );
    is $app->config_file, $test->{config_file}, sprintf( "line %d: %s", $test->{line}, $test->{title} );
    foreach my $filename ( @{$test->{make_files}} ) {
        unlink $filename;
    }

    chdir $cwd;
}

done_testing();
