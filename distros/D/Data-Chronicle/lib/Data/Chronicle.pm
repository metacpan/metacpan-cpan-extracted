package Data::Chronicle;
use strict;
use warnings;

=head1 NAME

Data::Chronicle - Chronicle storage system

=cut

our $VERSION = '0.16';

=head1 DESCRIPTION

This package contains two modules (Reader and Writer) which can be used to store and retrieve information
on an efficient storage with below properties:

=head2 Timeliness

It is assumed that data to be stored are time-based meaning they change over time and the latest version is most important for us.

=head2 Efficient

The module uses Redis cache to provide efficient data storage and retrieval.

=head2 Persistent

In addition to caching every incoming data, it is also stored in PostgreSQL for future retrieval.

=head2 Transparent

This modules hides all the details about caching, database structure and ... from developer. He only needs to call a method
to save data and another method to retrieve it. All the underlying complexities are handled by the module.

Note that you will need to pass `cache_writer`, `cache_reader` and `db_handle` to the `Data::Chronicle::Reader/Writer` modules. These three arguments, provide access to your Redis and PostgreSQL which will be used by Chronicle modules.

`cache_writer` and `cache_reader` should be to be able to get/set given data under given key (both of type string). `db_handle` should be capable to store and retrieve data with `category`,`name` in addition to the timestamp of data insertion. So it should be able to retrieve data for a specific timestamp, category and name. Category, name and data are all string. This can easily be achieved by defining a table in you database containing these columns: `timestamp, category, name, value`.

=head1 METHODS

There are four important methods this module provides:

=head2 L<Data::Chronicle::Writer/set>

Given a category, name and value stores the JSONified value in Redis and PostgreSQL database under "category::name" group and also stores current
system time as the timestamp for the data (Which can be used for future retrieval if we want to get data as of a specific time). Note that the value
MUST be either hash-ref or array-ref.

    $writer->set("category1", "name1", "value1");
    $writer->set("category1", "name2", "value2", Date::Utility->new("2016-08-01 00:06:00"));

=head2 L<Data::Chronicle::Reader/get>

Given a category and name returns the latest version of the data according to current Redis cache

    my $value1 = $reader->get("category1, "name1"); #value1

=head2 L<Data::Chronicle::Reader/get_for>

Given a category, name and timestamp returns version of data under "category::name" as of the given date (using a DB lookup).

    my $some_old_data = $reader->get_for("category1", "name2", Date::Utility->new("2016-08-01 00:06:00"));


=head2 L<Data::Chronicle::Reader/get_for_period>

Given a category, name, start_timestamp and end_timestamp returns an array-ref containing all data stored between given period for the given "category::name" (using a DB lookup).

    my $arrayref = $reader->get_for_period("category1", "name2", Date::Utility->new("2015-08-01 00:06:00"), Date::Utility->new("2015-08-01 00:06:00"));

=head1 Examples

    my $d = get_some_log_data();

    my $chronicle_w = Data::Chronicle::Writer->new(
        cache_writer => $writer,
        db_handle    => $dbh);

    my $chronicle_r = Data::Chronicle::Reader->new(
        cache_reader => $reader,
        db_handle    => $dbh);


    #store data into Chronicle - each time we call `set` it will also store
    #a copy of the data for historical data retrieval
    $chronicle_w->set("log_files", "syslog", $d);

    #retrieve latest data stored for syslog under log_files category
    my $dt = $chronicle_r->get("log_files", "syslog");

    #find historical data for `syslog` at given point in time
    my $some_old_data = $chronicle_r->get_for("log_files", "syslog", $epoch1);

=cut

1;
