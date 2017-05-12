use strict;
use warnings;
use Test::More;

use Scalar::Util qw(refaddr isweak);
use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{CREATE TABLE parent (id integer primary key)},
        q{CREATE TABLE child (id integer primary key, parent_id integer REFERENCES parent(id))},
    ],
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );

$mapper->metadata->autoload_all_tables;
$mapper->metadata->t('parent')->insert->values(id => 1)->execute();
$mapper->metadata->t('child')->insert->values({parent_id => 1})->execute() for 1 .. 5;

{
    package MyTest20::Parent;

    sub new {
        my $class = shift;
        my %param = @_ % 2 == 0 ? @_ : %{$_[0]};
        my $self = bless \%param, $class;
        return $self;
    }

    sub id {
        my $self = shift;
        $self->{id} = shift if @_;
        $self->{id};
    }

    sub children {
        my $self = shift;
        $self->{children} = shift if @_;
        return $self->{children};
    }

    1;
};

{
    package MyTest20::Child;
    use Scalar::Util qw(weaken isweak);

    sub new {
        my $class = shift;
        my %param = @_ % 2 == 0 ? @_ : %{$_[0]};
        my $self = bless \%param, $class;
        weaken $self->{parent};
        return $self;
    }

    sub id {
        my $self = shift;
        $self->{id} = shift if @_;
        $self->{id};
    }

    sub parent_id {
        my $self = shift;
        if( @_ ) {
            $self->{parent_id} = shift;
        }
        $self->{parent_id};
    }

    sub parent {
        my $self = shift;
        if( @_ ) {
            $self->{parent} = shift;
        }
        weaken $self->{parent} unless isweak $self->{parent};
        $self->{parent};
    }

    1;
};

$mapper->maps(
    $mapper->metadata->t('parent') => 'MyTest20::Parent',
    attributes => {
        properties => {
            children => {
                isa => $mapper->relation( has_many => 'MyTest20::Child' ),
            }
        }
    }
);

$mapper->maps(
    $mapper->metadata->t('child') => 'MyTest20::Child',
    attributes => {
        properties => {
            parent => {
                isa => $mapper->relation( belongs_to => 'MyTest20::Parent' ),
            }
        }
    }
);

{
    my $session = $mapper->begin_session();
    ok my $p = $session->get( 'MyTest20::Parent' => 1 );
    ok my $p2 = $session->get( 'MyTest20::Parent' => 1 );
    isnt refaddr($p), refaddr($p2);
    ok $p->children;
    my $loop_cnt;
    for my $c ( @{$p->children}) {
        $loop_cnt++;
        is $c->parent_id, 1;
        ok $c->parent;
        isnt refaddr($c->parent), refaddr($p);
    }

    eval "require Test::Memory::Cycle";
    unless( $@ ) {
        Test::Memory::Cycle::memory_cycle_ok( $p );
    }
};

{
    my $session = $mapper->begin_session( share_object => 1 );
    ok my $p = $session->get( 'MyTest20::Parent' => 1 );
    ok my $p2 = $session->get( 'MyTest20::Parent' => 1 );
    is refaddr($p), refaddr($p2);
    ok $p->children;
    my $loop_cnt;
    for my $c ( @{$p->children}) {
        $loop_cnt++;
        is $c->parent_id, 1;
        ok $c->parent;
        is refaddr($c->parent), refaddr($p);
    }

    eval "require Test::Memory::Cycle";
    unless( $@ ) {
        Test::Memory::Cycle::memory_cycle_ok( $p );
    }
};

done_testing;
