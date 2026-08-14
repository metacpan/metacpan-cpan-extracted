use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path );

use App::karr::Role::TaskMutation;

# Ticket #141, the third and last module in the run #128 started.
# App::karr::Role::DependencyCheck declared nothing it called on its consumer;
# #128 fixed that and #137 finished it. The role that composes it --
# App::karr::Role::TaskMutation -- still declared nothing at all, while calling
# five methods on whoever composed it:
#
#   run_batch             $self->json
#   update_task_guarded   $self->git, $self->save_task
#   delete_task_guarded   $self->git, $self->log_task_write
#   apply_status_change   $self->store
#
# Nothing was broken, because every real command on the mutation path composes
# App::karr::Role::BoardAccess and App::karr::Role::Output and so brings all
# five along. That is the accident, not the guarantee: the next command to reach
# for update_task_guarded would have inherited a compare-and-swap loop whose
# collaborators nobody had checked for, and found out from inside the callback
# as a "Can't locate object method".
#
# The ticket proposed six names. It is five: check_claim is not the consumer's
# to supply. It comes from App::karr::Role::ClaimTimeout, which this role
# composes, exactly as check_dependencies comes from DependencyCheck -- see the
# third subtest for why declaring either would be worse than leaving it out.

# What the role declares on its own behalf, and who supplies each: git and store
# from App::karr::Role::BoardDiscovery, save_task and log_task_write from
# App::karr::Role::BoardAccess, json from App::karr::Role::Output.
my @DECLARED = qw( git json log_task_write save_task store );

# What it inherits as a requirement from the role it composes, over and above
# its own list (store and json are on both). Role::Tiny hands an unmet requires
# of a composed role up to whoever composes the composer, so a consumer of
# TaskMutation has to satisfy these too -- t/135-dependency-check-requires.t is
# where they are the subject.
my @INHERITED = qw( find_task quiet );

my @ALL = sort( @DECLARED, @INHERITED );

# A fresh package every time: Moo caches what it has applied to a class, so a
# second composition into the same name would not be the same experiment.
my $seq = 0;

sub compose_with {
    my (@supplied) = @_;
    my $pkg  = 'MutationStub' . ++$seq;
    my $subs = join "\n", map {"sub $_ { }"} @supplied;
    my $ok   = eval "package $pkg; use Moo; $subs;
                     with 'App::karr::Role::TaskMutation'; 1";
    return ( $ok, $@, $pkg );
}

subtest 'the role declares every call it makes on its consumer' => sub {
    # A requires list is only as good as its last edit, and this one went four
    # tickets without existing at all. So read the calls out of the source and
    # hold the declaration against them, rather than trusting the list.
    my $file = path( $INC{'App/karr/Role/TaskMutation.pm'} );
    ok $file->exists, 'found the source of the role to read' or return;

    my $src = $file->slurp_utf8;
    # POD and comments carry example code -- `$self->check_claim( $task,
    # $self->claim )` among them, and $self->claim is a method no consumer is
    # asked for. The declaration is about what actually executes.
    $src =~ s/^=\w+.*?^=cut\b.*?$//msg;
    $src =~ s/^\s*#.*$//mg;

    my %called = map { $_ => 1 } $src =~ /\$self->(\w+)/g;

    # Its own methods are whatever the role package can do: the subs defined in
    # it, and -- the part a `^sub` scan would miss -- the ones the composed
    # roles installed there. check_claim and check_dependencies arrive that way.
    my %own = map { $_ => 1 }
      grep { App::karr::Role::TaskMutation->can($_) } keys %called;

    # Read out of the role rather than restated here, so removing the requires
    # line fails this subtest instead of only the composition ones below. json
    # appears twice -- once from this role, once handed up by DependencyCheck --
    # which is intended and why this is a set.
    my %declared =
      map { $_ => 1 } @{ $Role::Tiny::INFO{'App::karr::Role::TaskMutation'}
          {requires} || [] };

    is_deeply [ sort keys %declared ], \@ALL,
        'the role asks its consumer for exactly the expected names';

    my @undeclared = sort grep { !$own{$_} && !$declared{$_} } keys %called;

    # Empty, and it stays empty: a new $self->foo in this role is a method
    # nobody promised the consumer would have, and the fix is to require it --
    # not to add it here.
    is_deeply \@undeclared, [], 'no call is left undeclared'
        or diag "undeclared: @undeclared";

    # And the other direction, so the list cannot grow names the role never
    # calls: everything declared is either called here or by the composed role.
    my @unused = sort grep { !$called{$_} } @DECLARED;
    is_deeply \@unused, [], 'and nothing is declared that the role never calls'
        or diag "unused: @unused";
};

subtest 'a consumer that supplies none of them will not compose' => sub {
    # The whole point of a requires is that it fails at composition time rather
    # than from inside a compare-and-swap callback on the one run where it
    # mattered. Before #141 this composed cleanly:
    #
    #   $ perl -Ilib -e 'package Bare; use Moo;
    #       with "App::karr::Role::TaskMutation"; print "composed\n"'
    my ( $ok, $err ) = compose_with();

    ok !$ok, 'a bare consumer of TaskMutation refuses to compose';
    like $err, qr/\bmissing\b/, '...and says so as a missing-method error';
    like $err, qr/\b\Q$_\E\b/, "...naming $_" for @DECLARED;
};

subtest 'every declared name is load-bearing' => sub {
    # Drop one name at a time. Each has to be the difference between composing
    # and not -- which is what a declaration that cannot fail would flunk, and
    # is the guard against putting check_claim or check_dependencies on the
    # list. Role::Tiny installs a role's methods into the consumer *before* it
    # checks the requires (role_application_steps), so requiring a name the role
    # supplies itself passes for every consumer, forever: it reads as a checked
    # promise and is not one.
    for my $missing (@ALL) {
        my @supplied = grep { $_ ne $missing } @ALL;
        my ( $ok, $err ) = compose_with(@supplied);

        ok !$ok, "a consumer without ->$missing does not compose";
        like $err, qr/\b\Q$missing\E\b/, "...and the error names $missing";
    }

    my ($ok) = compose_with(@ALL);
    ok $ok, 'and the full set composes, so the list is satisfiable';
};

subtest 'check_claim and check_dependencies are the role\'s own' => sub {
    # The two calls the ticket's list got wrong. Both come from a composed role,
    # so a consumer is never asked for them -- and must not be, per the subtest
    # above.
    my ( $ok, $err, $pkg ) = compose_with(@ALL);
    ok $ok, 'a consumer supplying neither still composes' or diag $err;

    ok( $pkg->can($_), "...and is handed ->$_ by the composition" )
        for qw( check_claim check_dependencies );

    ok( App::karr::Role::TaskMutation->can($_),
        "the role package itself holds ->$_" )
        for qw( check_claim check_dependencies );

    ok( Role::Tiny::does_role( 'App::karr::Role::TaskMutation', $_ ),
        "because it composes $_" )
        for map { "App::karr::Role::$_" } qw( ClaimTimeout DependencyCheck );
};

subtest 'every command on the mutation path supplies all of them' => sub {
    # Moo reports an unmet requires when the class is compiled, so loading each
    # one is most of the test: a name added to the list that a command does not
    # have breaks `karr <cmd>` outright, not just this file. The ->can loop is
    # what says which name, instead of leaving it to a compile error.
    for my $cmd (qw( Move Edit Handoff Delete Archive )) {
        my $pkg = "App::karr::Cmd::$cmd";
        require_ok($pkg) or next;
        ok( $pkg->can($_), "$cmd supplies ->$_" ) for @ALL;
    }
};

done_testing;
