package App::Rssfilter::Feed::Tester;
use Moo;
use App::Rssfilter::Feed;
use Test::MockObject;

has feed => (
    is => 'lazy',
    default => sub {
        my ( $self ) = @_;
        App::Rssfilter::Feed->new(
            storage    => $self->mock_storage,
            user_agent => $self->mock_ua,
            rules      => $self->rules,
            name       => $self->feed_name,
            url        => $self->feed_url,
        );
    },
);

has feed_name => (
    is => 'ro',
    default => sub { 'Totally Cool Tester'; },
);

has rules => (
    is => 'ro',
    default => sub {
        my ( $self ) = @_;
        return [ $self->mock_rule ];
    },
);

has feed_url => (
    is => 'ro',
    default => sub { 'http://rad.cool.com/totally.rss' },
);

has fetched_headers => (
    is => 'ro',
    default => sub { "HTTP/1.0 200 OK\r\nContent-Type: text/xml\r\n" },
);

has new_feed =>  (
    is => 'ro',
    default => sub { undef },
);

has old_feed => (
    is => 'ro',
    default => sub { undef },
);

has last_modified => (
    is => 'ro',
    default => sub { undef },
);

has path => (
    is => 'ro',
    default => sub { undef },
);

has mock_storage => (
    is => 'lazy',
    default => sub {
        my ( $self ) = @_;
        my $mock_storage = Test::MockObject->new;
        $mock_storage->set_isa( 'App::Rssfilter::Feed::Storage' );
        $mock_storage->set_always( 'last_modified', $self->last_modified );
        $mock_storage->set_always( 'load_existing', $self->old_feed );
        $mock_storage->set_always( 'save_feed', undef );
        $mock_storage->set_always( 'path', $self->path );
        $mock_storage->set_always( 'set_name', $mock_storage );
        return $mock_storage;
    },
);

has mock_ua => (
    is => 'lazy',
    default => sub {
        my ( $self ) = @_;
        Test::MockObject->new->mock(
            get => sub {
                use Mojo::Transaction;
                use Mojo::Message::Response;
                Mojo::Transaction->new->res(
                    Mojo::Message::Response->new->parse(
                        join "\r\n", grep { defined } map { $self->$_ } qw< fetched_headers new_feed >
                    )
                );
            }
        );
    },
);

has mock_rule => (
    is => 'lazy',
    default => sub {
        my $mock_rule = Test::MockObject->new;
        $mock_rule->set_always( 'constrain', 1 );
        $mock_rule->set_always( 'condition_name', 'redhead' );
        $mock_rule->set_always( 'action_name', 'swan' );
        $mock_rule->set_isa( 'App::Rssfilter::Rule' );
        return $mock_rule;
    },
);

sub BUILDARGS {
    my ( $class, $opts ) = @_;
    for my $feed ( qw< new_feed old_feed > ) {
        $opts->{ $feed } = Mojo::DOM->new( $opts->{ $feed } // q{} );
    }
    return $opts;
}

1;
