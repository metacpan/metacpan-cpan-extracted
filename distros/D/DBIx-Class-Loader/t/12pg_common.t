use strict;
use lib qw( . ./t );
use dbixcl_common_tests;

my $database = $ENV{PG_NAME} || '';
my $user     = $ENV{PG_USER} || '';
my $password = $ENV{PG_PASS} || '';

my $tester = dbixcl_common_tests->new(
    vendor      => 'Pg',
    auto_inc_pk => 'SERIAL NOT NULL PRIMARY KEY',
    dsn         => "dbi:Pg:dbname=$database",
    user        => $user,
    password    => $password,
);

if( !$database || !$user ) {
    $tester->skip_tests('You need to set the PG_NAME, PG_USER and PG_PASS environment variables');
}
else {
    $tester->run_tests();
}
