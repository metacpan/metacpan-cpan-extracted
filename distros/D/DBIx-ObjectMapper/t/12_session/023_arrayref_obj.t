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

{
    package MyTest023::Parent;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $id = shift;
        my $children = shift || undef;
        bless [ $id, $children ] , $class;
    }

    sub id {
        my $self = shift;
        $self->[0] = shift if @_;
        return $self->[0];
    }

    sub children {
        my $self = shift;
        $self->[1] = shift if @_;
        return $self->[1];
    }

    1;
};

{
    package MyTest023::Child;
    use strict;
    use warnings;

    my %param = ( id => 0, parent_id => 1, parent => 2 );

    sub new {
        my $class = shift;
        my $array = shift;
        bless $array , $class;
    }

    sub param {
        my $self = shift;

        if( @_ == 1 ) {
            my $i = $param{$_[0]};
            return unless defined $i;
            return $self->[$i];
        }
        elsif( @_ == 2 ) {
            my $i = $param{$_[0]};
            return unless defined $i;
            $self->[$i] = $_[1];
            return $self->[$i];
        }

        return( map { $_ => $self->[$param{$_}] } ( keys %param ) );
    }

    1;
};

my $parent = $mapper->metadata->t('parent');
my $child = $mapper->metadata->t('child');

ok $mapper->maps(
    $parent => 'MyTest023::Parent',
    constructor => +{ arg_type => 'ARRAY' },
    attributes  => +{
        properties => [
            +{ isa => $parent->c('id') },
            +{
                isa => $mapper->relation(
                    has_many => 'MyTest023::Child',
                    { order_by => $child->c('id')->desc },
                ),
                name => 'children',
            }
        ]
    }
);

ok $mapper->maps(
    $child => 'MyTest023::Child',
    constructor => +{ arg_type => 'ARRAYREF' },
    accessors   => +{ generic_setter => 'param', generic_getter => 'param' },
    attributes  => +{
        properties => [
            +{ isa => $child->c('id') },
            +{ isa => $child->c('parent_id') },
            +{
                isa    => $mapper->relation( belongs_to => 'MyTest023::Parent' ),
                name => 'parent',
            }
        ]
    },
);

{
    my $session = $mapper->begin_session;
    ok my $parent = $session->get( 'MyTest023::Parent' => 1 );
    is $parent->id, 1;
    ok my $children = $parent->children;
    is @$children, 5;
    my $loop_cnt = 5;
    for my $c ( @$children ) {
        is $c->param('id'), $loop_cnt--;
        is $c->param('parent_id'), 1;
        is $c->param('parent')->id, 1;
    }
};

{
    my $session = $mapper->begin_session;
    ok my $parent = $session->get(
        'MyTest023::Parent' => 1,
        { eagerload => 'children' },
    );

    is $parent->id, 1;
    ok my $children = $parent->children;
    is @$children, 5;
    my $loop_cnt = 5;
    for my $c ( @$children ) {
        $loop_cnt--;
        is $c->param('parent_id'), 1;
        is $c->param('parent')->id, 1;
    }
    is $loop_cnt, 0;
};

{
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest023::Parent');
    my $it = $session->search('MyTest023::Parent')
        ->filter( $attr->p('children.parent_id') == 1 )->execute;
    is $it->next->id, 1;
    ok !$it->next;
};

done_testing;
