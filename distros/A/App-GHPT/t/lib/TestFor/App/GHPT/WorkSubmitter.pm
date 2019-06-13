package TestFor::App::GHPT::WorkSubmitter;

use App::GHPT::Wrapper::OurTest::Class::Moose;

use Hash::Objectify qw( objectify );
use Helper::MockPTAPI        ();
use App::GHPT::WorkSubmitter ();
use Test::Differences;
use Test::Output qw( stdout_is stdout_like );

sub test_build_project_ids ( $self, @ ) {
    my $pt_api = Helper::MockPTAPI->new(
        token => '5d41402abc4b2a76b9719d911017c592' );

    eq_or_diff(
        App::GHPT::WorkSubmitter->new(
            _pt_api => $pt_api, project => 'Team Uhura'
        )->_project_ids,
        [456],
        q{selecting a single project works}
    );

    eq_or_diff(
        App::GHPT::WorkSubmitter->new( _pt_api => $pt_api )->_project_ids,
        [ 123, 456, 789, 303 ],
        q{not selecting any project works}
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
            $stories = App::GHPT::WorkSubmitter
                ->_filter_chores_and_maybe_warn_user($story_set_no_chores);
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
            $stories = App::GHPT::WorkSubmitter
                ->_filter_chores_and_maybe_warn_user($story_set_with_chores);
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
        App::GHPT::WorkSubmitter->_filter_chores_and_maybe_warn_user(
            $story_set_all_chores),
        ## use critic
        [],
        q{empty array ref when only chores are found}
    );
}

__PACKAGE__->meta->make_immutable;
1;
