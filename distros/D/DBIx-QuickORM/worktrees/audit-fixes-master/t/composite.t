use Test2::V0 -target => 'DBIx::QuickORM';
use lib 't/lib';
use DBIx::QuickORM::Test;

{
    package My::Schema;
    use DBIx::QuickORM;

    orm MyORM => sub {
        autofill;
    };
}

use DBIx::QuickORM only => [qw/db_name connect dialect db/];

My::Schema->import('qorm');

do_for_all_dbs {
    my $db = shift;

    qorm(orm => 'MyORM')->db(
        db sub {
            dialect main::curdialect();
            db_name 'quickdb';
            connect sub { $db->connect };
        }
    );

    my $con = qorm('MyORM');
    isa_ok($con, ['DBIx::QuickORM::Connection'], "Got a connection");
};

done_testing;
