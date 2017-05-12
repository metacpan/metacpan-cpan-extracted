use strict;
use warnings;
use Test::More;
use MIME::Base64;
use DateTime;
use DateTime::Duration;
use Storable;
use YAML;
use URI;
use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Metadata::Sugar qw(:all);

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    on_connect_do => [
        q{
CREATE TABLE test_types (
  id INTEGER PRIMARY KEY,
  created DATETIME,
  photo BLOB,
  num NUMERIC(10,5),
  float REAL,
  storable TEXT,
  yaml TEXT,
  uri  TEXT
)
},
    ]
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
my $table = $mapper->metadata->table(
    test_types => [
        Col( storable => Mush() ),
        Col( yaml => Yaml() ),
        Col( uri => Uri() ),
    ],
    { 'autoload' => 1 },
);
my $GIF = 'R0lGODlhAQABAJEAAAAAAP///////wAAACH5BAUUAAIALAAAAAABAAEAAAICVAEAOw==
';
my $now = DateTime->now;

$table->insert(
    created => $now,
    photo => MIME::Base64::decode($GIF),
    num => 10.276529,
    float => 0.92819092,
    storable => { a => 1, b => 2, c => 3 },
    yaml => [ qw(perl python ruby)],
    uri => URI->new('http://example.com/path/to/index.html?a=1&b=2'),
)->execute;


{ # find
    ok my $d = $table->find(1);
    is ref($d->{created}), 'DateTime';
    is $d->{created}, $now;
    is MIME::Base64::encode($d->{photo}), $GIF;
    is $d->{num},  10.276529;

    is int( $d->{float} * 100000000 ), 92819092;

    is_deeply $d->{storable}, { a => 1, b => 2, c => 3 };
    is_deeply $d->{yaml}, [ qw(perl python ruby) ];
    is ref($d->{uri}), 'URI::http';
    is $d->{uri}, 'http://example.com/path/to/index.html?a=1&b=2';
};

{ # search by blob
    ok my $d = $table->select->where(
        $table->c('photo') == MIME::Base64::decode($GIF),
    )->first;
    is $d->{id}, 1;
};

{ # search by datetime
    ok my $d = $table->select->where(
        $table->c('created') == $now,
    )->first;
    is $d->{id}, 1;
};

{ # search by storable
    ok my $d = $table->select->where(
        $table->c('storable') == { a => 1, b => 2, c => 3 },
    )->first;
    is $d->{id}, 1;
};

{ # search by yaml
    ok my $d = $table->select->where(
        $table->c('yaml') == \[ qw(perl python ruby)],
    )->first;
    is $d->{id}, 1;
};

{ # search by uri
    ok my $d = $table->select->where(
        $table->c('uri') == URI->new('http://example.com/path/to/index.html?a=1&b=2'),
    )->first;
    is $d->{id}, 1;
};

{ # update
    $now->add( days => 1 );
    ok $table->update->set( created => $now )->where( $table->c('id') == 1 )->execute;
    my $d = $table->find(1);
    is $d->{created}, $now;
};

done_testing;

