[![Build Status](https://travis-ci.org/ccakes/DBIx-SimpleMigration.svg?branch=master)](https://travis-ci.org/ccakes/DBIx-SimpleMigration) [![MetaCPAN Release](https://badge.fury.io/pl/DBIx-SimpleMigration.svg)](https://metacpan.org/release/DBIx-SimpleMigration)
DBIx::SimpleMigration - extremely simple DBI migrations

# DESCRIPTION

This is a very simple module to simplify schema updates in a larger application. This will scan a directory of SQL files and execute them on a supplied [DBI](https://metacpan.org/pod/DBI) handle. Files are executed in order and inside transactions for safety. The module will create a table to track progress so new releases can add migrations as a SQL file and this will only deploy what is required.

### Wait! Is this the right tool?

Be sure this is the right tool for you. This is incredibly simple and doesn't have any verification or rollback capabilities. Before you use this, look at [App::Sqitch](http://sqitch.org) or [DBIx::Class::Migration](https://metacpan.org/pod/DBIx::Class::Migration) as they're probably better choices.

# SYNOPSIS

    use DBI;
    use DBIx::SimpleMigration;

    my $dbh = DBI->connect(...);
    my $migration = DBIx::SimpleMigration->new(
      source => './sql/',
      dbh => $dbh
    );

    eval { $migration->apply };
    if ($@) {
      # some error happened
    }

DBIx::SimpleMigration will die on error so if that's unacceptable for your use case, make sure to wrap in an `eval`.

# CONTRIBUTING

I primarily use PostgreSQL so that's the driver getting the most attention. Happy to take suggestions but if you're using another DBI driver and want locking or better support, feel free to create a ::Client::$driver package and send over a PR.

# SUPPORT

Questions, bugs, feedback are all welcome. Just create an issue under this project.

# AUTHOR

Cameron Daniel <cam.daniel@gmail.com>
