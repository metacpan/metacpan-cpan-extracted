package DT;

use strict;
use warnings 'FATAL';
no warnings 'uninitialized';

use Carp qw();
use Scalar::Util qw(looks_like_number);
use Sub::Install;

use DateTime::Format::ISO8601;

use parent 'DateTime::Moonpig';

our $VERSION = '0.4.0';

use overload
    '=='  => \&_dt_int_eq,
    '!='  => \&_dt_int_ne,
    '<=>' => \&_dt_int_cmp,
    '<'   => \&_dt_int_lt,
    '<='  => \&_dt_int_le,
    '>'   => \&_dt_int_gt,
    '>='  => \&_dt_int_ge,
    'eq'  => \&_dt_str_eq,
    'ne'  => \&_dt_str_ne,
    'cmp' => \&_dt_str_cmp,
    'lt'  => \&_dt_str_lt,
    'le'  => \&_dt_str_le,
    'gt'  => \&_dt_str_gt,
    'ge'  => \&_dt_str_ge;

my $HAVE_PG;

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
            $dt = eval {
                $HAVE_PG || ($HAVE_PG = require DateTime::Format::Pg);
                DateTime::Format::Pg->parse_datetime($_[0]);
            };
            

            # May be a real ISO8601 format date/time
            $dt = eval { DateTime::Format::ISO8601->parse_datetime($_[0]) }
                if not $dt;
        }
    }

    # This will croak
    $dt = DateTime->new(@_) unless $dt;

    # Rebless into DT so our methods are called instead of DateTime
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

sub TO_JSON {
    my ($self) = @_;
    
    return "$self";
}

############## PRIVATE METHODS BELOW ##############

sub _promote {
    my $side_b = $_[1];
    
    # Deliberately not catching errors here
    $side_b = DT->new($side_b)
        if not ref($side_b) or not $side_b->isa('DateTime');
    
    return ($_[0], $side_b, $_[2]);
}

sub _dt_int_eq {
    return undef unless defined $_[1];
    
    my ($side_a, $side_b) = _promote(@_);
    
    return DateTime::compare($side_a, $side_b) == 0;
}

sub _dt_int_cmp {
    return undef unless defined $_[1];

    my ($side_a, $side_b, $flip) = _promote(@_);
    
    return $flip ? DateTime::compare($side_b, $side_a)
         :         DateTime::compare($side_a, $side_b)
         ;
}

sub _dt_int_ne { !defined($_[1]) ? undef : !_dt_int_eq(@_) }
sub _dt_int_lt { !defined($_[1]) ? undef : _dt_int_cmp(@_) < 0 }
sub _dt_int_le { !defined($_[1]) ? undef : _dt_int_cmp(@_) <= 0 }
sub _dt_int_gt { !defined($_[1]) ? undef : _dt_int_cmp(@_) > 0 }
sub _dt_int_ge { !defined($_[1]) ? undef : _dt_int_cmp(@_) >= 0 }

sub _dt_str_eq {
    return undef unless defined $_[1];
    
    my ($side_a, $side_b) = _promote(@_);
    
    return ("$side_a" || '') eq ("$side_b" || '');
}

sub _dt_str_cmp {
    return undef unless defined $_[1];
    
    my ($side_a, $side_b) = _promote(@_);
    
    $side_b = DT->new($side_b)
        if not ref($side_b) or not $side_b->isa('DateTime');
    
    return $_[2] ? ("$side_b" || '') cmp ("$side_a" || '')
         :         ("$side_a" || '') cmp ("$side_b" || '')
         ;
}

sub _dt_str_ne { !defined($_[1]) ? undef : !_dt_str_eq(@_) }
sub _dt_str_lt { !defined($_[1]) ? undef : _dt_str_cmp(@_) < 0 }
sub _dt_str_le { !defined($_[1]) ? undef : _dt_str_cmp(@_) <= 0 }
sub _dt_str_gt { !defined($_[1]) ? undef : _dt_str_cmp(@_) > 0 }
sub _dt_str_ge { !defined($_[1]) ? undef : _dt_str_cmp(@_) >= 0 }

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

    use DT;

    my $dt_now = DT->new(time); # Just works
    my $dt_fh = DT->new('2018-02-06T15:45:00-0500'); # Just works

    my ($pg_time_str) = $pg_dbh->selectrow_array("SELECT now();")
    my $dt_pg = DT->new($pg_time_str); # Also just works
    
    say "Wowza!" if $dt_now < time + 1; # Unexpectedly, works too!

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

    use DT;
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

=head1 DATE COMPARISON

Yet another pretty annoying L<DateTime> quirk is comparison operator overloading.
In my humble opinion it is not very unreasonable to expect a sophisticated date module
to automatically grok something like this and Just Work without throwing an exception,
or requiring a metric ton of boilerplate:

    if ( $dt < time ) {
        ...
    }

As a side effect of added operator overload C<DT> also has saner semantics for
comparing with C<undef> values: the result of course is C<undef>.

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
