
use strict;
use warnings;

use Test::More;
use Test::Deep;

use AnyEvent::InfluxDB;
use EV;
use AnyEvent;
use JSON;

my $true = JSON::true;
my $false = JSON::false;

my $db = AnyEvent::InfluxDB->new(
    server => $ENV{INFLUXDB_SERVER} || 'http://127.0.0.1:8086',
    username => 'admin',
    password => 'admin',
);

# random data
my @measurements = qw(cpu_load mem_free cpu_temp disk_free);
my @regions = qw(us-east us-west eu-east eu-east);
my @hosts = map { sprintf('server%02d', $_) } 1 .. 10;
my @fields = map { sprintf('field%02d', $_) } 1 .. 10;
my $_15days_ago = time() - int(15 * 24 * 3600);
my $existing_region;

# common patterns
my $dt_re = re('^\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}Z$');
my $pos_int = code(sub { $_[0] >= 1 });
my $pos_num = code(sub { $_[0] > 0 });

my $cv;
{
    note "=== ping ===";
    $cv = AE::cv;
    $db->ping(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to ping database: @_");
        }
    );
    my $version;
    eval {
     $version = $cv->recv;
    };
    if ( $version ) {
        plan tests => 62;
        ok(1, "Connected to InfluxDB server version $version at: ". $db->server);
    } else {
        plan skip_all => 'InfluxDB server not found at: '. $db->server;
    }
}
{
    note "=== create_database ===";
    $cv = AE::cv;
    $db->create_database(
        q => "CREATE DATABASE mydb",
        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to create database: @_");
        }
    );
    ok($cv->recv, "database mydb created");
}
{
    note "=== create_database ===";
    $cv = AE::cv;
    $db->create_database(
        q => "CREATE DATABASE foo",
        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to create database: @_");
        }
    );
    ok($cv->recv, "database foo created");
}
{
    note "=== show_databases ===";
    $cv = AE::cv;
    $db->show_databases(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list databases: @_");
        }
    );
    my @db_names = $cv->recv;
    Test::More::note "@db_names";
    is_deeply( [ sort @db_names ], [qw( _internal foo mydb )], "databases listed");
}
{
    note "=== create_database ===";
    $cv = AE::cv;
    $db->create_database(
        q => "CREATE DATABASE mydb",
        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to create database: @_");
        }
    );
    ok($cv->recv, "database already exists, but that's ok");
}
{
    note "=== create_retention_policy ===";
    $cv = AE::cv;
    $db->create_retention_policy(
        q => "CREATE RETENTION POLICY last_day ON mydb DURATION 1d REPLICATION 1 SHARD DURATION 12h",

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to create retention policy: @_");
        }
    );
    ok($cv->recv, "rp last_day created");
}
{
    note "=== alter_retention_policy ===";
    $cv = AE::cv;
    $db->alter_retention_policy(
        q => "ALTER RETENTION POLICY last_day ON mydb DURATION 2d REPLICATION 1",

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to alter retention policy: @_");
        }
    );
    ok($cv->recv, "rp last_day altered");
}
{
    note "=== show_retention_policies ===";
    $cv = AE::cv;
    $db->show_retention_policies(
        q => "SHOW RETENTION POLICIES ON mydb",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list retention policies: @_");
        }
    );
    my @retention_policies = $cv->recv;
    is_deeply(
        [ @retention_policies ],
        [
            { name => "autogen", duration => 0, shardGroupDuration => '168h0m0s', replicaN => 1, default => $true },
            { name => "last_day", duration => "48h0m0s", shardGroupDuration => '12h0m0s', replicaN => 1, default => $false },
        ],
        "Retention policies listed"
    );
    for my $rp ( @retention_policies ) {
        note "Name: $rp->{name}";
        note "Duration: $rp->{duration}";
        note "Replication factor: $rp->{replicaN}";
        note "Default?: $rp->{default}";
    }
}
{
    note "=== drop_retention_policy ===";

    $cv = AE::cv;
    $db->drop_retention_policy(
        q => "DROP RETENTION POLICY last_day ON mydb",

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to drop continuous query: @_");
        }
    );
    ok($cv->recv, "rp last_day dropped");
}
{
    note "=== create_continuous_query ===";
    $cv = AE::cv;
    $db->create_continuous_query(
        q => 'CREATE CONTINUOUS QUERY per5minutes ON mydb'
            .' RESAMPLE EVERY 10s FOR 10m'
            .' BEGIN'
            .' SELECT MEAN(value) INTO "cpu_load_per5m" FROM cpu_load GROUP BY time(5m)'
            .' END',

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to create continuous query: @_");
        }
    );
    ok($cv->recv, "cq per5minutes created");
}
{
    note "=== show_continuous_queries ===";
    $cv = AE::cv;
    $db->show_continuous_queries(
        database => 'mydb',

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list continuous queries: @_");
        }
    );
    note "show_continuous_queries";
    my $continuous_queries = $cv->recv;
    is_deeply( $continuous_queries,
        {
            _internal => [],
            foo => [],
            mydb => [
                {
                    name => 'per5minutes',
                    query => 'CREATE CONTINUOUS QUERY per5minutes ON mydb'
                        .' RESAMPLE EVERY 10s FOR 10m BEGIN'
                        .' SELECT mean(value) INTO mydb.autogen.cpu_load_per5m'
                        .' FROM mydb.autogen.cpu_load GROUP BY time(5m) END',
                }
            ]
        },
        "cqs listed"
    );
    for my $database ( sort keys %{ $continuous_queries } ) {
        note "Database: $database";
        for my $s ( @{ $continuous_queries->{$database} } ) {
            note " Name: $s->{name}";
            note " Query: $s->{query}";
        }
    }
}
{
    note "=== drop_continuous_query ===";

    $cv = AE::cv;
    $db->drop_continuous_query(
        q => 'DROP CONTINUOUS QUERY per5minutes ON mydb',

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to drop continuous query: @_");
        }
    );
    ok($cv->recv, "cq per5minutes dropped");

}
{
    note "=== create_user ===";

    $cv = AE::cv;
    $db->create_user(
        q => "CREATE USER jdoe WITH PASSWORD 'mypassword'",

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to create user: @_");
        }
    );
    ok($cv->recv, "user created");

}
{
    note "=== set_user_password ===";

    $cv = AE::cv;
    $db->set_user_password(
        q => "SET PASSWORD FOR jdoe = 'otherpassword'",

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to set password: @_");
        }
    );
    ok($cv->recv, "password changed");
}
{
    note "=== show_users ===";

    $cv = AE::cv;
    $db->show_users(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list users: @_");
        }
    );
    my @users = $cv->recv;
    is_deeply(
        [ @users ],
        [
            {
                user => 'jdoe',
                admin => $false,
            }
        ],
        "users listed"
    );
    for my $u ( @users ) {
        note "Name: $u->{user}";
        note "Admin?: $u->{admin}";
    }

}
{
    note "=== grant_privileges ===";

    $cv = AE::cv;
    $db->grant_privileges(
        q => "GRANT ALL ON mydb TO jdoe",

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to grant privileges: @_");
        }
    );
    ok($cv->recv, "privileges granted");
}
{
    note "=== show_grants ===";

    $cv = AE::cv;
    $db->show_grants(
        q => "SHOW GRANTS FOR jdoe",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list users: @_");
        }
    );
    my @grants = $cv->recv;
    is_deeply(
        [ @grants ],
        [
            {
                database => 'mydb',
                privilege => 'ALL PRIVILEGES',
            }
        ],
        "grants listed"
    );

    for my $g ( @grants ) {
        note "Database: $g->{database}";
        note "Privilege: $g->{privilege}";
    }
}
{
    note "=== revoke_privileges ===";

    $cv = AE::cv;
    $db->revoke_privileges(
        q => "REVOKE WRITE ON mydb FROM jdoe",

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to revoke privileges: @_");
        }
    );
    ok($cv->recv, "privileges revoked");
}
{
    note "=== show_grants ===";

    $cv = AE::cv;
    $db->show_grants(
        q => "SHOW GRANTS FOR jdoe",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list users: @_");
        }
    );
    my @grants = $cv->recv;
    is_deeply(
        [ @grants ],
        [
            {
                database => 'mydb',
                privilege => 'READ',
            }
        ],
        "grants listed (after revoke WRITE)"
    );
    for my $g ( @grants ) {
        note "Database: $g->{database}";
        note "Privilege: $g->{privilege}";
    }
}
{
    note "=== write ===";

    $cv = AE::cv;
    for my $rno ( map { "request no. $_" } 1 .. 15 ) {
        $cv->begin;
        note "preparing $rno...";

        $db->write(
            database => 'mydb',
            rp => 'autogen',
            precision => 's',
            data => [
                    map {
                        +{
                            measurement => $measurements[rand @measurements],
                            tags => {
                                host => $hosts[rand @hosts],
                                region => $regions[rand @regions],
                            },
                            fields => {
                                value => sprintf('%.2f', rand(100)),
                                $fields[rand @fields] => rand(100),
                                request => qq{"$rno"},
                            },
                            time => time() - int(rand(14 * 24 * 3600))
                        }
                    } 1 .. 5
                ],
            on_success => sub {
                ok(1, "finished $rno...");
                $cv->end();
            },
            on_error => sub {
                my $error_msg = shift;
                ok(0, "$rno failed: $error_msg\n");
                $cv->end();
            }
        );
    }
    note "waiting for all requests";
    $cv->recv;
    note "all requests done";
}

