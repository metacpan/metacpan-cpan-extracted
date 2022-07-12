package App::GHPT::WorkSubmitter;

use App::GHPT::Wrapper::OurMoose;

our $VERSION = '2.000001';

use App::GHPT::Types qw( ArrayRef Bool HashRef PositiveInt Str );
use App::GHPT::WorkSubmitter::AskPullRequestQuestions ();
use File::HomeDir                                     ();
use IPC::Run3                                         qw( run3 );
use Lingua::EN::Inflect                               qw( PL PL_V );
use List::AllUtils                                    qw( first part );
use Pithub                                            ();
use Term::CallEditor                                  qw( solicit );
use Term::Choose                                      qw( choose );
use WebService::PivotalTracker 0.10                   ();
use YAML::PP                                          ();

with 'MooseX::Getopt::Dashes';

has create_story => (
    is            => 'ro',
    isa           => Bool,
    documentation =>
        'If true, will create a new story instead of finding an existing one.',
);

has _env_keys => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_env_keys',
    handles => { _all_env_keys => 'elements', _get_env_key => 'get', },
);

has _is_ghe => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub ($self) { lc( $self->_host ) eq 'github.com' ? 0 : 1; },
);

has project => (
    is            => 'ro',
    isa           => Str,
    documentation =>
        'The name of the PT project to search. This will be matched against the names of all the projects you have access to. By default, all projects will be searched.',
    default => sub {
        $ENV{APP_GHPT_PROJECT} // q{};
    },
);

has base => (
    is            => 'ro',
    isa           => Str,
    default       => 'main',
    documentation =>
        'The branch against which you want base the pull request. This defaults to main.',
);

has dry_run => (
    is            => 'ro',
    isa           => Bool,
    default       => 0,
    documentation => 'Dry run, just print out the PR we would have created',
);

has github_protocol => (
    is            => 'ro',
    isa           => Str,
    predicate     => '_has_github_protocol',
    documentation => 'The protocol you want to use for GitHub API request.',
);

has github_token => (
    is            => 'ro',
    isa           => Str,
    predicate     => '_has_github_token',
    documentation => 'Your GitHub token for API access.',
);

has pivotaltracker_token => (
    is            => 'ro',
    isa           => Str,
    lazy          => 1,
    builder       => '_build_pivotaltracker_token',
    documentation => 'Your Pivotal Tracker token for API access.',
);

has pivotaltracker_username => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub ($self) {
        my $env_key = 'PIVOTALTRACKER_USERNAME';
        my $key     = 'submit-work.pivotaltracker.username';

        return $ENV{$env_key} // $self->_config_val($key)
            // $self->_require_env_or_git_config( $env_key, $key );
    },
    documentation => 'Your Pivotal Tracker username for API access.',
);

has requester => (
    is            => 'ro',
    isa           => Str,
    default       => q{},
    documentation =>
        q{When creating a story, this will be the requester. You can provide a substring of the person's name (case insensitive) and it will find them.},
);

has story_name => (
    is            => 'ro',
    isa           => Str,
    default       => q{},
    documentation =>
        'When creating a story, this is the name (title) to set.',
);

has _question_namespaces => (
    is      => 'ro',
    isa     => ArrayRef [Str],
    lazy    => 1,
    default => sub ($self) {
        my $ns = $ENV{APP_GHPT_QUESTION_NAMESPACES}
            // $self->_config_val('submit-work.question-namespaces');
        [
            $ns
            ? ( split / +/, $ns )
            : 'App::GHPT::WorkSubmitter::Question'
        ];
    },
);

has _github_api => (
    is      => 'ro',
    isa     => 'Pithub',
    lazy    => 1,
    builder => '_build_github_api',
);

has _github_ua => (
    traits    => ['NoGetopt'],
    init_arg  => 'github_ua',
    is        => 'ro',
    isa       => 'LWP::UserAgent',
    predicate => '_has_github_ua',
);

has _pt_api => (
    is            => 'ro',
    isa           => 'WebService::PivotalTracker',
    lazy          => 1,
    builder       => '_build_pt_api',
    documentation =>
        'A WebService::PivotalTracker object built using $self->pivotaltracker_token',
);

has _include_requester_name_in_pr => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub ($self) {
        return $ENV{APP_GHPT_INCLUDE_REQUESTER_NAME_IN_PR}
            // $self->_config_val('submit-work.include-requester-name-in-pr')
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

has _git_remote => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_git_remote',
    handles => { _remote_val => 'get' },
);

has _host => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub ($self) { $self->_remote_val('host') },
);

has _project_ids => (
    is      => 'ro',
    isa     => ArrayRef [PositiveInt],
    lazy    => 1,
    builder => '_build_project_ids',
);

