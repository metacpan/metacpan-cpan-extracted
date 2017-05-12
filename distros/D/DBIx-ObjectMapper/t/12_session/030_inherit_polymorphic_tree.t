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
            q{CREATE TABLE employee(id integer primary key, type text, name text, memo text)},
            q{CREATE TABLE engineer(id integer primary key, language text, FOREIGN KEY(id) REFERENCES person(id))},
            q{CREATE TABLE manager(id integer primary key, type text, golf_swing text, FOREIGN KEY(id) REFERENCES employee(id))},
            q{CREATE TABLE geek_manager (id integer primary key, language TEXT, memo text, FOREIGN KEY (id) REFERENCES employee(id))},
            q{CREATE TABLE deadshit_manager (id integer primary key, iq integer, memo text, FOREIGN KEY (id) REFERENCES employee(id))},
        ],
    }),
);

$mapper->metadata->autoload_all_tables;

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

    sub name {
        my $self = shift;
        $self->{name} = shift if @_;
        return $self->{name};
    }

    sub t {
        my $self = shift;
        $self->{t} = shift if @_;
        return $self->{t};
    }

    sub memo {
        my $self = shift;
        $self->{memo} = shift if @_;
        return $self->{memo};
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
    package My::Engineer::PerlMonger;
    use base qw(My::Engineer);

    1;
};

