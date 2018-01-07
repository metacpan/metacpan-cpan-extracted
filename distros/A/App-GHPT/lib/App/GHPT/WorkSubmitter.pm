package App::GHPT::WorkSubmitter;

use App::GHPT::Wrapper::OurMoose;

our $VERSION = '1.000010';

use App::GHPT::Types qw( ArrayRef Bool PositiveInt Str );
use App::GHPT::WorkSubmitter::AskPullRequestQuestions;
use File::HomeDir ();
use IPC::Run3 qw( run3 );
use Lingua::EN::Inflect qw( PL PL_V );
use List::AllUtils qw( part );
use Path::Class qw( dir file );
use Term::CallEditor qw( solicit );
use Term::Choose qw( choose );
use WebService::PivotalTracker 0.10;

with 'MooseX::Getopt::Dashes';

has project => (
    is  => 'ro',
    isa => Str,
    documentation =>
        'The name of the PT project to search. This will be matched against the names of all the projects you have access to. By default, all projects will be searched.',
);

has base => (
    is      => 'ro',
    isa     => Str,
    default => 'master',
    documentation =>
        'The branch against which you want base the pull request. This defaults to master.',
);

has dry_run => (
    is            => 'ro',
    isa           => Bool,
    default       => 0,
    documentation => 'Dry run, just print out the PR we would have created',
);

has _question_namespaces => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    default => sub ($self) {
        my $ns = $self->_config_val('submit-work.question-namespaces');
        [
            $ns
            ? ( split / +/, $ns )
            : 'App::GHPT::WorkSubmitter::Question'
        ];
    },
);

has _username => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub ($self) {
        my $key = 'submit-work.pivotaltracker.username';
        $self->_config_val($key) // $self->_require_git_config($key);
    },
);

has _pt_api => (
    is      => 'ro',
    isa     => 'WebService::PivotalTracker',
    lazy    => 1,
    builder => '_build_pt_api',
    documentation =>
        'A WebService::PivotalTracker object built using $self->_pt_token',
);

has _include_requester_name_in_pr => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub ($self) {
        return $self->_config_val('submit-work.include-requester-name-in-pr')
            // 1;
    },
);

has _git_config => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_git_config',
    handles => { _config_val => 'get' },
);

sub _build_pt_api ($self) {
    return WebService::PivotalTracker->new(
        token => $self->_pt_token,
    );
}

has _project_ids => (
    is      => 'ro',
    isa     => ArrayRef [PositiveInt],
    lazy    => 1,
    builder => '_build_project_ids',
);

sub _build_project_ids ($self) {
    my $want = $self->project;
    if ($want) {
        for my $project ( $self->_pt_api->projects->@* ) {
            my $munged_name = $project->name =~ s/ /-/gr;
            return [ $project->id ] if $munged_name =~ /$want/i;
        }
        die 'Could not find a project id for project named ' . $self->project;
    }

    return [ map { $_->id } $self->_pt_api->projects->@* ];
}

before print_usage_text => sub {
    say <<'EOF';
Please see POD in App::GHPT for installation and troubleshooting directions.
EOF
};

sub run ($self) {
    unless ( -s dir( File::HomeDir->my_home )->file( '.config', 'hub' ) ) {
        die
            "hub does not appear to be set up. Please run 'hub browse' to set it up.\n";
    }

    my $chosen_story = $self->_choose_pt_story;
    unless ($chosen_story) {
        die "No started stories found!\n";
    }

    my $pull_request_url = $self->_create_pull_request(
        $self->_append_question_answers(
            $self->_confirm_story(
                $self->_text_for_story($chosen_story),
            ),
        ),
    );
    $self->_update_pt_story( $chosen_story, $pull_request_url );
    say $chosen_story->url;
    say $pull_request_url;

    return 0;
}

sub _append_question_answers ( $self, $text ) {
    my $qa_markdown = App::GHPT::WorkSubmitter::AskPullRequestQuestions->new(
        merge_to_branch_name => 'origin/' . $self->base,
        question_namespaces  => $self->_question_namespaces,
    )->ask_questions;
    return $text unless defined $qa_markdown and length $qa_markdown;
    return join "\n\n",
        $text,
        '----',
        $qa_markdown,
        ;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _pt_token ($self) {
    my $key = 'submit-work.pivotaltracker.token';
    return $self->_config_val($key) // $self->_require_git_config($key);
}
## use critic

sub _choose_pt_story ($self) {
    my $stories = [
        map {
            $self->_pt_api->project_stories_where(
                project_id => $_,
                filter     => sprintf(
                    '(owner:%s AND (state:started OR state:finished))',
                    $self->_username
                ),
                )->@*
        } $self->_project_ids->@*
    ];

    $stories = $self->_filter_chores_and_maybe_warn_user($stories);

    return unless $stories->@*;

    my %stories_lookup = map { $_->name => $_ } $stories->@*;
    my $chosen_story = choose( [ sort keys %stories_lookup ] );
    return unless $chosen_story;

    return $stories_lookup{$chosen_story};
}

sub _filter_chores_and_maybe_warn_user ( $self, $stories ) {
    my ( $chore_stories, $non_chore_stories )
        = part { $_->story_type eq 'chore' ? 0 : 1 } $stories->@*;

    say 'Note: '
        . ( scalar $chore_stories->@* )
        . PL( ' chore', scalar $chore_stories->@* )
        . PL_V( ' is', scalar $chore_stories->@* )
        . ' not shown here (chores by definition do not require review).'
        if $chore_stories;

    return $non_chore_stories // [];
}

sub _confirm_story ( $self, $text ) {
    my $result = choose( [ 'Accept', 'Edit' ], { prompt => $text } )
        or exit 1;    # user hit q or ctrl-d to quit
    return $text if $result eq 'Accept';
    my $fh = solicit($text);
    return do { local $/ = undef; <$fh> };
}

sub _text_for_story ( $self, $story ) {
    join "\n\n",
        $story->name,
        $story->url,
        ( $story->description ? $story->description : () ),
        (
        $self->_include_requester_name_in_pr
        ? 'Reviewer: ' . $story->requested_by->name
        : ()
        ),
}

sub _create_pull_request ( $self, $text ) {
    if ( $self->dry_run ) {
        print $text;
        exit;
    }

    run3(
        [ qw(hub pull-request -F - -b), $self->base ],
        \$text,
        \my $hub_output,
        \my $err,
        {
            binmode_stdin  => ':encoding(UTF-8)',
            binmode_stdout => ':encoding(UTF-8)',
            binmode_stderr => ':encoding(UTF-8)',
        },
    );

    warn $err if $err;
    exit 1 if $?;

    return $hub_output;
}

sub _update_pt_story ( $self, $story, $pr_url ) {
    $story->update( current_state => 'finished' );
    $story->add_comment( text => $pr_url );
    return;
}

sub _build_git_config ($self) {
    run3(
        [ 'git', 'config', '--list' ],
        \undef,
        \my @conf_values,
        \my $error,
    );

    if ( $error || $? ) {
        die q{Could not run "git config --list"}
            . ( defined $error ? ": $error" : q{} );
    }

    return {
        map { split /=/, $_, 2 }
            grep {/^submit-work/}
            ## no critic (BuiltinFunctions::ProhibitComplexMappings)
            map { chomp; $_ } @conf_values
    };
}

sub _require_git_config ( $self, $key ) {
    die "Please set $key using 'git config --global $key VALUE'\n";
}

__PACKAGE__->meta->make_immutable;

1;
