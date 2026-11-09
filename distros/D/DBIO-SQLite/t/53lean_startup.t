use strict;
use warnings;

use Test::More;

# What a plain SQLite session must NOT load. The list is a contract: each
# module below is lazy on purpose, and loading one of them for an ordinary
# deploy / CRUD / prefetch / transaction run is a startup-cost regression.
# It is a negative list -- what else gets loaded is nobody's promise.
my %lazy_because = (
  'Moo'                          => 'optional bridge, only for Moo-based result classes',
  'Moose'                        => 'optional bridge, only for Moose-based result classes',
  'DateTime'                     => 'only InflateColumn::DateTime users pay for it',
  'DateTime::Format::SQLite'     => 'datetime parser is resolved when a column is inflated',
  'SQL::Translator'              => 'the legacy deploy path is gone, deploy is native',
  'Data::Dumper'                 => 'debug output only',
  'JSON::MaybeXS'                => 'only the json() DSL helper needs it',
  'JSON'                         => 'only the json() DSL helper needs it',
  'Math::BigInt'                 => 'only wide-integer handling needs it',
  'Encode'                       => 'unicode is the DBD attribute, not our decoding',
);

# A child process: the %INC measured is the driver's own, not whatever
# the other test files of this run loaded into a shared interpreter.
my $probe = <<'PROBE';
use strict; use warnings;
use DBIO::Test; use DBIO::SQLite::Test;
my $loaded = sub { exists $INC{ ($_[0] =~ s{::}{/}gr) . '.pm' } ? 1 : 0 };
my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('DBIO::SQLite::Storage');
$schema = $schema->connect('dbi:SQLite:dbname=:memory:');
print "connected-without-DBI=", ($loaded->('DBI') ? 0 : 1), "\n";
$schema->storage->ensure_connected;
DBIO::Test->deploy_schema($schema);
DBIO::Test->populate_schema($schema);
my $cd = $schema->resultset('CD')->create({ artist => 1, title => 'x', year => 2000 });
$cd->update({ title => 'y' });
$schema->resultset('CD')->search({ title => 'y' })->delete;
my @rows = $schema->resultset('Artist')->search({}, { prefetch => 'cds' })->all;
$schema->txn_do(sub { $schema->resultset('Artist')->create({ name => 'lean' }) });
print "ran=", scalar(@rows) ? 1 : 0, "\n";
print "loaded=$_\n" for grep { $loaded->($_) } @ARGV;
PROBE

open my $fh, '-|', $^X, (map { "-I$_" } @INC), '-e', $probe, sort keys %lazy_because
  or die "cannot start the probe: $!";
my @out = <$fh>;
close $fh;
is $?, 0, 'the probe session ran to the end' or diag @out;

my %out = map { /^(\w[\w-]*)=(.*)$/ ? ($1 => $2) : () } map { chomp; $_ } @out;
my @loaded = map { /^loaded=(.+)$/ ? $1 : () } map { chomp; $_ } @out;

is $out{'connected-without-DBI'}, 1, 'DBI waits for the first real connection';
is $out{ran}, 1, 'the session did real work (prefetch returned rows)';
is_deeply \@loaded, [], 'no lazy-by-contract module was loaded'
  or diag map { "loaded $_, lazy because: $lazy_because{$_}\n" } @loaded;

done_testing;
