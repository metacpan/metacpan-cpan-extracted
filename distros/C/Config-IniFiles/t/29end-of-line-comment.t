#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use Config::IniFiles;
use File::Spec;

use lib "./t/lib";
use Config::IniFiles::TestPaths;

use File::Temp qw(tempdir);

# Test of handle_trailing_comment enabled
{
    my $ini = Config::IniFiles->new(
        -file                    => t_file("end-of-line-comment.ini"),
        -handle_trailing_comment => 1
    );

    # TEST
    is( $ini->val( "section1", "param1" ),
        "value1",
        "Comments after ';' should be omitted when tailing comment enabled" );

    # TEST
    is( $ini->GetParameterTrailingComment( "section1", "param1" ),
        "comment1", "Test GetParameterTrailingComment()" );

    # Test write back
    my $dirname = tempdir( CLEANUP => 1 );
    my $filename =
        File::Spec->catfile( $dirname, "end-trailing-comment-writeback.ini" );

    # TEST
    ok( $ini->WriteConfig($filename), "Write trailing comments back" );

    open my $fh, '<', $filename;
    my $works = 0;
    while ( my $line = <$fh> )
    {
        $works = 1 if ( $line =~ /param1\s*=\s*value1\s*[;#]\s*comment1/ );
    }
    close $fh;

    # TEST
    ok( $works, "Test trailing comment rewrite ok." );

    # Test set()
    # TEST
    ok(
        $ini->SetParameterTrailingComment(
            "section1", "param1", "changed comment1"
        ),
        "Test SetParameterTrailingComment() returns."
    );

    # TEST
    is(
        $ini->GetParameterTrailingComment( "section1", "param1" ),
        "changed comment1",
        "Test whether SetParameterTrailingComments() works."
    );
}

# Test of handle_trailing_comment disabled
{
    my $ini = Config::IniFiles->new(
        -file                    => t_file("end-of-line-comment.ini"),
        -handle_trailing_comment => 0
    );

    # TEST
    is( $ini->val( "section1", "param1" ),
        "value1;comment1",
        "Comments after ';' should be kept when tailing comment disabled" );

    # TEST
    is( $ini->GetParameterTrailingComment( "section1", "param1" ),
        "", "Test whether SetParameterTrailingComments() works." );
}

# Test of default handle_trailing_comment
{
    # The default handle_trailing_comment param should be off
    my $ini =
        Config::IniFiles->new( -file => t_file("end-of-line-comment.ini") );

    # TEST
    is( $ini->val( "section1", "param1" ),
        "value1;comment1",
        "Test default trailing comment, which should be off." );
}

