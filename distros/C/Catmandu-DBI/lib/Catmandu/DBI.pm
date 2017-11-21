package Catmandu::DBI;

our $VERSION = "0.0701";

=head1 NAME

Catmandu::DBI - Catmandu tools to communicate with DBI based interfaces

=head1 SYNOPSIS

    # From the command line

    # Export data from a relational database
    $ catmandu convert DBI --dsn dbi:mysql:foobar --user foo --password bar --query "select * from table"

    # Import data into a relational database
    $ catmandu import JSON to DBI --data_source dbi:SQLite:mydb.sqlite < data.json

    # Export data from a relational database
    $ catmandu export DBI --data_source dbi:SQLite:mydb.sqlite to JSON

    # Or via a configuration file
    $ cat catmandu.yml
    ---
    store:
       mydb:
         package: DBI
         options:
            data_source: "dbi:mysql:database=mydb"
            username: xyz
            password: xyz
    ...
    $ catmandu import JSON to mydb < data.json
    $ catmandu export mydb to YAML > data.yml

    # Export one record
    $ catmandu export mydb --id 012E929E-FF44-11E6-B956-AE2804ED5190 to JSON > record.json

    # Count the number of records
    $ catmandu count mydb

    # Delete data
    $ catmandy delete mydb

=head1 MODULES

L<Catmandu::Importer::DBI>

L<Catmandu::Store::DBI>

=head1 AUTHORS

Nicolas Franck C<< <nicolas.franck at ugent.be> >>

Patrick Hochstenbach C<< <patrick.hochstenbach at ugent.be> >>

Vitali Peil C<< <vitali.peil at uni-bielefeld.de> >>

Nicolas Steenlant C<< <nicolas.steenlant at ugent.be> >>

=head1 SEE ALSO

L<Catmandu>, L<Catmandu::Importer> , L<Catmandu::Store::DBI>

=cut

1;
