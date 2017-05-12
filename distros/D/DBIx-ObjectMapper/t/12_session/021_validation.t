use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{CREATE TABLE parent (id integer primary key, name text)},
        q{CREATE TABLE child (id integer primary key, parent_id integer REFERENCES parent(id))},
        q{CREATE TABLE has_one ( id integer primary key, memo text ) },
    ],
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );

$mapper->metadata->table(
    'parent' => 'autoload',
    { validation => { name => sub{ $_[0] && $_[0] =~ /^[a-z]+$/ } } }
);

$mapper->metadata->table( 'child' => 'autoload' );
$mapper->metadata->table( 'has_one' => 'autoload' );


{
    package MyTest21::Parent;

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

    sub name {
        my $self = shift;
        $self->{name} = shift if @_;
        return $self->{name};
    }

    sub children {
        my $self = shift;
        if( @_ ) {
            $self->{children} = shift;
        }
        $self->{children};
    }

    sub has_one {
        my $self = shift;
        if( @_ ) {
            $self->{has_one} = shift;
        }
        $self->{has_one};
    }

    1;
};

{
    package MyTest21::Child;

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
        $self->{parent};
    }

    1;
};

{
    package MyTest21::HasOne;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my %param = @_ % 2 == 0 ? @_ : %{$_[0]};
        my $self = bless \%param, $class;
        return $self;
    }

    sub id {
        my $self = shift;
        $self->{id} = shift if @_;
        return $self->{id};
    }

    sub memo {
        my $self = shift;
        $self->{memo} = shift if @_;
        return $self->{memo};
    }

    sub parent {
        my $self = shift;
        if( @_ ) {
            $self->{parent} = shift;
        }
        $self->{parent};
    }

    1;
};

my $parent_mapper = $mapper->maps(
    $mapper->metadata->t('parent') => 'MyTest21::Parent',
    attributes => {
        properties => {
            children => {
                isa => $mapper->relation(
                    has_many => 'MyTest21::Child',
                    { cascade => 'save_update' }
                ),
                validation => 1,
            },
            has_one => {
                isa => $mapper->relation(
                    has_one => 'MyTest21::HasOne',
                    { cascade => 'save_update' }
                ),
                validation => 1,
            },
            id => { validation => 1 },
            name => { validation => 1 },
        }
    }
);

ok $parent_mapper->attributes->property('children')->is_cascade_save_update, 'only cascade save_update';
ok $parent_mapper->attributes->property('children')->validation, 'set validation option';

$mapper->maps(
    $mapper->metadata->t('child') => 'MyTest21::Child',
    attributes => {
        properties => {
            parent => {
                isa => $mapper->relation(
                    belongs_to => 'MyTest21::Parent',
                    { cascade => 'save_update' }
                ),
                validation => 1,
            },
        }
    }
);


$mapper->maps(
    $mapper->metadata->t('has_one') => 'MyTest21::HasOne',
    attributes => {
        properties => {
            parent => {
                isa => $mapper->relation( has_one => 'MyTest21::Parent' ),
                validation => 1,
            },
            memo => { validation => 1 },
        }
    }
);

{
    my $session = $mapper->begin_session;

    my $parent = MyTest21::Parent->new( id => 1 );
    $session->add($parent);

    ok $parent->name('abcdef'),'set parent.name ok';
    dies_ok { $parent->name(123) } 'validation failed parent.name';
    dies_ok { $parent->name('abc-efg') } 'validation failed parent.name2';

    dies_ok { $parent->children(1) } 'validation failed parent.children';
    dies_ok { $parent->children([qw(a b c)]) } 'validation failed parent.children2';
    my @children = map { MyTest21::Child->new( parent_id => 1 ) } ( 1 .. 5 );
    ok $parent->children(\@children);

    dies_ok { $parent->has_one( 'a' ) } 'validation failed prent.has_one';
    dies_ok { $parent->has_one( ['a'] ) } 'validation failed prent.has_one2';
    ok $parent->has_one( MyTest21::HasOne->new( memo => 'memo' ) );
};

{
    my $session = $mapper->begin_session;
    ok my $parent = $session->get( 'MyTest21::Parent' => 1 );
    is $parent->name, 'abcdef';
    ok @{$parent->children} == 5;
    ok $parent->has_one;
};

{
    my $session = $mapper->begin_session;
    my $has_one = MyTest21::HasOne->new( memo => 'hoge' );
    $session->add($has_one);
    $session->flush;

    ok my $r = $session->get( 'MyTest21::HasOne' => 2 );
    is $r->memo, 'hoge';
};

done_testing;
