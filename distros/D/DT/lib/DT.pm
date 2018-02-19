package DT;

use strict;
use warnings 'FATAL';
no warnings 'uninitialized';

use Carp qw();
use Scalar::Util qw(looks_like_number);
use Sub::Install;

use parent 'DateTime::Moonpig';

our $VERSION = '0.2.3';

my ($HAVE_PG, $HAVE_ISO);

sub import {
    my ($class, @args) = @_;

    $HAVE_PG = $HAVE_ISO = undef;

    if ( grep /^:?pg$/, @args ) {
        eval { require DateTime::Format::Pg };
        Carp::croak($@) if $@;

        $HAVE_PG = 1;
    }

    if ( not grep /^:?no_iso(?:8601)?$/, @args ) {
        eval { require DateTime::Format::ISO8601 };
        Carp::croak($@) if $@;

        $HAVE_ISO = 1;
    }
}

sub new {
    my $class = shift;

    my $dt;

    if ( @_ == 1 ) {
        # Most probably Unix time, will croak if not
        if ( looks_like_number $_[0] ) {
            $dt = $class->SUPER::new(@_);
        }
        elsif ( not ref $_[0] ) {
            # May be ISO8601(ish) format used by PostgreSQL
            $dt = eval { DateTime::Format::Pg->parse_datetime($_[0]) }
                if $HAVE_PG;

            # May be a real ISO8601 format date/time
            $dt = eval { DateTime::Format::ISO8601->parse_datetime($_[0]) }
                if $HAVE_ISO and not $dt;
        }
    }

    # This will croak
    $dt = DateTime->new(@_) unless $dt;

    # Rebless into DT so our methods work
    return bless $dt, $class;
}

sub unix_time {
    my ($dt) = @_;

    return $dt->epoch;
}

sub pg_timestamp_notz {
    my ($dt) = @_;

    return DateTime::Format::Pg->format_timestamp_without_time_zone($dt);
}

sub pg_timestamp_tz {
    my ($dt) = @_;
    
    return DateTime::Format::Pg->format_timestamptz($dt);
}

{
    for my $method (qw(
        add_duration subtract_duration
        truncate
        set set_time_zone set_year set_month set_day
        set_hour set_minute set_second set_nanosecond
    )) {
        Sub::Install::install_sub({
            code => sub {
                my $dt = shift;
                
                my $copy = $dt->clone;
                bless $copy, 'DateTime';
                
                $copy->$method(@_);
                
                bless $copy, ref $dt;
                
                return $copy;
            },
            as => $method,
        });
    }
}

1;

__END__
=pod

=begin readme text

DT
==

=end readme

=for readme stop

=head1 NAME

DT - DateTime wrapper that tries hard to DWYM

=head1 SYNOPSIS

    use DT qw(:pg);

    my $dt_now = DT->new(time); # Just works
    my $dt_fh = DT->new('2018-02-06T15:45:00-0500'); # Just works

    my ($pg_time_str) = $pg_dbh->selectrow_array("SELECT now();")
    my $dt_pg = DT->new($pg_time_str); # Also just works

    my $timestamp_notz = $dt_pg->pg_timestamp_notz;
    my $timestamp_tz = $dt->pg->pg_timestamp_tz;

=head1 DESCRIPTION

=for readme continue

DT is a very simple and thin wrapper over DateTime::Moonpig, which
in turn is a wrapper over DateTime. DateTime::Moonpig brings immutability
and saner operator overloading at the cost of cartoonish name but also
lacks date/time parsing capabilities that are badly needed all the time.

There is a myriad of helpful modules on CPAN but oh all that typing!

Consider:

    use DateTime;
    my $dt = DateTime->from_epoch(epoch => time);

    use DateTime::Format::Pg;
    my $dt = DateTime::Format::Pg->parse_datetime($timestamp_from_postgres);

    use DateTime::Format::ISO8601;
    my $dt = DateTime::Format::ISO8601->parse_datetime($iso_datetime);

Versus:

    use DT ':pg';
    my $dt_unix = DT->new(time);
    my $dt_pg = DT->new($timestamp_from_postgres);
    my $dt_iso = DT->new($iso_datetime);

DT constructor will try to Do What You Mean, and if it cannot it will
fall back to default DateTime constructor. Simple.

=for readme stop

=head1 IMMUTABILITY AND DATE MATH

One thing that L<DateTime::Moonpig> authors get right is data immutability:
any operations on a L<DateTime> object should not mutate original object
as this leads to a multitude of potential prioblems.

However the solution presented in L<DateTime::Moonpig> is to throw an exception
when a mutator method is called, which is far from Doing What I Mean. Even more,
with C<add_duration> and C<subtract_duration> methods rendered effectively unusable
the only way to handle date arithmetic suggested is by adding or subtracting
the number of seconds from the date which semantically is not the same as adding
or subtracting days/months/etc.

A more reasonable approach is to clone the date object, perform the mutation
on the copy and return the new object.

=head1 METHODS

The following mutator methods are overridden to return a new C<DT> object
instead of performing operations on the original object:

C<add>, C<add_duration>, C<subtract>, C<subtract_duration>, C<truncate>,
C<set>, C<set_time_zone>, C<set_year>, C<set_month>, C<set_day>,
C<set_hour>, C<set_minute>, C<set_second>, C<set_nanosecond>

Note that C<set_locale> and C<set_formatter> are not overridden. These methods
do not affect the actual date/time value so are safe to use.

DT also adds a few useful methods:

=over 4

=item C<unix_time>

A synonym for C<epoch>. No special magic, just easier to remember.

=item C<pg_timestamp_notz>

Format $dt object into a string suitable for PostgreSQL
C<TIMESTAMP WITHOUT TIME ZONE> type column.

=item C<pg_timestamp_tz>

Format $dt object into a string suitable for PostgreSQL
C<TIMESTAMP WITH TIME ZONE> type column.

=back

=for readme continue

=head1 INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make && make test && make install

=for readme stop

=for readme continue

=head1 DEPENDENCIES

L<DateTime::Moonpig> is the parent class for C<DT>. L<DateTime::Format::ISO8601>
is required for parsing ISO8601 date/time formats.

PostgreSQL related methods are optional and depend on L<DateTime::Format::Pg>
being installed.

=for readme stop

=head1 REPORTING BUGS

No doubt there are some. Please post an issue on GitHub (see below)
if you find something. Pull requests are also welcome.

GitHub repository: https://github.com/nohuhu/DT

=for readme continue

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 by Alex Tokarev E<lt>nohuhu@cpan.orgE<gt>.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<"perlartistic">.

=for readme stop

=cut
