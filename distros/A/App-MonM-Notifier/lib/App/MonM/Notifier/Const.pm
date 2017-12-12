package App::MonM::Notifier::Const; # $Id: Const.pm 41 2017-11-30 11:26:30Z abalama $
use strict;

=head1 NAME

App::MonM::Notifier::Const - Interface for constants

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Const qw/ :levels :bits :functions :reasons :jobs /;

=head1 DESCRIPTION

This module provide interface for constants

=head2 BIT_SET

Returns value of Bit in SET state (1)

=head2 BIT_UNSET

Returns value of Bit in UNSET state (0)

=head1 FUNCTIONS

=head2 C<getBit>

    print getBit(123, LVL_DEBUG) ? "SET" : "UNSET"; # UNSET

Getting specified Bit

=head2 C<setBit>

    printf("%08b", setBit(123, LVL_INFO)); # 01111011

Setting specified Bit. Returns new value.

=head2 C<getLevelName>

    print getLevelName(1); # info

Returns level name

=head2 C<getLevelByName>

    print getLevelByName("LVL_INFO") # 1

Returns level value by level name

=head2 C<getPriorityMask>

    printf("%010b", getPriorityMask(LVL_FATAL)); # 1100000000

Returns default mask. The default mask defines the ability to send messages with a level
greater than the specified

=head2 C<setPriorityMask>

    printf("%010b", setPriorityMask("info error fatal")); # 0100010010

Returns mask by list of levels. All elements of the list should be separated by any non-alphabetic
characters

=head2 C<getErr>

    my $errmsg = getErr(101);

Returns error mask for (s)printf by errorcode

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use constant {
        # General
        MSWIN           => $^O =~ /mswin/i ? 1 : 0,

        # LEVELS
        LEVELS => {
            'debug'     => 0,
            'info'      => 1,
            'notice'    => 2,
            'warning'   => 3,
            'error'     => 4,
            'crit'      => 5,
            'alert'     => 6,
            'emerg'     => 7,
            'fatal'     => 8,
            'except'    => 9,
        },

        # LEVELS by name
        LVL_DEBUG       => 0,
        LVL_INFO        => 1,
        LVL_NOTICE      => 2,
        LVL_WARNING     => 3, LVL_WARN => 3,
        LVL_ERROR       => 4, LVL_ERR => 4,
        LVL_CRIT        => 5,
        LVL_ALERT       => 6,
        LVL_EMERG       => 7,
        LVL_FATAL       => 8,
        LVL_EXCEPT      => 9, LVL_EXCEPTION => 9,

        # Job Statuses (JBS_*)
        JBS_NEW         => "NEW",       # New job
        JBS_PROGRESS    => "PROGRESS",  # In progress...
        JBS_POSTPONED   => "POSTPONED", # Status for waited jobs
        JBS_EXPIRED     => "EXPIRED",   # Expired job. Closed status
        JBS_SKIP        => "SKIP",      # Temporary error status. Closed status
        JBS_SENT        => "SENT",      # Ok status. Message is sent
        JBS_DONE        => "DONE",      # Ok status. Job is closed
        JBS_ERROR       => "ERROR",     # Error status. Closed status
        JBS_FAILED      => "FAILED",    # Error status. Internal error

        # REASONS
        RSN_DEFAULT     => 0, RSN_UNKNOWN => 0,
        RSN_CHANNEL     => 1,
        RSN_TYPE        => 2,
        RSN_DISABLED    => 3,
        RSN_PUBDATE     => 10,
        RSN_LEVEL       => 11,
        RSN_ERROR       => 12,
        REASONS     => {
            0   => "Unknown reason", # DEFAULT
            1   => "Config's channel incorrect",
            2   => "Config's type incorrect",
            3   => "Channel is disabled",
            10  => "Time for event has not come yet",
            11  => "Level mismatch",
            12  => "Sending error",
        },

        # BITS
        BIT_SET     => 1,
        BIT_UNSET   => 0,

        # ERRORS
        ERRCODES    => {
            101 => "Can't calculate the period. Please check configuration section for user %s",
            102 => "Can't send message: %s",
        },
    };

use base qw/Exporter/;

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use List::Util qw/ max /;
use Carp; # carp - warn; croak - die;

use vars qw/$VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS/;
$VERSION = '1.00';

# Named groups of exports
%EXPORT_TAGS = (
    'levels'    => [qw/
        LEVELS
        LVL_DEBUG
        LVL_INFO
        LVL_NOTICE
        LVL_WARNING LVL_WARN
        LVL_ERROR   LVL_ERR
        LVL_CRIT
        LVL_ALERT
        LVL_EMERG
        LVL_FATAL
        LVL_EXCEPT  LVL_EXCEPTION
    /],
    'jobs'  => [qw/
        JBS_NEW
        JBS_PROGRESS
        JBS_POSTPONED
        JBS_EXPIRED
        JBS_SKIP
        JBS_SENT
        JBS_DONE
        JBS_ERROR
        JBS_FAILED
    /],
    'bits'  => [qw/
        BIT_SET
        BIT_UNSET
    /],
    'reasons' => [qw/
        REASONS
        RSN_DEFAULT RSN_UNKNOWN
        RSN_CHANNEL
        RSN_TYPE
        RSN_DISABLED
        RSN_PUBDATE
        RSN_LEVEL
        RSN_ERROR
    /],
    'functions' => [qw/
        getBit
        setBit
        getLevelName
        getLevelByName
        getPriorityMask
        setPriorityMask
        getErr
    /],
);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = (qw/
        MSWIN
    /, @{$EXPORT_TAGS{functions}}, @{$EXPORT_TAGS{levels}}, @{$EXPORT_TAGS{jobs}});

# Other items we are prepared to export if requested
@EXPORT_OK = (qw/
        MSWIN
    /, map {@{$_}} values %EXPORT_TAGS);

sub setBit {
    my $v = fv2zero(shift);
    my $n = fv2zero(shift);
    return $v | (2**$n);
}
sub getBit {
    my $v = fv2zero(shift);
    my $n = fv2zero(shift);
    return ($v & (1 << $n)) ? BIT_SET : BIT_UNSET;
}

# Level's functions
sub getLevelName { # by index
    my $i = shift || 0;
    do {carp("Incorrect level"); return} unless is_int($i);
    my %ls = reverse %{(LEVELS)};
    return exists($ls{$i}) ? $ls{$i} : undef;
}
sub getLevelByName {
    my $name = shift;
    my %ls = %{(LEVELS)};
    return undef unless defined($name) && exists($ls{$name});
    return $ls{$name};
}
sub getPriorityMask {
    my $m = shift || 0;
    my $max = max values %{(LEVELS)};
    my $x = (($m < 0) || ($m > $max)) ? 0 : $m;
    #my $ini = setBit(0, $max + 1) - 1;
    my $res = 0;
    $res = setBit($res, $_) for ($x..$max);
    return $res;
}
sub setPriorityMask {
    my $mask = shift || '';
    my @ls = keys %{(LEVELS)};
    $mask =~ s/^\s+//;
    $mask =~ s/\s+$//;
    my @req = ();
    foreach my $u (split /[^a-z]+/, lc($mask)) {
       push @req, $u if grep {$u eq $_} @ls;
    }
    return 0 unless @req;
    my $res = 0;
    for (@req) {
        $res = setBit($res, getLevelByName($_));
    }
    return $res;
}
sub getErr {
    my $code = shift;
    my %es = %{(ERRCODES)};
    do {carp("Incorrect error code"); return} unless defined($code) && exists($es{$code});
    return $es{$code};
}

1;
