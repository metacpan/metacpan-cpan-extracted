use strict;
use warnings;
use Test::More;
use MIME::Base64;
use DateTime;
use DateTime::Duration;
use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper;

BEGIN {
    eval "use Bit::Vector";
    plan skip_all => 'need Bit::Vector this test' if $@;
};

my ($dsn, $user, $pass) = @ENV{map { "MAPPER_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{MAPPER_TEST_PG_DSN}, _USER and _PASS to run this test' unless ($dsn && $user);


my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => $dsn,
    username => $user,
    password => $pass,
    on_connect_do => [
        q{
CREATE TABLE test.test_types (
  id SERIAL PRIMARY KEY,
  i integer,
  array_int integer[],
  array_2d_text text[][],
  bit BIT(2),
  created TIMESTAMP(0) WITHOUT TIME ZONE DEFAULT NOW(),
  modified TIMESTAMP,
  photo bytea,
  d DATE,
  t TIME,
  intvl INTERVAL
)
},
    ],
    on_disconnect_do => q{DROP TABLE test_types},
    time_zone => 'Asia/Tokyo',
    db_schema => 'test',
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
$mapper->metadata->autoload_all_tables;
my $table = $mapper->metadata->t( 'test_types' );

my $GIF = 'R0lGODlhAQABAJEAAAAAAP///////wAAACH5BAUUAAIALAAAAAABAAEAAAICVAEAOw==
';
my $now = DateTime->now( time_zone => 'UTC' );
my $duration = DateTime::Duration->new(
    years   => 3,
    months  => 5,
    weeks   => 1,
    days    => 1,
    hours   => 6,
    minutes => 15,
    seconds => 45,
    nanoseconds => 12000
);

$table->insert(
    array_int => [ 1, 2, 3, 4 ],
    array_2d_text => [ [qw(a b c c)], [qw(e f g h)] ],
    bit => '11',
    photo => MIME::Base64::decode($GIF),
    d     => $now,
    t     => $now,
    intvl => $duration,
)->execute;


{ # find
    ok my $d = $table->find(1);
    is_deeply $d->{array_int}, [ 1, 2, 3, 4 ];
    is_deeply $d->{array_2d_text}, [ [qw(a b c c)], [qw(e f g h)] ];
    is $d->{bit}->to_Hex, 3;
    is MIME::Base64::encode($d->{photo}), $GIF;

    is ref($d->{created}), 'DateTime';
    is $d->{created}->time_zone->name, 'Asia/Tokyo';
    ok !$d->{created}->time_zone->is_utc;
    is $d->{created}->time_zone->offset_for_datetime($now), 9*60*60;

    ok !$d->{modified};
    is $d->{d}->ymd('-'), $now->ymd('-');
    is $d->{t}->hms(':'), $now->hms(':');
    is $d->{intvl}->years, 3;
    is $d->{intvl}->months, 5;
    is $d->{intvl}->weeks, 1;
    is $d->{intvl}->days, 1;
    is $d->{intvl}->minutes, 15;
    is $d->{intvl}->seconds, 45;
    is $d->{intvl}->nanoseconds, 12000;
};

{ # search by array
    ok my $d
        = $table->select->where( $table->c('array_int') == \[ 1, 2, 3, 4 ] )
        ->first;
    is $d->{id}, 1;
};

{ # search by array2d
    ok my $d = $table->select->where(
        $table->c('array_2d_text') == \[ [qw(a b c c)], [qw(e f g h)] ],
    )->first;
    is $d->{id}, 1;
};

{ # search by bit
    ok my $d = $table->select->where(
        $table->c('bit') == Bit::Vector->new_Hex(2,3),
    )->first;

    is $d->{id}, 1;
};

{ # search by bytea
    ok my $d = $table->select->where(
        $table->c('photo') == MIME::Base64::decode($GIF),
    )->first;
    is $d->{id}, 1;
};

{ # search by date
    ok my $d = $table->select->where(
        $table->c('d') == $now,
    )->first;
    is $d->{id}, 1;
};

{ # search by time
    ok my $d = $table->select->where(
        $table->c('t') == $now,
    )->first;
    is $d->{id}, 1;
};

{ # search by duration
    ok my $d = $table->select->where(
        $table->c('intvl') > DateTime::Duration->new(
            years => 3
        ),
    )->first;
    is $d->{id}, 1;

};

{ # update
    ok $table->update->set( modified => $now )->where( $table->c('id') == 1 )->execute;
    my $d = $table->find(1);
    is $d->{modified}, $now;
};

$mapper->maps(
    $table => 'My::PgTest',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
);

{ # transaction rollback
    my $session = $mapper->begin_session( autocommit => 0 );
    $session->add( My::PgTest->new( i => 10 ) );
    $session->rollback;
};

{ # check
    my $session = $mapper->begin_session( autocommit => 0 );
    my $attr = $mapper->attribute('My::PgTest');
    is $session->search('My::PgTest')->filter( $attr->p('i') == 10 )->count, 0;
};

{ # transaction commit
    my $session = $mapper->begin_session( autocommit => 0 );
    $session->add( My::PgTest->new( i => 10 ) );
    $session->commit;
};

{ # check
    my $session = $mapper->begin_session( autocommit => 0 );
    my $attr = $mapper->attribute('My::PgTest');
    is $session->search('My::PgTest')->filter( $attr->p('i') == 10 )->count, 1;
};


{ # savepoint
    my $session = $mapper->begin_session( autocommit => 0 );
    $session->add( My::PgTest->new( i => 11 ) );
    eval {
        $session->txn(
            sub {
                $session->add( My::PgTest->new( id => 1, i => 11 ) );
                $session->commit;
            }
        );
    };
    ok $@;
    $session->add( My::PgTest->new( i => 11 ) );
    $session->commit;
};

{
    my $session = $mapper->begin_session( autocommit => 0 );
    my $attr = $mapper->attribute('My::PgTest');
    is $session->search('My::PgTest')->filter( $attr->p('i') == 11 )->count, 2;
};



done_testing;
