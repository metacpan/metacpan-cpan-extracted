DBIx::HTML
==========
Just another HTML table generating DBI extension. [![CPAN Version](https://badge.fury.io/pl/DBIx-HTML.svg)](https://metacpan.org/pod/DBIx::HTML)

See [DBIx::HTML](http://search.cpan.org/dist/DBIx-HTML/)
and [Spreadsheet::HTML](http://search.cpan.org/dist/Spreadsheet-HTML/)
for more information.

Synopsis
--------
```perl
use DBIx::HTML;

my $generator = DBIx::HTML->connect( @db_credentials );
$generator->do( $query );

# supports multiple orientations
print $generator->portrait;
print $generator->landscape;

# stackable method calls:
print DBIx::HTML
    ->connect( @db_credentials )
    ->do( 'select foo,baz from bar' )
    ->landscape
;

# rotating attributes:
print $generator->portrait( tr => { class => [qw( odd even )] } );
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
After installing, you can find documentation for this module with the
perldoc command.
```
perldoc DBIx::HTML
```
You can also find documentation at [metaCPAN](https://metacpan.org/pod/DBIx::HTML).

License and Copyright
---------------------
See [source POD](/lib/DBIx/HTML.pm).
