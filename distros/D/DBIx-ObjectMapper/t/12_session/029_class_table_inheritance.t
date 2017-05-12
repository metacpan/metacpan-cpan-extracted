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
            q{CREATE TABLE employee(id integer primary key, type text)},
            q{CREATE TABLE engineer(id integer primary key, language text, FOREIGN KEY(id) REFERENCES person(id))},
            q{CREATE TABLE manager(id integer primary key, golf_swing text, FOREIGN KEY(id) REFERENCES person(id))},
        ],
    }),
);

my $person = $mapper->metadata->t( 'employee' => 'autoload' );
my $engineer = $mapper->metadata->t( 'engineer' => 'autoload' );
my $manager = $mapper->metadata->t( 'manager' => 'autoload' );

{
    package My::Employee;

    sub new {
        my $class = shift;
        my $attr = shift;
        bless $attr, $class;
    }

    sub id {
        my $self = shift;
        $self->{id} = shift if @_;
        return $self->{id};
    }

    1;
};

{
    package My::Engineer;
    use base qw(My::Employee);

    sub language {
        my $self = shift;
        $self->{language} = shift if @_;
        return $self->{language};
    }

    1;
};

{
    package My::Manager;
    use base qw(My::Employee);

    sub golf_swing {
        my $self = shift;
        $self->{golf_swing} = shift if @_;
        return $self->{golf_swing};
    }

    1;
};

$mapper->maps(
    $person => 'My::Employee',
    polymorphic_on => 'type',
    attributes => {
        exclude => ['type'],
    }
);

my $engineer_map = $mapper->maps(
    $engineer => 'My::Engineer',
    polymorphic_identity => 'engineer',
    inherits => 'My::Employee',
);

$mapper->maps(
    $manager => 'My::Manager',
    polymorphic_identity => 'manager',
    inherits => 'My::Employee',
);

my @languages = (
    'java',
    'C/C++',
    'C#',
    'Perl',
    'Python',
    'Ruby',
    'Visual Basic',
    'Visual C++',
    'Visual C#',
    'Delphi'
);

my @golf_swings = (
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    1000
);

my $session = $mapper->begin_session;

my @persons = ();
for my $i ( 1 .. 10 ) {
    push @persons, My::Employee->new({ id => $i });
}

for my $i ( 1 .. 10 ) {
    push @persons, My::Engineer->new({
        language => $languages[$i - 1]
    });
}

for my $i ( 1 .. 10 ) {
    push @persons, My::Manager->new({
        golf_swing => $golf_swings[$i - 1]
    });
}

for my $person ( @persons ) {
    $session->add($person);
    $session->commit();
}

is @{$session->search('My::Employee')->execute}, 30;
is @{$session->search('My::Engineer')->execute}, 10;
is @{$session->search('My::Manager')->execute}, 10;

ok !$session->get('My::Engineer' => 1 );
ok my $e = $session->get('My::Engineer' => 11 );
$e->language('Java');
$e->id('10000');
$session->commit;

my $attr = $mapper->attribute('My::Engineer');
my $perl_monk = $session->search('My::Engineer')->filter(
    $attr->p('language') == 'Perl',
)->execute;

while( my $p = $perl_monk->next ) {
    is $p->language, 'Perl';
}


my $it = $session->search('My::Employee')->with_polymorphic('*')->execute;
my %result;
while( my $e = $it->next ) {
    $result{ref($e)}++;
    if( ref($e) eq 'My::Employee' ) {
        ok $e->id <= 10;
    }
    elsif( ref($e) eq 'My::Engineer' ) {
        ok $e->language;
    }
    elsif( ref($e) eq 'My::Manager' ) {
        ok $e->golf_swing;
    }
}

is $result{'My::Employee'}, 10;
is $result{'My::Engineer'}, 10;
is $result{'My::Manager'}, 10;

my $managers = $session->search('My::Manager')->execute;
while( my $m = $managers->next ) {
    $session->delete($m);
}

my $emp = $session->search('My::Employee')->execute;
while( my $m = $emp->next ) {
    $session->delete($m);
}

$session->commit;

is $session->search('My::Employee')->count, 0;
is $session->search('My::Manager')->count, 0;
is $session->search('My::Engineer')->count, 0;

done_testing;
