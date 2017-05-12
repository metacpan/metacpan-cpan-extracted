package Calendar::CSA;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

#	Copyright (c) 1997 Kenneth Albanowski. All rights reserved.
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.


@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	CSA_CLASS_PUBLIC
	CSA_CLASS_PRIVATE
	CSA_CLASS_CONFIDENTIAL
	SUBTYPE_CLASS
	SUBTYPE_HOLIDAY
	SUBTYPE_MISCELLANEOUS
	SUBTYPE_PHONE_CALL
	SUBTYPE_SICK_DAY
	SUBTYPE_SPECIAL_OCCASION
	SUBTYPE_TRAVEL
	SUBTYPE_VACATION
	CAL_ATTR_ACCESS_LIST
	CAL_ATTR_CALENDAR_NAME
	CAL_ATTR_CALENDAR_OWNER
	CAL_ATTR_CALENDAR_SIZE
	CAL_ATTR_CHARACTER_SET
	CAL_ATTR_COUNTRY
	CAL_ATTR_DATE_CREATED
	CAL_ATTR_LANGUAGE
	CAL_ATTR_NUMBER_ENTRIES
	CAL_ATTR_PRODUCT_IDENTIFIER
	CAL_ATTR_TIME_ZONE
	CAL_ATTR_VERSION
	CAL_ATTR_WORK_SCHEDULE
	ENTRY_ATTR_ATTENDEE_LIST
	ENTRY_ATTR_AUDIO_REMINDER
	ENTRY_ATTR_CLASSIFICATION
	ENTRY_ATTR_DATE_COMPLETED
	ENTRY_ATTR_DATE_CREATED
	ENTRY_ATTR_DESCRIPTION
	ENTRY_ATTR_DUE_DATE
	ENTRY_ATTR_END_DATE
	ENTRY_ATTR_EXCEPTION_DATES
	ENTRY_ATTR_EXCEPTION_RULE
	ENTRY_ATTR_FLASHING_REMINDER
	ENTRY_ATTR_LAST_UPDATE
	ENTRY_ATTR_MAIL_REMINDER
	ENTRY_ATTR_NUMBER_RECURRENCES
	ENTRY_ATTR_ORGANIZER
	ENTRY_ATTR_POPUP_REMINDER
	ENTRY_ATTR_PRIORITY
	ENTRY_ATTR_RECURRENCE_RULE
	ENTRY_ATTR_RECURRING_DATES
	ENTRY_ATTR_REFERENCE_IDENTIFIER
	ENTRY_ATTR_SEQUENCE_NUMBER
	ENTRY_ATTR_SPONSOR
	ENTRY_ATTR_START_DATE
	ENTRY_ATTR_STATUS
	ENTRY_ATTR_SUBTYPE
	ENTRY_ATTR_SUMMARY
	ENTRY_ATTR_TIME_TRANSPARENCY
	ENTRY_ATTR_TYPE
	SUBTYPE_MEETING
	X_DT_CAL_ATTR_CAL_DELIMITER
	X_DT_CAL_ATTR_DATA_VERSION
	X_DT_CAL_ATTR_SERVER_VERSION
	X_DT_ENTRY_ATTR_ENTRY_DELIMITER
	X_DT_ENTRY_ATTR_REPEAT_INTERVAL
	X_DT_ENTRY_ATTR_REPEAT_OCCURRENCE_NUM
	X_DT_ENTRY_ATTR_REPEAT_TIMES
	X_DT_ENTRY_ATTR_REPEAT_TYPE
	X_DT_ENTRY_ATTR_SEQUENCE_END_DATE
	X_DT_ENTRY_ATTR_SHOWTIME
);
@EXPORT_OK = qw(
	logon
	list_calendars
);
$VERSION = '0.8';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Csa macro $constname";
	}
    }
    if ($val =~ /^[0-9]+$/) {
	    eval "sub $AUTOLOAD { $val }";
	} else {
	    eval "sub $AUTOLOAD { \"\Q$val\E\" }";
	}
    goto &$AUTOLOAD;
}

bootstrap Calendar::CSA $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Calendar::CSA - Perl extension to interface with CDE Calendar Manager

=head1 SYNOPSIS

  use Calendar::CSA;
  [etc]

=head1 DESCRIPTION

Unfortunately, this module is not documented at this time.

=head1 AUTHOR

Kenneth Albanowski <kjahds@kjahds.com>, with the assistance of Bharat
Mediratta <Bharat.Mediratta@Corp.Sun.COM>. Please contact me (Kenneth
Albanowski) about matters pertaining to this module.

=cut