{
    package My::Engineer::Pythonista;
    use base qw(My::Engineer);

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

{
    package My::Manager::Geek;
    use base qw(My::Manager);

    sub old_language {
        my $self = shift;
        $self->{old_language} = shift if @_;
        return $self->{old_language};
    }

    sub memo {
        my $self = shift;
        $self->{memo} = shift if @_;
        return $self->{memo};
    }

    1;
};

{
    package My::Manager::Deadshit;
    use base qw(My::Manager);

    sub iq {
        my $self = shift;
        $self->{iq} = shift if @_;
        return $self->{iq};
    }

    1;
};

$mapper->maps(
    $mapper->metadata->t('employee') => 'My::Employee',
    polymorphic_on => 'type',
    attributes => {
        properties => {
            t => { isa => $mapper->metadata->t('employee')->c('type') },
        }
    }
);

$mapper->maps(
    $mapper->metadata->t('engineer') => 'My::Engineer',
    polymorphic_identity => 'engineer',
    inherits => 'My::Employee',
);

$mapper->maps(
    $mapper->metadata->t('engineer') => 'My::Engineer::PerlMonger',
    inherits => 'My::Engineer',
    polymorphic_on => 'language',
    polymorphic_identity => 'Perl',
);

$mapper->maps(
    $mapper->metadata->t('engineer') => 'My::Engineer::Pythonista',
    inherits => 'My::Engineer',
    polymorphic_on => 'language',
    polymorphic_identity => 'Python',
);


$mapper->maps(
    $mapper->metadata->t('manager') => 'My::Manager',
    polymorphic_identity => 'manager',
    inherits => 'My::Employee',
);

# -- memo
# polymorphic_onはカラム名(not 属性名)
#
# さらに多段に継承しているときには
# 親のpolymorphic_onと同じ名前ならそれは同期されるべきで、
# もし別の意味でのカラムなら、別の名前でなくてはいけない。
#

$mapper->maps(
    $mapper->metadata->t('geek_manager') => 'My::Manager::Geek',
    inherits => 'My::Manager',
    polymorphic_on => 'type',
    polymorphic_identity => 'geek_manager',
    attributes => {
        properties => {
            old_language => {
                isa => $mapper->metadata->t('geek_manager')->c('language'),
            }
        }
    }
);

$mapper->maps(
    $mapper->metadata->t('deadshit_manager') => 'My::Manager::Deadshit',
    inherits => 'My::Manager',
    polymorphic_on => 'type',
    polymorphic_identity => 'deadshit_manager',
);

my @languages = (
    'Java',
    'C/C++',
    'C#',
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
);

my $session = $mapper->begin_session;

my @persons = ();
for my $i ( 1 .. 10 ) {
    push @persons, My::Employee->new({ id => $i, name => 'employee' . $i });
}

for my $i ( 1 .. 9 ) {
    push @persons, My::Engineer->new({
        language => $languages[$i - 1],
        name     => 'engineer' . $i,
    });
}

push @persons, My::Engineer::PerlMonger->new({ name => 'perlmonger' });

for my $i ( 1 .. 5 ) {
    push @persons, My::Manager->new({
        golf_swing => $golf_swings[$i - 1],
        name => 'manager' . $i,
    });
}

my @manager_language = (
    'Cobol',
    'Lisp',
    'Algol',
    'Fortran',
    'Pascal',
);

for my $i ( 1 .. 5 ) {
    push @persons, My::Manager::Geek->new({
        golf_swing => $i * 10,
        old_language => $manager_language[$i - 1],
        name => 'geek_manager' . $i,
        memo => 'geek_manager_memo' . $i,
    });
}

for my $i ( 1 .. 5 ) {
    push @persons, My::Manager::Deadshit->new({
        golf_swing => $i * 1000,
        name => 'deadshit_manager' . $i,
        memo => 'deadshit_manager_memo' . $i,
        iq   => 1 * $i,
    });
}

$session->add_all(@persons);
$session->commit();

is $session->search('My::Employee')->count, 35;
is $session->search('My::Engineer')->count, 10;
is $session->search('My::Engineer::PerlMonger')->count, 1;
is $session->search('My::Engineer::Pythonista')->count, 1;
is $session->search('My::Manager')->count, 15;
is $session->search('My::Manager::Geek')->count, 5;
is $session->search('My::Manager::Deadshit')->count, 5;

my $it = $session->search( 'My::Employee' )->with_polymorphic('*')->execute;
my $loop_cnt = 0;
my %classes;
while( my $e = $it->next ) {
    $classes{ref($e)} ||= [];
    push @{$classes{ref($e)}}, $e;
    $loop_cnt++;
}

is $loop_cnt, 35;
is @{$classes{'My::Employee'}}, 10;
is @{$classes{'My::Engineer'}}, 8;
is @{$classes{'My::Engineer::PerlMonger'}}, 1;
is @{$classes{'My::Engineer::Pythonista'}}, 1;
is @{$classes{'My::Manager'}}, 5;
is @{$classes{'My::Manager::Geek'}}, 5;
is @{$classes{'My::Manager::Deadshit'}}, 5;

for my $eng ( @{$classes{'My::Engineer'}} ) {
    ok $eng->language;
}

for my $man ( @{$classes{'My::Manager'}} ) {
    ok $man->golf_swing;
}

is $classes{'My::Engineer::PerlMonger'}->[0]->language, 'Perl';
is $classes{'My::Engineer::Pythonista'}->[0]->language, 'Python';


# 同じ名前のカラムがあるなら
# それは同じ値が格納される geek_manager.memo = employee.memo
my %memo;
for my $geek_m ( @{$classes{'My::Manager::Geek'}} ) {
    ok $geek_m->old_language;
    ok $geek_m->golf_swing;
    ok $geek_m->memo;
    $memo{$geek_m->id} = $geek_m->memo;
}

for my $deadshit ( @{$classes{'My::Manager::Deadshit'}} ) {
    ok $deadshit->iq;
    ok $deadshit->golf_swing;
    ok $deadshit->memo;
    $memo{$deadshit->id} = $deadshit->memo;
}

my $man_attr = $mapper->attribute('My::Manager');
my $it2 = $session->search( 'My::Manager' )->execute;
my $memo_cnt = 0;
while( my $m = $it2->next ) {
    if( $m->memo ) {
        is $memo{$m->id}, $m->memo;
        $memo_cnt++;
    }
}
is $memo_cnt, 10;

my $attr2 = $mapper->attribute('My::Manager::Deadshit');

my $most_deadshit = $session->search('My::Manager::Deadshit')
    ->order_by( $attr2->p('iq') )->first;

$most_deadshit->memo('最もバカ');
$most_deadshit->iq(0);
$most_deadshit->golf_swing(100000);
$most_deadshit->id(100);
$session->commit;

my $check_most_deadshit = $session->search('My::Manager::Deadshit')
    ->filter( $attr2->p('iq') == 0 )->first;
is $check_most_deadshit->id, 100;
is $check_most_deadshit->memo,'最もバカ';
is $check_most_deadshit->iq, 0;

is $check_most_deadshit->golf_swing, 100000;

$session->delete($check_most_deadshit);
$session->commit;

ok !$session->get('My::Manager::Deadshit' => 100 );
ok !$session->get('My::Manager' => 100 );
ok !$session->get('My::Employee' => 100 );

done_testing;
