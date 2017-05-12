#!perl

use strict;
use warnings;

use Data::HandyGen::mysql;
use DBI;
use JSON qw(decode_json);
use YAML;
use Getopt::Long;

my %ids = ();
my $req;

main();
exit(0);

=head1 NAME

hd_insert_bulk.pl - Inserts records into mysql tables, using Data::HandyGen.


=head1 VERSION

This documentation refers to hd_insert_bulk.pl 0.0.2

=cut

sub main {
    my $infile;
    my $debug = 0;
    my $noutf8 = 0;
    my ($dbname, $host, $port, $user, $password);
    my ($target_table, $number, $required_fields);
    GetOptions(
        'i|in|infile=s' => \$infile,
        'd|dbname=s'    => \$dbname,
        'h|host=s'      => \$host,
        'port=i'        => \$port,
        'u|user=s'      => \$user,
        'p|password=s'  => \$password,
        'debug'         => \$debug,
        'noutf8'        => \$noutf8,
        't|table=s'     => \$target_table,
        'n|number=i'    => \$number,
        'required=s'    => \$required_fields,
    );
   
    ($infile) or ($target_table and $number) or usage();

    my $dsn = "dbi:mysql:dbname=$dbname";
    $host and $dsn .= ";host=$host";
    $port and $dsn .= ";port=$port";

    my $dbh = DBI->connect($dsn, $user, $password, { RaiseError => 1, AutoCommit => 0 })
        or die $DBI::errstr;
    $dbh->do("SET NAMES UTF8") unless $noutf8;

    my $hd = Data::HandyGen::mysql->new( dbh => $dbh, fk => 1, debug => $debug );

    eval {
        if ( $infile ) {
            insert_from_file($hd, $infile);
        }
        else {
            insert_to_table($hd, $target_table, $number, $required_fields);
        }
    };
    if ($@) {
        $hd->dbh->rollback;
        die "Failed to insert : $@";
    }
    else {
        $hd->dbh->commit;
    }

    print YAML::Dump($hd->inserted);
}



sub insert_from_file {
    my ($hd, $infile) = @_;

    open my $JSON, '<', $infile
        or die "Failed to open infile : $infile : $!";
    my $json = do { local $/; <$JSON> };
    close $JSON;

    $req = decode_json($json);

    for my $table (keys %$req) {

        my $list = $req->{$table};
        
        #  When arrayref is passed instead of hashref, IDs in the arrayref will be assigned to each elements.
        if ( ref $list eq 'ARRAY' ) {
            $list = {};
            my $no = 1;
            for ( @{ $req->{$table} } ) {
                $list->{$no++} = $_;
            }
        }

        for my $id ( keys %$list ) {
            next if $ids{$table}{$id};
            my $real_id = insert($hd, $table, $list->{$id});
            $ids{$table}{$id} = $real_id;
        }
    }
}


sub insert_to_table {
    my ($hd, $table, $num, $required) = @_;

    my %user_val = ();
    for ( split ',', $required ) {
        $user_val{$_} = \'any';
    }

    for ( 1 .. $num ) {
        $hd->insert($table, \%user_val);
    } 
}


sub insert {
    my ($hd, $table, $rec) = @_;

    my %user_val = ();
    for my $col ( keys %$rec ) {

        if ( $rec->{$col} =~ /^##(\w+)\.(\d+)$/ ) {
            my $ref_table = $1;
            my $ref_id    = $2;
            unless ( $ids{$ref_table}{$ref_id} ) {

                ref($req->{$ref_table}) eq 'HASH'
                    or die "Invalid ID reference. table = $ref_table, ID = $ref_id";

                my $real_id = insert($hd, $ref_table, $req->{$ref_table}{$ref_id});
                $ids{$ref_table}{$ref_id} = $real_id;
            }
            $user_val{$col} = $ids{$ref_table}{$ref_id};
        }
        else {
            $user_val{$col} = $rec->{$col};
        }
    }

    my $id = $hd->insert($table, \%user_val);

    return $id;
}




sub usage {
    print STDERR <<USAGE;
Options:
    -d(--dbname)      : database name
    -h(--host)        : host
    --port            : port no
    -u(--user)        : username
    -p(--password)    : password

Options reading config from file:
    -i(--in,--infile) : input file (JSON)

Options simply inserting records to a table:
    -t(--table)       : table
    -n(--number)      : the number of inserted records
    --required        : a list of columns which require value

USAGE

    exit(-1);
}



__END__




=head1 USAGE

    $ hd_insert_bulk.pl --infile mysample.json -d mydb -u myuser -p mypasswd


=head1 ARGUMENTS

=head2 General

=over 4

=item * -d | --dbname

I<< (Required) >> A name of database

=item * -h | --host

I<< (Optional) >> Hostname of database

=item * --port

I<< (Optional) >> Port no.

=item * -u | --user

I<< (Required) >> User name to connect mysql

=item * -p | --password

I<< (Required) >> Password to connect mysql

