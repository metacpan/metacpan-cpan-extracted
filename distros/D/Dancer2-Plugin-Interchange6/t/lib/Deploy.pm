package Deploy;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Dancer2 '!pass', appname => 'TestApp';
use Dancer2::Plugin::DBIC;

sub deploy {
    diag "Deploy";

    my $dsn = shift;
    my $config = config;
    $config->{plugins}->{DBIC}->{default}->{dsn} = $dsn;
    $config->{plugins}->{DBIC}->{shop2}->{dsn}   = $dsn;

    my $schema = schema;

    lives_ok { $schema->deploy } "schema->deploy lives";
    my $fixtures = Fixtures->new( ic6s_schema => schema );
    lives_ok { $fixtures->load_all_fixtures } "load_all_fixtures lives";
}

1;
