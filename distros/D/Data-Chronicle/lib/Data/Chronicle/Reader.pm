package Data::Chronicle::Reader;

use 5.014;
use strict;
use warnings;
use Data::Chronicle;
use Date::Utility;
use JSON::MaybeUTF8 qw(decode_json_utf8);
use Moose;

=head1 NAME

Data::Chronicle::Reader - Provides reading from an efficient data storage for volatile and time-based data

=cut

our $VERSION = '0.17';    ## VERSION

=head1 DESCRIPTION

This module contains helper methods which can be used to store and retrieve information
on an efficient storage with below properties:

=over 4

=item B<Timeliness>

It is assumed that data to be stored are time-based meaning they change over time and the latest version is most important for us.

=item B<Efficient>

The module uses Redis cache to provide efficient data storage and retrieval.

=item B<Persistent>

In addition to caching every incoming data, it is also stored in PostgreSQL for future retrieval.

=item B<Transparent>

This modules hides all the details about distribution, caching, database structure and ... from developer. He only needs to call a method
to save data and another method to retrieve it. All the underlying complexities are handled by the module.

=back

There are three important methods this module provides:

=over 4

=item C<set>

Given a category, name and value stores the JSONified value in Redis and PostgreSQL database under "category::name" group and also stores current
system time as the timestamp for the data (Which can be used for future retrieval if we want to get data as of a specific time). Note that the value
MUST be either hash-ref or array-ref.

=item C<get>

Given a category and name returns the latest version of the data according to current Redis cache

=item C<get_for>

Given a category, name and timestamp returns version of data under "category::name" as of the given date (using a DB lookup).

=back

=head1 Example

 my $d = get_some_log_data();

 my $chronicle_w = Data::Chronicle::Writer->new(
    cache_writer => $writer,
    dbic         => $dbic);

 my $chronicle_r = Data::Chronicle::Reader->new(
    cache_reader => $reader,
    dbic         => $dbic);

 my $chronicle_r2 = Data::Chronicle::Reader->new(
    cache_reader => $hash_ref);

 #store data into Chronicle - each time we call `set` it will also store
 #a copy of the data for historical data retrieval
 $chronicle_w->set("log_files", "syslog", $d);

 #retrieve latest data stored for syslog under log_files category
 my $dt = $chronicle_r->get("log_files", "syslog");

 #find historical data for `syslog` at given point in time
 my $some_old_data = $chronicle_r->get_for("log_files", "syslog", $epoch1);

=cut

=head2 cache_reader

cache_reader can be an object which has `get` method used to fetch data.
or it can be a plain hash-ref.

=cut

has 'cache_reader' => (
    is      => 'ro',
    default => undef,
);

=head2 dbic

dbic should be an object of DBIx::Connector.

=cut

has 'dbic' => (
    isa     => 'Maybe[DBIx::Connector]',
    is      => 'ro',
    default => undef,
);

=head3 C<< my $data = get("category1", "name1") >>

Query for the latest data under "category1::name1" from the cache reader.
Will return `undef` if the data does not exist.

=cut

sub get {
    my $self     = shift;
    my $category = shift;
    my $name     = shift;

    my @cached_data = $self->mget([[$category, $name]]);
    return $cached_data[0] if @cached_data;

    return undef;
}

=head3 C<< my $data = mget([["category1", "name1"], ["category2", "name2"], ...]) >>

Query for the latest data under "category1::name1", "category2::name2", etc from the cache reader.
Will return an arrayref containing results in the same ordering, with `undef` if the data does not exist.

=cut

sub mget {
    my $self  = shift;
    my $pairs = shift;

    my @keys = map { $_->[0] . '::' . $_->[1] } @$pairs;

    if (blessed($self->cache_reader)) {
        my @cached_data = $self->cache_reader->mget(@keys);
        return map { decode_json_utf8($_) if $_ } @cached_data;
    } else {
        return map { $self->cache_reader->{$_} } @keys;
    }

    return undef;
}

=head3 C<< my $data = get_for("category1", "name1", 1447401505) >>

Query Pg archive for the data under "category1::name1" at or exactly before the given epoch/Date::Utility.

=cut

sub get_for {
    my $self     = shift;
    my $category = shift;
    my $name     = shift;
    my $date_for = shift;    #epoch or Date::Utility

    my $db_timestamp = Date::Utility->new($date_for)->db_timestamp;

    die "Requesting for historical data without a valid DB connection [$category,$name,$date_for]" if not defined $self->dbic;

    my $db_data = $self->dbic->run(
        fixup => sub {
            $_->selectall_hashref(q{SELECT * FROM chronicle where category=? and name=? and timestamp<=? order by timestamp desc limit 1},
                'id', {}, $category, $name, $db_timestamp);
        });

    return if not %$db_data;

    my $id_value = (sort keys %{$db_data})[0];
    my $db_value = $db_data->{$id_value}->{value};

    return decode_json_utf8($db_value);
}

=head3 C<< my $data = get_for_period("category1", "name1", 1447401505, 1447401900) >>

Query Pg historical data and return records whose date is between given period.

=cut

sub get_for_period {
    my $self     = shift;
    my $category = shift;
    my $name     = shift;
    my $start    = shift;    #epoch or Date::Utility
    my $end      = shift;    #epoch or Date::Utility

    my $start_timestamp = Date::Utility->new($start)->db_timestamp;
    my $end_timestamp   = Date::Utility->new($end)->db_timestamp;

    die "Requesting for historical period data without a valid DB connection [$category,$name]" if not defined $self->dbic;

    my $db_data = $self->dbic->run(
        fixup => sub {
            $_->selectall_hashref(q{SELECT * FROM chronicle where category=? and name=? and timestamp<=? AND timestamp >=? order by timestamp desc},
                'id', {}, $category, $name, $end_timestamp, $start_timestamp);
        });

    return if not %$db_data;

    my @result;

    for my $id_value (keys %$db_data) {
        my $db_value = $db_data->{$id_value}->{value};

        push @result, decode_json_utf8($db_value);
    }

    return \@result;
}

=head3 C<< my $data = get_history("category1", "name1", 1) >>

Query Pg archive for the data under "category1::name1" at the provided number of revisions in the past.

=cut

sub get_history {
    my $self     = shift;
    my $category = shift;
    my $name     = shift;
    my $rev      = shift;

    die "Revision must be >= 0" unless (defined $rev && $rev >= 0);
    die "Requesting for historical data without a valid DB connection [$category,$name,$rev]" if not defined $self->dbic;

    my $db_data = $self->dbic->run(
        fixup => sub {
            $_->selectall_hashref(q{SELECT * FROM chronicle where category=? and name=? order by timestamp desc limit 1 offset ?},
                'id', {}, $category, $name, $rev);
        });

    return if not %$db_data;

    my $id_value = (sort keys %{$db_data})[0];
    my $db_value = $db_data->{$id_value}->{value};

    return decode_json_utf8($db_value);
}

no Moose;

=head1 AUTHOR

Binary.com, C<< <support at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-chronicle at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Chronicle>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Chronicle::Reader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Chronicle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Chronicle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Chronicle>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Chronicle/>

=back


=head1 ACKNOWLEDGEMENTS

=cut

1;
