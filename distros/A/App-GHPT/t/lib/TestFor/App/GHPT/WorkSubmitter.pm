package TestFor::App::GHPT::WorkSubmitter;

use App::GHPT::Wrapper::OurTest::Class::Moose;

use Hash::Objectify       qw( objectify );
use Helper::MockPTAPI     ();
use Helper::WorkSubmitter ();
use Test::Differences;
use Test::More;
use Test::Output qw( stdout_is stdout_like );

# This test suite relies upon mock PT data returned by Helper::MockPTAPI
# and mock Term::Choose::choose() data returned by Helper::WorkSubmitter.

sub test_build_project_ids ( $self, @ ) {
    my $pt_api = Helper::MockPTAPI->new(
        token => '5d41402abc4b2a76b9719d911017c592' );

    eq_or_diff(
        Helper::WorkSubmitter->new(
            _pt_api => $pt_api,
            project => 'Uhura'
        )->_project_ids,
        [456],
        q{finding a single project by part of its name works}
    );

    eq_or_diff(
        Helper::WorkSubmitter->new( _pt_api => $pt_api )->_project_ids,
        [ 303, 789, 123, 456 ],
        q{finding all projects works}
    );
}

sub test_find_project ( $self, @ ) {
    my $pt_api = Helper::MockPTAPI->new(
        token => '5d41402abc4b2a76b9719d911017c592' );

    eq_or_diff(
        Helper::WorkSubmitter->new(
            _pt_api => $pt_api,
            project => 'Data',
        )->_find_project,
        $pt_api->team_data,
        q{finding a project by part of its name works}
    );

    eq_or_diff(
        Helper::WorkSubmitter->new(
            _pt_api => $pt_api,
        )->_find_project,
        $pt_api->team_uhura,
        q{finding a project using choose works}
    );

    eq_or_diff(
        Helper::WorkSubmitter->new(
            _pt_api => $pt_api,
            project => 'Team',
        )->_find_project,
        $pt_api->team_scotty,
        q{finding a project using part of its name and then choose works}
    );
}

sub test_find_requester ( $self, @ ) {
    my $pt_api = Helper::MockPTAPI->new(
        token => '5d41402abc4b2a76b9719d911017c592' );

    eq_or_diff(
        Helper::WorkSubmitter->new(
            _pt_api   => $pt_api,
            requester => 'Two'
        )->_find_requester( $pt_api->team_scotty ),
        $pt_api->team_scotty_member_two_person,
        q{finding a requester by part of their name works}
    );

    eq_or_diff(
        Helper::WorkSubmitter->new(
            _pt_api => $pt_api,
        )->_find_requester( $pt_api->team_scotty ),
        $pt_api->team_scotty_member_one_person,
        q{finding a requester using choose works}
    );

    eq_or_diff(
        Helper::WorkSubmitter->new(
            _pt_api   => $pt_api,
            requester => 'Scotty Member',
        )->_find_requester( $pt_api->team_scotty ),
        $pt_api->team_scotty_member_two_person,
        q{finding a requester using part of their name and then choose works}
    );
}

sub test_chore_filter ( $self, @ ) {
    my $feature = objectify { story_type => 'feature' };
    my $chore   = objectify { story_type => 'chore' };
    my $bug     = objectify { story_type => 'bug' };

    my $story_set_no_chores = [ $feature, $feature, $bug, $feature, $bug ];
    my $stories;
    stdout_is(
        sub {
            ## no critic (Subroutines::ProtectPrivateSubs)
            $stories
                = Helper::WorkSubmitter->_filter_chores_and_maybe_warn_user(
                $story_set_no_chores);
            ## use critic
        },
        q{},
        q{stays quiet when no chores are present}
    );

    eq_or_diff(
        $stories,
        [ $feature, $feature, $bug, $feature, $bug ],
        q{chores are filtered correctly}
    );

    my $story_set_with_chores = [ $feature, $chore, $chore, $bug ];
    stdout_like(
        sub {
            ## no critic (Subroutines::ProtectPrivateSubs)
            $stories
                = Helper::WorkSubmitter->_filter_chores_and_maybe_warn_user(
                $story_set_with_chores);
            ## use critic
        },
        qr/^Note: 2 chores are not shown here/a,
        q{emits note for user for user when chores are filtered}
    );

    eq_or_diff(
        $stories,
        [ $feature, $bug ],
        q{chores are filtered correctly}
    );

    my $story_set_all_chores = [ $chore, $chore, $chore ];
    eq_or_diff(
        ## no critic (Subroutines::ProtectPrivateSubs)
        Helper::WorkSubmitter->_filter_chores_and_maybe_warn_user(
            $story_set_all_chores),
        ## use critic
        [],
        q{empty array ref when only chores are found}
    );
}

sub test_token_from_env ( $self, @ ) {
    my $ws = App::GHPT::WorkSubmitter->new;
    local $ENV{PIVOTALTRACKER_TOKEN} = 'env value';
    is(
        $ws->pivotaltracker_token, 'env value',
        'value comes from environment'
    );
}

__PACKAGE__->meta->make_immutable;
1;
