#!/usr/bin/perl

package Date::Parser;

use strict;
use warnings;

use Date::Parser::Date;

use Date::Format;
use I18N::Langinfo qw( langinfo
    ABDAY_1 ABDAY_2 ABDAY_3 ABDAY_4 ABDAY_5 ABDAY_6 ABDAY_7
    ABMON_1 ABMON_2 ABMON_3 ABMON_4 ABMON_5 ABMON_6
    ABMON_7 ABMON_8 ABMON_9 ABMON_10 ABMON_11 ABMON_12
    DAY_1 DAY_2 DAY_3 DAY_4 DAY_5 DAY_6 DAY_7
    MON_1 MON_2 MON_3 MON_4 MON_5 MON_6
    MON_7 MON_8 MON_9 MON_10 MON_11 MON_12
);

our $VERSION = 0.4;

my @days = map { langinfo $_ } (
    DAY_1, DAY_2, DAY_3, DAY_4, DAY_5, DAY_6, DAY_7
);
my @days_ab = map { langinfo $_ } (
    ABDAY_1, ABDAY_2, ABDAY_3, ABDAY_4, ABDAY_5, ABDAY_6, ABDAY_7
);
my @months = map { langinfo $_ } (
    MON_1, MON_2, MON_3, MON_4, MON_5, MON_6,
    MON_7, MON_8, MON_9, MON_10, MON_11, MON_12
);
my @months_ab = map { langinfo $_ } (
    ABMON_1, ABMON_2, ABMON_3, ABMON_4, ABMON_5, ABMON_6,
    ABMON_7, ABMON_8, ABMON_9, ABMON_10, ABMON_11, ABMON_12
);

