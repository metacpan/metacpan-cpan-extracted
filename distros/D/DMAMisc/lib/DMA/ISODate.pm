#=============================== ISODate.pm ==================================
# Filename:             ISODate.pm
# Description:          ISO date handling.
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:                 $Date: 2008-08-28 23:14:03 $ 
# Version:              $Revision: 1.8 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;

package DMA::ISODate;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

use POSIX;

#=============================================================================
#				Class Methods
#=============================================================================

sub new {
  my ($class, $datestring) = @_;
  return ($class->_new (0,$datestring));
}

#------------------------------------------------------------------------------

sub unix {
  my ($class, $time,$utcflg)  = @_;
  my $self = bless {}, $class;

  defined $time   || (return undef);
  defined $utcflg || ($utcflg = 0);

  my($havedate,$havetime,$y2k) = (1,1,0);
  my ($sec,$min,$hr,$day,$mon,$yr) = 
    ($utcflg) ? gmtime($time) : localtime ($time);
  $yr+=1900; $mon+=1;

  @$self{'y2k','havetime','isUTC',
	 'yr','mon','day','hr','min','sec'} =
    ($y2k,$havetime,$utcflg,
     $yr,$mon,$day,$hr,$min,$sec);

  $self->_set_iso_strings;
  return $self;
}

#------------------------------------------------------------------------------

sub now {return (shift->_new (0,undef));}
sub utc {return (shift->_new (1,undef));}

#------------------------------------------------------------------------------

sub new_formatted {
  my ($class,$fmt,$string) = @_;
  my $self = bless {}, $class;

  return $self;
}

#=============================================================================
#			Object Methods
#=============================================================================

sub get {
  my ($self) = @_;
  return $self->{'date'} . (($self->{'havetime'}) ? $self->{'time'} : "");}

sub canonical {my ($self) = @_; return $self->{'date'} . $self->{'time'};}

#------------------------------------------------------------------------------

sub yearly {
  my ($self) = @_;
  @$self{'mon','day','hr','min','sec','havetime'} = (0,0,0,0,0,0);
  $self->_set_iso_strings;
  return $self;
}

sub monthly {
  my ($self) = @_;
  @$self{'day','hr','min','sec','havetime'} = (0,0,0,0,0);
  $self->_set_iso_strings;
  return $self;
}

#------------------------------------------------------------------------------

sub isyearly {
  my ($self) = @_;
  return (($self->{'mon'} + $self->{'day'} + $self->{'havetime'}) ? 0 : 1);
}

sub ismonthly {
  my ($self) = @_;
  return (($self->{'day'} + $self->{'havetime'}) ? 0 : 1);
}

#------------------------------------------------------------------------------

my @Q = ("Q1-Q4",
	 "Q1",  "Q1", "Q1",
	 "Q2",  "Q2", "Q2",
	 "Q3",  "Q3", "Q3",
	 "Q4",  "Q4", "Q4");

sub quarter {return $Q[shift->{'month'}];}

#------------------------------------------------------------------------------

sub date     {return shift->{'date'};}
sub time     {return shift->{'time'};}
sub y2k      {return shift->{'y2k'};}
sub havetime {return shift->{'havetime'};}
sub isUTC    {return shift->{'isUTC'};}

#------------------------------------------------------------------------------

sub timearray {
  my ($self) = @_;
  return (@$self{'yr','mon','day','hr','min','sec',
		 'havetime','isUTC','y2k'});
}

#=============================================================================
#			Internal Methods
#=============================================================================

sub _new {
  my ($class, $utcflg,$str) = @_;
  my $self = bless {}, $class;

  my ($havedate,$havetime,$y2k,
      $yr,$mon,$day,$hr,$min,$sec) =
	(0,0,0,
	 0,0,0,0,0,0);

  # Times come back in 2-3 digit format which we treat as a y2k correction.
  if (!defined $str) {
    ($havedate,$havetime,$y2k) = (1,1,0);
    ($sec,$min,$hr,$day,$mon,$yr) = 
      ($utcflg) ? gmtime(CORE::time) : localtime (CORE::time);
    $yr+=1900; $mon+=1;
  }
  else {

    # Try ISO date format first.
    # ***** THESE VALUES ARE NOT CHECKED FOR LIMITS OR THAT THE DAY OF THE
    #       MONTH EXISTS IN THAT MONTH AND YEAR.
    ($havedate,$havetime,$y2k,
     $yr,$mon,$day,$hr,$min,$sec) = $self->_isodate($str);

    # ***** Later on fill this in so it handles other formats.
    if (!$havedate) {return undef;}
  }

  $havedate || return undef;

  @$self{'y2k','havetime','isUTC',
	 'yr','mon','day','hr','min','sec'} =
    ($y2k,$havetime,$utcflg,
     $yr,$mon,$day,$hr,$min,$sec);

  $self->_set_iso_strings;
  return $self;
}

