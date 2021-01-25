package TestFor::App::GHPT::WorkSubmitter::AskPullRequestQuestions;

use App::GHPT::Wrapper::OurTest::Class::Moose;

use App::GHPT::WorkSubmitter::AskPullRequestQuestions ();

with 'TestRole::WithGitRepo';

sub test_startup {
    my $self = shift;
    $self->test_skip(
        'This test does not run in CI because of the way it uses git when testing a PR'
    ) if $ENV{CI};
}

sub test_question_namespaces {
    local @INC = ( @INC, 't/lib' );

    my $ask = App::GHPT::WorkSubmitter::AskPullRequestQuestions->new(
        merge_to_branch_name => 'master',
        question_namespaces  => ['Helper::QuestionNamespace1'],
    );

    is_deeply(
        [ sort map { ref($_) } $ask->_questions->@* ],
        ['Helper::QuestionNamespace1::Question'],
        'asker only looks in namespace it is given'
    );

    $ask = App::GHPT::WorkSubmitter::AskPullRequestQuestions->new(
        merge_to_branch_name => 'master',
        question_namespaces  =>
            [ 'Helper::QuestionNamespace1', 'Helper::QuestionNamespace2' ],
    );

    is_deeply(
        [ sort map { ref($_) } $ask->_questions->@* ],
        [
            'Helper::QuestionNamespace1::Question',
            'Helper::QuestionNamespace2::Question'
        ],
        'asker can find questions in multiple namespaces'
    );
}

__PACKAGE__->meta->make_immutable;
1;
