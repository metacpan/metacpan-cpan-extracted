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

my ($dsn, $user, $pass) = @ENV{map { "MAPPER_TEST_MYSQL_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{MAPPER_TEST_MYSQL_DSN}, _USER and _PASS to run this test.' unless ($dsn && $user);

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => $dsn,
    username => $user,
    password => $pass,
    on_connect_do => [
        q{
CREATE TABLE test_types (
  id INTEGER AUTO_INCREMENT PRIMARY KEY,
  tint TINYINT,
  sint SMALLINT,
  mint MEDIUMINT,
  i    INT,
  bint BIGINT,
  num  NUMERIC(10,2),
  f    FLOAT(5,4),
  d    DOUBLE(5,4),
  deci DECIMAL(10,2),
  bool BOOLEAN,
  photo BLOB,
  bit BIT(2),
  lblob LONGBLOB,
  created TIMESTAMP(0) DEFAULT NOW(),
  modified TIMESTAMP,
  dt DATE,
  tm TIME
) type=InnoDB

}
    ],
    on_disconnect_do => q{DROP TABLE test_types},
    time_zone => 'Asia/Tokyo',
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
$mapper->metadata->autoload_all_tables;
my $table = $mapper->metadata->t( 'test_types' );
my $GIF = 'R0lGODlhAQABAJEAAAAAAP///////wAAACH5BAUUAAIALAAAAAABAAEAAAICVAEAOw==
';
my $now = DateTime->now( time_zone => 'UTC' );


is $table->c('id')->type->type, 'int';
is $table->c('tint')->type->type, 'smallint';
is $table->c('sint')->type->type, 'smallint';
is $table->c('mint')->type->type, 'int';
is $table->c('i')->type->type, 'int';
is $table->c('bint')->type->type, 'bigint';
is $table->c('num')->type->type, 'numeric';
is $table->c('f')->type->type, 'float';
is $table->c('d')->type->type, 'float';
is $table->c('deci')->type->type, 'numeric';
is $table->c('bool')->type->type, 'smallint'; # ???
is $table->c('photo')->type->type, 'binary';
is $table->c('bit')->type->type, 'bit';
is $table->c('lblob')->type->type, 'binary';
is $table->c('created')->type->type, 'datetime';
is $table->c('modified')->type->type, 'datetime';
is $table->c('dt')->type->type, 'date';
is $table->c('tm')->type->type, 'time';


{
    my $r = $table->insert(
        tint => 1,
        sint => 100,
        mint => 10000,
        i    => 2,
        bint => 1000000000,

        num  => 0.202927272,
        f    => 0.202927272,
        d    => 0.202927272,
        deci => 20,

        bool  => 0,
        photo => MIME::Base64::decode($GIF),
        lblob => MIME::Base64::decode($GIF),
        bit   => '11',

        dt => $now,
        tm => $now,
    )->execute;

    # check last_insert_id
    is $r->{id}, 1;
};


{ # find
    ok my $d = $table->find(1);

    TODO : {
        todo_skip 'bit type' => 1;
        ok $d->{bit}->to_Hex == 3, $d->{bit}->to_Hex;
    };

    is MIME::Base64::encode($d->{photo}), $GIF;
    is MIME::Base64::encode($d->{lblob}), $GIF;

    is ref($d->{created}), 'DateTime';
    is $d->{created}->time_zone->name, 'Asia/Tokyo';
    ok !$d->{created}->time_zone->is_utc;
    is $d->{created}->time_zone->offset_for_datetime($now), 9*60*60;

    ok !$d->{modified};
    is $d->{dt}->ymd('-'), $now->ymd('-');
    is $d->{tm}->hms(':'), $now->hms(':');

    ok $d->{tint} == 1;
    ok $d->{sint} == 100;
    ok $d->{mint} == 10000;
    ok $d->{i} == 2;
    ok $d->{bint} == 1000000000;

    ok $d->{num} == 0.20;
    ok $d->{f} == 0.2029;
    ok $d->{d} == 0.2029;
    ok $d->{deci} == 20.00;
    ok !$d->{bool};

};

TODO: { # search by bit
    todo_skip 'bit type' => 2;
    ok my $d = $table->select->where(
        $table->c('bit') == Bit::Vector->new_Hex(2,3),
    )->first;

    is $d->{id}, 1;
};

{ # search by binary
    ok my $d = $table->select->where(
        $table->c('photo') == MIME::Base64::decode($GIF),
    )->first;
    is $d->{id}, 1;
};

{ # search by date
    ok my $d = $table->select->where(
        $table->c('dt') == $now,
    )->first;
    is $d->{id}, 1;
};

{ # search by time
    ok my $d = $table->select->where(
        $table->c('tm') == $now,
    )->first;
    is $d->{id}, 1;
};

{ # update
    ok $table->update->set( modified => $now )->where( $table->c('id') == 1 )->execute;
    my $d = $table->find(1);
    is $d->{modified}, $now;
};

{ # limit, offset
    ok my $r = $table->select->limit(1)->offset(0)->execute;
    is $r->first->{id}, 1;
};

$mapper->maps(
    $table => 'My::MySQLTest',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
);

{ # transaction rollback
    my $session = $mapper->begin_session( autocommit => 0 );
    $session->add( My::MySQLTest->new( i => 10 ) );
    $session->rollback;
};

{ # check
    my $session = $mapper->begin_session( autocommit => 0 );
    my $attr = $mapper->attribute('My::MySQLTest');
    is $session->search('My::MySQLTest')->filter( $attr->p('i') == 10 )->count, 0;
};

{ # transaction commit
    my $session = $mapper->begin_session( autocommit => 0 );
    $session->add( My::MySQLTest->new( i => 10 ) );
    $session->commit;
};

{ # check
    my $session = $mapper->begin_session( autocommit => 0 );
    my $attr = $mapper->attribute('My::MySQLTest');
    is $session->search('My::MySQLTest')->filter( $attr->p('i') == 10 )->count, 1;
};


{ # savepoint
    my $session = $mapper->begin_session( autocommit => 0 );
    $session->add( My::MySQLTest->new( i => 11 ) );
    eval {
        $session->txn(
            sub {
                $session->add( My::MySQLTest->new( id => 1, i => 11 ) );
                $session->commit;
            }
        );
    };
    ok $@;
    $session->add( My::MySQLTest->new( i => 11 ) );
    $session->commit;
};

{
    my $session = $mapper->begin_session( autocommit => 0 );
    my $attr = $mapper->attribute('My::MySQLTest');
    is $session->search('My::MySQLTest')->filter( $attr->p('i') == 11 )->count, 2;
};

done_testing;
