use Test2::V0 '!meta', '!pass';

# A db registered under a name that contains a dot must still be fetchable by
# that name. The dotted form is only interpreted as a server-qualified lookup
# ("server.db") when the leading segment is an actually-defined server.

{
    package My::Dotted;
    use DBIx::QuickORM;
}

my $b = My::Dotted->builder;

$b->db('my.db' => sub {
    $b->dialect('SQLite');
    $b->db_name('somefile');
});

my $fetched;
ok(
    lives { $fetched = $b->db('my.db') },
    "fetching a db whose name contains a dot does not croak about an undefined server",
) or note $@;

ok($fetched, "the dotted-name db is returned");
is($fetched->db_name, 'somefile', "the returned db is the one that was registered");

# Genuine server-qualified lookup still resolves.
$b->server(myserver => sub {
    $b->db(realdb => sub {
        $b->dialect('SQLite');
        $b->db_name('serverfile');
    });
});

my $sq;
ok(lives { $sq = $b->db('myserver.realdb') }, "server-qualified lookup still works") or note $@;
is($sq->db_name, 'serverfile', "server-qualified lookup returns the right db");

done_testing;
