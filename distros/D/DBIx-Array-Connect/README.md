# NAME

DBIx::Array::Connect - Database Connections from an INI Configuration File

# SYNOPSIS

    use DBIx::Array::Connect;
    my $dbx=DBIx::Array::Connect->new->connect("mydatabase"); #isa DBIx::Array

    my $dac=DBIx::Array::Connect->new(file=>"./my.ini");      #isa DBIx::Array::Connect
    my $dbx=$dac->connect("mydatabase");                      #isa DBIx::Array

# DESCRIPTION

Provides an easy way to construct database objects and connect to databases while providing an easy way to centralize management of database connection strings.

This package reads database connection information from an INI formatted configuration file and returns a connected database object.

This module is used to connect to both Oracle 10g and 11g using [DBD::Oracle](https://metacpan.org/pod/DBD::Oracle) on both Linux and Win32, MySQL 4 and 5 using [DBD::mysql](https://metacpan.org/pod/DBD::mysql) on Linux, and Microsoft SQL Server using [DBD::Sybase](https://metacpan.org/pod/DBD::Sybase) on Linux and using [DBD::ODBC](https://metacpan.org/pod/DBD::ODBC) on Win32 systems in a 24x7 production environment.

# USAGE

Create an INI configuration file with the following format.  The default location for the INI file is /etc/database-connections-config.ini on Linux-like systems and C:\\Windows\\database-connections-config.ini on Windows-like systems.

    [mydatabase]
    connection=DBI:mysql:database=mydb;host=myhost.mydomain.tld
    user=myuser
    password=mypassword
    options=AutoCommit=>1, RaiseError=>1

Connect to the database.

    my $dbx=DBIx::Array::Connect->new->connect("mydatabase"); #isa DBIx::Array
    my $dbh=$dbx->dbh; #if you don't want to use DBIx::Array...

Use the [DBIx::Array](https://metacpan.org/pod/DBIx::Array) object like you normally would.

# CONSTRUCTOR

## new

    my $dac=DBIx::Array::Connect->new;                        #Defaults
    my $dac=DBIx::Array::Connect->new(file=>"path/my.ini");   #Override the INI location

# METHODS

## connect

Returns a database object for the database nickname which is an INI section name.

    my $dbx=$dac->connect($nickname);                         #isa DBIx::Array

    my %overrides=(
                   connection => $connection,
                   user       => $user,
                   password   => $password,
                   options    => {},
                   execute    => [],
                  );
    my $dbx=$dac->connect($nickname, \%overrides);            #isa DBIx::Array

## sections

Returns all of the "active" section names in the INI file with the given type.

    my $list=$dac->sections("db"); #[]
    my @list=$dac->sections("db"); #()
    my @list=$dac->sections;       #All "active" sections in INI file

Note: active=1 is assumed active=0 is inactive

Example:

    my @dbx=map {$dac->connect($_)} $dac->sections("db");     #Connect to all active databases of type db

## section\_hash

Returns the contents of the INI section as a hash or hash reference.

    my $hash_ref = $dac->section_hash("db1"); #isa HASH
    my %hash     = $dac->section_hash("db1"); #isa LIST

## class

Returns the class in to which to bless objects.  The "class" is assumed to be a base DBIx::Array object.  This package MAY work with other objects that have a connect method that pass directly to DBI->connect.  The object must have a similar execute method to support the package's execute on connect capability.

    my $class=$dac->class; #$
    $dac->class("DBIx::Array::Export"); #If you want the exports features of DBIx::Array

Set on construction

    my $dac=DBIx::Array::Connect->new(class=>"DBIx::Array::Export");

## file

Sets or returns the profile INI filename

    my $file=$dac->file;
    my $file=$dac->file("./my.ini");

Set on construction

    my $dac=DBIx::Array::Connect->new(file=>"./my.ini");

## path

Sets and returns a list of search paths for the INI file.

    my $path=$dac->path;            # []
    my $path=$dac->path(".", ".."); # []

Default: \[".", dirname($0), "/etc"\]       on Linux-like systems
Default: \[".", dirname($0), 'C:\\Windows'\] on Windows-like systems

Overloading path is a good way to migrate from one location to another over time.

    package My::Connect;
    use base qw{DBIx::Array::Connect};
    sub path {[".", "..", "/etc", "/home"]};

Put INI file in the same folder as tnsnames.ora file.

    package My::Connect::Oracle;
    use base qw{DBIx::Array::Connect};
    use Path::Class qw{};
    sub path {[Path::Class::dir($ENV{"ORACLE_HOME"}, qw{network admin})]}; #not taint safe

## basename

Returns the INI basename.

You may want to overload the basename property if you inherit this package.

    package My::Connect;
    use base qw{DBIx::Array::Connect};
    sub basename {"whatever.ini"};

Default: database-connections-config.ini

## cfg

Returns the [Config::IniFiles](https://metacpan.org/pod/Config::IniFiles) object so that you can read additional information from the INI file.

    my $cfg=$dac->cfg; #isa Config::IniFiles

Example

    my $connection_string=$dac->cfg->val($database, "connection");

# INI File Format

## Section

The INI section is the value that needs to be passed in the connect method which is the database nickname.

    [section]

    my $dbx=DBIx::Array::Connect->new->connect("section");

## connection

The string passed to DBI to connect to the database.

Examples:

    connection=DBI:CSV:f_dir=.
    connection=DBI:mysql:database=mydb;host=myhost.mydomain.tld
    connection=DBI:Sybase:server=mssqlserver.mydomain.tld;datasbase=mydb
    connection=DBI:Oracle:MYTNSNAME

## user

The string passed to DBI as the user.  Default is "" for user-less drivers.

## password

The string passed to DBI as the password.  Default is "" for password-less drivers.

## options

Split and passed as a hash reference to DBI->connect.

    options=AutoCommit=>1, RaiseError=>1, ReadOnly=>1

## execute

Connection settings that you want to execute every time you connect

    execute=ALTER SESSION SET NLS_DATE_FORMAT = 'MM/DD/YYYY HH24:MI:SS'
    execute=INSERT INTO mylog (mycol) VALUES ('Me')

## type

Allows grouping database connections in groups.

    type=group

## active

This option is used by the sections method to filter out databases that may be temporarily down.

    active=1
    active=0

Default: 1

# LIMITATIONS

Once the file method has cached a filename, basename and path are ignored. Once the Config::IniFiles is constructed the file method is ignored.  If you want to use two different INI files, you should construct two different objects.

The file, path and basename methods are common exports from other packages.  Be wary!

# BUGS

Send email to author and log on RT.

# SUPPORT

DavisNetworks.com supports all Perl applications including this package.

# AUTHOR

    Michael R. Davis

# COPYRIGHT

This program is free software licensed under the...

    The General Public License (GPL)
    Version 2, June 1991

The full text of the license can be found in the LICENSE file included with this module.

# SEE ALSO

## The Building Blocks

[DBIx::Array](https://metacpan.org/pod/DBIx::Array), [Config::IniFiles](https://metacpan.org/pod/Config::IniFiles), [Path::Class](https://metacpan.org/pod/Path::Class)

## The Competition

[DBIx::MyPassword](https://metacpan.org/pod/DBIx::MyPassword) uses a CSV file to store data. The constructor is wrapper around DBI->connect.

    my $dbh = DBIx::MyPassword->connect("user");

[DBIx::PasswordIniFile](https://metacpan.org/pod/DBIx::PasswordIniFile) uses an INI file to store data. It uses encrypted passwords and the constructor returns array reference to feed into DBI->connect.

    my $dbh = DBI->connect(@{DBIx::PasswordIniFile->new(%arg)->getDBIConnectParams})

[DBIx::Password](https://metacpan.org/pod/DBIx::Password) uses and internal hash reference to store data.  The constructor is wrapper around DBI->connect. 

    my $dbh = DBIx::Password->connect("user");

## The Comparison

[DBIx::Array::Connect](https://metacpan.org/pod/DBIx::Array::Connect) uses an INI file to store data.  The constructor returns a [DBIx::Array](https://metacpan.org/pod/DBIx::Array) object which is a wrapper around DBI.

    my $dbx = DBIx::Array::Connect->new->connect("nickname");
    my $dbh = $dbx->dbh; #if you don't want to use DBIx::Array...
