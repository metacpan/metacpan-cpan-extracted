use strict;
use warnings;
use Test::More;

use App::karr::Role::DependencyArgs;
use App::karr::Role::DependencyCheck;
use App::karr::Role::TaskMutation;

# Ticket #137. One role carried two concerns with two different contracts:
#
#   set-time     parse_dependency_ids, assert_dependencies_exist
#                turn --depends-on & friends into ids, refuse the invocation
#                consumers: create, edit
#
#   report-time  check_dependencies, dependency_report
#                read depends_on when a card is taken up, warn, proceed
#                consumers: TaskMutation (move/edit/delete/archive/handoff),
#                           pick
#
# The cost was concrete, not aesthetic. App::karr::Cmd::Create composed the
# whole role for the set-time half and has no --json, so the reporting half's
# call to $self->json could not go on the requires line #128 added:
#
#   $ perl -Ilib -e 'use App::karr::Role::DependencyCheck;
#       push @{ $Role::Tiny::INFO{"App::karr::Role::DependencyCheck"}{requires} },
#         "json";
#       require App::karr::Cmd::Create'
#   Can't apply App::karr::Role::DependencyCheck to App::karr::Cmd::Create
#     - missing json at lib/App/karr/Cmd/Create.pm line 15.
#
# And create inherited check_dependencies/dependency_report -- two methods it
# must never call, because a card that does not exist yet cannot be taken up.
#
# The requires lines themselves are t/135-dependency-check-requires.t's subject.
# This file is about the split: which half each consumer gets, and that neither
# half brings the other along.

my %SET_TIME    = map { $_ => 1 } qw( parse_dependency_ids assert_dependencies_exist );
my %REPORT_TIME = map { $_ => 1 } qw( check_dependencies dependency_report
                                      _dependency_warnings );

# What each command is entitled to, and by the same token what it must not have.
# `edit` is the only one on both lists: it parses --add-depends-on and takes the
# warning path through --status, and since the split those arrive from two
# different roles.
my %EXPECTED = (
    Create  => ['set'],
    Edit    => [ 'set', 'report' ],
    Move    => ['report'],
    Pick    => ['report'],
    Handoff => ['report'],
    Delete  => ['report'],
    Archive => ['report'],
);

subtest 'the two roles share no method' => sub {
    # The split is only a split if it actually divided them. A method left
    # behind in both packages would compose from whichever role won and the
    # consumers would look right by accident.
    my %args  = _subs_of('App::karr::Role::DependencyArgs');
    my %check = _subs_of('App::karr::Role::DependencyCheck');

    is_deeply [ sort keys %args ], [ sort keys %SET_TIME ],
        'DependencyArgs holds the set-time helpers and nothing else';

    is_deeply [ sort keys %check ], [ sort keys %REPORT_TIME ],
        'DependencyCheck holds the reporting half and nothing else';

    my @both = sort grep { $check{$_} } keys %args;
    is_deeply \@both, [], 'and no name is defined in both roles'
        or diag "in both: @both";
};

subtest 'every command gets the half it uses, and only that half' => sub {
    for my $cmd ( sort keys %EXPECTED ) {
        my $pkg = "App::karr::Cmd::$cmd";
        require_ok($pkg) or next;

        my %want = map { $_ => 1 } @{ $EXPECTED{$cmd} };

        for my $method ( sort keys %SET_TIME ) {
            is !!$pkg->can($method), !!$want{set},
                sprintf( '%s %s ->%s', $cmd, $want{set} ? 'has' : 'has no', $method );
        }
        for my $method ( sort keys %REPORT_TIME ) {
            is !!$pkg->can($method), !!$want{report},
                sprintf( '%s %s ->%s', $cmd, $want{report} ? 'has' : 'has no', $method );
        }
    }
};

subtest 'create is the consumer the split was for' => sub {
    # It is what kept json off the requires line, so its shape is the one that
    # regresses first: a `with 'App::karr::Role::DependencyCheck'` put back on
    # create would fail to compile now, and a create that quietly lost the
    # set-time half would take a bad --depends-on all the way to the write.
    require App::karr::Cmd::Create;

    ok( App::karr::Cmd::Create->does('App::karr::Role::DependencyArgs'),
        'create does the set-time role' );
    ok( !App::karr::Cmd::Create->does('App::karr::Role::DependencyCheck'),
        'and not the reporting role' );
};

subtest 'edit is the only command that composes both halves' => sub {
    require App::karr::Cmd::Edit;

    ok( App::karr::Cmd::Edit->does('App::karr::Role::DependencyArgs'),
        'edit does the set-time role, for --add/--remove-depends-on' );
    ok( App::karr::Cmd::Edit->does('App::karr::Role::DependencyCheck'),
        '...and the reporting role, for --status' );

    # Through TaskMutation, not by naming it: edit --status goes down the same
    # apply_status_change path as move, which is where the check is called.
    ok( App::karr::Role::TaskMutation->can('apply_status_change'),
        'and it is TaskMutation that brings the second one' );

    for my $cmd (qw( Move Pick Handoff Delete Archive )) {
        my $pkg = "App::karr::Cmd::$cmd";
        require_ok($pkg) or next;
        ok( !$pkg->does('App::karr::Role::DependencyArgs'),
            "$cmd does not compose the set-time role it has no options for" );
    }
};

subtest 'the mutation role carries the reporting half only' => sub {
    # TaskMutation is how five commands get the check without asking for it, and
    # how they used to get the set-time helpers too. A consumer of it must be
    # asked for the reporting collaborators and no others.
    ok( Role::Tiny::does_role( 'App::karr::Role::TaskMutation',
            'App::karr::Role::DependencyCheck' ),
        'TaskMutation composes DependencyCheck' );
    ok( !Role::Tiny::does_role( 'App::karr::Role::TaskMutation',
            'App::karr::Role::DependencyArgs' ),
        'and not DependencyArgs' );
};

# What a role actually composes into a consumer: everything in its symbol table
# except the sugar Moo::Role put there, which Role::Tiny itself tracks under
# non_methods. `has` generates its accessor into the role package too, so
# _dependency_warnings comes out of this the same way a `sub` does.
sub _subs_of {
    my ($pkg)   = @_;
    my $non     = $Role::Tiny::INFO{$pkg}{non_methods} || {};
    no strict 'refs';
    return map { $_ => 1 }
      grep { !$non->{$_} }
      grep { defined &{"${pkg}::$_"} }
      keys %{"${pkg}::"};
}

done_testing;
