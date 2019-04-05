use Test::Roo;

use Test::Most;

use Class::Load qw/ load_class /;
use Ref::Util qw/ is_plain_arrayref /;
use SQL::Abstract::Test import => [qw/ is_same_sql_bind /];
use SQL::Translator 0.11018;

use lib 't/lib';

has dsn => (
    is      => 'lazy',
    default => 'dbi:SQLite::memory:',
);

has schema_class => (
    is      => 'ro',
    default => 'Test::Schema',
);

has schema => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        my $class = $self->schema_class;
        load_class($class);
        return $class->deploy_or_connect( $self->dsn );
    },
);

has base_rs => (
    is      => 'lazy',
    builder => sub {
        shift->schema->resultset('Artist'),;
    },
);

has args => (
    is       => 'ro',
    required => 1,
);

has rs => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        my $args = $self->args;
        return is_plain_arrayref($args)
          ? $self->base_rs->simple_stats(@$args)
          : $self->base_rs->simple_stats($args);
    },
    handles => [qw/ current_source_alias /],
);

has sql => (
    is       => 'ro',
    required => 1,
);

has as => (
    is       => 'ro',
    required => 1,
);

has bind => (
    is => 'ro',
    default => sub { [] },
);


before setup => sub {
    my ($self) = @_;
    ok my $rs = $self->rs, 'build resultset';
};

test 'expected SQL' => sub {
    my ($self) = @_;

    my $sql = $self->sql;

    my $rs = $self->rs;
    my $alias = $self->current_source_alias;
    $sql =~ s/\bme\b/$alias/g;

    is_same_sql_bind(
        $rs->as_query,
        "(${sql})",
        $self->bind,
        'expected sql and bind'
    );
};

test 'resultset as' => sub {
    my ($self) = @_;
    is_deeply $self->rs->{attrs}{as}, $self->as, 'as';
};



run_me(
    {
        args => 'name',
        sql  => 'SELECT me.name, COUNT(me.name) FROM artist me GROUP BY me.name ORDER BY me.name',
        as   => [qw/ me.name name_count /],
    }
);

run_me(
    {
        args => { count => 'name' },
        sql  => 'SELECT me.name, COUNT(me.name) FROM artist me GROUP BY me.name ORDER BY me.name',
        as   => [qw/ me.name name_count /],
    }
);


run_me(
    {
        args => { count => 'name', -as => 'blahs' },
        sql  => 'SELECT me.name, COUNT(me.name) FROM artist me GROUP BY me.name ORDER BY me.name',
        as   => [qw/ me.name blahs /],
    }
);

run_me(
    {
        args => [ 'name', { sum => 'fingers' } ],
        sql  => 'SELECT me.name, me.fingers, SUM(me.fingers) FROM artist me GROUP BY me.name, me.fingers ORDER BY me.name, me.fingers',
        as   => [qw/ me.name me.fingers fingers_sum /],
    }
);

run_me(
    {
        args => [qw/ name artistid /],
        sql  => 'SELECT me.name, me.artistid, COUNT(me.name) FROM artist me GROUP BY me.name, me.artistid ORDER BY me.name, me.artistid',
        as   => [qw/ me.name me.artistid name_count /],
    }
);

run_me(
    {
        args => [ map { { $_ => 'name' } } qw/ min max sum count /],
        sql  => 'SELECT me.name, MIN(me.name), MAX(me.name), SUM(me.name), COUNT(me.name) FROM artist me GROUP BY me.name ORDER BY me.name',
        as   => ['me.name', map { "name_$_" } qw/ min max sum count / ],
    }
);

done_testing;
