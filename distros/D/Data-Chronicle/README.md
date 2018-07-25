# Chronicle storage system (perl-Data-Chronicle)

[![Build Status](https://travis-ci.org/binary-com/perl-Data-Chronicle.svg?branch=master)](https://travis-ci.org/binary-com/perl-Data-Chronicle)
[![codecov](https://codecov.io/gh/binary-com/perl-Data-Chronicle/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Data-Chronicle)

This repository contains three modules (Reader, Writer, and Subscriber) which can be used to store and retrieve information
on an efficient storage with below properties:
 
* **Timeliness**
It is assumed that data to be stored are time-based meaning they change over time and the latest version is most important for us.

* **Efficient**:
The module uses Redis cache to provide efficient data storage and retrieval.

* **Persistent**:
In addition to caching every incoming data, it is also stored in PostgresSQL for future retrieval.

* **Transparent**:
This modules hides all the details about caching, database structure and ... from developer. He only needs to call a method
to save data and another method to retrieve it. All the underlying complexities are handled by the module.

Note that you will need to pass `cache_writer`, `cache_reader` and `db_handle` to the `Data::Chronicle::Reader/Writer` modules. These three arguments, provide access to your Redis and PostgreSQL which will be used by Chronicle modules.

`cache_writer` and `cache_reader` should be to be able to get/set given data under given key (both of type string). `db_handle` should be capable to store and retrieve data with `category`,`name` in addition to the timestamp of data insertion. So it should be able to retrieve data for a specific timestamp, category and name. Category, name and data are all string. This can easily be achieved by defining a table in you database containing these columns: `timestamp, category, name, value`. 

There are nine important methods this module provides:

* **set** (in Data::Chronicle::Writer):
Given a category, name and value stores the JSONified value in Redis and PostgreSQL database under "category::name" group and also stores current
system time as the timestamp for the data (Which can be used for future retrieval if we want to get data as of a specific time). Note that the value
MUST be either hash-ref or array-ref.

* **mset** (in Data::Chronicle::Writer):
Given multiple categories, names and values atomically performs the set operation on each corresponding category, name, value set.

* **get** (in Data::Chronicle::Reader):
Given a category and name returns the latest version of the data according to current Redis cache

* **mget** (in Data::Chronicle::Reader):
Given multiple categories and name atomically performs the get operation on each corresponding category, name set.

* **get_for** (in Data::Chronicle::Reader):
Given a category, name and timestamp returns version of data under "category::name" as of the given date (using a DB lookup).

* **get_for_period** (in Data::Chronicle::Reader):
Given a category, name, start_timestamp and end_timestamp returns an array-ref containing all data stored between given period for the given "category::name" (using a DB lookup).

* **get_history** (in Data::Chronicle::Reader):
Given a category, name, and revision returns version of the data the specified number of revisions in the past.
If revision 0 is chosen, the latest version of the data will be returned.
If revision 1 is chosen, the previous version of the data will be returned.

* **subscribe** (in Data::Chronicle::Subscriber):
Given a category, name, and callback assigns the callback to be called when a new value is set for the specified category and name (if the writer has publish_on_set enabled).

* **unsubscribe** (in Data::Chronicle::Subscriber):
Given a category, name, clears the callbacks associated with the specified category and name.

## Examples ##

```
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

```
