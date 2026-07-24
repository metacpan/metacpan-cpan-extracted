#!/usr/bin/env perl

use v5.36;

use strict;
use warnings;
use Test2::V0;
use File::Temp qw/tempfile tempdir/;

use Concierge::Auth;
use Concierge::Auth::Pwd;

# --- new(backend_class => ..., file => $tmpfile) creates file, returns backend instance ---

subtest 'new with file' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $file = "$dir/auth.pwd";

    my $auth = Concierge::Auth->new( backend_class => 'Concierge::Auth::Pwd', file => $file );

    ok( defined $auth, 'constructor returns defined value' );
    isa_ok( $auth, ['Concierge::Auth::Pwd'], 'object is a Concierge::Auth::Pwd' );
    isa_ok( $auth, ['Concierge::Auth::Base'], 'object is also a Concierge::Auth::Base' );
    ok( -e $file, 'password file was created' );
};

# --- new(backend_class => ..., no_file => 1) returns object without file (warns) ---

subtest 'new with no_file' => sub {
    my $auth;
    my $warnings = warnings {
        $auth = Concierge::Auth->new( backend_class => 'Concierge::Auth::Pwd', no_file => 1 );
    };

    ok( defined $auth, 'constructor returns defined value' );
    isa_ok( $auth, ['Concierge::Auth::Pwd'], 'object is a Concierge::Auth::Pwd' );
    ok( scalar @$warnings > 0, 'emits a warning' );
    like( $warnings->[0], qr/Utilities only/, 'warning mentions utilities only' );
};

# --- new(backend_class => ...) with no file or no_file still returns object (warns) ---

subtest 'new with no other args' => sub {
    my $auth;
    my $warnings = warnings {
        $auth = Concierge::Auth->new( backend_class => 'Concierge::Auth::Pwd' );
    };

    ok( defined $auth, 'constructor returns defined value' );
    isa_ok( $auth, ['Concierge::Auth::Pwd'], 'object is a Concierge::Auth::Pwd' );
    ok( scalar @$warnings > 0, 'emits a warning' );
    like( $warnings->[0], qr/No auth file/, 'warning mentions no auth file' );
};

# --- new(backend_class => ..., file => '/nonexistent/dir/file') croaks ---

subtest 'new with nonexistent directory croaks' => sub {
    my $died = dies {
        Concierge::Auth->new( backend_class => 'Concierge::Auth::Pwd', file => '/nonexistent/dir/file.pwd' );
    };

    ok( defined $died, 'constructor croaks on bad path' );
    like( $died, qr/Can't/, 'error message mentions failure' );
};

# --- new(backend_class => ..., file => $existing_file) opens existing file (does not truncate) ---

subtest 'new with existing file' => sub {
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = "$dir/auth.pwd";

    # Create the file and put a record in it
    open my $fh, '>', $file or die "Cannot create test file: $!";
    print $fh "alice\tsomehash\t|\n";
    close $fh;

    ok( -e $file, 'file exists before new()' );

    my $auth = Concierge::Auth->new( backend_class => 'Concierge::Auth::Pwd', file => $file );

    ok( defined $auth, 'constructor returns defined value for existing file' );
    isa_ok( $auth, ['Concierge::Auth::Pwd'], 'object is a Concierge::Auth::Pwd' );
    ok( -e $file, 'file still exists after new()' );

    # Existing content must not have been erased
    open my $rfh, '<', $file or die $!;
    my $contents = do { local $/; <$rfh> };
    close $rfh;
    like( $contents, qr/alice/, 'existing file content is preserved' );
};

# --- factory-specific behavior ---

subtest 'new without backend_class croaks' => sub {
    my $died = dies {
        Concierge::Auth->new( file => '/tmp/whatever.pwd' );
    };

    ok( defined $died, 'constructor croaks without a backend_class' );
    like( $died, qr/requires a 'backend_class'/, 'error message mentions missing backend_class' );
};

subtest 'new with unloadable backend croaks' => sub {
    my $died = dies {
        Concierge::Auth->new( backend_class => 'Concierge::Auth::DoesNotExist' );
    };

    ok( defined $died, 'constructor croaks on unloadable backend' );
    like( $died, qr/Cannot load Auth backend/, 'error message names the failure' );
    like( $died, qr/Concierge::Auth::DoesNotExist/, 'error message names the backend class' );
};

subtest 'new with backend whose own new() dies' => sub {
    # Minimal in-test backend that conforms to Base's loadability but
    # fails during its own construction, to exercise the
    # "Failed to initialize backend" branch distinctly from the
    # "Cannot load" branch above. Mark it pre-loaded in %INC so the
    # factory's `require` doesn't go looking for a .pm file on disk.
    package Concierge::Auth::TestBroken {
        sub new { die "broken on purpose\n" }
    }
    $INC{'Concierge/Auth/TestBroken.pm'} = 1;

    my $died = dies {
        Concierge::Auth->new( backend_class => 'Concierge::Auth::TestBroken' );
    };

    ok( defined $died, 'constructor croaks when backend new() dies' );
    like( $died, qr/Failed to initialize backend/, 'error message mentions initialization failure' );
};

done_testing;
