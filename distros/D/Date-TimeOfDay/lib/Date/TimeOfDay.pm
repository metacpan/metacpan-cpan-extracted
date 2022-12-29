package Date::TimeOfDay;

use 5.010001;
use strict;
use warnings;

use overload (
    #fallback => 1,
    '<=>'    => '_compare_overload',
    'cmp'    => '_string_compare_overload',
    q{""}    => 'stringify',
    q{0+}    => 'float',
    bool     => sub {1},
    #'-'      => '_subtract_overload',
    #'+'      => '_add_overload',
    'eq'     => '_string_equals_overload',
    'ne'     => '_string_not_equals_overload',
);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-22'; # DATE
our $DIST = 'Date-TimeOfDay'; # DIST
our $VERSION = '0.006'; # VERSION

sub new {
    my $class = shift;
    my %args = @_;

    my $tod = 0;
    if (defined $args{hour}) {
        die "'hour' must be an integer"
            unless $args{hour} == int($args{hour});
        die "'hour' must be between 0 & 23"
            unless $args{hour} >= 0 && $args{hour} <= 23;
        $tod += delete($args{hour}) * 3600;
    } else {
        die "Please specify 'hour'";
    }
    if (defined $args{minute}) {
        die "'minute' must be an integer"
            unless $args{minute} == int($args{minute});
        die "'minute' must be between 0 & 59"
            unless $args{minute} >= 0 && $args{minute} <= 59;
        $tod += delete($args{minute}) * 60;
    } else {
        die "Please specify 'minute'";
    }
    if (defined $args{second}) {
        die "'second' must be an integer"
            unless $args{second} == int($args{second});
        die "'second' must be between 0 & 59"
            unless $args{second} >= 0 && $args{second} <= 59;
        $tod += delete($args{second});
    } else {
        die "Please specify 'second'";
    }

    if (defined $args{nanosecond}) {
        die "'nanosecond' must be an integer"
            unless $args{nanosecond} == int($args{nanosecond});
        die "'nanosecond' must be between 0 & 999_999_999"
            unless $args{nanosecond} >= 0 && $args{nanosecond} <= 999_999_999;
        $tod += delete($args{nanosecond}) / 1e9;
    }

    die "Unknown parameter(s): ".join(", ", sort keys %args) if keys %args;

    return bless \$tod, $class;
}

sub from_float {
    my $class = shift;
    my %args = @_;

    my $tod;
    if (defined $args{float}) {
        $tod = delete($args{float}) + 0;
        die "'float' must be between 0-86400"
            unless $tod >= 0 && $tod < 86400;
    } else {
        die "Please specify 'float'";
    }

    die "Unknown parameter(s): ".join(", ", sort keys %args) if keys %args;

    return bless \$tod, $class;
}

sub from_hms {
    my $class = shift;
    my %args = @_;

    my $tod;
    if (defined $args{hms}) {
        my $hms = delete $args{hms};
        $hms =~ /\A([0-9]{1,2}):([0-9]{1,2})(?::([0-9]{1,2})(\.[0-9]{1,9})?)?\z/
            or die "Invalid hms '$hms', must be hh:mm:ss or hh:mm";
        $tod = $class->new(
            hour=>$1, minute=>$2,
            second => defined($3) ? $3 : 0,
            nanosecond=>defined($4) ? $4*1e9 : 0);
    } else {
        die "Please specify 'hms'";
    }

    die "Unknown parameter(s): ".join(", ", sort keys %args) if keys %args;

    $tod;
}

sub _now {
    require Time::Local;

    my ($class, $utc, $time) = @_;

    my @time = $utc ? gmtime($time) : localtime($time);
    @time[0..2] = (0,0,0);

    my $time_bod = $utc ?
        Time::Local::timegm(@time) : Time::Local::timelocal(@time);

    my $tod = $time - $time_bod;
    return bless \$tod, $class;
}

sub now_local {
    my $class = shift;
    $class->_now(0, time());
}

sub now_utc {
    my $class = shift;
    $class->_now(1, time());
}

sub hires_now_local {
    require Time::HiRes;

    my $class = shift;
    $class->_now(0, Time::HiRes::time());
}

sub hires_now_utc {
    require Time::HiRes;

    my $class = shift;
    $class->_now(1, Time::HiRes::time());
}

sub _elements {
    my $self = shift;

    my $n = $$self;
    my $hour   = int($n / 3600); $n -= $hour*3600;
    my $minute = int($n /   60); $n -= $minute*60;
    my $second = int($n);        $n -= $second;
    my $nanosecond = sprintf("%.0f", $n*1e9);
    ($hour, $minute, $second, $nanosecond);
}

