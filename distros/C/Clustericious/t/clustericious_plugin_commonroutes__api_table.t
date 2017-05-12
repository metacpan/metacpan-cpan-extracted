use strict;
use warnings;
use Test::Clustericious::Cluster 0.26;
use Test::More;
use File::Find qw( find );
use File::Basename qw( dirname );
use Clustericious::Plugin::CommonRoutes ();

plan skip_all => 'requires Rose::Planter 0.34 and DBD::SQLite: '
  unless eval q{ use Rose::Planter 0.34 (); use DBD::SQLite (); 1 };

plan tests => 43;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('SomeService');
my $t = $cluster->t;

$t->get_ok("/api")
  ->status_is(200);

$t->get_ok("/api/bogus_table")
  ->status_is(404);

$t->get_ok("/api/person")
  ->status_is(200)
  ->json_is("/columns/first_name/not_null", 1)
  ->json_is("/columns/first_name/rose_db_type", "varchar")
  ->json_is("/columns/first_name/type", "string")
  ->json_is("/columns/id/not_null", 0)
  ->json_is("/columns/id/rose_db_type", "integer")
  ->json_is("/columns/id/type", "integer")
  ->json_is("/columns/last_name/not_null", 0)
  ->json_is("/columns/last_name/rose_db_type", "varchar")
  ->json_is("/columns/last_name/type", "string")
  ->json_is("/primary_key/0", "id");

find(
    {
        wanted => sub {
            my $name = $File::Find::name;
            return if -d $name || $name =~ /^\./;
            $name =~ s{^.*(Rose/DB/Object/Metadata/Column/.*?\.pm)$}{$1};
            eval qq{ require '$name'; };
            my $class = $name;
            $class =~ s{/}{::}g;
            $class =~ s/\.pm$//;
            return if $class =~ /^Rose::DB::Object::Metadata::Column::(Array|Scalar)$/;
            return if Clustericious::Plugin::CommonRoutes->_dump_api_table_types($class->type) ne 'unknown';
            diag "not sure about type for $class";
        },
        no_chdir => 1,
    },
    dirname($INC{'Rose/DB/Object/Metadata/Column.pm'}) . "/Column",
);

foreach my $type (qw( character text varchar ))
{
  is(Clustericious::Plugin::CommonRoutes->_dump_api_table_types($type), 'string', "$type = string");
}

foreach my $type ('numeric', 'float', 'double precision', 'decimal')
{
  is(Clustericious::Plugin::CommonRoutes->_dump_api_table_types($type), 'numeric', "$type = numeric");
}

foreach my $type (qw( blob set time interval enum datetime bytea chkpass bitfield date boolean ))
{
  is(Clustericious::Plugin::CommonRoutes->_dump_api_table_types($type), $type, "$type = $type");
}

foreach my $type (qw( bigint integer bigserial serial ))
{
  is(Clustericious::Plugin::CommonRoutes->_dump_api_table_types($type), 'integer', "$type = integer");
}

foreach my $type ('epoch', 'epoch hires')
{
  is(Clustericious::Plugin::CommonRoutes->_dump_api_table_types($type), 'epoch', "$type = epoch");
}

foreach my $type ('timestamp', 'timestamp with time zone')
{
  is(Clustericious::Plugin::CommonRoutes->_dump_api_table_types($type), 'timestamp', "$type = timestamp");
}

__DATA__


@@ etc/SomeService.conf
---
url: <%= cluster->url %>
db:
  database: <%= home %>/database.sqlite
  driver: SQLite


@@ lib/SomeService.pm
package SomeService;

use strict;
use warnings;
use SomeService::DB;
use Capture::Tiny qw( capture_stderr );

BEGIN {
  capture_stderr {
    Rose::Planter->plant(
      "SomeService::Objects" => File::Spec->catfile(File::HomeDir->my_home, qw( lib SomeService Objects autolib)));
  };
}


use SomeService::Objects;
use SomeService::Routes;

our $VERSION = '1.0';
use base 'Clustericious::App';

1;



@@ lib/SomeService/DB.pm
package SomeService::DB;

use strict;
use warnings;
use File::HomeDir;
use base qw( Rose::Planter::DB );
use Clustericious::Config;
use DBI;
use File::HomeDir;
use Test::More;

my $home = File::HomeDir->my_home;
my $db_filename = "$home/database.sqlite";
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_filename", '', '', { RaiseError => 1, AutoCommit => 1 });

$dbh->do(q{create table person (
  id integer primary key,
  first_name varchar not null,
  last_name varchar
)});

$dbh->do(q{create table employer (
  id integer primary key,
  name varchar not null,
  tax_id integer
)});

$dbh->do(q{ create table employment_contract (
  id integer primary key,
  person_id integer,
  employer_id integer,
  text terms
)});

undef $dbh;

__PACKAGE__->register_databases(
  module_name => 'SomeService',
  conf => Clustericious::Config->new('SomeService'),
);

1;



@@ lib/SomeService/Objects.pm
package SomeService::Objects;

use strict;
use warnings;
use File::HomeDir;
use File::Spec;
use Rose::Planter
    loader_params => {
        class_prefix => 'SomeService::Object',
        db_class     => 'SomeService::DB',
    },
    convention_manager_params => {};
;

1;



@@ lib/SomeService/Routes.pm
package SomeService::Routes;

use strict;
use warnings;
use Clustericious::RouteBuilder;
use Clustericious::RouteBuilder::CRUD
    create   => { -as => "do_create" },
    read     => { -as => "do_read" }, 
    delete   => { -as => "do_delete" }, 
    update   => { -as => "do_update" }, 
    list     => { -as => "do_list" }, 
    defaults => { finder => "Rose::Planter" };
use Clustericious::RouteBuilder::Search
    search   => { -as => "do_search" },
    defaults => { finder => "Rose::Planter" };

get '/' => sub { shift->render(text => "hello"); };

post  '/:items/search' => \&do_search;
get   '/:items/search' => \&do_search;
post  '/:table'        => [ table => Rose::Planter->regex_for_tables ] => \&do_create;
get   '/:table/*key'   => [ table => Rose::Planter->regex_for_tables ] => \&do_read;
post  '/:table/*key'   => [ table => Rose::Planter->regex_for_tables ] => \&do_update;
del   '/:table/*key'   => [ table => Rose::Planter->regex_for_tables ] => \&do_delete;
get   '/:table'        => [ table => Rose::Planter->regex_for_tables ] => \&do_list;

1;
