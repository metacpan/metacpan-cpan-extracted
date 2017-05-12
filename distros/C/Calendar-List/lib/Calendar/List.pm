package Calendar::List;

use strict;
use warnings;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT);
$VERSION = '0.28';

#----------------------------------------------------------------------------

=head1 NAME

Calendar::List - A module for creating date lists

=head1 SYNOPSIS

  use Calendar::List;

  # basic usage
  my %hash = calendar_list('DD-MM-YYYY' => 'DD MONTH, YYYY' );
  my @list = calendar_list('MM-DD-YYYY');
  my $html = calendar_selectbox('DD-MM-YYYY' => 'DAY DDEXT MONTH, YYYY');

  # using the hash
  my %hash01 = (
    'options'   => 10,
    'exclude'   => { 'weekend' => 1 },
    'start'     => '01-05-2003',
  );

  my %hash02 = (
    'options'   => 10,
    'exclude'   => { 'holidays' => \@holidays },
    'start'     => '01-05-2003',
  );

  my %hash03 = (
    'exclude'   => { 'monday' => 1,
                     'tuesday' => 1,
                     'wednesday' => 1 },
    'start'     => '01-05-2003',
    'end'       => '10-05-2003',
    'name'      => 'MyDates',
    'selected'  => '04-05-2003',
  );

  my %hash = calendar_list('DD-MM-YYYY' => 'DDEXT MONTH YYYY', \%hash01);
  my @list = calendar_list('DD-MM-YYYY', \%hash02);
  my $html = calendar_selectbox('DD-MM-YYYY',\%hash03);

=head1 DESCRIPTION

The module is intended to be used to return a simple list, hash or scalar
of calendar dates. This is achieved by two functions, calendar_list and
calendar_selectbox. The former allows a return of a list of dates and a
hash of dates, whereas the later returns a scalar containing a HTML code
snippet for use as a HTML Form field select box.

=head1 EXPORT

  calendar_list,
  calendar_selectbox

=cut

#----------------------------------------------------------------------------

#############################################################################
#Export Settings                                                            #
#############################################################################

require Exporter;

