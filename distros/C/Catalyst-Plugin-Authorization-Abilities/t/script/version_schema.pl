#!/usr/bin/perl -w
use strict;

BEGIN {
  $ENV{DBIC_OVERWRITE_HELPER_METHODS_OK}=1;
}

use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Schema::Abilities;
use Schema::Utils;


my $sqldir  = "db/sql";
mkdir $sqldir if ( ! -d $sqldir );

my $conf = 'myapp.yml';
my $su = Schema::Utils->new(conf => $conf, ns_conf => 'Authorization::Abilities', debug => 0);


my $version = Schema::Abilities->VERSION;

my $schema  = $su->schema;


$schema->create_ddl_dir(
    ['SQLite', 'MySQL', 'PostgreSQL'],
    $version > 1 ? $version : undef,
    $sqldir,
    $version ? $version-1 : $version
);

print "OK: Schema saved in $sqldir\n";
