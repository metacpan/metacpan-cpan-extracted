use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Encode qw( decode );
use YAML::XS qw( Dump );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::ActivityLog;
use App::karr::Cmd::Pick;

# Regression for karr board ticket #75:
#   ActivityLog sanitized the git email into a ref name with
#   s/[^a-zA-Z0-9._-]/_/g, which is not the grammar git-check-ref-format
#   actually enforces. An ordinary address produced a name libgit2 refuses:
#
#     git config user.email 'a..b@example.com'
#     karr pick --claim x
#       -> the given reference name 'refs/karr/log/user/a..b_example.com'
#          is not valid                                            rc=1
#
#   ...and it died *after* the claim had been written, leaving the task
#   claimed and its lock ref behind. The same mapping also collapsed four
#   distinct addresses (a b@x, a-b@x, a+b@x, a/b@x) onto one log ref, and
#   turned every non-ASCII byte into '_'.
#
#   The identity is now percent-encoded: legal by construction, injective,
#   and reversible via decode_identity.

sub _init_repo {
    my ($email) = @_;
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo );
    system( 'git', '-C', $repo, 'config', 'user.email', $email );
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
    return $repo;
}

sub _run_execute {
    my ( $cmd, @args ) = @_;
    my $out;
    my $err = do {
        local $@;
        eval {
            local *STDOUT;
            open STDOUT, '>', \$out or die $!;
            $cmd->execute( \@args, [] );
        };
        $@;
    };
    return ( $err, $out );
}

sub _log_for {
    my ( $email, %args ) = @_;
    my $log = App::karr::ActivityLog->new( git => undef, %args );
    no warnings 'redefine';
    local *App::karr::ActivityLog::_email = sub { $email };
    return $log->identity;
}

subtest 'addresses git ref names cannot hold are encoded, not mangled' => sub {
    for my $email (
        'a..b@example.com',      # '..' is illegal anywhere in a ref name
        'ab@example.lock',       # a component may not end in '.lock'
        '.leading@example.com',  # a component may not start with '.'
        'trailing.@example.com', # ...nor end with '.'
        'sp ace@example.com',
        'q?uestion@example.com',
        'star*@example.com',
        'tilde~caret^@example.com',
        'colon:@example.com',
        'brack[et@example.com',
        'back\\slash@example.com',
        'at@{brace@example.com',
        '@',
        )
    {
        my $id = _log_for($email);
        ok( Git::Native->reference_name_is_valid("refs/karr/log/$id"),
            "'$email' -> refs/karr/log/$id is a valid ref name" );
        my ( $role, $decoded ) = App::karr::ActivityLog->decode_identity($id);
        is( $decoded, $email, "'$email' round-trips out of the ref name" );
        is( $role, 'user', "'$email' keeps its role component" );
    }
};

subtest 'distinct addresses never share one log ref' => sub {
    my @colliding = ( 'a b@x.com', 'a-b@x.com', 'a+b@x.com', 'a/b@x.com', 'a_b@x.com' );
    my %seen;
    $seen{ _log_for($_) }++ for @colliding;
    is( scalar keys %seen, scalar @colliding,
        'five addresses that used to sanitize to a_b_x.com get five refs' );
};

subtest 'a non-ASCII address survives as UTF-8, not as mojibake' => sub {
    my $octets = "j\xc3\xbcrgen\@example.com";       # what libgit2 hands back
    my $chars  = decode( 'UTF-8', $octets );

    my $from_octets = _log_for($octets);
    my $from_chars  = _log_for($chars);

    is( $from_chars, $from_octets,
        'characters and octets encode to the same ref name' );
    is( $from_octets, 'user/j%C3%BCrgen%40example.com',
        'the UTF-8 octets are percent-encoded, not replaced by _' );
    ok( Git::Native->reference_name_is_valid("refs/karr/log/$from_octets"),
        'and the name is legal' );

    my ( undef, $decoded ) = App::karr::ActivityLog->decode_identity($from_octets);
    is( $decoded, $chars, 'decodes back to the original characters' );
};

