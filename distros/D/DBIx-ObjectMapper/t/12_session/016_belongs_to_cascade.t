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
            q{CREATE TABLE parent (id integer primary key, name text)},
            q{CREATE TABLE child (id integer primary key, parent_id integer REFERENCES parent(id), name text)},
        ]
    }),
);

$mapper->metadata->autoload_all_tables;

ok $mapper->maps(
    $mapper->metadata->t('parent') => 'MyTest016::Parent',
    constructor => +{ auto => 1 },
    accessors   => +{ auto => 1 },
    attributes  => +{
        properties => +{
            children => +{
                isa => $mapper->relation(
                    has_many => 'MyTest016::Child',
                ),
            }
        }
    }
);

ok $mapper->maps(
    $mapper->metadata->t('child') => 'MyTest016::Child',
    constructor => +{ auto => 1 },
    accessors   => +{ auto => 1 },
    attributes  => +{
        properties => +{
            parent => +{
                isa => $mapper->relation(
                    belongs_to => 'MyTest016::Parent',
                    { cascade => 'save_update,delete' }
                )
            }
        }
    },
);

{
    my $session = $mapper->begin_session;
    my @child = map{ MyTest016::Child->new( name => 'child' . $_ ) } 1 .. 5;
    my $parent = MyTest016::Parent->new( id => 1, name => 'parent1' );
    $_->parent($parent) for @child;
    $session->add_all(@child);
    $session->commit;
    ok 'done';
};

{
    my $session = $mapper->begin_session;

    my $it = $session->search('MyTest016::Child')->execute;
    my $loop_cnt = 0;
    while( my $c = $it->next ) {
        ok $c->id;
        is $c->parent_id, 1;
        ok $c->parent;
        is $c->parent->id, 1;
        $loop_cnt++;
    }
    is $loop_cnt, 5;
};

{
    my $session = $mapper->begin_session( autocommit => 0, autoflush => 1 );
    my @child = map{ MyTest016::Child->new( name => 'child' . $_ ) } 6 .. 10;
    my $parent = MyTest016::Parent->new( id => 2, name => 'parent2' );
    $session->add($parent);
    $_->parent($parent) for @child;
    $session->add_all(@child);
    $session->commit;
    ok 'done';
};

{
    my $session = $mapper->begin_session;

    my $it = $session->search('MyTest016::Child')->execute;
    my $loop_cnt = 0;
    while( my $c = $it->next ) {
        ok $c->id;
        ok $c->parent;
        if( $c->id > 5 ) {
            is $c->parent->id, 2;
        }
        else {
            is $c->parent->id, 1;
        }
        $loop_cnt++;
    }
    is $loop_cnt, 10;
};


{
    my $session = $mapper->begin_session( autocommit => 0 );
    $session->get( 'MyTest016::Parent' => 1 );
    my $c1 = $session->get( 'MyTest016::Child' => 1 );
    $session->delete($c1);
    $session->commit;
    ok !$session->get( 'MyTest016::Parent' => 1 );

    # 1 child deleted. and others, parent_id is null
    my $child_attr = $mapper->attribute('MyTest016::Child');
    my $children = $session->search('MyTest016::Child')->filter(
        $child_attr->p('parent_id') == undef
    )->execute;
    is @$children, 4;

    ok 'done';
};

ok $mapper->maps(
    $mapper->metadata->t('parent') => 'MyTest016::Parent2',
    constructor => +{ auto => 1 },
    accessors   => +{ auto => 1 },
    attributes  => +{
        properties => +{
            children => +{
                isa => $mapper->relation(
                    has_many => 'MyTest016::Child2',
                    { cascade => 'all' },
                ),
            }
        }
    }
);

ok $mapper->maps(
    $mapper->metadata->t('child') => 'MyTest016::Child2',
    constructor => +{ auto => 1 },
    accessors   => +{ auto => 1 },
    attributes  => +{
        properties => +{
            parent => +{
                isa => $mapper->relation(
                    belongs_to => 'MyTest016::Parent2',
                    { cascade => 'save_update,delete' }
                )
            }
        }
    },
);

{
    my $session = $mapper->begin_session;
    my @child = map{ MyTest016::Child2->new( name => 'child' . $_ ) } 11 .. 15;
    my $parent = MyTest016::Parent2->new( id => 3, name => 'parent3' );
    $_->parent($parent) for @child;
    $session->add_all(@child);
    $session->commit;
    ok 'done';
};

{
    my $session = $mapper->begin_session( autocommit => 0 );
    $session->get( 'MyTest016::Parent2' => 3 );
    my $c11 = $session->get( 'MyTest016::Child2' => 11 );
    $session->delete($c11);
#    $session->commit;

    ok !$session->get( 'MyTest016::Parent2' => 3 );

    # all children deleted.
    my $child_attr = $mapper->attribute('MyTest016::Child2');
    my $children = $session->search('MyTest016::Child2')->filter(
        $child_attr->p('parent_id') == 3
    )->execute;
    is @$children, 0;

    ok 'done';
};

{
    my $session = $mapper->begin_session( autocommit => 0 );
    my $p = $session->get( 'MyTest016::Parent2' => 3 );
    $session->detach($p);
    ok 'done';
};

done_testing;

