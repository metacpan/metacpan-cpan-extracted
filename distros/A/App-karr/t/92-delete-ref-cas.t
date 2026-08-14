use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use App::karr::Git;
use App::karr::BoardStore;
use App::karr::Task;
use App::karr::Cmd::Delete;

# Ticket #94: no delete in karr could be guarded.
#
# App::karr::Git::delete_ref goes through libgit2's git_reference_remove(repo,
# name), which takes a name and no expected-old OID. So whatever the caller
# checked before calling it may have changed by the time the ref goes -- and the
# thing being checked is the claim guard from #56. `karr delete` re-read the
# task and re-applied the claim rule immediately before the remove, which closed
# the minutes-long window behind the confirmation prompt but not the last
# microseconds of it.
#
# The guarded form exists upstream: Git::Native::Reference->delete operates on a
# looked-up reference and libgit2 refuses it once the ref no longer matches what
# was looked up. delete_ref_cas wires it in, with the same retryable outcomes
# retry_contended already understands.

sub repo {
    my $dir = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $dir );
    system( 'git', '-C', $dir, 'config', 'user.email', 'a@karr.test' );
    system( 'git', '-C', $dir, 'config', 'user.name',  'agent-a' );
    return $dir;
}

sub task {
    my (%f) = @_;
    return App::karr::Task->new(
        id => 1, title => 'One', status => 'todo',
        priority => 'high', class => 'standard', body => '', %f,
    );
}

my $REF = 'refs/karr/tasks/1/data';

subtest 'a ref that moved since it was read is not deleted' => sub {
    my $git = App::karr::Git->new( dir => repo() );
    $git->write_ref( $REF, "as read\n" );
    my ($judged) = $git->read_ref_with_oid($REF);

    # Somebody else writes the same ref in the window.
    $git->write_ref( $REF, "claimed_by: other-agent\n" );

    is $git->delete_ref_cas( $REF, $judged ), 0,
        'the guarded delete reports that it did not land';
    ok $git->ref_exists($REF), 'and the ref is still there';
    is $git->read_ref($REF), 'claimed_by: other-agent',
        'holding the revision the deleter never judged';
};

subtest 'a ref that did not move is deleted' => sub {
    my $git = App::karr::Git->new( dir => repo() );
    $git->write_ref( $REF, "untouched\n" );
    my ($oid) = $git->read_ref_with_oid($REF);

    is $git->delete_ref_cas( $REF, $oid ), 1, 'the delete lands';
    ok !$git->ref_exists($REF), 'and the ref is gone';
};

subtest 'a ref somebody else already deleted is not a landed delete' => sub {
    my $git = App::karr::Git->new( dir => repo() );
    $git->write_ref( $REF, "gone in a moment\n" );
    my ($oid) = $git->read_ref_with_oid($REF);
    $git->delete_ref($REF);

    is $git->delete_ref_cas( $REF, $oid ), 0,
        'losing the race to another deleter is reported, not claimed as success';
};

subtest 'a lost race does not count as a write' => sub {
    my $git = App::karr::Git->new( dir => repo() );
    $git->write_ref( $REF, "one\n" );
    my ($judged) = $git->read_ref_with_oid($REF);
    $git->write_ref( $REF, "two\n" );

    # $WRITES is what App::karr::SyncGuard reads to decide whether local refs
    # still need pushing, so it may only ever count writes that landed.
    local $App::karr::Git::WRITES = 0;
    $git->delete_ref_cas( $REF, $judged );
    is $App::karr::Git::WRITES, 0, 'a refused delete leaves the counter alone';

    my ($now) = $git->read_ref_with_oid($REF);
    $git->delete_ref_cas( $REF, $now );
    is $App::karr::Git::WRITES, 1, 'a delete that landed counts once';
};

subtest 'the guard needs a revision to guard against' => sub {
    my $git = App::karr::Git->new( dir => repo() );
    $git->write_ref( $REF, "x\n" );

    my $err = do { local $@; eval { $git->delete_ref_cas( $REF, undef ); 1 } ? '' : $@ };
    like $err, qr/no expected revision/,
        'an undefined expected-old is refused rather than silently unguarded';
    ok $git->ref_exists($REF), 'and nothing was deleted';
};