{
    note "=== show_series ===";

    $cv = AE::cv;
    $db->show_series(
        database => 'mydb',

        q => "SHOW SERIES",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list series: @_");
        }
    );
    my @series = $cv->recv;
    cmp_deeply(
        [ @series ],
        array_each(
            re('^('.join('|', @measurements).'),host=server\d{2},region=('.join('|', @regions).')'),
        ),
        "all series as expected"
    );
    note "$_" for @series;
}
{
    note "=== show_series ===";

    $cv = AE::cv;
    $db->show_series(
        database => 'mydb',

        q => "SHOW SERIES FROM cpu_load",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list series: @_");
        }
    );
    my @series = $cv->recv;
    cmp_deeply(
        [ @series ],
        array_each(
            re('^cpu_load,host=server\d{2},region=('.join('|', @regions).')'),
        ),
        "cpu_load series as expected"
    );
    note "$_" for @series;
}
{
    note "=== show_tag_keys ===";

    $cv = AE::cv;
    $db->show_tag_keys(
        database => 'mydb',

        q => "SHOW TAG KEYS FROM cpu_load",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list tag keys: @_");
        }
    );
    my $tag_keys = $cv->recv;
    is_deeply(
        $tag_keys,
        {
            cpu_load => [qw( host region )],
        },
        "tag keys"
    );
    for my $measurement ( sort keys %{ $tag_keys } ) {
        note "Measurement: $measurement";
        note " * $_" for @{ $tag_keys->{$measurement} };
    }
}
{
    note "=== show_tag_values ===";

    $cv = AE::cv;
    $db->show_tag_values(
        database => 'mydb',

        q => q{SHOW TAG VALUES WITH KEY = "host"},

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list tag values: @_");
        }
    );
    my $tag_values = $cv->recv;
    cmp_deeply($tag_values,
        hashkeys(@measurements) => hashkeys('host') => array_each(any(@hosts)),
        "tag values"
    );
    for my $measurement ( sort keys %{ $tag_values } ) {
        note "Measurement: $measurement";
        for my $tag_key ( sort keys %{ $tag_values->{$measurement} } ) {
            note "  Tag key: $tag_key";
            note "   * $_" for @{ $tag_values->{$measurement}->{$tag_key} };
        }
    }
}
{
    note "=== show_tag_values ===";

    $cv = AE::cv;
    $db->show_tag_values(
        database => 'mydb',

        q => "SHOW TAG VALUES FROM cpu_load WITH KEY IN (host, region)",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list tag values: @_");
        }
    );
    my $tag_values = $cv->recv;
    cmp_deeply($tag_values,
        hashkeys('cpu_load') => hashkeys(qw(host region)) => array_each(any(@hosts)),
        "tag values"
    );
    for my $measurement ( sort keys %{ $tag_values } ) {
        note "Measurement: $measurement";
        for my $tag_key ( sort keys %{ $tag_values->{$measurement} } ) {
            note "  Tag key: $tag_key";
            note "   * $_" for @{ $tag_values->{$measurement}->{$tag_key} };
        }
    }
}
{
    note "=== show_field_keys ===";

    $cv = AE::cv;
    $db->show_field_keys(
        database => 'mydb',

        q => "SHOW FIELD KEYS FROM cpu_load",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list tag keys: @_");
        }
    );
    my $field_keys = $cv->recv;
    cmp_deeply($field_keys,
        {
            "cpu_load" => array_each(
                {
                    name => any(@fields, qw(request value)),
                    type => any(qw(float string))
                }
            ),
        },
        "field keys"
    );
    for my $measurement ( sort keys %{ $field_keys } ) {
        note "Measurement: $measurement";
        for my $field ( @{ $field_keys->{$measurement} } ) {
            note "  Key:  $field->{name}";
            note "  Type: $field->{type}";
        }
    }
}
{
    note "=== select ===";

    $cv = AE::cv;
    $db->select(
        database => 'mydb',
        epoch => 's',

        q => "SELECT count(value) FROM cpu_load"
            ." WHERE region = 'eu-east' AND time > now() - 14d"
            ." GROUP BY time(1d) fill(none)"
            ." ORDER BY time DESC"
            ." LIMIT 10",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to select data: @_");
        }
    );
    my $results = $cv->recv;
    cmp_deeply($results,
        [
            {
                name => 'cpu_load',
                values => array_each(
                        {
                            count => $pos_int,
                            time => code(sub { $_[0] >= $_15days_ago }),
                        }
                )
            }
        ],
        "select result"
    );
    for my $row ( @{ $results } ) {
        note "Measurement: $row->{name}";
        note "Values:";
        for my $value ( @{ $row->{values} || [] } ) {
            note " * $_ = $value->{$_}" for keys %{ $value || {} };
        }
    }
}
{
    note "=== show_shard_groups ===";

    $cv = AE::cv;
    $db->show_shard_groups(

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list tag keys: @_");
        }
    );
    my @shard_groups = $cv->recv;
    cmp_deeply(
        [ @shard_groups ],
        array_each(
            {
                id => $pos_int,
                database => any(qw(_internal mydb)),
                retention_policy => any(qw(monitor autogen)),
                start_time => $dt_re,
                end_time => $dt_re,
                expiry_time => $dt_re,
            }
        ),
        "shard groups as expected"
    );
    for my $sg ( @shard_groups ) {
        note "ID: $sg->{id}";
        note "Database: $sg->{database}";
        note "Retention Policy: $sg->{retention_policy}";
        note "Start Time: $sg->{start_time}";
        note "End Time: $sg->{end_time}";
        note "Expiry Time: $sg->{expiry_time}";
    }
}
{
    note "=== show_queries ===";

    $cv = AE::cv;
    $db->show_queries(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list tag keys: @_");
        }
    );
    my @queries = $cv->recv;
    cmp_deeply(
        [ @queries ],
        array_each(
            {
                qid => $pos_int,
                query => 'SHOW QUERIES',
                database => ignore(),
                duration => re('\d+'),
            }
        ),
        "queries as expected"
    );

    for my $q ( @queries ) {
        note "ID: $q->{qid}\n";
        note "Query: $q->{query}\n";
        note "Database: $q->{database}\n";
        note "Duration: $q->{duration}\n";
    }
}
{
    note "=== show_shards ===";

    $cv = AE::cv;
    $db->show_shards(

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list tag keys: @_");
        }
    );
    my $shards = $cv->recv;
    cmp_deeply($shards,
        {
            foo => [],
            _internal => array_each(
                    {
                        id => $pos_int,
                        database => '_internal',
                        retention_policy => 'monitor',
                        shard_group => $pos_int,
                        start_time => $dt_re,
                        end_time => $dt_re,
                        expiry_time => $dt_re,
                        owners => ignore(), # used to be 1 in 0.10, now is empty in 0.13 - a bug?
                    }
                ),
            mydb => array_each(
                    {
                        id => $pos_int,
                        database => 'mydb',
                        retention_policy => 'autogen',
                        shard_group => $pos_int,
                        start_time => $dt_re,
                        end_time => $dt_re,
                        expiry_time => $dt_re,
                        owners => ignore(), # used to be 1 in 0.10, now is empty in 0.13 - a bug?
                    }
                ),
        },
        "shards as expected"
    );
    for my $database ( sort keys %{ $shards } ) {
        note "Database: $database";
        for my $s ( @{ $shards->{$database} } ) {
            note " * $_: $s->{$_}" for sort keys %{ $s };
        }
    }
}
{
    note "=== create_subscription ===";

    $cv = AE::cv;
    $db->create_subscription(
        name => q{alldata},
        database => q{"mydb"},
        rp => q{"autogen"},
        mode => "ANY",
        destinations => [
            q{'udp://h1.example.com:9090'},
            q{'udp://h2.example.com:9090'}
        ],

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to create subscription: @_");
        }
    );
    ok($cv->recv, "subscription alldata created ");

    $cv = AE::cv;
    $db->create_subscription(
        name => q{"alldata2"},
        database => q{"mydb"},
        rp => q{"autogen"},
        mode => "ALL",
        destinations => q{'udp://h1.example.com:9090'},

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to create subscription: @_");
        }
    );
    ok($cv->recv, "subscription alldata2 created ");

    $cv = AE::cv;
    $db->create_subscription(
        name => q{"alldata3"},
        database => q{"foo"},
        rp => q{"autogen"},
        mode => "ALL",
        destinations => q{'udp://h2.example.com:9090'},

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to create subscription: @_");
        }
    );
    ok($cv->recv, "subscription alldata3 created ");
}
{
    note "=== show_subscriptions ===";

    $cv = AE::cv;
    $db->show_subscriptions(
        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list shards: @_");
        }
    );
    my $subscriptions = $cv->recv;
    cmp_deeply(
        $subscriptions,
        {
            foo => [
                {
                    destinations => [
                        "udp://h2.example.com:9090"
                    ],
                    mode => "ALL",
                    name => "alldata3",
                    retention_policy => "autogen"
                }
            ],
            mydb => [
                {
                    destinations => [
                        "udp://h1.example.com:9090",
                        "udp://h2.example.com:9090"
                    ],
                    mode => "ANY",
                    name => "alldata",
                    retention_policy => "autogen"
                },
                {
                    destinations => [
                        "udp://h1.example.com:9090"
                    ],
                    mode => "ALL",
                    name => "alldata2",
                    retention_policy => "autogen"
                }
            ]
        },
        "subscriptions listed"
    );
    for my $database ( sort keys %{ $subscriptions } ) {
        note "Database: $database";
        for my $s ( @{ $subscriptions->{$database} } ) {
            note " Name: $s->{name}";
            note " Retention Policy: $s->{retention_policy}";
            note " Mode: $s->{mode}";
            note " Destinations:";
            note "  * $_" for @{ $s->{destinations} || [] };
        }
    }
}
{
    note "=== drop_subscription ===";

    my %subs = (
        alldata => 'mydb',
        alldata2 => 'mydb',
        alldata3 => 'foo',
    );
    while (my ($s, $d) = each %subs) {
        $cv = AE::cv;
        $db->drop_subscription(
            q => qq{DROP SUBSCRIPTION "$s" ON "$d"."autogen"},

            on_success => sub { $cv->send("test ok") },
            on_error => sub {
                #$cv->croak("Failed to drop subscription: @_");
                $cv->send("Failed to drop subscription: @_");
            }
        );
        ok($cv->recv, "subscription $s dropped ");
    }
}
{
    note "=== query ===";

    $cv = AE::cv;
    $db->query(
        query => {
            db => 'mydb',
            q => 'SELECT * FROM cpu_load LIMIT 5; SELECT * from cpu_temp LIMIT 5',
        },
        on_response => $cv,
    );
    my ($response_data, $response_headers) = $cv->recv;
    cmp_deeply(
        decode_json($response_data),
        {
            results => [
                {
                    series => [
                        {
                            name => 'cpu_load',
                            columns => array_each(
                                any(@fields, qw(time host region request value))
                            ),
                            values => [
                                array_each(ignore()),
                                array_each(ignore()),
                                array_each(ignore()),
                                array_each(ignore()),
                                array_each(ignore()),
                            ],
                        }
                    ],
                },
                {
                    series => [
                        {
                            name => 'cpu_temp',
                            columns => array_each(
                                any(@fields, qw(time host region request value))
                            ),
                            values => [
                                array_each(ignore()),
                                array_each(ignore()),
                                array_each(ignore()),
                                array_each(ignore()),
                                array_each(ignore()),
                            ],
                        }
                    ],
                },
            ]
        },
        "multiquery works"
    );
}
{
    note "=== show_measurements ===";

    $cv = AE::cv;
    $db->show_measurements(
        database => 'mydb',

        q => "SHOW MEASUREMENTS",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list measurements: @_");
        }
    );
    my @measurements = $cv->recv;
    cmp_deeply(
        [ @measurements ],
        subbagof(qw( cpu_load cpu_temp mem_free disk_free )),
        "measurements listed"
    );
    note "$_" for @measurements;

}
{
    note "=== drop_measurement ===";

    $cv = AE::cv;
    $db->drop_measurement(
        database => 'mydb',

        q => "DROP MEASUREMENT cpu_load",

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to drop measurement: @_");
        }
    );
    ok($cv->recv, "cpu_load dropped ");
}
{
    note "=== drop_user ===";

    $cv = AE::cv;
    $db->drop_user(
        q => "DROP USER jdoe",

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to drop user: @_");
        }
    );
    ok($cv->recv, "user dropped");
}
{
    note "=== show_measurements ===";

    $cv = AE::cv;
    $db->show_measurements(
        database => 'mydb',

        q => "SHOW MEASUREMENTS",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list measurements: @_");
        }
    );
    my @measurements = $cv->recv;
    cmp_deeply(
        [ @measurements ],
        subbagof(qw( cpu_temp mem_free disk_free )),
        "measurements listed"
    );
    note "$_" for @measurements;

}
{

    $cv = AE::cv;
    $db->drop_series(
        database => 'mydb',

        q => "DROP SERIES FROM cpu_temp",

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to drop measurement: @_");
        }
    );
    ok($cv->recv, "cpu_temp series dropped ");
}
{
    note "=== show_series ===";

    $cv = AE::cv;
    $db->show_series(
        database => 'mydb',

        q => "SHOW SERIES",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list series: @_");
        }
    );
    my $series = $cv->recv;
    my @sub_measurements = grep { ! /^cpu_/ } @measurements;
    my @series = $cv->recv;
    cmp_deeply(
        [ @series ],
        array_each(
            re('^('.join('|', @sub_measurements).'),host=server\d{2},region=('.join('|', @regions).')'),
        ),
        "all series as expected"
    );
    ($existing_region) = $series[0] =~ /region=(.*)$/;
    note "$_" for @series;
}
{
    note "=== delete_series ===";

    $cv = AE::cv;
    $db->delete_series(
        database => 'mydb',

        q => qq{DELETE FROM disk_free WHERE region='$existing_region'},

        on_success => sub { $cv->send("test ok") },
        on_error => sub {
            $cv->croak("Failed to delete series: @_");
        }
    );
    ok($cv->recv, "disk_free series from region $existing_region deleted");
}
{
    note "=== show_series ===";

    $cv = AE::cv;
    $db->show_series(
        database => 'mydb',
        q => "SHOW SERIES FROM disk_free",

        on_success => $cv,
        on_error => sub {
            $cv->croak("Failed to list series: @_");
        }
    );
    my @sub_measurements = grep { ! /^cpu_/ } @measurements;
    my @series = $cv->recv;
    cmp_deeply(
        [ @series ],
        array_each(
            re('^disk_free,host=server\d{2},region=('.join('|', grep { ! /$existing_region/ } @regions).')'),
        ),
        "all series as expected"
    );
    note "$_" for @series;
}
{
    for my $d ( qw( mydb foo ) ) {
        $cv = AE::cv;
        $db->drop_database(
            q => "DROP DATABASE $d",

            on_success => sub { $cv->send("test ok") },
            on_error => sub {
                $cv->croak("Failed to drop database: @_");
            }
        );
        ok($cv->recv, "database $d dropped ");
    }
}

EV::run();

