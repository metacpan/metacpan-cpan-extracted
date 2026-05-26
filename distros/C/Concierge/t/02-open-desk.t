#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use Test2::V0;
use File::Temp qw(tempdir);

use Concierge::Desk::Setup;
use Concierge;

# Create temporary desk for testing
my $test_dir = tempdir(CLEANUP => 1);

# Build desk first
my $build = Concierge::Desk::Setup::build_quick_desk(
    $test_dir,
    ['field1'],
);
ok $build->{success}, 'desk built for testing';

subtest 'open_desk basic functionality' => sub {
    my $result = Concierge->open_desk($test_dir);

    ok $result->{success}, 'open_desk succeeds';
    isa_ok $result->{concierge}, ['Concierge'], 'returns Concierge object';
    is $result->{concierge}{desk_location}, $test_dir, 'desk_location set correctly';
};

subtest 'open_desk initializes components' => sub {
    my $result = Concierge->open_desk($test_dir);
    my $concierge = $result->{concierge};

    isa_ok $concierge->auth, ['Concierge::Auth'], 'auth component initialized';
    isa_ok $concierge->sessions, ['Concierge::Sessions'], 'sessions component initialized';
    isa_ok $concierge->users, ['Concierge::Users'], 'users component initialized';
};

subtest 'open_desk initializes user_keys mapping' => sub {
    my $result = Concierge->open_desk($test_dir);
    my $concierge = $result->{concierge};

    ref_ok $concierge->{user_keys}, 'HASH', 'user_keys is a hashref';
};

subtest 'open_desk fails for nonexistent directory' => sub {
    my $fake_dir = '/nonexistent/directory/path';

    like dies { Concierge->open_desk($fake_dir) },
        qr/./,
        'croaks for nonexistent directory';
};

subtest 'open_desk fails with invalid JSON config' => sub {
    use File::Spec;
    my $bad_dir = tempdir(CLEANUP => 1);
    Concierge::Desk::Setup::build_quick_desk($bad_dir);

    # Overwrite concierge.conf with invalid JSON
    my $conf_file = File::Spec->catfile($bad_dir, 'concierge.conf');
    open my $fh, '>', $conf_file or die "Cannot write: $!";
    print $fh 'this is not valid json {{{';
    close $fh;

    my $result = Concierge->open_desk($bad_dir);
    ok !$result->{success}, 'open_desk fails with invalid JSON';
    like $result->{message}, qr/invalid json/i, 'error mentions invalid JSON';
};

subtest 'open_desk runs cleanup_sessions' => sub {
    # Create desk and add expired session manually (if needed)
    my $temp_dir = tempdir(CLEANUP => 1);

    Concierge::Desk::Setup::build_quick_desk($temp_dir);

    # Open desk - should run cleanup_sessions
    my $result = Concierge->open_desk($temp_dir);

    ok $result->{success}, 'open_desk with cleanup succeeds';
    # Cleanup runs without error (more detailed test in 06-cleanup-sync.t)
};

done_testing;
