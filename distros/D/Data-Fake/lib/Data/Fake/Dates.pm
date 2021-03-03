use 5.008001;
use strict;
use warnings;

package Data::Fake::Dates;
# ABSTRACT: Fake date data generators

our $VERSION = '0.006';

use Exporter 5.57 qw/import/;

our @EXPORT = qw(
  fake_past_epoch
  fake_future_epoch
  fake_past_datetime
  fake_future_datetime
);

use Time::Piece 1.27; # portability fixes

sub _past { int( rand(time) ) }

sub _future {
    my $now = time;
    return $now + int( rand($now) );
}

#pod =func fake_past_epoch
#pod
#pod     $generator = fake_past_epoch();
#pod
#pod This returns a generator that gives a randomly-selected integer number of
#pod seconds between the Unix epoch and the current time.
#pod
#pod =cut

sub fake_past_epoch { \&_past }

#pod =func fake_future_epoch
#pod
#pod     $generator = fake_future_epoch();
#pod
#pod This returns a generator that gives a randomly-selected integer number of
#pod seconds between the the current time and a period as far into the future as
#pod the Unix epoch is in the past (i.e. about 45 years as of 2015).
#pod
#pod =cut

sub fake_future_epoch { \&_future }

#pod =func fake_past_datetime
#pod
#pod     $generator = fake_past_datetime();
#pod     $generator = fake_past_datetime("%Y-%m-%d");
#pod     $generator = fake_past_datetime($strftime_format);
#pod
#pod This returns a generator that selects a past datetime like
#pod C<fake_past_epoch> does but formats it as a string using FreeBSD-style
#pod C<strftime> formats.  (See L<Time::Piece> for details.)
#pod
#pod The default format is ISO8601 UTC "Zulu" time (C<%Y-%m-%dT%TZ>).
#pod
#pod =cut

sub fake_past_datetime {
    my ($format) = @_;
    $format ||= "%Y-%m-%dT%H:%M:%SZ";
    return sub {
        Time::Piece->strptime( _past(), "%s" )->strftime($format);
    };
}

#pod =func fake_future_datetime
#pod
#pod     $generator = fake_future_datetime();
#pod     $generator = fake_future_datetime("%Y-%m-%d");
#pod     $generator = fake_future_datetime($strftime_format);
#pod
#pod This returns a generator that selects a future datetime like
#pod C<fake_future_epoch> does but formats it as a string using FreeBSD-style
#pod C<strftime> formats.  (See L<Time::Piece> for details.)
#pod
#pod The default format is ISO8601 UTC "Zulu" time (C<%Y-%m-%dT%TZ>).
#pod
#pod =cut

sub fake_future_datetime {
    my ($format) = @_;
    $format ||= "%Y-%m-%dT%H:%M:%SZ";
    return sub {
        Time::Piece->strptime( _future(), "%s" )->strftime($format);
    };
}


# vim: ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Fake::Dates - Fake date data generators

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use Data::Fake::Dates;

    $past   = fake_past_epoch()->();
    $future = fake_future_epoch()->();

    $past   = fake_past_datetime()->();     # ISO-8601 UTC
    $future = fake_future_datetime()->();   # ISO-8601 UTC

    $past   = fake_past_datetime("%Y-%m-%d")->();
    $future = fake_future_datetime("%Y-%m-%d")->();

=head1 DESCRIPTION

This module provides fake data generators for past and future dates and times.

All functions are exported by default.

=head1 FUNCTIONS

=head2 fake_past_epoch

    $generator = fake_past_epoch();

This returns a generator that gives a randomly-selected integer number of
seconds between the Unix epoch and the current time.

=head2 fake_future_epoch

    $generator = fake_future_epoch();

This returns a generator that gives a randomly-selected integer number of
seconds between the the current time and a period as far into the future as
the Unix epoch is in the past (i.e. about 45 years as of 2015).

=head2 fake_past_datetime

    $generator = fake_past_datetime();
    $generator = fake_past_datetime("%Y-%m-%d");
    $generator = fake_past_datetime($strftime_format);

This returns a generator that selects a past datetime like
C<fake_past_epoch> does but formats it as a string using FreeBSD-style
C<strftime> formats.  (See L<Time::Piece> for details.)

The default format is ISO8601 UTC "Zulu" time (C<%Y-%m-%dT%TZ>).

=head2 fake_future_datetime

    $generator = fake_future_datetime();
    $generator = fake_future_datetime("%Y-%m-%d");
    $generator = fake_future_datetime($strftime_format);

This returns a generator that selects a future datetime like
C<fake_future_epoch> does but formats it as a string using FreeBSD-style
C<strftime> formats.  (See L<Time::Piece> for details.)

The default format is ISO8601 UTC "Zulu" time (C<%Y-%m-%dT%TZ>).

=for Pod::Coverage BUILD

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