subtest 'the role component is encoded too' => sub {
    my $id = _log_for( 'dev@example.com', role => 'weird/role..name' );
    ok( Git::Native->reference_name_is_valid("refs/karr/log/$id"),
        "role 'weird/role..name' still yields a valid ref name" );
    my ($role) = App::karr::ActivityLog->decode_identity($id);
    is( $role, 'weird/role..name', 'role round-trips' );
};

subtest 'pick with an invalid-under-the-old-scheme email completes' => sub {
    my $repo = _init_repo('a..b@example.com');
    my $git  = App::karr::Git->new( dir => $repo );
    $git->write_ref( 'refs/karr/config', Dump( { version => 1, board => { name => 'T' } } ) );
    $git->write_ref( 'refs/karr/meta/next-id', "2\n" );
    my $store = App::karr::BoardStore->new( git => $git );
    $store->save_task(
        App::karr::Task->new(
            id       => 1,
            title    => 'Task 1',
            status   => 'todo',
            priority => 'high',
            class    => 'standard',
        )
    );

    my $cmd = App::karr::Cmd::Pick->new( store => $store, claim => 'agent-test' );
    my ( $err, $out ) = _run_execute($cmd);

    is( $err, '', 'pick does not die on the log write' ) or diag("died with: $err");
    like( $out, qr/Picked task 1/, 'the pick was reported' );
    ok( !$git->ref_exists('refs/karr/tasks/1/lock'),
        'the task lock was released rather than left behind' );

    my @entries = App::karr::ActivityLog->new( git => $git )->entries;
    ok( ( grep { ( $_->{action} // '' ) eq 'pick' } @entries ),
        'the pick reached the activity log' );
};

subtest 'refs written under the old naming schemes are still read' => sub {
    my $repo = _init_repo('dev@example.com');
    my $git  = App::karr::Git->new( dir => $repo );

    # Pre-role scheme: bare sanitized email.
    $git->write_ref( 'refs/karr/log/dev_example.com',
        '{"ts":"2026-01-01T00:00:00Z","agent":"old","action":"move","task_id":1}' );
    # Role-qualified scheme with the pre-#75 sanitizer.
    $git->write_ref( 'refs/karr/log/user/dev_example.com',
        '{"ts":"2026-02-01T00:00:00Z","agent":"older","action":"edit","task_id":2}' );

    my $log = App::karr::ActivityLog->new( git => $git );
    $log->log_entry( agent => 'now', action => 'create', task_id => 3,
        ts => '2026-03-01T00:00:00Z' );

    ok( $git->ref_exists('refs/karr/log/user/dev%40example.com'),
        'the new entry went to the percent-encoded ref' );

    my @entries = $log->entries;
    is_deeply( [ map { $_->{task_id} } @entries ], [ 1, 2, 3 ],
        'both legacy refs are merged in ahead of the current one' );

    # ...and nothing is counted twice when a legacy name equals the new one.
    my @again = $log->entries;
    is( scalar @again, 3, 'reading again yields the same three entries' );
};

subtest 'an unwritable log warns instead of killing its caller' => sub {
    my $repo = _init_repo('dev@example.com');
    my $git  = App::karr::Git->new( dir => $repo );
    my $log  = App::karr::ActivityLog->new( git => $git );

    no warnings 'redefine';
    local *App::karr::ActivityLog::_ref = sub { 'refs/karr/log/user/bad..name' };

    my $warning = '';
    my $rc;
    {
        local $SIG{__WARN__} = sub { $warning .= $_[0] };
        $rc = eval { $log->log_entry( action => 'move', task_id => 1 ); 1 };
    }
    ok( $rc, 'log_entry returned rather than died' ) or diag("died with: $@");
    like( $warning, qr/not a valid git ref name/, 'and said so on stderr' );
    ok( !$git->ref_exists('refs/karr/log/user/bad..name'), 'nothing was written' );
};

done_testing;
