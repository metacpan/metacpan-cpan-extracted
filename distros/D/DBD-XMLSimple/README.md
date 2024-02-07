# NAME

DBD::XMLSimple - Access XML data via the DBI interface

# VERSION

Version 0.07

# SYNOPSIS

Reads XML and makes it available via DBI.

Sadly DBD::AnyData doesn't work with the latest DBI and DBD::AnyData2 isn't
out yet, so I am writing this pending the publication of DBD::AnyData2

DBD-XMLSimple doesn't yet expect to support complex XML data, so that's why
it's not called DBD-XML.

    use FindBin qw($Bin);
    use DBI;

    my $dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');

    $dbh->func('person', 'XML', "$Bin/../data/person.xml", 'xmlsimple_import');

    my $sth = $dbh->prepare("SELECT * FROM person");

Input data will be something like this:

    <?xml version="1.0" encoding="US-ASCII"?>
    <table>
        <row id="1">
            <name>Nigel Horne</name>
            <email>njh@bandsman.co.uk</email>
        </row>
        <row id="2">
            <name>A N Other</name>
            <email>nobody@example.com</email>
        </row>
    </table>

If a leaf appears twice it will be concatenated

    <?xml version="1.0" encoding="US-ASCII"?>
    <table>
        <row id="1">
            <name>Nigel Horne</name>
            <email>njh@bandsman.co.uk</email>
            <email>nhorne@pause.org</email>
        </row>
    </table>

    $sth = $dbh->prepare("Select email FROM person");
    $sth->execute();
    $sth->dump_results();

    Gives the output "njh@bandsman.co.uk,nhorne@pause.org"

# SUBROUTINES/METHODS

## driver

No routines in this module should be called directly by the application.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

# SEE ALSO

[DBD::AnyData](https://metacpan.org/pod/DBD%3A%3AAnyData), which was also used as a template for this module.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBD::XMLSimple

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBD-XMLSimple](http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBD-XMLSimple)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/DBD-XMLSimple](http://annocpan.org/dist/DBD-XMLSimple)

- CPAN Ratings

    [http://cpanratings.perl.org/d/DBD-XMLSimple](http://cpanratings.perl.org/d/DBD-XMLSimple)

- Search CPAN

    [http://search.cpan.org/dist/DBD-XMLSimple/](http://search.cpan.org/dist/DBD-XMLSimple/)

# LICENCE AND COPYRIGHT

Copyright 2016-2024 Nigel Horne.

This program is released under the following licence: GPL
