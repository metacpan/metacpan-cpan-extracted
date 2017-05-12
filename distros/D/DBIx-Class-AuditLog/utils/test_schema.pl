#/usr/bin/env perl

use Modern::Perl;

use Data::Printer;
use Try::Tiny;

use lib '../lib';
use AuditTest::Schema;
use DBIx::Class::AuditLog;

my $schema = AuditTest::Schema->connect( "DBI:mysql:database=audit_test",
    "root", $ARGV[0], { RaiseError => 1, PrintError => 1 } );

my $al_schema;

# deploy the audit log schema if it's not installed
try {
    $al_schema = $schema->audit_log_schema;
    my $changesets = $al_schema->resultset('AuditLogChangeset')->all;
}
catch {
    $al_schema->deploy;
};

my $user_01;
$schema->txn_do(
    sub {
        $user_01 = $schema->resultset('User')->create(
            {   name  => "JohnSample",
                email => 'jsample@sample.com',
                phone => '999-888-7777',
            }
        );
    },
    {   description => "adding new user: JohnSample",
        user_id     => "TestAdminUser",
    },
);

$schema->txn_do(
    sub {
        $user_01->phone('111-222-3333');
        $user_01->update();
    },
    {   description => "updating phone of JohnSample",
        user        => "TestAdminUser",
    },
);


$schema->txn_do(
    sub {
        $user_01->delete;
    },
    {   description => "delete user: JohnSample",
        user_id     => "YetAnotherAdminUser",
    },
);

$schema->txn_do(
    sub {
        $schema->resultset('User')->create(
            {   name  => "TehPnwerer",
                email => 'jeremy@purepwnage.com',
                phone => '999-888-7777',
            }
        );
    },
    { description => "adding new user: TehPwnerer -- no admin user", },
);

my $superman;
my $spiderman;
$schema->txn_do(
    sub {
        $superman = $schema->resultset('User')->create(
            {   name  => "Superman",
                email => 'ckent@dailyplanet.com',
                phone => '123-456-7890',
            }
        );
        $superman->update(
            {   name  => "Superman",
                email => 'ckent@dailyplanet.com',
                phone => '123-456-7890',
            }
        );
        $spiderman = $schema->resultset('User')->create(
            {   name  => "Spiderman",
                email => 'ppaker@dailybugle.com',
                phone => '987-654-3210',
            }
        );
        $schema->resultset('User')->search( { name => "Spiderman" } )
            ->first->update(
            {   name  => "Spiderman",
                email => 'pparker@dailybugle.com',
                phone => '987-654-3210',
            }
            );
        $schema->resultset('User')->search( { name => "TehPnwerer" } )
            ->first->update(
            { name => 'TehPwnerer', phone => '416-123-4567' } );
    },
    {   description => "multi-action changeset",
        user_id     => "ioncache",
    },
);

$schema->resultset('User')->create(
    {   name  => "NonChangesetUser",
        email => 'ncu@oanda.com',
        phone => '987-654-3210',
    }
);

$schema->txn_do(
    sub {
        $schema->resultset('User')->create(
            {   name  => "Drunk Hulk",
                email => 'drunkhulk@twitter.com',
                phone => '123-456-7890',
            }
        );
        $schema->resultset('User')->search( { name => "Drunk hulk" } )
            ->first->update( { email => 'drunkhulk@everywhere.com' } );
    },
    { user_id => "markj", },
);

$schema->resultset('User')->search( { name => "NonChangesetUser" } )
    ->first->update( { phone => '543-210-9876' } );

my $atbdu = $schema->resultset('User')->create(
    {   name  => "AboutToBeDeletedUser",
        email => 'atbdu@oanda.com',
        phone => '987-654-3210',
    }
);

$atbdu->delete;


# basic test of get_changes
my $changes = $al_schema->get_changes({ id => $user_01->id, table => 'user', change_order => 'asc' });

while ( my $change = $changes->next ) {
    say "*" x 50;
    say "Time:   " . $change->Action->Changeset->timestamp;
    say "Action: " . $change->Action->type;
    say "Field:  " . $change->Field->name;
    say "Old:    " . ($change->old_value ? $change->old_value : '');
    say "New:    " . ($change->new_value ? $change->new_value : '');
}

1;