my $format_chars = {
    '%' => {     # PERCENT
        regexp => '%',
    },
    'a' => {     # day of the week abbr
        regexp => '('.join("|", @days_ab).')',
        type => 'dow',
        parser => sub { for (0..$#days_ab) { return $_ if ($_[0] eq $days_ab[$_]); } },
    },
    'A' => {     # day of the week
        regexp => '('.join("|", @days).')',
        type => 'dow',
        parser => sub { for (0..$#days) { return $_ if ($_[0] eq $days[$_]); } },
    },
    'b' => {     # month abbr
        regexp => '('.join("|", @months_ab).')',
        type => 'month',
        parser => sub { for (0..$#months_ab) { return $_ if ($_[0] eq $months_ab[$_]); } },
    },
    'B' => {     # month
        regexp => '('.join("|", @months).')',
        type => 'month',
        parser => sub { for (0..$#months) { return $_ if ($_[0] eq $months[$_]); } },
    },
    'd' => {     # numeric day of the month, with leading zeros (eg 01..31)
        regexp => '(0[1-9]|[1-2][0-9]|3[01])',
        type => 'day',
        parser => \&_strip_zero,
    },
    'e' => {     # like %d, but a leading zero is replaced by a space (eg  1..31)
        regexp => '( [1-9]|[1-2][0-9]|3[01])',
        type => 'day',
        parser => \&_strip_leading_space,
    },
    'h' => {     # month abbr
        regexp => '('.join("|", @months_ab).')',
        type => 'month',
        parser => sub { for (0..$#months_ab) { return $_ if ($_[0] eq $months_ab[$_]); } },
    },
    'H' => {     # hour, 24 hour clock, leading 0's)
        regexp => '([0-1][0-9]|2[0-3])',
        type => 'hour24',
        parser => \&_strip_leading_space,
    },
    'I' => {     # hour, 12 hour clock, leading 0's)
        regexp => '(0[1-9]|1[0-2])',
        type => 'hour12',
        parser => \&_strip_leading_space,
    },
    'j' => {     # day of the year
        regexp => '(0[0-9][0-9]|[1-2][0-9][0-9]|3[0-5][0-9]|36[0-6])',
        type => 'doy',
        parser => \&_strip_zeros,
    },
    'k' => {     # hour
        regexp => '( [0-9]|1[0-9]|2[0-3])',
        type => 'hour24',
        parser => \&_strip_leading_space,
    },
    'l' => {     # hour, 12 hour clock
        regexp => '( [0-9]|1[0-2])',
        type => 'hour12',
        parser => \&_strip_leading_space,
    },
    'L' => {     # month number, starting with 1
        regexp => '( [0-9]|1[0-2])',
        type => 'month',
        parser => sub { $_[0] = _strip_leading_space($_[0]); --$_[0]; $_[0] },
    },
    'm' => {     # month number, starting with 01
        regexp => '(0[0-9]|1[0-2])',
        type => 'month',
        parser => sub { $_[0] = _strip_zero($_[0]); --$_[0]; $_[0] },
    },
    'M' => {     # minute, leading 0's
        regexp => '([0-5][0-9])',
        type => 'min',
        parser => \&_strip_zero,
    },
    'o' => {     # ornate day of month -- "1st", "2nd", "25th", etc.
        regexp => '([1-2][0-9]|3[0-1])\S+', # TODO: localized st, dn, rd, th?
        type => 'day',
    },
    'p' => {     # AM or PM
        regexp => '(AM|PM)',
        type => 'hour12_ind',
    },
    'P' => {     # am or pm (Yes %p and %P are backwards :)
        regexp => '(am|pm)',
        type => 'hour12_ind',
    },
    'q' => {     # Quarter number, starting with 1
        regexp => '([1-4])',
        type => 'quarter',
    },
    's' => {     # seconds since the Epoch, UCT
        regexp => '(\d+)',
        type => 'unixtime',
    },
    'S' => {     # seconds, leading 0's
        regexp => '([0-5][0-9])',
        type => 'sec',
        parser => \&_strip_zero,
    },
    't' => {     # TAB
        regexp => '\\t',
    },
    'U' => {     # week number, Sunday as first day of week
        regexp => '(0[1-9]|[1-4][0-9]|5[0-2])',
        type => 'week',
        parser => \&_strip_zero,
    },
    'w' => {     # day of the week, numerically, Sunday == 0
        regexp => '([0-7])',
        type => 'dow',
    },
    'W' => {     # week number, Monday as first day of week
        regexp => '(0[1-9]|[1-4][0-9]|5[0-2])',
        type => 'week',
        parser => \&_strip_zero,
    },
    'y' => {     # year (2 digits)
        regexp => '([0-9][0-9])',
        type => 'year2',
    },
    'Y' => {     # year (4 digits)
        regexp => '([0-9][0-9][0-9][0-9])',
        type => 'year4',
    },
    # TODO
    'Z' => {     # timezone in ascii. eg: PST
        regexp => '(\S+)', # TODO: localized values?
        type => 'timezone',
    },
    'z' => {     # timezone in format -/+0000
        regexp => '(?:-|+)(0[0-9][0-9][0-9]|1[0-1][0-9][0-9]|1200)',
        type => 'timezone',
    },
};

sub new {
    my ($class, %opts) = @_;

    my $self = bless {}, $class;

    return $self;
}

sub _get_regexp {
    my ($format) = @_;

    my @capture_order;
    my $flag = 0;
  CHAR:
    for my $c (split(//, $format)) {
        if ($flag) {
            unless (defined $format_chars->{$c}) {
                warn "no such format character: $c";
                next(CHAR);
            }
            my $regexp;
            $regexp = $format_chars->{$c}->{regexp};
            $format =~ s/%$c/$regexp/;
            push(@capture_order, $c);
            $flag = 0;
        }
        if ($c eq "%") {
            # next one is format character
            $flag = 1;
        }
    }
    my %reg = (
        format => $format,
        capture_order => \@capture_order,
    );

    return \%reg;
}

sub parse_data {
    my ($self, $format, $data) = @_;

    # return undef if either is missing
    return unless (defined $data && defined $format);

    my $regexp = _get_regexp($format);
    $format = $regexp->{format};
    my @capture_order = @{$regexp->{capture_order}};

    my (@items) = $data =~ /$format/;
    my %data;
    for my $i (0..$#items) {
        my $type = $format_chars->{$capture_order[$i]}->{type};
        if (defined(my $parser = $format_chars->{$capture_order[$i]}->{parser})) {
            $data{$type} = $parser->($items[$i]);
        } else {
            $data{$type} = $items[$i];
        }
    }

    my %opts;
    $opts{year} = _parse_year(%data) || time2str("%Y", time);
    $opts{hour} = _parse_hour(%data);  
    foreach my $key (qw/month day min sec unixtime/) {
        $opts{$key} = $data{$key} if (defined $data{$key});
    }

    my $date = Date::Parser::Date->new(%opts);

    return $date;
}

sub _parse_hour {
    my (%opts) = @_;

    return $opts{hour24} if (defined $opts{hour24});

    if (defined $opts{hour12} && defined $opts{hour12_ind}) {
        if (lc($opts{hour12_ind}) eq "pm") {
            return 0 if ($opts{hour12} == 12);
            return $opts{hour12} + 12;
        } else {
            return $opts{hour12};
        }
    }

    return;
}

sub _parse_year {
    my (%opts) = @_;

    return $opts{year4} if (defined $opts{year4});
    return "20.$opts{year2}" if (defined $opts{year2});

    return;
}

sub _strip_zero { $_[0] =~ s/^0//; return $_[0] };
sub _strip_zeros { $_[0] =~ s/^0//; return $_[0] };
sub _strip_leading_space { $_[0] =~ s/^ //; return $_[0] };

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Date::Parser - Simple date parsing

=head1 VERSION

Version 0.4

=head1 SYNOPSIS

  my $dp = Date::Parser->new;
  my $format = "%b %d %H:%M:%S";
  open(my $fh, "<", "/var/log/sshd.log") or die "failed to open log: $!";
  while (my $line = readline($fh)) {
      chomp($line);
      my $date = $dp->parse_data($format, $line);
      # do something with the date ..
  }
  close($fh);

=head1 DESCRIPTION

Really simple date parsing factory. Uses I18N::Langinfo for localized day/month names and abbreviations.

=head1 METHODS

=head2 parse_data($format, $data)

Parses given $data using $format.

Returns a new L<Date::Parser::Date> -object.

=head1 FORMAT

For parsing you can use the following formatting:

        %%      literal %, is not captured.
        %a      day of the week abbr
        %A      day of the week
        %b      month abbr
        %B      month
        %d      numeric day of the month, with leading zeros (eg 01..31)
        %e      like %d, but a leading zero is replaced by a space (eg  1..32)
        %h      month abbr
        %H      hour, 24 hour clock, leading 0's
        %I      hour, 12 hour clock, leading 0's
        %j      day of the year
        %k      hour
        %l      hour, 12 hour clock
        %L      month number, starting with 1
        %m      month number, starting with 01
        %M      minute, leading 0's
        %o      ornate day of month - "1st", "2nd", etc. (only day int is captured)
        %p      AM or PM (both %p or %P and %I or %l are required ..)
        %P      am or pm (.. to resolve 12 hour clock time.)
        %q      Quarter number, starting with 1
        %s      seconds since the Epoch, UCT
        %S      seconds, leading 0's
        %t      TAB, is not captured
        %U      week number, Sunday as first day of week
        %w      day of the week, numerically, Sunday == 0
        %W      week number, Monday as first day of week
        %y      year (2 digits, e.g. 11 => 2011)
        %Y      year (4 digits)
        %Z      timezone in ascii. eg: PST
        %z      timezone in format -/+0000

=head1 CAVEATS

Still under work, so missing some features.. works for most log formats pretty well.

=head1 TODO

  - Day of week (in case doy is missing)
  - Localized values for ornate dom
  - Quarter support (in case month is missing)
  - Week number support (in case month/doy is missing)
  - Timezones (?)

=head1 AUTHOR

Heikki Mehtänen, C<< <heikki@mehtanen.fi> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Heikki Mehtänen, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