has _pithub_args => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_pithub_args',
);

sub _build_pithub_args ($self) {
    my $hub_config = $self->_hub_config->{ $self->_host }[0] // {};
    my $protocol   = $self->_github_protocol($hub_config);

    return {
        user  => $self->_remote_val('user'),
        repo  => $self->_remote_val('repo'),
        head  => $self->_git_current_branch,
        token => $self->_github_token($hub_config),
        (
            $self->_is_ghe
            ? ( api_uri =>
                    sprintf( '%s://%s/api/v3/', $protocol, $self->_host ) )
            : ()
        ),
        (
            $self->_has_github_ua
            ? (
                ua => $self->_github_ua,
                )
            : (),
        ),
    };
}

sub _build_github_api ($self) {
    return Pithub->new( $self->_pithub_args );
}

sub _github_protocol ( $self, $hub_config ) {
    return $self->github_protocol if $self->_has_github_protocol;

    return $ENV{GITHUB_PROTOCOL}
        // $self->_config_val('submit-work.github.protocol')
        // $hub_config->{protocol} // 'https';
}

sub _github_token ( $self, $hub_config ) {
    return $self->github_token if $self->_has_github_token;

    my $key = 'submit-work.github.token';
    return $self->_token_from_env // $self->_config_val($key)
        // $hub_config->{oauth_token}
        // $self->_require_env_or_git_config( $self->_get_env_key(0), $key );
}

# Use order of precedence for env vars as defined at
# https://cli.github.com/manual/gh_help_environment:w
#
# Add GITHUB_TOKEN to enterprise list for backwards compatibility.
sub _build_env_keys ($self) {
    return $self->_is_ghe
        ? [
        qw(
            GH_ENTERPRISE_TOKEN
            GITHUB_ENTERPRISE_TOKEN
            GITHUB_TOKEN
        )
        ]
        : [
        qw(
            GH_TOKEN
            GITHUB_TOKEN
        )
        ];
}

sub _token_from_env ($self) {
    my $key = first { $ENV{$_} } $self->_all_env_keys;
    return $key ? $ENV{$key} : undef;
}

sub _build_pivotaltracker_token ($self) {
    my $env_key = 'PIVOTALTRACKER_TOKEN';
    my $key     = 'submit-work.pivotaltracker.token';
    return $ENV{$env_key} // $self->_config_val($key)
        // $self->_require_env_or_git_config( $env_key, $key );
}

sub _build_pt_api ($self) {
    return WebService::PivotalTracker->new(
        token => $self->pivotaltracker_token,
    );
}

sub _build_project_ids ($self) {
    my $want = $self->project;
    return [
        map      { $_->id }
            grep { $want ? ( $_->name =~ /\Q$want/i ) : 1 }
            $self->_pt_api->projects->@*
    ];
}

sub _find_project ($self) {
    my $want     = $self->project;
    my @projects = grep { $want ? ( $_->name =~ /\Q$want/i ) : 1 }
        $self->_pt_api->projects->@*;

    return $projects[0] if @projects == 1;

    my %project_by_name = map { $_->name => $_ } @projects;
    my $name            = $self->_choose( [ sort keys %project_by_name ] );
    return $project_by_name{$name};
}

sub _find_requester ( $self, $project ) {
    my $want        = $self->requester;
    my @memberships = grep { $want ? ( $_->person->name =~ /\Q$want/i ) : 1 }
        $project->memberships->@*;

    return $memberships[0]->person if @memberships == 1;

    my %membership_by_person_name
        = map { $_->person->name => $_ } @memberships;
    my $name = $self->_choose( [ sort keys %membership_by_person_name ] );
    return $membership_by_person_name{$name}->person;
}

before print_usage_text => sub {
    say <<'EOF';
Please see POD in App::GHPT for installation and troubleshooting directions.
EOF
};

