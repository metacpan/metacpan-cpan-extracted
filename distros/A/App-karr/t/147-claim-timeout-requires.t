use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path );

use App::karr::Role::ClaimTimeout;

# Ticket #144, the last module in the run ticket #128 started.
# App::karr::Role::DependencyCheck declared nothing it called on its consumer;
# #128 fixed that, #137 finished it when it split off
# App::karr::Role::DependencyArgs, and #141 did the same for
# App::karr::Role::TaskMutation. This role -- the third on the mutation path,
# and the one that owns karr's single claim-ownership rule -- still declared
# nothing at all, while claim_timeout_secs called one method on whoever composed
# it:
#
#   claim_timeout_secs    $self->store
#
# Nothing was broken, because every consumer composes
# App::karr::Role::BoardAccess and so brings App::karr::Role::BoardDiscovery's
# store along. That is the accident, not the guarantee: check_claim was handed
# out to anything that asked, and a consumer without store would have found out
# from inside a mutation, as a "Can't locate object method", on the one run where
# a task was actually claimed by somebody else.
#
# One name is the whole list, and the interesting part of this file is why it is
# not more -- see the third and fourth subtests.

# What the role declares, and who supplies it: store is
# App::karr::Role::BoardDiscovery's attribute, which consumers get through
# App::karr::Role::BoardAccess.
my @DECLARED = qw( store );

# Unlike App::karr::Role::TaskMutation, this role composes no role at all (the
# fourth subtest checks that, since it is what makes the list this short), so
# there is nothing handed up from a composed role the way DependencyCheck's
# find_task and quiet reach consumers of TaskMutation in
# t/142-task-mutation-requires.t. What it declares is all a consumer must have.
my @ALL = sort @DECLARED;

# A fresh package every time: Moo caches what it has applied to a class, so a
# second composition into the same name would not be the same experiment.
my $seq = 0;

sub compose_with {
    my (@supplied) = @_;
    my $pkg  = 'TimeoutStub' . ++$seq;
    my $subs = join "\n", map {"sub $_ { }"} @supplied;
    my $ok   = eval "package $pkg; use Moo; $subs;
                     with 'App::karr::Role::ClaimTimeout'; 1";
    return ( $ok, $@, $pkg );
}

subtest 'the role declares every call it makes on its consumer' => sub {
    # A requires list is only as good as its last edit, and this one went the
    # whole life of the role without existing. So read the calls out of the
    # source and hold the declaration against them, rather than trusting the
    # list above -- or the ticket, whose count for #141 was wrong.
    my $file = path( $INC{'App/karr/Role/ClaimTimeout.pm'} );
    ok $file->exists, 'found the source of the role to read' or return;

    my $src = $file->slurp_utf8;
    # POD and comments carry example code, and here that is not hypothetical:
    # the =method check_claim synopsis is `$self->check_claim( $task,
    # $self->claim )`, and claim is a command's own option, not something this
    # role ever asks a consumer for. A scan that kept the POD would demand it.
    $src =~ s/^=\w+.*?^=cut\b.*?$//msg;
    $src =~ s/^\s*#.*$//mg;

    my %called = map { $_ => 1 } $src =~ /\$self->(\w+)/g;

    ok !$called{claim}, 'the POD-only $self->claim is not read as a call';

    # Its own methods are whatever the role package can do. For
    # App::karr::Role::TaskMutation that means more than a `^sub` scan would
    # find, because composed roles install into it; here it happens to be just
    # the subs in this file, which is the fourth subtest's point.
    my %own = map { $_ => 1 }
      grep { App::karr::Role::ClaimTimeout->can($_) } keys %called;

    # Read out of the role rather than restated here, so removing the requires
    # line fails this subtest instead of only the composition ones below.
    my %declared =
      map { $_ => 1 } @{ $Role::Tiny::INFO{'App::karr::Role::ClaimTimeout'}
          {requires} || [] };

    is_deeply [ sort keys %declared ], \@ALL,
        'the role asks its consumer for exactly the expected names';

    my @undeclared = sort grep { !$own{$_} && !$declared{$_} } keys %called;

    # Empty, and it stays empty: a new $self->foo in this role is a method
    # nobody promised the consumer would have, and the fix is to require it --
    # not to add it to this test.
    is_deeply \@undeclared, [], 'no call is left undeclared'
        or diag "undeclared: @undeclared";

    # And the other direction, so the list cannot grow names the role never
    # calls.
    my @unused = sort grep { !$called{$_} } @DECLARED;
    is_deeply \@unused, [], 'and nothing is declared that the role never calls'
        or diag "unused: @unused";
};

