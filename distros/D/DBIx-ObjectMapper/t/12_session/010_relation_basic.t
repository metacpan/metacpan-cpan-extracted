use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;

my $mapper = DBIx::ObjectMapper->new(
    engine => DBIx::ObjectMapper::Engine::DBI->new({
        dsn => 'DBI:SQLite:',
        username => '',
        password => '',
        on_connect_do => [
            q{CREATE TABLE parent (id integer primary key)},
            q{CREATE TABLE child (id integer primary key, parent_id integer REFERENCES parent(id))},
        ]
    }),
);
$mapper->metadata->autoload_all_tables;
$mapper->metadata->t('parent')->insert->values(id => 1)->execute();
$mapper->metadata->t('child')->insert->values({parent_id => 1})->execute() for 0 .. 4;

ok $mapper->maps(
    $mapper->metadata->t('parent') => 'MyTest010::Parent',
    constructor => +{ auto => 1 },
    accessors   => +{ auto => 1 },
    attributes  => +{
        properties => +{
            children => +{
                isa => $mapper->relation(
                    has_many => 'MyTest010::Child',
                    {
                        order_by =>
                            $mapper->metadata->t('child')->c('id')->desc,
                        cascade => 'all,delete_orphan',
                    }
                ),
            }
        }
    }
);

ok $mapper->maps(
    $mapper->metadata->t('child') => 'MyTest010::Child',
    constructor => +{ auto => 1 },
    accessors   => +{ auto => 1 },
    attributes  => +{
        properties => +{
            parent =>
                +{ isa => $mapper->relation( belongs_to => 'MyTest010::Parent' ) }
            }
    },
);

{
    my $session = $mapper->begin_session;
    my $parent = $session->get( 'MyTest010::Parent' => 1 ); # query_cnt++

    is ref($parent->children), 'ARRAY'; # query_cnt++

    my $loop_cnt = 5;
    for my $c ( @{$parent->children} ) {
        is $c->parent_id, $parent->id;
        is $c->id, $loop_cnt--;
    }
    is $loop_cnt, 0;

    my $child1 = $session->get( 'MyTest010::Child' => 4 );
    is $child1->parent->id, 1;

    my $child_child = $child1->parent->children;
    is $child_child->[0]->parent->id, 1; # query_cnt++
    is $child_child->[0]->parent->children->[3]->parent->id, 1; # query_cnt++
    is $session->uow->query_cnt, 4;

    eval "require Test::Memory::Cycle";
    unless( $@ ) {
        Test::Memory::Cycle::memory_cycle_ok( $parent );
    }

};

{
    my $session = $mapper->begin_session;
    ok my $parent = $session->get( 'MyTest010::Parent' => 1 );
    push @{$parent->children}, MyTest010::Child->new( id => 6 );
};

{
    my $session = $mapper->begin_session;
    ok my $parent = $session->get( 'MyTest010::Parent' => 1 );
    is @{$parent->children}, 6;
};

{
    my $session = $mapper->begin_session;
    ok my $parent = $session->get( 'MyTest010::Parent' => 1 );
    shift(@{$parent->children});
};

{
    my $session = $mapper->begin_session;
    ok my $parent = $session->get( 'MyTest010::Parent' => 1 );
    is @{$parent->children}, 5;
    is $session->search('MyTest010::Child')->count, 5; # delete_orphan
};

#### autoflush = true

{
    my $session = $mapper->begin_session( autoflush => 1 );
    ok my $parent = $session->get( 'MyTest010::Parent' => 1 );
    push @{$parent->children}, MyTest010::Child->new( id => 7 );
};

{
    my $session = $mapper->begin_session( autoflush => 1 );
    ok my $parent = $session->get( 'MyTest010::Parent' => 1 );
    is @{$parent->children}, 6;
};

{
    my $session = $mapper->begin_session( autoflush => 1 );
    ok my $parent = $session->get( 'MyTest010::Parent' => 1 );
    shift(@{$parent->children});
};

{
    my $session = $mapper->begin_session( autoflush => 1 );
    ok my $parent = $session->get( 'MyTest010::Parent' => 1 );
    is @{$parent->children}, 5;
    is $session->search('MyTest010::Child')->count, 5; # delete_orphan
};

done_testing;

__END__
