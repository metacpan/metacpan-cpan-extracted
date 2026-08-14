use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path );

use App::karr::Role::DependencyArgs;
use App::karr::Role::DependencyCheck;
use App::karr::Role::TaskMutation;

# Ticket #128. App::karr::Role::DependencyCheck called four methods it never
# declared -- store and find_task from check_dependencies, usage_error from the
# two set-time helpers, quiet from dependency_report -- and composed cleanly
# into anything at all:
#
#   $ perl -Ilib -e 'package Bare; use Moo;
#       with "App::karr::Role::DependencyCheck"; print "composed\n"'
#   composed
#
# It only worked because every consumer happened to bring the supplying roles
# along. App::karr::Role::TaskMutation composes this role, so the next command
# on the mutation path would have inherited the same four methods and found out
# at the moment a warning was due -- a "Can't locate object method" from inside
# a compare-and-swap callback, on the run where a dependency was unsatisfied and
# --json was off, rather than a composition error at compile time.
#
# The point of a `requires` is that it fails at composition, so that is what
# these tests reproduce: a consumer without the suppliers must not compose.
#
# Ticket #137 finished the job. #128 could not declare the fifth call, json,
# because one role carried two concerns: App::karr::Cmd::Create composed it for
# the two set-time helpers alone and has no --json, so requiring json refused a
# consumer that never reaches the reporting half. Splitting the set-time helpers
# out into App::karr::Role::DependencyArgs let both halves name every
# collaborator they have -- so this file no longer records an exception, it
# records that there is none.

my %REQUIRED = (

    # The reporting half: reads depends_on when a card is taken up and warns.
    # store for is_terminal_status, find_task to resolve each dependency id,
    # json and quiet to pick the channel the warning comes out of.
    'App::karr::Role::DependencyCheck' => [qw( find_task json quiet store )],

    # The set-time half: turns --depends-on & friends into validated ids.
    # usage_error to refuse the invocation, find_task to check each id exists --
    # deliberately the same lookup the reporting half resolves ids with.
    'App::karr::Role::DependencyArgs' => [qw( find_task usage_error )],
);

# A fresh package each time: Moo caches what it has applied to a class, and a
# second failed composition into the same name would not be the same experiment.
my $bare_seq = 0;

sub compose_bare {
    my ($role) = @_;
    my $pkg = 'BareConsumer' . ++$bare_seq;
    my $ok  = eval "package $pkg; use Moo; with '$role'; 1";
    return ( $ok, $@ );
}

subtest 'composing either half without its suppliers is a composition error' => sub {
    for my $role ( sort keys %REQUIRED ) {
        my ( $ok, $err ) = compose_bare($role);

        ok !$ok, "$role refuses a class that supplies none of them";
        like $err, qr/\bmissing\b/, '...and says so as a missing-method error';
        like $err, qr/\b\Q$_\E\b/, "...naming $_" for @{ $REQUIRED{$role} };
    }
};

subtest 'the requirement reaches consumers of TaskMutation' => sub {
    # This is the case the ticket is actually about: nobody writes `with
    # DependencyCheck` by hand on a new mutation command, they write `with
    # TaskMutation` and get it. Role::Tiny hands an unmet requires of a composed
    # role up to whoever composes the composer, so the error has to arrive here
    # too -- these four alongside the ones TaskMutation declares on its own
    # behalf since ticket #141, which are t/142-task-mutation-requires.t's.
    my ( $ok, $err ) = compose_bare('App::karr::Role::TaskMutation');

    ok !$ok, 'a bare consumer of TaskMutation refuses to compose too';
    like $err, qr/\b\Q$_\E\b/, "...naming $_"
        for @{ $REQUIRED{'App::karr::Role::DependencyCheck'} };

    # And only that half: since #137 the mutation path no longer drags the
    # set-time contract along, so a command that changes a status is not asked
    # for the collaborator only option parsing needs.
    unlike $err, qr/\busage_error\b/,
        'and not usage_error, which only the set-time half needs';
};