@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw(
    calendar_list
    calendar_selectbox
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

#############################################################################
#Library Modules                                                            #
#############################################################################

use Calendar::Functions qw(:all);
use Clone qw(clone);
use Tie::IxHash;

#############################################################################
#Variables
#############################################################################

# prime our print out names
my @months  = qw(   NULL January February March April May June July
                    August September October November December );
my @dotw    = qw(   Sunday Monday Tuesday Wednesday Thursday Friday Saturday );

my (%months,%dotw);
for my $key (1..12) { $months{lc $months[$key]} = $key }
for my $key (0..6)  { $dotw{  lc $dotw[$key]  } = $key }

# THE DEFAULTS
my $Format      = 'DD-MM-YYYY';
my @order       = qw( day month year );

my %Defaults = (
    maxcount    => 30,
    selectname  => 'calendar',
    selected    => [],
    startdate   => undef,
    enddate     => undef,
    start       => [1,1,1970],
    end         => [31,12,2037],
    holidays    => {},
    exclude     => { 
        days        => [ 0,0,0,0,0,0,0 ],
        months      => [ 0,0,0,0,0,0,0,0,0,0,0,0,0 ],
    },
);

my (%Settings);

#----------------------------------------------------------------------------

#############################################################################
#Interface Functions                                                        #
#############################################################################

=head1 FUNCTIONS

=over 4

=item calendar_list([DATEFORMAT] [,DATEFORMAT] [,OPTIONSHASH])

Returns a list in an array context or a hash reference in any other context.
All paramters are optional, one or two date formats can be specified for the
date formats returned in the list/hash. A hash of user defined settings can
also be passed into the function. See below for further details.

Note that a second date format is not required when returning a list. A
single date format when returning a hash reference, will be used in both
key and value portions.

=cut

sub calendar_list {
    my $wantarray = (@_ < 2 || ref($_[1]) eq 'HASH') ? 1 : 0;
    my ($fmt1,$fmt2,$hash) = _thelist(@_);
    return _callist($fmt1,$fmt2,$hash,$wantarray);
}

=item calendar_selectbox([DATEFORMAT] [,DATEFORMAT] [,OPTIONSHASH])

Returns a scalar containing a HTML string. The HTML snippet consists of an
HTML form field select box. All paramters are optional, one or two date
formats can be specified for the date formats returned in the value
attribute and data portion. A hash of user defined settings can
also be passed into the function. See below for further details.

Note that a single date format will be used in both value attribute and
data portions.

=cut

sub calendar_selectbox {
    my ($fmt1,$fmt2,$hash) = _thelist(@_);
    return _calselect($fmt1,$fmt2,$hash);
}

#############################################################################
#Internal Functions                                                         #
#############################################################################

# name: _thelist
# args: format string 1 .... optional
#       format string 2 .... optional
#       settings hash ...... optional
# retv: undef if invalid settings, otherwise a hash of dates, keyed by
#       an incremental counter.
# desc: The heart of the engine. Arranges the parameters passed to the
#       the interface function, calls for the settings to be decided,
#       them creates the main hash table of dates.
#       Stops when either the end date is reached, or the maximum number
#       of entries have been found.

sub _thelist {
    my ($format1,$format2,$usrhash);
    $format1 = shift    unless(ref($_[0]) eq 'HASH');
    $format2 = shift    unless(ref($_[0]) eq 'HASH');
    $usrhash = shift        if(ref($_[0]) eq 'HASH');

    $format1 = $Format  unless($format1);
    $format2 = $format1 unless($format2);

    return  if _setargs($usrhash,$format1);

    $Settings{nowdate} = $Settings{startdate};

    my $optcount = 0;   # our option counter
    my %DateHash;
    tie(%DateHash, 'Tie::IxHash');

    while($optcount < $Settings{maxcount}) {
        my ($nowday,$nowmon,$nowyear,$nowdow) = decode_date($Settings{nowdate});

        # ignore days we're not interested in
        unless(     $Settings{exclude}{days}->[$nowdow]
                ||  $Settings{exclude}{months}->[$nowmon]) {

            # store the date, unless its a holiday
            my $fdate = sprintf "%02d-%02d-%04d", $nowday,$nowmon,$nowyear;
            $DateHash{$optcount++} = [decode_date($Settings{nowdate})]
                unless($Settings{holidays}->{$fdate});
        }

        # stop if reached end date
        last    if(compare_dates($Settings{nowdate},$Settings{enddate}) == 0);

        # increment
        $Settings{nowdate} = add_day($Settings{nowdate});
    }

    return $format1,$format2,\%DateHash;
}

# name: _callist
# args: format string 1 .... optional
#       format string 2 .... optional
#       settings hash ...... optional
# retv: undef if invalid settings, otherwise an array if zero or one
#       date format provided, in ascending order, or a hash if two
#       date formats.
# desc: The cream on top. Takes the hash provided by _thelist and uses
#       it to create a formatted array or hash.

sub _callist {
    my ($fmt1,$fmt2,$hash,$wantarray) = @_;
    return  unless($hash);

    my (@returns,%returns);
    tie(%returns, 'Tie::IxHash');

    foreach my $key (sort {$a <=> $b} keys %$hash) {
        my $date1 = format_date($fmt1,@{$hash->{$key}});
        if($wantarray) {
            push @returns, $date1;
        } else {
            my $date2 = format_date($fmt2,@{$hash->{$key}});
            $returns{$date1} = $date2;
        }
    }

    return @returns if($wantarray);
    return %returns;
}


# name: _calselect
# args: format string 1 .... optional
#       format string 2 .... optional
#       settings hash ...... optional
# retv: undef if invalid settings, otherwise a hash of dates, keyed by
#       an incremental counter.
# desc: The cream on top. Takes the hash provided by _thelist and uses
#       it to create a HTML select box form field, making use of any
#       user defined settings.

sub _calselect {
    my ($fmt1,$fmt2,$hash) = @_;
    return  unless($hash);

    # open SELECT tag
    my $select = "<select name='$Settings{selectname}'>\n";

    # add an OPTION elements
    foreach my $key (sort {$a <=> $b} keys %$hash) {
        my $selected = 0;

        # check whether this option has been selected
        $selected = 1
            if( @{$Settings{selected}} &&
                $hash->{$key}->[0] == $Settings{selected}->[0] &&
                $hash->{$key}->[1] == $Settings{selected}->[1] &&
                $hash->{$key}->[2] == $Settings{selected}->[2]);

        # format date strings
        my $date1 = format_date($fmt1,@{$hash->{$key}});
        my $date2 = format_date($fmt2,@{$hash->{$key}});

        # create the option
        $select .= "<option value='$date1'";
        $select .= ' selected="selected"'   if($selected);
        $select .= ">$date2</option>\n";
    }

    # close SELECT tag
    $select .= "</select>\n";
    return $select;
}

# name: _setargs
# args: settings hash ...... optional
# retv: 1 to indicate any bad settings, otherwise undef.
# desc: Sets defaults, then deciphers user defined settings.

sub _setargs {
    my $hash    = shift;
    my $format1 = shift;

    # set the current date
    my @now = localtime();
    my @today = ( $now[3], $now[4]+1, $now[5]+1900 );

    %Settings = ();
    %Settings = %{ clone(\%Defaults) };
    $Settings{startdate} = encode_date(@today);

    # if no user hash table provided, lets go
    return  unless($hash);

    for my $key1 (keys %$hash) {

        # store excluded days
        if(lc $key1 eq 'exclude') {
            for my $key2 (keys %{$hash->{$key1}}) {
                my $inx = $dotw{lc $key2};

                # exclude days of the week
                if(defined $inx) {
                    $Settings{exclude}{days}->[$inx] = $hash->{$key1}{$key2};

                # exclude months
                } elsif($inx = $months{lc $key2}) {
                    $Settings{exclude}{months}->[$inx] = $hash->{$key1}{$key2};

                # exclude weekends
                } elsif(lc $key2 eq 'weekend') {
                    $Settings{exclude}{days}->[0] = $hash->{$key1}{$key2};
                    $Settings{exclude}{days}->[6] = $hash->{$key1}{$key2};
        
                # exclude weekdays
                } elsif(lc $key2 eq 'weekday') {
                    for $inx (1..5) { $Settings{exclude}{days}->[$inx] = $hash->{$key1}{$key2}; }
        
                # check for holiday setting
                } elsif(lc $key2 eq 'holidays' and ref($hash->{$key1}{$key2}) eq 'ARRAY') {
                    %{$Settings{holidays}} = map {$_ => 1} @{$hash->{$key1}{$key2}};
                }
            }

            # ensure we aren't wasting time
            my $count = 0;
            foreach my $inx (0..6)  { $count++  if($Settings{exclude}{days}->[$inx]) }
            return 1    if($count == 7);
            $count = 0;
            foreach my $inx (1..12) { $count++  if($Settings{exclude}{months}->[$inx]) }
            return 1    if($count == 12);

        # store selected date
        } elsif(lc $key1 eq 'select') {
            my @dates = ($hash->{$key1} =~ /(\d+)/g);
            $Settings{selected} = \@dates;

        # store start date
        } elsif(lc $key1 eq 'start') {
            my @dates = ($hash->{$key1} =~ /(\d+)/g);
            $Settings{startdate} = encode_date(@dates);

        # store end date
        } elsif(lc $key1 eq 'end') {
            $Settings{maxcount} ||= 9999;
            my @dates = ($hash->{$key1} =~ /(\d+)/g);
            $Settings{enddate} = encode_date(@dates);

        # store user defined values
        } elsif(lc $key1 eq 'options') {
            $Settings{maxcount} = $hash->{$key1};
        } elsif(lc $key1 eq 'name') {
            $Settings{selectname} = $hash->{$key1};
        }
    }

    # check whether we have a bad start/end dates
    return 1    if(!$Settings{startdate});
    return 1    if( $Settings{enddate} && compare_dates($Settings{enddate},$Settings{startdate}) < 0);
    return 1    if(!$Settings{maxcount});

    return 0;
}

1;

__END__

#----------------------------------------------------------------------------

=back

=head1 DATE FORMATS

=over 4

=item Parameters

The date formatted parameters passed to the two exported functions can take
many different formats. If a single array is required then only one date
format string is required.

Each format string can have the following components:

  DD
  MM
  YYYY
  DAY
  MONTH
  DDEXT
  DMY
  MDY
  YMD
  MABV
  DABV
  EPOCH

The first three are translated into the numerical day/month/year strings.
The DAY format is translated into the day of the week name, and MONTH
is the month name. DDEXT is the day with the appropriate suffix, eg 1st,
22nd or 13th. DMY, MDY and YMD default to '13-09-1965' (DMY) style strings.
MABV and DABV provide 3 letter abbreviations of MONTH and DAY respectively.

EPOCH is translated into the number od seconds since the system epoch. Note
that the Time::Piece module must be installed to use this format.

=item Options

In the optional hash that can be passed to either function, it should be
noted that all 3 date formatted strings MUST be in the format 'DD-MM-YYYY'.

=back

=head1 OPTIONAL SETTINGS

An optional hash of settings can be passed as the last parameter to each
external function, which consists of user defined limitations. Each
setting will effect the contents of the returned lists. This may lead to
conflicts, which will result in an undefined reference being returned.

=over 4

=item options

The maximum number of items to be returned in the list.

Note that where 'options' and 'end' are both specified, 'options' takes 
precedence.

=item name

Used by calendar_selectbox. Names the select box form field.

=item select

Used by calendar_selectbox. Predefines the selected entry in a select box.

=item exclude

The exclude key allows the user to defined which days they wish to exclude
from the returned list. This can either consist of individual days or the
added flexibility of 'weekend' and 'weekday' to exclude a traditional
group of days. Full list is:

  weekday
  monday
  tuesday
  wednesday
  thursday
  friday
  weekend
  saturday
  sunday

=item start

References a start date in the format DD-MM-YYYY.

=item end

References an end date in the format DD-MM-YYYY. Note that if an end
date has been set alongside a setting for the maximum number of options,
the limit will be defined by which one is reached first.  

Note that where 'options' and 'end' are both specified, 'options' takes 
precedence.

=back

=head1 DATE MODULES

Internal to the Calendar::Functions module, there is some date comparison
code. As a consequence, this requires some date modules that can handle a
wide range of dates. There are three modules which are tested for you,
these are, in order of preference, Date::ICal, DateTime and Time::Local.

Each module has the ability to handle dates, although only Time::Local exists
in the core release of Perl. Unfortunately Time::Local is limited by the
Operating System. On a 32bit machine this limit means dates before the epoch
(1st January, 1970) and after the rollover (January 2038) will not be
represented. If this date range is well within your scope, then you can safely
allow the module to use Time::Local. However, should you require a date range
that exceedes this range, then it is recommend that you install one of the two
other modules.

=head1 SEE ALSO

  Calendar::Functions

  Clone
  Date::ICal
  DateTime
  Time::Local
  Time::Piece

  The Calendar FAQ at http://www.tondering.dk/claus/calendar.html

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug to the RT system (see link below). However,
it would help greatly if you are able to pinpoint problems or even supply a
patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me by sending an email
to barbie@cpan.org .

RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-List

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 THANKS TO

Dave Cross, E<lt>dave at dave.orgE<gt> for creating Calendar::Simple, the
newbie poster on a technical message board who inspired me to write the
original code and Richard Clamp E<lt>richardc at unixbeard.co.ukE<gt>
for testing the beta versions.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003-2014 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
