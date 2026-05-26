#!/usr/bin/env perl

use v5.36;

use strict;
use warnings;
use Test2::V0;
use File::Temp qw/tempfile tempdir/;

use Concierge::Auth;

# --- new({ file => $tmpfile }) creates file, returns blessed object ---

subtest 'new with file' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $file = "$dir/auth.pwd";

    my $auth = Concierge::Auth->new({ file => $file });

    ok( defined $auth, 'constructor returns defined value' );
    isa_ok( $auth, ['Concierge::Auth'], 'object is a Concierge::Auth' );
    ok( -e $file, 'password file was created' );
};

# --- new({ no_file => 1 }) returns object without file (warns) ---

subtest 'new with no_file' => sub {
    my $auth;
    my $warnings = warnings {
        $auth = Concierge::Auth->new({ no_file => 1 });
    };

    ok( defined $auth, 'constructor returns defined value' );
    isa_ok( $auth, ['Concierge::Auth'], 'object is a Concierge::Auth' );
    ok( scalar @$warnings > 0, 'emits a warning' );
    like( $warnings->[0], qr/Utilities only/, 'warning mentions utilities only' );
};

# --- new({}) with no file or no_file still returns object (warns) ---

subtest 'new with empty args' => sub {
    my $auth;
    my $warnings = warnings {
        $auth = Concierge::Auth->new({});
    };

    ok( defined $auth, 'constructor returns defined value' );
    isa_ok( $auth, ['Concierge::Auth'], 'object is a Concierge::Auth' );
    ok( scalar @$warnings > 0, 'emits a warning' );
    like( $warnings->[0], qr/No auth file/, 'warning mentions no auth file' );
};

# --- new({ file => '/nonexistent/dir/file' }) croaks ---

subtest 'new with nonexistent directory croaks' => sub {
    my $died = dies {
        Concierge::Auth->new({ file => '/nonexistent/dir/file.pwd' });
    };

    ok( defined $died, 'constructor croaks on bad path' );
    like( $died, qr/Can't/, 'error message mentions failure' );
};

# --- new({ file => $existing_file }) opens existing file (does not truncate) ---

subtest 'new with existing file' => sub {
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = "$dir/auth.pwd";

    # Create the file and put a record in it
    open my $fh, '>', $file or die "Cannot create test file: $!";
    print $fh "alice\tsomehash\t|\n";
    close $fh;

    ok( -e $file, 'file exists before new()' );

    my $auth = Concierge::Auth->new({ file => $file });

    ok( defined $auth, 'constructor returns defined value for existing file' );
    isa_ok( $auth, ['Concierge::Auth'], 'object is a Concierge::Auth' );
    ok( -e $file, 'file still exists after new()' );

    # Existing content must not have been erased
    open my $rfh, '<', $file or die $!;
    my $contents = do { local $/; <$rfh> };
    close $rfh;
    like( $contents, qr/alice/, 'existing file content is preserved' );
};

done_testing;
