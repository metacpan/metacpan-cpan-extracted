package Data::Sah::Util::Type::Date;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Scalar::Util qw(blessed looks_like_number);

require Exporter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-01'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.911'; # VERSION

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       coerce_date
                       coerce_duration
               );

our $DATE_MODULE = $ENV{DATA_SAH_DATE_MODULE} // $ENV{PERL_DATE_MODULE} //
    "DateTime"; # XXX change defaults to Time::Piece (core)

my $re_ymd = qr/\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/;
my $re_ymdThmsZ = qr/\A([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z\z/;

sub coerce_date {
    my $val = shift;
    if (!defined($val)) {
        return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    }

    if ($DATE_MODULE eq 'DateTime') {
        require DateTime;
        if (blessed($val) && $val->isa('DateTime')) {
            return $val;
        } elsif (looks_like_number($val) && $val >= 10**8 && $val <= 2**31) {
            return DateTime->from_epoch(epoch => $val);
        } elsif ($val =~ $re_ymd) {
            my $d;
            eval { $d = DateTime->new(year=>$1, month=>$2, day=>$3, time_zone=>'UTC') };
            return undef if $@; ## no critic: Subroutines::ProhibitExplicitReturnUndef
            return $d;
        } elsif ($val =~ $re_ymdThmsZ) {
            my $d;
            eval { $d = DateTime->new(year=>$1, month=>$2, day=>$3, hour=>$4, minute=>$5, second=>$6, time_zone=>'UTC') };
            return undef if $@; ## no critic: Subroutines::ProhibitExplicitReturnUndef
            return $d;
        } elsif (blessed($val) && $val->isa('Time::Moment')) {
            return DateTime->from_epoch(epoch => $val->epoch);
        } elsif (blessed($val) && $val->isa('Time::Piece')) {
            return DateTime->from_epoch(epoch => $val->epoch);
        } else {
            return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        }
    } elsif ($DATE_MODULE eq 'Time::Moment') {
        require Time::Moment;
        if (blessed($val) && $val->isa('Time::Moment')) {
            return $val;
        } elsif (looks_like_number($val) && $val >= 10**8 && $val <= 2**31) {
            return Time::Moment->from_epoch(int($val), $val-int($val));
        } elsif ($val =~ $re_ymd) {
            my $d;
            eval { $d = Time::Moment->new(year=>$1, month=>$2, day=>$3) };
            return undef if $@; ## no critic: Subroutines::ProhibitExplicitReturnUndef
            return $d;
        } elsif ($val =~ $re_ymdThmsZ) {
            my $d;
            eval { $d = Time::Moment->new(year=>$1, month=>$2, day=>$3, hour=>$4, minute=>$5, second=>$6) };
            return undef if $@; ## no critic: Subroutines::ProhibitExplicitReturnUndef
            return $d;
        } elsif (blessed($val) && $val->isa('DateTime')) {
            return Time::Moment->from_epoch($val->epoch);
        } elsif (blessed($val) && $val->isa('Time::Piece')) {
            return Time::Moment->from_epoch($val->epoch);
        } else {
            return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        }
    } elsif ($DATE_MODULE eq 'Time::Piece') {
        require Time::Piece;
        if (blessed($val) && $val->isa('Time::Piece')) {
            return $val;
        } elsif (looks_like_number($val) && $val >= 10**8 && $val <= 2**31) {
            return scalar Time::Piece->gmtime($val);
        } elsif ($val =~ $re_ymd) {
            my $d;
            eval { $d = Time::Piece->strptime($val, "%Y-%m-%d") };
            return undef if $@; ## no critic: Subroutines::ProhibitExplicitReturnUndef
            return $d;
        } elsif ($val =~ $re_ymdThmsZ) {
            my $d;
            eval { $d = Time::Piece->strptime($val, "%Y-%m-%dT%H:%M:%SZ") };
            return undef if $@; ## no critic: Subroutines::ProhibitExplicitReturnUndef
            return $d;
        } elsif (blessed($val) && $val->isa('DateTime')) {
            return scalar Time::Piece->gmtime(epoch => $val->epoch);
        } elsif (blessed($val) && $val->isa('Time::Moment')) {
            return scalar Time::Piece->gmtime(epoch => $val->epoch);
        } else {
            return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        }
    } else {
        die "BUG: Unknown Perl date module '$DATE_MODULE'";
    }
}

sub coerce_duration {
    my $val = shift;
    if (!defined($val)) {
        return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    } elsif (blessed($val) && $val->isa('DateTime::Duration')) {
        return $val;
    } elsif ($val =~ /\AP
                      (?: ([0-9]+(?:\.[0-9]+)?)Y )?
                      (?: ([0-9]+(?:\.[0-9]+)?)M )?
                      (?: ([0-9]+(?:\.[0-9]+)?)W )?
                      (?: ([0-9]+(?:\.[0-9]+)?)D )?
                      (?:
                          T
                          (?: ([0-9]+(?:\.[0-9]+)?)H )?
                          (?: ([0-9]+(?:\.[0-9]+)?)M )?
                          (?: ([0-9]+(?:\.[0-9]+)?)S )?
                      )?
                      \z/x) {
        require DateTime::Duration;
        my $d;
        eval {
            $d = DateTime::Duration->new(
                years   => $1 // 0,
                months  => $2 // 0,
                weeks   => $3 // 0,
                days    => $4 // 0,
                hours   => $5 // 0,
                minutes => $6 // 0,
                seconds => $7 // 0,
            );
        };
        return undef if $@; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        return $d;
    } else {
        return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    }
}

1;
# ABSTRACT: Utility related to date/duration type

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Util::Type::Date - Utility related to date/duration type

=head1 VERSION

This document describes version 0.911 of Data::Sah::Util::Type::Date (from Perl distribution Data-Sah), released on 2021-12-01.

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 coerce_date($val) => DATETIME OBJ|undef

Coerce value to DateTime object according to perl Sah compiler (see
L<Data::Sah::Compiler::perl::TH::date>). Return undef if value is not
acceptable.

=head2 coerce_duration($val) => DATETIME_DURATION OBJ|undef

Coerce value to DateTime::Duration object according to perl Sah compiler (see
L<Data::Sah::Compiler::perl::TH::duration>). Return undef if value is not
acceptable.

=head1 ENVIRONMENT

=head2 DATA_SAH_DATE_MODULE => string (default: DateTime)

Pick the date module to use. Available choices: DateTime, Time::Moment.

=head2 PERL_DATE_MODULE => string (default: DateTime)

Pick the date module to use. Available choices: DateTime, Time::Moment. Has
lower priority compared to DATA_SAH_DATE_MODULE.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
