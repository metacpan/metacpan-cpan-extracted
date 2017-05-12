package DBIx::Class::TimeStamp::WithTimeZone;

use 5.010001;
use strict;
use warnings;

use base qw(DBIx::Class::TimeStamp);

use DateTime;

our $VERSION = '0.03';

=head1 NAME

DBIx::Class::TimeStamp::WithTimeZone - DBIx::Class::TimeStamp extension that uses a specified timezone

=head1 DESCRIPTION

A subclass of DBIx::Class::TimeStamp that uses a specified timezone instead of the floating timezone.

=head1 SYNOPSIS

 package My::Schema;

 __PACKAGE__->load_components(qw( TimeStamp::WithTimezone ... Core ));

 __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    t_created => { data_type => 'datetime', set_on_create => 1 },
    t_updated => { data_type => 'datetime',
        set_on_create => 1, set_on_update => 1 },
 );

The timezone will be taken from the first environment variable defined:

* TZ

* TIMEZONE

It will default to 'GMT' otherwise.

=cut

sub get_timestamp {
    return DateTime->now->set_time_zone($ENV{TZ}||$ENV{TIMEZONE}||'GMT');
}

1;