#------------------------------------------------------------------------------
# See if we can make an ISODATE out of the string with no chars left over.
# An ISODATE must be at least 6 digits long; it may be for 1 Million AD,
# so we allow lots of digits. Of course you can't stuff that in a Unix
# timval, but we don't need to anyway. 
#
# The return values are in a canonical form:
#	havedate => true if we found the date
#	havetime => true if we found the time
#	y2k      => true if we had a 2 digit year on input.
#
# We could get fancier if we had to. It would not be hard to deal with
# ISO time and date seperated by delimiters; we could also check potential
# MM,DD,YY,HH, MM, SS for validity if we needed to. We will let the caller
# use a standard Perl Module of some sort for that job rather than redoing
# it. We just assume that if it looks ISODATE and is not, it was wrong
# and could not have been parsed in an alternative format. Until someone
# points out an exception, that's my story and I'm sticking to it.
#
# I am leaving extra conditionals here as hooks for in case I was wrong.
# Otherwise I could simplify the routine by a number of lines. Likewise,
#
# ASSUME: I assume two or three digit years should always be replaced 
#	  by yr+1900. Two digit is assumed to be a Y2K problem; 3 digit
#	  is assumed to be a Unix timval that really is yr-1900. Perhaps
#	  we'll need a U2K for 2038...
#
# ASSUME: There is no such thing as an ISODATE that only has the time
#         portion HHMMSS.
#
# Args:		self
#		string
# Returns:	(havedate, havetime, y2k,
#		 year, month, day, hour, minute, second,
#		 remaining_chars)

sub _isodate {
  my ($self, $str) = @_;
  my $r = $str;

  # See if we've got a possible ISO date, at least 6 chars.
  if ($str =~ /^(\d{6,})$/) {
    my ($a1,$a2,$a3,$b1,$b2,$b3,$b4,$b5,$b6);
    my ($iso, $len) = ($1, length $1);
    
    # The 3 item (minimum 6 digits) parse
    if ($iso =~ /^(\d{2,})(\d\d)(\d\d)(.*)/) {($a1,$a2,$a3,$r) = ($1,$2,$3,$4);}
    
    # The 6 item (minimum 12 digits) parse
    if (($len > 6) && 
	($iso =~ /^(\d{2,})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(.*)$/)) {
      ($b1,$b2,$b3,$b4,$b5,$b6,$r) = ($1,$2,$3,$4,$5,$6,$7);}
    
    # 3 item: YYMMDD; (or HHMMSS if we allowed that). This is a Y2K.
    if ($len == 6)               {return (1,0,1, $a1+1900,$a2,$a3, 0,0,0, $r);}

    # 3 item: YYYMMDD, probably a Unix year after 1900. Not a y2k.
    if ($len == 7)               {return (1,0,0, $a1+1900,$a2,$a3, 0,0,0, $r);}
    
    # 3 item: YYYYMMDD to YYYYYYYYMMDD, the later being rather unlikely
    if (($len >= 8) && ($len < 12)) {return (1,0,0, $a1,$a2,$a3, 0,0,0, $r);}
    
    # 6 item: YYMMDDHHMMSS, a y2k date or 3 item: YYYYYYYYMMDD, the later 
    # being rather unlikely but an annoying loss. 
    if ($len == 12) {return (1,1,1, $b1+1900,$b2,$b3, $b4,$b5,$b6, $r);}
    
    # YYYMMDDHHMMSS or YYYYYYYYYYMMDD, the first being a format error
    # with a Unix year after 1900 but more likely than the later.
    if ($len == 13) {return (1,1,0, $b1+1900,$b2,$b3, $b4,$b5,$b6, $r);}
    
    # YYYYMMDDHHMMSS to {Y...}YYYYMMDDHHMMSS to infinity and beyond...
    return (1,1,0, $b1,$b2,$b3, $b4,$b5,$b6, $r);
  }
  return (0,0,0, 0,0,0, 0,0,0, $r);
}

#------------------------------------------------------------------------------
# Update the date and time strings from the yr,mon,day,hr,min,sec fields.

