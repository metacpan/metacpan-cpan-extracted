package DateTime::Fiction::JRRTolkien::Shire::Types;

use 5.008004;

use strict;
use warnings;

use parent qw{ Specio::Exporter };

use Carp;
use Date::Tolkien::Shire::Data 0.001 qw{
    __holiday_name_to_number
    __month_name_to_number
};
use Specio 0.18;
use Specio::Declare;
use Specio::Library::Builtins;
use Specio::Library::Numeric;
use Specio::Library::String;

our $VERSION = '0.905';

declare(
    DayOfMonth	=>
    parent	=> t( 'PositiveInt' ),
    inline	=> sub {
	$_[0]->parent->inline_check( $_[1] ) .  " && $_[1] <= 30";
    },
);

declare(
    DayOfYear	=>
    parent	=> t( 'PositiveInt' ),
    inline	=> sub {
	$_[0]->parent->inline_check( $_[1] ) .  " && $_[1] <= 366";
    },
);

=begin comment

object_isa_type(
    Duration	=>
    class	=> 'DateTime::Fiction::JRRTolkien::Shire::Duration',
#    class	=> 'DateTime::Duration',
);

=end comment

=cut

# For some reason the above does not compile, though if you specify
# 'DateTime::Duration' it does. I believe the following to be
# equivalent, though I am sure it will produce a less-salubrious error
# message.

declare(
    Duration	=>
    parent	=> t( 'Object' ),
#    inline	=> sub {
#	$_[0]->parent->inline_check( $_[1] ) .
#	" && $_[1]->isa( 'DateTime::Fiction::JRRTolkien::Shire::Duration' )";
#    },
#   For some reason the above is a problem under 5.8.9. So:
    where	=> sub { $_[0]->isa(
	    'DateTime::Fiction::JRRTolkien::Shire::Duration' ) },
);

enum(
    EndOfMonthMode	=>
    values	=> [ qw{ limit preserve wrap } ],
);

any_can_type(
    Formatter	=>
    methods	=> [ qw{ format_datetime } ],
);

declare(
    HolidayName	=>
    parent	=> t( 'NonEmptySimpleStr' ),
    where	=> sub { __holiday_name_to_number( $_[0] ) },
#   Not the following, because the inline code gets evaluated in a Safe
#   sandbox and I can not get access to the subroutine
#   inline	=> sub {
#	$_[0]->parent->inline_check( $_[1] ) .
#	" && __holiday_name_to_number( $_[1] )";
#   },
);

declare(
    HolidayNumber	=>
    parent	=> t( 'PositiveInt' ),
    inline	=> sub {
	$_[0]->parent->inline_check( $_[1] ) .  " && $_[1] <= 6";
    },
);

union(
    Holiday	=>
    of		=> [ map { t( $_ ) } qw{ HolidayNumber HolidayName } ],
);

declare(
    Hour	=>
    parent	=> t( 'PositiveOrZeroInt' ),
    inline	=> sub {
	$_[0]->parent->inline_check( $_[1] ) .  " && $_[1] < 24";
    },
);

union(
    IntOrUndef	=>
    of	=> [ map { t( $_ ) } qw{ Int Undef } ],
);


declare(
    LocaleObject	=>
    parent	=> t( 'Object' ),
    inline	=> sub {
        # Can't use $_[1] directly because 5.8 gives very weird errors
        my $var = $_[1];
        <<"EOF";
(
    $var->isa('DateTime::Locale::FromData')
    || $var->isa('DateTime::Locale::Base')
)
EOF
    },
);

union(
    Locale	=>
    of => [ map { t( $_ ) } qw{ NonEmptySimpleStr LocaleObject } ],
);

declare(
    Minute	=>
    parent	=> t( 'PositiveOrZeroInt' ),
    inline	=> sub {
	$_[0]->parent->inline_check( $_[1] ) .  " && $_[1] < 60";
    },
);

declare(
    MonthName	=>
    parent	=> t( 'NonEmptySimpleStr' ),
    where	=> sub { __month_name_to_number( $_[0] ) },
#   Not the following, because the inline code gets evaluated in a Safe
#   sandbox and I can not get access to the subroutine
#   inline	=> sub {
#	$_[0]->parent->inline_check(#$_[1] ) .
#	"#&& __month_name_to_number( $_[1] )";
#   },
);

declare(
    MonthNumber	=>
    parent	=> t( 'PositiveInt' ),
    inline	=> sub {
	$_[0]->parent->inline_check( $_[1] ) .  " && $_[1] <= 12";
    },
);

union(
    Month	=>
    of		=> [ map { t( $_ ) } qw{ MonthNumber MonthName } ],
);

declare(
    Nanosecond	=>
    parent	=> t( 'PositiveOrZeroInt' ),
);

declare(
    Second	=>
    parent	=> t( 'PositiveOrZeroInt' ),
    inline	=> sub {
	$_[0]->parent->inline_check( $_[1] ) .  " && $_[1] < 62";
    },
);


object_can_type(
    'TimeZoneObject',
    methods => [
        qw(
            is_floating
            is_utc
            name
            offset_for_datetime
            short_name_for_datetime
            )
    ],
);

declare(
    'TimeZone',
    of => [ map { t( $_ ) } qw{ NonEmptySimpleStr TimeZoneObject } ],
);

enum(
    TruncationLevel	=>
    values	=> [ qw{
	year
	quarter
	month
	week
	local_week
	day
	hour
	minute
	second
	nanosecond
    } ],
);

declare(
    Year	=>
    parent	=> t( 'Int' ),
);

1;

__END__

=head1 NAME

DateTime::Fiction::JRRTolkien::Shire::Types - Specio types used for argument checking in DateTime::Fiction::JRRTolkien::Shire

=head1 SYNOPSIS

No user-serviceable parts inside.

=head1 DESCRIPTION

This Perl module is private to the
L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>
distribution. It can be changed or revoked at any time.

The purpose of this module is to provide L<Specio|Specio> argument type
definitions for
L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>.

=head1 SEE ALSO

L<DateTime::Fiction::JRRTolkien::Shire|DateTime::Fiction::JRRTolkien::Shire>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://github.com/trwyant/perl-DateTime-Fiction-JRRTolkien-Shire/issues>,
or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