sub hour {
    my $self = shift;

    my ($hour, $minute, $second, $nanosecond) = $self->_elements;
    $hour;
}

sub minute {
    my $self = shift;

    my ($hour, $minute, $second, $nanosecond) = $self->_elements;
    $minute;
}

sub second {
    my $self = shift;

    my ($hour, $minute, $second, $nanosecond) = $self->_elements;
    $second;
}

sub nanosecond {
    my $self = shift;

    my ($hour, $minute, $second, $nanosecond) = $self->_elements;
    $nanosecond;
}

sub float {
    my $self = shift;
    $$self;
}

sub hms {
    my ($self, $sep) = @_;

    $sep //= ":";
    my ($hour, $minute, $second, $nanosecond) = $self->_elements;

    sprintf("%02d%s%02d%s%02d", $hour, $sep, $minute, $sep, $second);
}

sub stringify {
    my $self = shift;

    my ($hour, $minute, $second, $nanosecond) = $self->_elements;

    if ($nanosecond) {
        sprintf(
            "%02d:%02d:%s%.11g",
            $hour,
            $minute,
            $second < 10 ? "0" : "",
            $second + $nanosecond/1e9);
    } else {
        sprintf("%02d:%02d:%02d", $hour, $minute, $second);
    }
}

sub strftime {
    # XXX
}

sub compare {
    my $class = ref $_[0] ? undef : shift;
    my ($tod1, $tod2) = @_;

    unless ($tod1->can('float') && $tod2->can('float')) {
        die "A Date::TimeOfDay object can only be compared to another ".
            "Date::TimeOfDay object";
    }
    $tod1->float <=> $tod2->float;
}

sub _compare_overload {
    my ($tod1, $tod2, $flip) = @_;
    ($flip ? -1:1) * (compare($tod1, $tod2));
}

sub _string_compare_overload {
    my ($tod1, $tod2, $flip) = @_;
    ($flip ? -1:1) * ("$tod1" cmp "$tod2");
}

sub _string_equals_overload {
    my ($tod1, $tod2) = @_;
    "$tod1" eq "$tod2";
}

sub _string_not_equals_overload {
    my ($tod1, $tod2) = @_;
    "$tod1" ne "$tod2";
}

1;
# ABSTRACT: Represent time of day (hh:mm:ss)

__END__

=pod

=encoding UTF-8

=head1 NAME

Date::TimeOfDay - Represent time of day (hh:mm:ss)

=head1 VERSION

This document describes version 0.006 of Date::TimeOfDay (from Perl distribution Date-TimeOfDay), released on 2022-09-22.

=head1 SYNOPSIS

 use Date::TimeOfDay;

 my $tod = Date::TimeOfDay->new(
     hour=>23, minute=>59, second=>59,
     # nanosecond => 999_999_999, # optional
 );

=head1 DESCRIPTION

B<EARLY RELEASE, API MIGHT CHANGE WITHOUT NOTICE.>

This is a simple module to represent time of day. Interface is modelled after
L<DateTime>. Internal representation is currently float (number of seconds from
midnight 00:00:00). Currently does not handle leap second nor time zone.

TODO:

 * set
 * strftime
 * add DateTime + TimeOfDay
 * add TimeOfDay + TimeOfDay
 * convert to duration
 * convert to another time zone

=head1 METHODS

=head2 new

=head2 from_hms

Example:

 my $tod = Date::TimeOfDay->from_hms(hms => "23:59:59");
 say $tod; # => "23:59:59"

=head2 from_float

Example:

 my $tod = Date::TimeOfDay->from_float(float => 86399);
 say $tod; # => "23:59:59"

=head2 now_local

=head2 hires_now_local

=head2 now_utc

=head2 hires_now_utc

=head2 hour

=head2 minute

=head2 second

=head2 nanosecond

=head2 float

=head2 hms

Usage:

 $tod->hms([ $sep ])

Default separator is ":".

=head2 (TODO) set

=head2 (TODO) strftime

=head2 stringify

Is also invoked via overload of q("").

=head2 compare

Example:

 $tod->compare($tod2); # -1 if $tod is less than $tod2, 0 if equal, 1 if greater than

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Date-TimeOfDay>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Date-TimeOfDay>.

=head1 SEE ALSO

L<DateTime>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Date-TimeOfDay>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