=back

=head2 Required only using config file

=over 4

=item * -i | --in | --infile

I<< (Required) >> a file in which a list of records to be inserted is written.

=back

=head2 Required only specifying table name and the number of records

=over 4

=item * -t | --table
I<< (Required) >> target table name

=item * -n | --number
I<< (Required) >> the number of inserted records

=item * --required
I<< (Optional) >> a list of column names which require value. Multiple columns should be separated by comma(,), like 'col_1,col_2,col_3'. This option is useful when you want any value to be inserted to nullable columns.

=back

 
=head1 DESCRIPTION
 
This application inserts a collection of data into tables. You don't need to specify values to every required fields. You only need to specify values what you're really interested in. If you don't want to consider foreign key constraints, nor the order of insertion (usually you would insert a referenced record at first), it's ok. This application automatically determines values for required fields in the right order.


=head2 HOW TO PREPARE INPUT FILE


    [Sample table definitions]

    create table item (
        id integer primary key auto_increment,
        name varchar(20)
    );

    create table customer (
        id integer primary key auto_increment,
        name varchar(50) not null
    );
        
    create table purchase (
        id integer primary key auto_increment,
        customer_id integer not null,
        item_id integer not null,
        constraint foreign key (customer_id) references customer(id),
        constraint foreign key (item_id) references item(id)
    );



=head3 json

Currently this application accepts JSON format.

FORMAT:

    {
        (table name) : {
            (ID): { (column name): (value), ... },
            ...
        },
        ....
    }

EXAMPLE: Save the following as C<example.json>

    {
        "item" : {
            "1": { "name": "Apple" },
            "2": { "name": "Banana" }
        },
        "customer": {
            "1": { },
            "2": { }
        },
        "purchase" : {
            "1": { "customer_id" : "##customer.1", "item_id" : "##item.1" },
            "2": { "customer_id" : "##customer.2", "item_id" : "##item.1" },
            "3": { "customer_id" : "##customer.2", "item_id" : "##item.2" }
        }
    }
    
    * If a value references foreign key, its format is "##(table name).(ID)".


This will make

    $ hd_insert_bulk.pl --infile example.json -d testdb -u myuser -p mypasswd

    [item] (Assuming next auto_increment value is 101)
        +-----+--------+
        | id  | name   |
        |-----+--------|
        | 101 | Apple  |
        | 102 | Banana |
        +-----+--------+

    [customer] (Assuming next auto_increment value is 50)
        +-----+---------+
        | id  | name    |
        |-----+---------|
        |  50 | name_50 |
        |  51 | name_51 |
        +-----+---------+
        * No values in table 'customer' has been specified, so required values in the table will be determined automatically. 
    
    [purchase] (Assuming next auto_increment value is 501)
        +-----+-------------+---------+
        | id  | customer_id | item_id |
        |-----+-------------+---------+
        | 501 |          50 |     101 |
        | 502 |          51 |     102 |
        | 503 |          51 |     101 |
        +-----+-------------+---------+

NOTE: ID can be omitted if it starts with 1 and is incremented one by one. 

        "purchase" : {
            "1": { "customer_id" : "##customer.1", "item_id" : "##item.1" },
            "2": { "customer_id" : "##customer.2", "item_id" : "##item.1" },
            "3": { "customer_id" : "##customer.2", "item_id" : "##item.2" }
        }

is equivalent to:

        "purchase" : [
            { "customer_id" : "##customer.1", "item_id" : "##item.1" },
            { "customer_id" : "##customer.2", "item_id" : "##item.1" },
            { "customer_id" : "##customer.2", "item_id" : "##item.2" }
        ]

This is especially useful when those records won't be referenced from any other tables and you don't need to care about its ID.

=head1 OUTPUT

It will output all table names and IDs to STDOUT with YAML format like the followings:

    ---
    customer:
      - 50
      - 51
    item:
      - 101
      - 102
    purchase:
      - 501
      - 502
      - 503


You can use those values to delete test data. If you redirect the output to a file, you may later pass it to hd_delete_all.pl (included in this package) as an argument to delete those records.

    $ hd_insert_bulk.pl --infile example.json -d testdb -u myuser -p mypasswd > inserted.yml
    
    #  ...later

    $ hd_delete_all inserted.yml --i inserted.yml -d testdb -u myuser -p mypasswd
    (This will delete all records above)


=head1 TODO

=over 4

=item * To handle also YAML, CSV and TSV formats.


=back
 
=head1 BUGS AND LIMITATIONS

Please report problems to Takashi Egawa (C<< egawa.takashi at gmail com >>)
Patches are welcome.


=head1 SEE ALSO

L<Data::HandyGen::mysql>
L<hd_delete_all.pl>


=head1 AUTHOR

Takashi Egawa (C<< egawa.takashi at gmail com >>)


=head1 LICENCE AND COPYRIGHT

Copyright (c)2013 Takashi Egawa (C<< egawa.takashi at gmail com >>). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 

