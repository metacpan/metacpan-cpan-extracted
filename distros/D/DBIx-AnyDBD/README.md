# NAME

DBIx::AnyDBD - DBD independent class

# VERSION

Version 2.02

# SYNOPSIS

This class provides application developers with an abstraction class
a level away from DBI, that allows them to write an application that
works on multiple database platforms. The idea isn't to take away the
responsibility for coding different SQL on different platforms, but
to simply provide a platform that uses the right class at the right
time for whatever DB is currently in use.

    use DBIx::AnyDBD;
    
    my $db = DBIx::AnyDBD->connect("dbi:Oracle:sid1", 
        "user", "pass", {}, "MyClass");

    my $foo = $db->foo;
    my $blee = $db->blee;

That doesn't really tell you much... Because you have to implement a
bit more than that. Underneath you have to have a module 
MyClass::Oracle that has methods foo() and blee in it. If those
methods don't exist in MyClass::Oracle, it will check in MyClass::Default,
allowing you to implement code that doesn't need to be driver
dependent in the same module. The foo() and blee() methods will receive
the DBIx::AnyDBD instance as thier first parameter, and any parameters
you pass just go as parameters.

See the example Default.pm and Sybase.pm classes in the AnyDBD directory
for an example.

Underneath it's all implemented using the ISA hierarchy, which is modified 
when you connect to your database. The inheritance tree ensures that the
right functions get called at the right time. There is also an AUTOLOADer
that steps in if the function doesn't exist and tries to call the function
on the database handle (i.e. in the DBI class). The sub-classing uses
`ucfirst($dbh-`{Driver}->{Name})> (along with some clever fiddling for
ODBC and ADO) to get the super-class, so if you don't know what to name
your class (see the list below first) then check that.

# SUBROUTINES/METHODS

## new

    dsn => $dsn, 
    user => $user, 
    pass => $pass, 
    attr => $attr,
    package => $package

new() is a named parameter call that connects and creates a new db object
for your use. The named parameters are dsn, user, pass, attr and package.
The first 4 are just the parameters passed to DBI->connect, and package
contains the package prefix for your database dependent modules, for example,
if package was "MyPackage", the AUTOLOADer would look for 
MyPackage::Oracle::func, and then MyPackage::Default::func. Beware that the
DBD driver will be ucfirst'ed, because lower case package names are reserved
as pragmas in perl. See the known DBD package mappings below.

If package parameter is undefined then the package name used to call
the constructor is used.  This will usually be DBIx::AnyDBD.  This, in
itself, is not very useful but is convenient if you subclass
DBIx::AnyDBD.

If attr is undefined then the default attributes are:

    AutoCommit => 1
    PrintError => 0
    RaiseError => 1

So be aware if you don't want your application dying to either eval{} all
db sections and catch the exception, or pass in a different attr parameter.

After re-blessing the object into the database specific object, DBIx::AnyDBD
will call the \_init() method on the object, if it exists. This allows you
to perform some driver specific post-initialization.

## new\_with\_dbh

Instantiate an object around an existing DBI database handle.

## connect($dsn, $user, $pass, $attr, $package)

connect() is very similar to DBI->connect, taking exactly the same first
4 parameters. The 5th parameter is the package prefix, as above.

connect() doesn't try and default attributes for you if you don't pass them.

After re-blessing the object into the database specific object, DBIx::AnyDBD
will call the \_init() method on the object, if it exists. This allows you
to perform some driver specific post-initialization.

## $db->get\_dbh()

This method is mainly for the DB dependent modules to use, it returns the
underlying DBI database handle. There will probably have code added here
to check the db is still connected, so it may be wise to always use this
method rather than trying to retrieve $self->{dbh} directly.

## Controlling error propagation from AUTOLOADed DBI methods

Typicially the implementation packages will make calls to DBI methods
as though they were methods of the DBIx::AnyDBD object.  If one of
these methods reports an error in DBI::AnyDBD then the error is caught
and rethrown by DBIx::AnyDBD so that the error is reported as occuring
in the implementation module.  It does this by calling Carp::croak()
with the current package set to DBIx::AnyDBD::Carp.