sub _set_iso_strings {
  my ($self) = @_;
  @$self{'date','time','havetime'} =
    (sprintf ("%04d%02d%02d", @$self{'yr','mon','day'}),
     sprintf ("%02d%02d%02d", @$self{'hr','min','sec'}), 
     $self->{'havetime'});
  return $self;
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documentation section with the 'perldoc' cmd.

=head1 NAME

 DMA::ISODate.pm - ISO date handling.

=head1 SYNOPSIS

 use DMA::ISODate;

 $obj         = DMA::ISOdate->new ($datestring);
 $obj         = DMA::ISOdate->now;
 $obj         = DMA::ISOdate->utc;
 $obj         = DMA::ISOdate->unix ($time, $gmflag);
 $obj         = DMA::ISOdate->new_formatted ($fmt, $string);

 $datestring  = $obj->get;
 $datestring  = $obj->canonical;
 $obj         = $obj->yearly;
 $obj         = $obj->monthly;
 $obj         = $obj->isyearly;
 $obj         = $obj->ismonthly;
 $quarter     = $obj->quarter;
 $season      = $obj->season;
 $datestring  = $obj->date;
 $timestring  = $obj->time;
 $havetime    = $obj->havetime;
 $y2k         = $obj->y2k;
 $utc         = $obj->isUTC;

 ($yr,$mon,$day,$hr,$min,$sec,$havetime,$utc,$y2k) = $obj->timearray;

=head1 Inheritance

 UNIVERSAL

=head1 Description

The primary date time we use is the ISO date, almost always in the basic 
form of YYYYMMDD , like 20021209, but the DMA::ISOdate class will attempt to
create an ISODate from what ever you give it:

 Input data               Canonical ISO result
 YYMMDD              =>       19YYMMDD000000
 YYYMMDD             => (1900+YYY)MMDD000000
 YYYYMMDD            =>       YYYYMMDD000000
 YYYYYMMDD           =>      YYYYYMMDD000000
 YYYYYYMMDD          =>     YYYYYYMMDD000000
 YYYYYYYMMDD         =>    YYYYYYYMMDD000000
 YYMMDDHHMMSS        =>       19YYMMDDHHMMSS
 YYYMMDDHHMMSS       =>  (1900+YY)MMDDHHMMSS
 YYYYMMDDHHMMSS      =>       YYYYMMDDHHMMSS
 {Y..}YYYYMMDDHHMMSS =>  {Y..}YYYYMMDDHHMMSS    

Note that a minimum of 4 digits is needed to correctly express years like 
40AD so as to differentiate it from 1940AD which is what the Y2K correction 
would do with "401209". There are also problems: years cannot be expressed 
beyond 9999999 in the date only format.

Two digit years (00-99) are assume to be Y2K legacy dates. We set the y2k 
flag and add 1900 to the year value when we see one.

Three digit years (000-999) are likely to be uncorrected Unix date returns. 
We do not set the y2k but we do add 1900. This is safe until we hit what 
I'll call the "U2K" date of 2038 when Unix 32b int timevals roll over. This 
is not a problem for this Class; we follow the philosophy of "be liberal on 
inputs and conservative on outputs".

If this all seems very ad hoc -- it is. Date formats are very ad hoc with 
ambiguities which can only be decided with contextual information. That's a 
job for people, not a poor wee ISODate Class.

Four digit year formats are not limited to 4 digits. We can express dates far
into the future. In any place hereafter where we use "YYYY", any number of 
extra digits are possible. 

[We aren't affected by the size of Unix timval (ie the 2038 max year) except 
it is not convenient right now to do a perpetual calendar of my own to check 
the validity of a date.]

We do not, however, have any means of representing dates BC. For this we might
consider using the Peter Kokh dating system which adds 10000 to the AD date to
represent all of human history after the end of the most recent Ice Age. This
allows much easier translation between all modern and ancient dating systems
if you remember there was no year zero as they had not gotten around to 
inventing nothing back then. (Given some recent discoveries offshore in India,
I might prefer adding 20000 years!)

=head1 Examples

 None.

=head1 Class Variables

 None.

=head1 Instance Variables

 y2k            Set if external input was in two digit year format, t/f.
 havetime       Set if input included the time, t/f
 isUTC          date/time is known to be UTC, t/f. 
                (What should the default be since we will
                 only know this if we got the time via newgm.)
 date           "YYYYMMDD" 
 time           "HHMMSS", default is "000000"
 yr             integer year, 0 -size of int
 mon            integer month, 1-12,; 0=no month
 day            integer day, 1-28,29,30 or 31; 0=no day
 hr             integer hour, 0-23
 min            integer minute, 0-59
 sec            integer second, 0-59

=head1 Class Methods

=over 4

=item B<$obj = DMA::ISOdate-E<gt>new ($datestring)>

Assume the $datestring is a local ISO date or date/time in one of the formats
discussed earlier. Returns undef if $datestring can't be parsed our way; 1900
is added to the year if 2 or 3 digits are found and the y2k flag set for 2 
digit years. havetime is set if there was an HHMMSS in the string.

Returns a new object or undef on failure.

=item B<$obj = DMA::ISOdate-E<gt>new_formatted ($fmt, $string)>

Use a Perl date format string to identify the date format we believe $string 
to be in. It returns undef instead of creating a new object if the date 
doesn't work in the given format.

=item B<$obj = DMA::ISOdate-E<gt>now>

Create an object with the current time set to right now in local time. Always
succeeds, always Y2K compliant and has HHMMSS available.

=item B<$obj = DMA::ISOdate-E<gt>unix ($time, $gmflag)>

Create an object for a unix timeval. $time is required and assumed to be a 
unix time integer. If $gmflag is present and set, make it a UTC  time, 
otherwise it is local time. Always succeeds, always Y2K compliant and has 
HHMMSS available.

This routine is useful when dealing with info from archive file directory 
stats.

=item B<$obj = DMA::ISOdate-E<gt>utc>

Create an object with the current time set to right now in UTC time. Always 
succeeds, always Y2K compliant and has HHMMSS available.

=back 4

=head1 Instance Methods

=over 4

=item B<$datestring = $obj-E<gt>canonical>

Returns an the object's ISODATE. In a canonical form:  YYYYMMDD HHMMSS . If 
havetime is not set, we get YYYYMMDD000000. 

=item B<$datestring  = $obj-E<gt>date>

Returns the ISO date as YYYYMMDD .

=item B<$datestring = $obj-E<gt>get>

Returns an the object's ISODATE. In one of two forms, either YYYYMMDD  if 
havetime is not set or YYYYMMDDHHMMSS  if it is.

=item B<$havetime = $obj-E<gt>havetime>

True if we have a time of day stored.

=item B<$obj = $obj-E<gt>ismonthly>

Test if the ISO date is suitable for things like monthly magazines. Returns 
true if havetime and day of month are clear. It means your ISO date is of the
form "19950500".

=item B<$utc = $obj-E<gt>isUTC>

True if the time we stored was UTC.

=item B<$obj = $obj-E<gt>isyearly>

Test if the ISO date is suitable for things like yearly reports. Returns true
if havetime, month and day of month are clear. It means your ISO date is of 
the form "19950000".

=item B<$obj = $obj-E<gt>monthly>

Change the ISO date so it is of use for things like monthly magazines. 
havetime is cleared.  All time and date field below month are zeroed. Your 
ISO date will now look like "19950500".

=item B<$quarter = $obj-E<gt>quarter>

Returns the quarter string for the date. Q1,Q2,Q3,Q4 or Q1-Q4 if the date has
no month, eg "19950000".

=item B<$season = $obj-E<gt>season>

Returns the season: winter, spring,summer,fall.

=item B<$timestring  = $obj-E<gt>time>

Returns the time as HHMMSS if havetime is set; otherwise the midnight time 
string "000000".

=item B<($yr,$mon,$day,$hr,$min,$sec,$havetime,$utc,$y2k) = $obj-E<gt>timearray>

Return the date/time information.

=item B<$y2k = $obj-E<gt>y2k>

True if we applied a Y2K correction to the year in our stored date.

=item B<$obj = $obj-E<gt>yearly>

Change the ISO date so it is of use for things like yearly reports. havetime 
is cleared.  All time and date field below year are zeroed. Your ISO date 
will now look like "19950000".

=back 4

=head1 Private Class Methods

=over 4

=item B<$obj = DMA::ISOdate-E<gt>_new ($type,$gmflag,$datestring)>

Internal base initializer method which all the other initializer methods  
call.

Not part of the advertised interface for this class, so don't try to use it 
directly.

Returns	self or undef if no date found/created.

=back 4

=head1 Private Instance Methods

None, although I may wish to include the code comments from _isodate here as
it is quite extensive.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 None.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: ISODate.pm,v $
# Revision 1.8  2008-08-28 23:14:03  amon
# perldoc section regularization.
#
# Revision 1.7  2008-08-15 21:47:52  amon
# Misc documentation and format changes.
#
# Revision 1.6  2008-04-18 14:07:54  amon
# Minor documentation format changes
#
# Revision 1.5  2008-04-11 22:25:23  amon
# Add blank line after cut.
#
# Revision 1.4  2008-04-11 18:56:35  amon
# Fixed quoting problem with formfeeds.
#
# Revision 1.3  2008-04-11 18:39:15  amon
# Implimented new standard for headers and trailers.
#
# Revision 1.2  2008-04-10 15:01:08  amon
# Added license to headers, removed claim that the documentation section still
# relates to the old doc file.
#
# Revision 1.1.1.1  2004-09-19 21:59:12  amon
# Dale's library of primitives in Perl
#
# 20040813	Dale Amon <amon@vnl.com>
#		Moved to DMA:: from Archivist::
#		to make it easier to enforce layers.
#
# 20021207	Dale Amon <amon@vnl.com>
#		Created.
1;
