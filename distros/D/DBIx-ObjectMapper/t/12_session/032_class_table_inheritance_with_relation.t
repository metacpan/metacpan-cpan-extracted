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
            q{CREATE TABLE language (id integer primary key, name text)},
            q{CREATE TABLE employee(id integer primary key, type text)},
            q{CREATE TABLE engineer(id integer primary key, language_id integer REFERENCES language(id), FOREIGN KEY(id) REFERENCES person(id))},
        ],
    }),
);

my $person = $mapper->metadata->t( 'employee' => 'autoload' );
my $engineer = $mapper->metadata->t( 'engineer' => 'autoload' );
my $language = $mapper->metadata->t( 'language' => 'autoload' );

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

    sub language_id {
        my $self = shift;
        $self->{language_id} = shift if @_;
        return $self->{language_id};
    }

    sub language {
        my $self = shift;
        $self->{language} = shift if @_;
        return $self->{language};
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

$mapper->maps(
    $language => 'My::Language',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
);

my $engineer_map = $mapper->maps(
    $engineer => 'My::Engineer',
    polymorphic_identity => 'engineer',
    inherits => 'My::Employee',
    attributes => {
        properties => {
            language => {
                isa => $mapper->relation( belongs_to => 'My::Language' ),
            },
        }
    }
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

$language->insert->values( name => $_ )->execute for @languages;

my $session = $mapper->begin_session( autocommit => 0 );
my $lang = $session->get( 'My::Language' => 1 ) || undef;
my $engineer1 = My::Engineer->new({ language => $lang });
ok $session->add($engineer1);
$session->commit;

is $engineer1->language_id, 1;
is $engineer1->language->id, 1;

my $lang2 = $session->get( 'My::Language' => 2 );
$engineer1->language( $lang2 );
$session->commit;

is $engineer1->language_id, 2;
is $engineer1->language->id, 2;

done_testing;