sub run ($self) {
    my ( $requester, $chosen_story ) = $self->_choose_pt_story;
    unless ($requester) {
        die "No requester found!\n";
    }
    unless ($chosen_story) {
        die "No started stories found!\n";
    }

    my $pull_request_url = $self->_create_pull_request(
        $self->_append_question_answers(
            $self->_confirm_story(
                $self->_text_for_story( $chosen_story, $requester ),
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

sub _choose {
    my $self = shift;
    return choose(@_)
        || exit 1;    # user hit q or ctrl-d to quit
}

sub _choose_pt_story ($self) {
    if ( $self->create_story ) {
        my $project   = $self->_find_project;
        my $requester = $self->_find_requester($project);
        my $name      = $self->_get_story_name;

        if ( $self->dry_run ) {
            say "Would create story $name in "
                . $project->name
                . ' with requester '
                . $requester->name
                . ' but this is a dry-run.';
            exit;
        }

        return (
            $requester->name,
            $self->_pt_api->create_story(
                current_state => 'started',

                # This is primarily intended for small changes/stories, so 0 points.
                estimate        => 0,
                name            => $name,
                owner_ids       => [ $self->_pt_api->me->id ],
                project_id      => $project->id,
                requested_by_id => $requester->id,
            )
        );
    }

    my $stories = [
        map {
            $self->_pt_api->project_stories_where(
                project_id => $_,
                filter     => sprintf(
                    '(owner:%s AND (state:started OR state:finished))',
                    $self->pivotaltracker_username
                ),
            )->@*
        } $self->_project_ids->@*
    ];

    $stories = $self->_filter_chores_and_maybe_warn_user($stories);

    return undef unless $stories->@*;

    my %stories_lookup = map { $_->name => $_ } $stories->@*;
    my $chosen_story   = $self->_choose( [ sort keys %stories_lookup ] );

    return (
        $stories_lookup{$chosen_story}->requested_by->name,
        $stories_lookup{$chosen_story}
    );
}

sub _get_story_name ($self) {
    my $story_name = $self->story_name;
    if ( !$story_name ) {
        say q{Please enter the new story's name:};
        $story_name = $self->_read_line;
    }
    return $story_name;
}

sub _read_line ($) {
    while (1) {
        my $l = readline( \*STDIN );
        $l =~ s/^\s+|\s+$//g;
        return $l if $l;
    }
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
    my $result = $self->_choose(
        [ 'Accept', 'Edit' ],
        { prompt => $text, clear_screen => $ENV{'SUBMIT_WORK_CLEAR'} // 0 }
    );
    return $text if $result eq 'Accept';
    my $fh = solicit($text);
    return do { local $/ = undef; <$fh> };
}

sub _text_for_story ( $self, $story, $reviewer ) {
    join "\n\n",
        $story->name,
        $story->url,
        ( $story->description ? $story->description : () ),
        (
        $self->_include_requester_name_in_pr
        ? 'Reviewer: ' . $reviewer
        : ()
        ),
        ;
}

sub _create_pull_request ( $self, $text ) {
    if ( $self->dry_run ) {
        print $text;
        exit;
    }

    my ( $title, $body ) = split /\n\n/, $text, 2;

    my $res = $self->_github_api->pull_requests->create(
        data => {
            base  => $self->base,
            body  => $body,
            head  => $self->_git_current_branch,
            title => $title,
        },
    );

    unless ( $res->success ) {
        die "Error while creating pull request:\n\n"
            . _format_github_error($res) . "\n";
    }

    return $res->content->{html_url};
}

sub _format_github_error ($res) {
    my $content = $res->content;
    if ( my $msg = $content->{message} ) {
        if ( my $errors = $content->{errors} ) {
            $msg .= "\n\n" . join "\n", map { $_->{message} } @$errors;
        }
        return $msg;
    }
    return $res->raw_content;
}

sub _build_git_remote ($self) {
    my $git_url = $self->_git_config->{'remote.origin.url'} // q{};

    if ( my ( $host, $user, $repo )
        = $git_url =~ m{^git@([^:]+):([^/]+)/([^/]+?)(?:\.git)?$} ) {
        return { host => $host, user => $user, repo => $repo };
    }

    my $uri = URI->new($git_url);
    if ( $uri->can('host') && $uri->can('path') ) {
        if ( my ( $user, $repo )
            = $uri->path =~ m{/([^/]+)/([^/]+?)(?:\.git)?$} ) {
            return { host => $uri->host, user => $user, repo => $repo };
        }
    }

    die "Unable to determine host for remote origin ($git_url)!";
}

sub _update_pt_story ( $self, $story, $pr_url ) {
    $story->update( current_state => 'finished' );
    $story->add_comment( text => $pr_url );
    return;
}

sub _git_current_branch ($self) {
    run3(
        [qw( git rev-parse --abbrev-ref HEAD )],
        \undef,
        \my $branch,
        \my $error,
    );

    if ( $error || $? ) {
        die q{Could not run "git rev-parse --abbrev-ref HEAD"}
            . ( defined $error ? ": $error" : q{} );
    }

    chomp $branch;

    return $branch;
}

sub _hub_config ($self) {
    my $file
        = ( $ENV{XDG_CONFIG_HOME} // File::HomeDir->my_home . '/.config' )
        . '/hub';

    return {} unless -f $file;

    return YAML::PP->new->load_file($file);
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
            ## no critic (BuiltinFunctions::ProhibitComplexMappings)
            map { chomp; $_ } @conf_values
    };
}

sub _require_env_or_git_config ( $self, $env, $key ) {
    die
        "Please set '$env' environment variable or $key using 'git config --global $key VALUE'\n";
}

__PACKAGE__->meta->make_immutable;
1;