subtest 'a consumer that supplies none of them will not compose' => sub {
    # The whole point of a requires is that it fails at composition time rather
    # than the first time a claimed task reaches check_claim. Before #144 this
    # composed cleanly:
    #
    #   $ perl -Ilib -e 'package Bare; use Moo;
    #       with "App::karr::Role::ClaimTimeout"; print "composed\n"'
    #
    # t/72-claim-timeout.t's TimeoutConsumer was exactly that class, and had to
    # be given a store stub in the same change.
    my ( $ok, $err ) = compose_with();

    ok !$ok, 'a bare consumer of ClaimTimeout refuses to compose';
    like $err, qr/\bmissing\b/, '...and says so as a missing-method error';
    like $err, qr/\b\Q$_\E\b/, "...naming $_" for @DECLARED;
};

subtest 'every declared name is load-bearing' => sub {
    # Drop one name at a time. Each has to be the difference between composing
    # and not -- which is what a declaration that cannot fail would flunk, and
    # is the guard against putting one of this role's own subs on the list.
    # Role::Tiny installs a role's methods into the consumer *before* it checks
    # the requires (role_application_steps), so requiring a name the role
    # supplies itself passes for every consumer, forever: it reads as a checked
    # promise and is not one. That is how #141's proposed list of six turned out
    # to be five.
    #
    # With one name this loop is the bare case again, which is the honest state
    # of a one-method contract rather than a reason to skip it: it is the check
    # that catches the second name, on the day someone adds one.
    for my $missing (@ALL) {
        my @supplied = grep { $_ ne $missing } @ALL;
        my ( $ok, $err ) = compose_with(@supplied);

        ok !$ok, "a consumer without ->$missing does not compose";
        like $err, qr/\b\Q$missing\E\b/, "...and the error names $missing";
    }

    my ($ok) = compose_with(@ALL);
    ok $ok, 'and the full set composes, so the list is satisfiable';
};

subtest 'the parsing and claim helpers are the role\'s own' => sub {
    # Why the list is one name and not five. Every other $self-> call in the
    # role reaches a sub defined in the role, so a consumer is never asked for
    # one -- and must not be, per the subtest above.
    my ( $ok, $err, $pkg ) = compose_with(@ALL);
    ok $ok, 'a consumer supplying only store composes' or diag $err;

    my @OWN = qw( _parse_timeout _parse_claim_stamp _claim_expired
                  claim_timeout_secs check_claim );

    ok( $pkg->can($_), "...and is handed ->$_ by the composition" ) for @OWN;

    ok( App::karr::Role::ClaimTimeout->can($_),
        "the role package itself holds ->$_" ) for @OWN;

    # And it holds them because they are written here, not because a composed
    # role installed them. This is where App::karr::Role::TaskMutation differs:
    # its check_claim and check_dependencies arrive from the two roles it
    # composes, which is why they are off its list too but for a different
    # reason. This role composes nothing, so "own" has only the one meaning --
    # and if a `with` ever appears above, the first subtest's ->can filter will
    # quietly start excusing the new role's methods, which is correct but worth
    # knowing.
    my %applied = %{ $Role::Tiny::APPLIED_TO{'App::karr::Role::ClaimTimeout'}
          || {} };
    delete $applied{'App::karr::Role::ClaimTimeout'};
    is_deeply [ sort keys %applied ], [],
        'the role composes no other role';
};

subtest 'every consumer of the role supplies it' => sub {
    # Moo reports an unmet requires when the class is compiled, so loading each
    # one is most of the test: a name added to the list that a command does not
    # have breaks `karr <cmd>` outright, not just this file. The ->can loop is
    # what says which name, instead of leaving it to a compile error.
    #
    # Pick and Unlock compose App::karr::Role::ClaimTimeout by name; the rest
    # get it through App::karr::Role::TaskMutation, and Role::Tiny hands an
    # unmet requires of a composed role up to whoever composes the composer, so
    # the requirement reaches them just the same. All of them satisfy it the
    # same way, via App::karr::Role::BoardAccess.
    for my $cmd (qw( Pick Unlock Move Edit Handoff Delete Archive )) {
        my $pkg = "App::karr::Cmd::$cmd";
        require_ok($pkg) or next;
        ok( $pkg->can($_), "$cmd supplies ->$_" ) for @ALL;
    }
};

done_testing;
