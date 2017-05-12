Setting up your DBR application
===
This guide is intended to help you quickly set up the environment for your first DBR application.


*FIRST* Before reading this
---

See [README.md](https://github.com/dnorman/perl-DBR/blob/master/README.md) and try out some examples before trying to proceed here.


Setup Steps:
---

 1. Check out the code

    *Using the CPAN installer will not suffice for this step*

        git clone git://github.com/dnorman/perl-DBR.git
        cd perl-DBR
        perl Makefile.PL
        make
        sudo make install # this installs the tools you will need for the below steps

 2. Create your DBR database

    For SQLite:

        sqlite3 /path/to/my/dbr.sqlite < sql/dbr_schema_sqlite.sql

    For Mysql:

        mysql -e 'create database dbr;' # database name and access control are totally up to you
        mysql -h mydbhost -u myuser -p'mypasswd' dbr < sql/dbr_schema_mysql.sql

 3. Create your DBR.conf

    Location is up to you.

    For SQLite metadata DB:

        echo 'name=dbrconf; class=master; type=SQLite; dbfile=/path/to/my/dbr.sqlite; dbr_bootstrap=1' > /path/to/my/DBR.conf

    For a Mysql metadata DB:

        echo 'name=dbrconf; class=master; type=Mysql; hostname=mydbhost; database=dbr; user=myuser; password=mypasswd; dbr_bootstrap=1' > /path/to/my/DBR.conf

 4. Register your schema
    
        export DBR_CONF=/path/to/my/DBR.conf # can also specify -f /path/to/my/DBR.conf
        dbr-config assert schema myschema "My Schema name"

 5. Register your instances
    Some people have different copies of the same database ( class = master|query )

    For a Mysql instance:

        dbr-config assert instance -schema=myschema -class=master -module=mysql -host mydbhost -dbname myschema_db -username myuser -password 'mypassword'

    For a SQLite instance:
    
        dbr-config assert instance -schema=myschema -class=master -module=sqlite -dbfile=/path/to/my/DB.sqlite

    *Note:* you may mix and match DB types. For instance, the DBR metadata database could be Sqlite and the Application database could be mysql, or vice versa.

 6. Scan an instance

    This loads the table and field specifications into the DBR metadata database as defined in /path/to/my/DBR.conf

        bin/dbr-scan-db /path/to/my/DBR.conf myschema

 7. Load data spec

    When you reach this point, DBR is now usable, but will lack specifications such as relationships and translators. There are two ways to define these.
    1. DBR Admin

       An ncurses based interactive administration tool that allows you to browse schemas, instances, enums, tables, etc. It's pretty clunky right now, but it allows you to define relationships and translators for the tables/fields that DBR scans. *Note: this is not very intuitive right now, but an improved version is in the works.*

        dbr-admin /path/to/my/DBR.conf

    2. dbr-load-spec

       Takes tab delimited spec files which are pretty easy to write. See `example/schemas/music/spec` for a sample DBR spec file
       To load a spec file:

        dbr-load-spec /path/to/my/DBR.conf /path/to/my/specfile.tsv

        Thats it!

 8. Writing your first test script

    All you have to do is:
    * `cp example/example_basic.pl ~/my_first_dbr_app.pl`
    * remove the `use DBR::Sandbox` line
    * customize for your config file / schema

