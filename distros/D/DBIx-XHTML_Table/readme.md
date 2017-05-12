DBIx::XHTML_Table 
=================
Create HTML tables from SQL queries. [![CPAN Version](https://badge.fury.io/pl/DBIx-XHTML_Table.svg)](https://metacpan.org/pod/DBIx::XHTML_Table) [![Build Status](https://api.travis-ci.org/jeffa/DBIx-XHTML_Table.svg?branch=master)](https://travis-ci.org/jeffa/DBIx-XHTML_Table)

Synopsis
--------
```perl
use DBIx::XHTML_Table;

# database credentials - fill in the 'blanks'
my @creds = ($data_source,$usr,$pass);

my $table = DBIx::XHTML_Table->new( @creds );
$table->exec_query(q(
    select foo from bar
    where baz='qux'
    order by foo
));

print $table->output;

# stackable method calls:
print DBIx::XHTML_Table
    ->new( @creds )
    ->exec_query( 'select foo,baz from bar' )
    ->output;
```

Installation
------------
To install this module, you should use CPAN. A good starting
place is [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html).

If you truly want to install from this github repo, then
be sure and create the manifest before you test and install:
```
perl Makefile.PL
make
make manifest
make test
make install
```

Support and Documentation
-------------------------
* perldoc [DBIx::XHTML_Table](/lib/DBIx/XHTML_Table.pm)
* [Tutorial](http://www.unlocalhost.com/XHTML_Table/tutorial.html)
* [Cookbook](http://www.unlocalhost.com/XHTML_Table/cookbook.html)
* [FAQ](http://www.unlocalhost.com/XHTML_Table/FAQ.html)

Author
------
Jeff Anderson

License & Copyright
-------------------
See [source POD](/lib/DBIx/XHTML_Table.pm) for license and copyright information.
