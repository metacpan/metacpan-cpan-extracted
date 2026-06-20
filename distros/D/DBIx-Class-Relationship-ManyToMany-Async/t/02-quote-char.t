use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

use lib 't/lib';

# ─── 'group' is a SQL reserved word — quote_char makes it work ──────────────

my $loop           = IO::Async::Loop->new;
my ($fh, $db_file) = tempfile(UNLINK => 1);
my $schema         = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file", undef, undef,
    { quote_char => '"', name_sep => '.' },
    {
        workers      => 2,
        schema_class => 'TestSchemaQuoted',
        async_loop   => $loop,
        dbi_attrs    => { quote_char => '"' },
    },
);

$schema->await($schema->deploy({ add_drop_table => 0 }));

my $u_rs = $schema->resultset('User');
my $g_rs = $schema->resultset('Group');

my $alice = $schema->await($u_rs->create({ name => 'Alice' }));
my $admin = $schema->await($g_rs->create({ name => 'Admins' }));

$schema->await($alice->add_to_groups($admin));
my @g = @{ $schema->await($alice->groups) };
is(scalar @g, 1, 'one group (reserved word with quote_char)');
is($g[0]->name, 'Admins', 'correct group name');

$schema->disconnect;
done_testing;
