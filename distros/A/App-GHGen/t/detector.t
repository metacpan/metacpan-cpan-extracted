#!/usr/bin/env perl

use v5.36;
use Test::More;
use Path::Tiny;
use File::Temp qw(tempdir);

use_ok('App::GHGen::Detector', qw(detect_project_type get_project_indicators));

# Test get_project_indicators
{
    my $indicators = get_project_indicators('perl');
    ok(ref $indicators eq 'ARRAY', 'Returns array for perl indicators');
    ok(grep(/cpanfile/, @$indicators), 'Perl indicators include cpanfile');
    
    my $all_indicators = get_project_indicators();
    ok(ref $all_indicators eq 'HASH', 'Returns hash for all indicators');
    ok(exists $all_indicators->{perl}, 'All indicators include perl');
    ok(exists $all_indicators->{node}, 'All indicators include node');
}

# Test detection in a temporary directory
{
    my $tmpdir = Path::Tiny->tempdir;
    my $orig = Path::Tiny->cwd;
    
    chdir $tmpdir;
    
    # Test Perl detection
    {
        $tmpdir->child('cpanfile')->touch;
        $tmpdir->child('lib')->mkpath;
        
        my $type = detect_project_type();
        is($type, 'perl', 'Detects Perl project with cpanfile');
        
        # Clean up
        $tmpdir->child('cpanfile')->remove;
        $tmpdir->child('lib')->remove_tree;
    }
    
    # Test Node detection
    {
        $tmpdir->child('package.json')->spew_utf8('{}');
        
        my $type = detect_project_type();
        is($type, 'node', 'Detects Node.js project with package.json');
        
        # Clean up
        $tmpdir->child('package.json')->remove;
    }
    
    # Test Python detection
    {
        $tmpdir->child('requirements.txt')->touch;
        $tmpdir->child('setup.py')->touch;
        
        my $type = detect_project_type();
        is($type, 'python', 'Detects Python project with requirements.txt');
        
        # Clean up
        $tmpdir->child('requirements.txt')->remove;
        $tmpdir->child('setup.py')->remove;
    }
    
    # Test Rust detection
    {
        $tmpdir->child('Cargo.toml')->touch;
        
        my $type = detect_project_type();
        is($type, 'rust', 'Detects Rust project with Cargo.toml');
        
        # Clean up
        $tmpdir->child('Cargo.toml')->remove;
    }
    
    # Test Go detection
    {
        $tmpdir->child('go.mod')->touch;
        
        my $type = detect_project_type();
        is($type, 'go', 'Detects Go project with go.mod');
        
        # Clean up
        $tmpdir->child('go.mod')->remove;
    }
    
    # Test no detection
    {
        my $type = detect_project_type();
        ok(!defined $type, 'Returns undef when no project detected');
    }
    
    # Test multiple detections (returns highest score)
    {
        $tmpdir->child('package.json')->spew_utf8('{}');
        $tmpdir->child('Dockerfile')->touch;
        
        my @detections = detect_project_type();
        ok(@detections > 1, 'Detects multiple project types');
        is($detections[0]->{type}, 'node', 'Returns highest scored type first');
        
        # Clean up
        $tmpdir->child('package.json')->remove;
        $tmpdir->child('Dockerfile')->remove;
    }
    
    chdir $orig;
}

done_testing();