subtest 'the unguarded delete_ref is still unguarded, on purpose' => sub {
    my $git = App::karr::Git->new( dir => repo() );
    $git->write_ref( $REF, "one\n" );
    $git->read_ref_with_oid($REF);
    $git->write_ref( $REF, "two\n" );

    # `karr destroy`, delete_refs and break_lock all want last-writer-wins:
    # remove whatever is there. Adding the guard to delete_ref itself would
    # break them.
    is $git->delete_ref($REF), 1, 'delete_ref removes whatever is there';
    ok !$git->ref_exists($REF), 'as it always did';
};

# --- the path the ticket is actually about ----------------------------------

subtest 'a claim landing in the delete window blocks the delete' => sub {
    my $dir   = repo();
    my $git   = App::karr::Git->new( dir => $dir );
    my $store = App::karr::BoardStore->new( git => $git );
    $git->write_ref( 'refs/karr/config', "board:\n  name: demo\n" );
    $git->save_task_ref( task() );

    my $cmd = App::karr::Cmd::Delete->new( store => $store, yes => 1 );

    # The claim lands after delete_task_guarded has read the task and applied
    # the claim rule to it, and before the ref is removed -- the microsecond
    # window the re-read could not close. read_ref_with_oid is the read; wrap it
    # so the very next thing after it is another agent's claim.
    my $original = \&App::karr::Git::read_ref_with_oid;
    my $armed    = 1;
    my @answer;
    {
        no warnings 'redefine';
        local *App::karr::Git::read_ref_with_oid = sub {
            my ( $self, $ref ) = @_;
            my @out = $original->( $self, $ref );
            if ( $armed && $ref eq $REF ) {
                $armed = 0;
                $original->( $self, $ref );   # keep the recursion honest
                my $t = $self->load_task_ref(1);
                $t->claimed_by('other-agent');
                $t->updated('2026-08-10T00:00:00Z');
                $self->save_task_ref($t);
            }
            return @out;
        };
        @answer = do { local $@;
            eval { $cmd->delete_task_guarded( 1, undef ); 'deleted' } or $@ };
    }

    like $answer[0], qr/claimed by other-agent/i,
        'the delete is refused by the claim that landed in the window'
        or diag "got: $answer[0]";
    ok $git->ref_exists($REF), 'and the task is still on the board';
};

subtest 'an ordinary guarded delete still deletes' => sub {
    my $dir   = repo();
    my $git   = App::karr::Git->new( dir => $dir );
    my $store = App::karr::BoardStore->new( git => $git );
    $git->write_ref( 'refs/karr/config', "board:\n  name: demo\n" );
    $git->save_task_ref( task() );

    my $cmd  = App::karr::Cmd::Delete->new( store => $store, yes => 1 );
    my $gone = $cmd->delete_task_guarded( 1, undef );

    is $gone->id, 1, 'the deleted task is handed back';
    ok !$git->ref_exists($REF), 'and its ref is gone';
};

subtest 'a task another agent deleted first is reported as not found' => sub {
    my $dir   = repo();
    my $git   = App::karr::Git->new( dir => $dir );
    my $store = App::karr::BoardStore->new( git => $git );
    $git->write_ref( 'refs/karr/config', "board:\n  name: demo\n" );

    my $cmd = App::karr::Cmd::Delete->new( store => $store, yes => 1 );
    my $err = do { local $@;
        eval { $cmd->delete_task_guarded( 1, undef ); 1 } ? '' : $@ };
    like $err, qr/Task 1 not found/,
        'the retry loop does not spin on a task that is simply gone';
};

subtest 'a guarded delete is still recorded in the activity log' => sub {
    my $dir   = repo();
    my $git   = App::karr::Git->new( dir => $dir );
    my $store = App::karr::BoardStore->new( git => $git );
    $git->write_ref( 'refs/karr/config', "board:\n  name: demo\n" );
    $git->save_task_ref( task() );

    my $cmd = App::karr::Cmd::Delete->new( store => $store, yes => 1 );
    $cmd->delete_task_guarded( 1, undef );

    my @entries = grep { ( $_->{task_id} // 0 ) == 1 } $cmd->activity_log->entries;
    is scalar @entries, 1, 'one entry for the deleted task';
    is $entries[0]{action}, 'delete',
        'writing the ref directly did not lose the log entry (#64)';
};

done_testing;
