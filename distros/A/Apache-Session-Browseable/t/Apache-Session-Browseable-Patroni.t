use Test::More;

plan skip_all => "Optional modules (DBD::Pg, DBI) not installed"
  unless eval {
    require DBI;
    require DBD::Pg;
  };

$package = 'Apache::Session::Browseable::Store::Patroni';

use_ok($package);

my $foo = $package->new;

isa_ok $foo, $package;

$package = 'Apache::Session::Browseable::Patroni';
use_ok($package);

SKIP: {
    skip 'No patroniUrl, skipping', 1 unless $ENV{PATRONI_URL};
    my $args = {
        DataSource => 'dbi:Pg:dbname=sessions;host='
          . ( $ENV{PG_HOST} || '127.25.76.98:port=300' ),
        UserName   => 'postgres',
        Password   => 'postgres',
        PatroniUrl => $ENV{PATRONI_URL},
    };

    my %h;
    tie %h, $package, undef, $args;
    ok( %h && $h{_session_id}, 'Hash populated' );
    my $id = $h{_session_id};
    $h{a} = 'aa';
    untie %h;
    %h = ();
    tie %h, $package, $id, $args;
    is( $h{a}, 'aa', 'data stored' );
    untie %h;
    if ($ENV{PATRONI_NEXT}) {
        diag `$ENV{PATRONI_NEXT}`;
        sleep 1;
    }
    tie %h, $package, $id, $args;
    $h{a} = 'bb';
    untie %h;
    %h = ();
    tie %h, $package, $id, $args;
    is( $h{a}, 'bb', 'data changed' );
    untie %h;
}

done_testing();
