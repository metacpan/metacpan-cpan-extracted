# App-OverWatch

Designed to provide a simple framework to give some oversight to applications
running in a distributed environment.  Applications can quickly
register/release simple locks, register and send notifications, and log events
to a database using a very simple interface.

By simple, this means:

1) the framework should not be used in flight control or hospital systems,
2) we're ok with the database being a non-replicated central point of failure,

Basically this is a solution if you're happy with something that works 99%
of the time and has low admin overhead and runs on minimal hardware.

The data is all stored in a SQL database (mysql/postgres, or sqlite if you're
not so interested in the distributed environment bit), so it can be accessed and
manipulated however you like.

See the manpages/POD for servicelock for simple usage - or
App::OverWatch::ServiceLock for the Perl interface.

# Installation

# Configuration

Set up a back-end database with a user that has full access to it, configure
~/.overwatch.conf (or /etc/overwatch.conf if you fancy) with your database
details.  You'll need to provide the DSN as explained in the Perl DBD
documentation your particular database.

```
db_type = mysql
user = test
password = test
dsn = DBI:mysql:database=test;host=dbhost
```

Valid dd_types are mysql, postgres, sqlite.

Clearly passwords may be in this file, so consider your security options.

Then run:

```
servicelock --create_table
```

If that works, you're good to go.  You then create named locks and can start
locking and unlocking them:

```
servicelock --create_lock --system mylock
```

```
servicelock --lock --system mylock
servicelock --unlock --system mylock
```

See the servicelock manpage/POD for more details.

The 'eventlog' and 'notify' commands should work in the same way.