Usually this the the right thing to do but sometimes you may want to
report the error in the line containing the original method call on
the DBIx::AnyDBD object.  In this case you should temporarily set
@DBIx::AnyDBD::Carp::ISA.

    my $db = DBIx::AnyDBD->connect("dbi:Oracle:sid1", 
        "user", "pass", {}, "MyClass");

    my $foo = $db->foo;
    my $blee = $db->blee("too few arguments"); # Error reported here

    package MyClass::Oracle;
    
    sub foo { 
        shift->prepare("Invalid SQL"); # Error reported here
    }

    sub blee {
        local @DBIx::AnyDBD::Carp::ISA = __PACKAGE__;
        shift->selectall_arrayref(BLEE_STATEMENT,{},@_); # Error not reported here
    }

# NOTES

## Known DBD Package Mappings

The following are the known DBD driver name mappings, including ucfirst'ing
them:

    DBD::Oracle => Oracle.pm
    DBD::SQLite => SQLite.pm
    DBD::Sybase => Sybase.pm
    DBD::Pg => Pg.pm
    DBD::mysql => Mysql.pm
    DBD::Informix => Informix.pm
    DBD::AdabasD => AdabasD.pm
    DBD::XBase => XBase.pm

If you use this on other platforms, let me know what the mappings are.

## ODBC

ODBC needed special support, so when run with DBD::ODBC, we call GetInfo
to find out what database we're connecting to, and then map to a known package.
The following are the known package mappings for ODBC:

    Microsoft SQL Server (7.0 and MSDE) => MSSQL.pm
    Microsoft SQL Server (6.5 and below) => Sybase.pm (sorry!)
    Sybase (ASE and ASA) => Sybase.pm
    Microsoft Access => Access.pm
    Informix => Informix.pm
    Oracle => Oracle.pm
    Adabas D => AdabasD.pm

Anything that isn't listed above will get mapped using the following rule:

    Get rdbms name using: $dbh->func(17, GetInfo);
    Change whitespace to a single underscore
    Add .pm on the end.

So if you need to know what your particular database will map to, simply run
the $dbh->func(17, GetInfo) method to find out.

ODBC also inserts `$package::ODBC.pm` into the hierarchy if it exists, so
the hierarchy will look like:

    DBIx::AnyDBD <= ODBC.pm <= Informix.pm

(given that the database you're connecting to would be Informix). This is
useful because ODBC provides its own SQL abstraction layer.

## ADO

ADO uses the same semantics as ODBC for determining the right driver or
module to load. However in extension to that, it inserts an ADO.pm into
the inheritance hierarchy if it exists, so the hierarchy would look like:

    DBIx::AnyDBD <= ODBC.pm <= ADO.pm <= Informix.pm

I do understand that this is not fundamentally correct, as not all ADO
connections go through ODBC, but if you're doing some of that funky stuff
with ADO (such as queries on MS Index Server) then you're not likely to
need this module!

# LICENCE

This module is free software, and you may distribute it under the same 
terms as Perl itself.

# AUTHOR

Matt Sergeant, `<matt@sergeant.org>`

Maintained by Nigel Horne, `<njh at bandsman.co.uk>`

# SEE ALSO

Check out the example files in the example/ directory.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::AnyDBD

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/DBIx-AnyDBD](https://metacpan.org/release/DBIx-AnyDBD)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-AnyDBD](https://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-AnyDBD)

- CPANTS

    [http://cpants.cpanauthors.org/dist/DBIx-AnyDBD](http://cpants.cpanauthors.org/dist/DBIx-AnyDBD)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=DBIx-AnyDBD](http://matrix.cpantesters.org/?dist=DBIx-AnyDBD)

- CPAN Ratings

    [http://cpanratings.perl.org/d/DBIx-AnyDBD](http://cpanratings.perl.org/d/DBIx-AnyDBD)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=DBIx::AnyDBD](http://deps.cpantesters.org/?module=DBIx::AnyDBD)

- Search CPAN

    [http://search.cpan.org/dist/DBIx-AnyDBD/](http://search.cpan.org/dist/DBIx-AnyDBD/)
