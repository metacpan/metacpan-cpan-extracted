# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Exception::DB;

my $E = 'DBIx::QuickORM::Exception::DB';

subtest attributes => sub {
    my $err = $E->new(kind => 'unique_violation', state => '23505', native => 7, errstr => 'dup', statement => 'INSERT ...', message => 'DBD::Pg::st execute failed: dup');
    is([map { $err->$_ } qw/kind state native errstr statement/], ['unique_violation', '23505', 7, 'dup', 'INSERT ...'], "Holds what it was given");
    is("$err",                                                    'DBD::Pg::st execute failed: dup',                     "Stringifies to DBI's message");
    ok($err ? 1 : 0, "Always true");

    is($E->new(errstr => 'text')->message, 'text',                   "The message defaults to errstr");
    is($E->new->message,                   'Unknown database error', "and has a fallback");
};

subtest retriable => sub {
    is($E->new(kind => $_)->retriable, 1, "$_ is retriable") for qw/deadlock serialization_failure lock_timeout/;
    is($E->new(kind => $_)->retriable, 0, "$_ is not")       for qw/unique_violation foreign_key_violation not_null_violation check_violation/;
    is($E->new->retriable,                  undef, "An unknown kind is undef");
    is($E->new(kind => 'other')->retriable, undef, "and so is a kind this does not know");
};

done_testing;
