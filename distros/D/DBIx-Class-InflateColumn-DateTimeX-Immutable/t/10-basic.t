use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Schema;
use DateTimeX::Immutable;

my $schema = Test::Schema->connect( 'dbi:SQLite:dbname=:memory:', '', '' );
$schema->deploy;
my $rs = $schema->resultset('Example');

{
    my $result = $rs->create( {
            id => 1,
            dt => DateTimeX::Immutable->new(
                year      => '2014',
                month     => '12',
                day       => '19',
                hour      => '10',
                minute    => 0,
                second    => 0,
                time_zone => 'America/New_York',
            ) } );

    isa_ok $result, 'Test::Schema::Result::Example';
    isa_ok $result->dt, 'DateTimeX::Immutable';
    is $result->dt->st, '2014-12-19T10:00:00EST', '... correct date';
    undef $result;

    my $retrieved = $rs->find(1);
    isa_ok $retrieved, 'Test::Schema::Result::Example';
    isa_ok $retrieved->dt, 'DateTimeX::Immutable';
    is $retrieved->dt->st, '2014-12-19T15:00:00UTC', '... correct date';
}

{
    my $result = $rs->create( {
            id => 2,
            dt => DateTime->new(
                year      => '2014',
                month     => '12',
                day       => '20',
                hour      => '10',
                minute    => 0,
                second    => 0,
                time_zone => 'America/New_York',
            ) } );

    isa_ok $result, 'Test::Schema::Result::Example';
    isa_ok $result->dt, 'DateTime';
    ## is $result->dt->st, '2014-12-19T10:00:00EST', '... correct date';
    undef $result;

    my $retrieved = $rs->find(2);
    isa_ok $retrieved, 'Test::Schema::Result::Example';
    isa_ok $retrieved->dt, 'DateTimeX::Immutable';
    is $retrieved->dt->st, '2014-12-20T15:00:00UTC', '... correct date';
}

done_testing;
