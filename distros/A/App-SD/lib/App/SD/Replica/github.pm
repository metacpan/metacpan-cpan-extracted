package App::SD::Replica::github;
use Any::Moose;
extends qw/App::SD::ForeignReplica/;

use Params::Validate qw(:all);
use Memoize;

use URI;
use Memoize;
use Config::GitLike::Git;
use Prophet::ChangeSet;

use constant scheme => 'github';
use constant pull_encoder => 'App::SD::Replica::github::PullEncoder';
use constant push_encoder => 'App::SD::Replica::github::PushEncoder';

has github     => ( isa => 'Net::GitHub::V2', is => 'rw' );
has remote_url => ( isa => 'Str',             is => 'rw' );
has owner      => ( isa => 'Str',             is => 'rw' );
has repo       => ( isa => 'Str',             is => 'rw' );
has query      => ( isa => 'Str',             is => 'rw' );
has foreign_username => ( isa => 'Str', is              => 'rw' );

our %PROP_MAP = (
    state      => 'status',
    title      => 'summary',
    created_at => 'created',
);

=head2 GitHub sync details

GitHub has a somewhat limited ticketing functionality (GitHub calls tickets
"issues").

Tickets have two states: open or closed.

Once a ticket is created, the following modifications can be made to it:
- edit ticket body/title
- add a new comment
- edit a comment's body
- close a ticket (or reopen)

Thus, there is no "history" API call---we just get the current state, and we
can formulate our own history based on the list of comments, updated_at
timestamps, and comparing our state with the current state.

GitHub issues can also have arbitrary "labels" applied to them, but we're
currently ignoring this functionality.

=cut

sub BUILD {
    my $self = shift;

    eval {
        require Net::GitHub;
    };

    if ($@) {
        die "SD requires Net::GitHub to sync with a GitHub server. "
            . "'cpan Net::GitHub' may sort this out for you\n";
    }

    my ( $server, $owner, $repo )
        = $self->{url}
        =~ m{^github:((?:(?:http|git)://.*?github.com/|git\@github.com:))?(.*?)/([^/\.]+)(?:(/|\.git))?}
        or die
        "Can't parse Github server spec. Expected github:owner/repository or github:http://github.com/owner/repository.\n";

    my ( $uri, $username, $api_token );

    if ($server && $server =~ m!http!) {
        $uri = URI->new($server);
        if ( my $auth = $uri->userinfo ) {
            ( $username, $api_token ) = split /:/, $auth, 2;
            $uri->userinfo(undef);
        }
    }
    else {
        $uri = 'http://github.com/';
    }

    # try loading github username & token from git configuration
    # see http://github.com/blog/180-local-github-config
    unless ( $api_token ) {
        my $config = Config::GitLike::Git->new;
        $config->load;
        $username  = $config->get(key => 'github.user');
        $api_token = $config->get(key => 'github.token');
    }

    ($username, $api_token) = $self->login_loop(
        uri      => $uri,
        username => $username,
        password => $api_token,
        secret_prompt => sub {
            my ($uri, $username) = @_;
            return "GitHub API token for $username (from ${uri}account): ";
        },
        login_callback => sub {
            my ($self, $username, $api_token) = @_;

            $self->github(
                Net::GitHub->new(
                    login => $username,
                    token => $api_token,
                    repo  => $repo,
                    owner => $owner,
                ) );
        },
    );

    $self->remote_url("$uri");
    $self->owner( $owner );
    $self->repo( $repo );
}

sub record_pushed_transactions {}

sub _uuid_url {
    my $self = shift;
    Carp::cluck "- can't make a uuid for this" unless ($self->remote_url && $self->owner && $self->repo );
    return join( '/', $self->remote_url, $self->owner , $self->repo ) ;
}

sub remote_uri_path_for_comment {
    my $self = shift;
    my $id = shift;
    return "/comment/".$id;
}

sub remote_uri_path_for_id {
    my $self = shift;
    my $id = shift;
    return "/ticket/".$id;
}

sub database_settings {
    my $self = shift;
    return {
    # TODO limit statuses too? the problem is github's statuses are so poor,
    # it only has 2 statuses: 'open' and 'closed'.
        project_name => $self->owner . '/' . $self->repo,
    };

}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