subtest 'a consumer that supplies them still gets the role' => sub {
    # The negative tests above are only worth something if the requirement is
    # satisfiable -- otherwise they would pass just as well against a role that
    # cannot be composed at all. The four this file is about, plus the three
    # TaskMutation declares on its own behalf since ticket #141 (git, save_task,
    # log_task_write); t/142-task-mutation-requires.t is where that list is the
    # subject rather than the toll.
    my $ok = eval q{
        package StubConsumer;
        use Moo;
        sub store          { }
        sub find_task      { }
        sub json           { }
        sub quiet          { }
        sub git            { }
        sub save_task      { }
        sub log_task_write { }
        with 'App::karr::Role::TaskMutation';
        1;
    };
    ok $ok, 'the stubs are enough to compose TaskMutation' or diag $@;

    ok( StubConsumer->can($_), "...and it has ->$_" )
        for qw( check_dependencies dependency_report apply_status_change
                update_task_guarded );

    # The other half is not part of that bargain any more. A mutation command
    # never parses a dependency option -- only create and edit do -- and #137 is
    # what stopped it inheriting the helpers to do so anyway.
    ok( !StubConsumer->can($_), "...and not ->$_, which is the set-time half" )
        for qw( parse_dependency_ids assert_dependencies_exist );
};

subtest 'every command that composes either role today still composes it' => sub {
    # Moo reports a missing requires when the class is compiled, so loading each
    # consumer is the whole test: a name added to the list that one of them does
    # not have breaks `karr <cmd>` outright, not just this file.
    for my $cmd (qw( Create Move Edit Handoff Pick Delete Archive )) {
        my $pkg = "App::karr::Cmd::$cmd";
        ok eval("require $pkg; 1"), "App::karr::Cmd::$cmd composes" or diag $@;
    }
};

subtest 'each half declares everything it calls, with nothing left over' => sub {
    # A requires list is only as good as its last edit: the next `$self->foo` in
    # either role would put the hole back without touching anything below. So
    # read the calls out of the source and hold the declaration against them.
    for my $role ( sort keys %REQUIRED ) {
        ( my $inc_key = "$role.pm" ) =~ s{::}{/}g;
        my $file = path( $INC{$inc_key} );
        ok $file->exists, "found the source of $role to read" or next;

        my $src = $file->slurp_utf8;
        # POD and comments carry example code -- `$self->parse_dependency_ids(
        # '--depends-on', $self->depends_on )` among them -- and prose that
        # mentions method names. The declaration is about what actually executes.
        $src =~ s/^=\w+.*?^=cut\b.*?$//msg;
        $src =~ s/^\s*#.*$//mg;

        my %called = map { $_ => 1 } $src =~ /\$self->(\w+)/g;
        my %own = map { $_ => 1 } ( $src =~ /^sub (\w+)/mg, $src =~ /^has (\w+)/mg );

        my %declared =
          map { $_ => 1 } @{ $Role::Tiny::INFO{$role}{requires} || [] };

        is_deeply [ sort keys %declared ], [ sort @{ $REQUIRED{$role} } ],
            "$role declares exactly the expected requires";

        my @undeclared = sort grep { !$own{$_} && !$declared{$_} } keys %called;

        # Empty, and it stays empty: a new call on either half is a method
        # nobody promised the role would have, and the fix is to require it --
        # not to add it here. There is no consumer left that composes half a
        # role's methods, which is what forced the one exception this list used
        # to hold (json, until #137).
        is_deeply \@undeclared, [],
            "$role leaves no call undeclared";
    }
};

subtest 'the split is what lets DependencyCheck require json' => sub {
    # App::karr::Cmd::Create is the consumer that used to keep json out of the
    # list: it composed the whole role for the two set-time helpers and never
    # reached dependency_report, so requiring json would have refused a command
    # that was using the role correctly. It now composes the set-time half only.
    require App::karr::Cmd::Create;

    ok( App::karr::Cmd::Create->can($_), "create supplies ->$_" )
        for @{ $REQUIRED{'App::karr::Role::DependencyArgs'} };

    ok( App::karr::Cmd::Create->can('parse_dependency_ids'),
        'and it has the set-time half it composes the role for' );

    # Still no --json, and that is now nobody's problem: a create cannot have a
    # dependency warning to emit -- the card does not exist until it is written
    # -- so it must not carry the emitting half at all.
    ok( !App::karr::Cmd::Create->can('json'),
        'create still has no ->json' );
    ok( !App::karr::Cmd::Create->can($_), "and no ->$_ to call without one" )
        for qw( check_dependencies dependency_report );

    # The commands that do reach the reporting half all bring json, which is
    # what makes requiring it safe rather than merely legal.
    for my $cmd (qw( Edit Move Pick Handoff Delete Archive )) {
        my $pkg = "App::karr::Cmd::$cmd";
        require_ok($pkg) or next;
        ok( $pkg->can('json'), "$cmd supplies the ->json it reports through" );
    }
};

done_testing;
