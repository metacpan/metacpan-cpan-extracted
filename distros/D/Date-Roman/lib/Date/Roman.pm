package Date::Roman;
use Carp;
use Roman qw(); #do not import roman and Roman, we want define our
                #'roman' sub, which does something entierly different
                #from Roman::roman

use strict;

use vars qw($VERSION);

use constant LastJulian => 1582;

# Symbolic constants to identify fixed days

use constant Kalendae => 0;
use constant Nonae => 1;
use constant Idibus => 2;

$VERSION = '1.06';

# Array local variables containing months' names
my @MONS_SHORT = ('','Ian.','Feb.','Mar.','Apr.','Mai.','Iun.',
		  'Iul.','Aug.','Sep.','Oct.','Nov.','Dec.');

my @MONS = ('','Ianuarias','Februarias','Martias','Apriles',
	    'Maias','Iunias','Iulias','Augustas','Septembres',
	    'Octobres','Novembres','Decembres');

my @MONS_FD = ('','Ianuariis','Februariis','Martiis','Aprilibus',
	       'Maiis','Iuniis','Iuliis','Augustis','Septembribus',
	       'Octobribus','Novembribus','Decembribus');


# Array local variables containing fixed day names (Nota: the indexing
# is based on the constants above).

my @FD_SHORT = ('Kal.','Non.','Id.');
my @FD = ('Kalendas','Nonas','Idus');
my @FD_FD = ('Kalendis','Nonis','Idibus');




sub new {
  my $class = shift;
  my ($ical,$roman);
  
  # default behavior: Date::Roman->new() is the same thing as
  # Date::Roman->new(epoch => time())
  
  @_ = ('epoch',time()) unless @_;

  if (ref($_[0])) {
    my $dateobject = shift;
    if ($dateobject->can('roman')) {
      $roman = _parse_roman($dateobject->roman());
    }
    elsif ($dateobject->can('ical')) {
      $ical = _parse_ical($dateobject->ical());
    }
    else {
      croak "Bad parameter to ",__PACKAGE__,"::new()";
    }
  }
  elsif ($_[0] eq 'roman') {
    $roman = _parse_roman($_[1]);
  }
  elsif ($_[0] eq 'ical') {
    $ical = _parse_ical($_[1]);
  }
  elsif ($_[0] eq 'epoch') {
    my ($day,$month,$year) = (localtime($_[1]))[3,4,5];
    $ical->{day} = $day;
    $ical->{month} = $month + 1;
    $ical->{year} = $year + 1900;
  }
  else {
    my %args = @_;
    if (grep {exists $args{$_}} qw(base mons annus)) {
      $args{ad} = 1 unless exists $args{ad};
      $args{bis} = 0 unless exists $args{bis};
      $args{base} = lc($args{base});
      $args{base} = ($args{base} eq 'kal') ? Kalendae : 
	(($args{base} eq 'non') ? Nonae : Idibus);

      foreach (qw(base mons annus)) {
	croak "Parameter $_ is mandatory" unless exists $args{$_};
      }

      #I hate it...
      foreach (qw(ad mons annus)) {
	$args{$_} += 0;
      }

      _check_roman(\%args);
      $roman = \%args;
    }
    elsif (grep {exists $args{$_}} qw(day month year)) {
      #I hate it...
      foreach (keys %args) {
	croak "Parameter $_ mandatory" unless exists $args{$_};
	$args{$_} += 0;
      }      
      _check_ical(\%args);
      $ical = \%args;
    }
    else {
      croak "Bad parameters to ",__PACKAGE__,"::new()";
    }
  }

  $roman = _ical_to_roman($ical) unless $roman;

  
  bless $roman,$class;
}

sub roman {
  my $self = shift;
 
  if (@_) {
    my $roman = shift;
    my $rhash = _parse_roman($roman);
    if ($rhash) {
      %{$self} = %{$rhash};
    }
    else {
      carp __PACKAGE__," Malformed roman date string $roman";
    }
  }
  
  my $result;
  if ($self->{bis}) {
    $result = "b6 ";
  }
  elsif ($self->{ad} == 2) {
    $result = "pd ";
  }
  elsif ($self->{ad} > 2) {
    $result = "$self->{ad} ";
  }

  $result .= (qw(kal non id))[$self->{base}];

  $result .= " $self->{mons} $self->{annus}";

  return $result;
}


sub ical {
  my $self = shift;
  my $ihash;

  if (@_) {
    my $ical = shift;
    $ihash = _parse_ical($ical);
    if ($ihash) {
      my $rhash = _ical_to_roman($ihash);
      %{$self} = %{$rhash};
    }
    else {
      carp __PACKAGE__," Malformed ical string $ical";
    }
  }
    
  unless ($ihash) {
    $ihash = _roman_to_ical($self);
  }
  
  sprintf "%d%0.2d%0.2d",$ihash->{year},$ihash->{month},$ihash->{day};
}



sub add {
  my $self = shift;
  my ($days) = @_;
  my $class = ref($self);

  my %result = %{$self};
  $result{ad} -= $days;
  
  _normalize_roman_date(\%result);

  bless \%result,$class;
}

sub postridie {
  $_[0]->add(1);
}

sub heri {
  $_[0]->add(-1);
}


sub as_string {
  my $self = shift;
  my %args = @_;
  my %params = ();
  my $string = "";

  $params{prefix} = $args{prefix} ||$args{words} || 'abbrev';
  $params{die} = $args{die} || $args{num} || 'Roman';
  $params{mons} = $args{mons} || $args{words} || 'abbrev';
  $params{fday} = $args{fday} || $args{words} || 'abbrev';
  $params{annus} = $args{annus} || $args{num} || 'Roman';
  $params{auc} = $args{auc} || $args{words} || 'abbrev';

  if ($self->{ad} == 2) {
    $string = ($params{prefix} eq 'abbrev') ? "p.d. " : "pridie ";
  }
  elsif ($self->{ad} > 2) {
    $string = ($params{prefix} eq 'abbrev') ? "a.d. " : "ante diem ";
    if ($params{die} eq 'Roman') {
      $string .= Roman::Roman($self->{ad});
    }
    elsif ($params{die} eq 'roman') {
      $string .= Roman::roman($self->{ad});
    }
    else {
      $string .= $self->{ad};
    }
    $string .= " ";
  }

  
  if ($params{fday} eq 'abbrev') {
    $string .= $FD_SHORT[$self->{base}]." ";
  }
  else {
    $string .= ($self->{ad} == 0) ? "$FD_FD[$self->{base}] " 
      : "$FD[$self->{base}] ";
  }

  if ($params{mons} eq 'abbrev') {
    $string .= "$MONS_SHORT[$self->{mons}] ";
  }
  else {
    $string .= ($self->{ad} == 0) ? $MONS_FD[$self->{mons}] : $MONS[$self->{mons}];
    $string .= " ";
  }

  if ($params{annus} eq 'Roman') {
    $string .= Roman::Roman($self->{annus});
  }
  elsif ($params{annus} eq 'roman') {
    $string .= Roman::roman($self->{annus});
  }
  else {
    $string .= $self->{annus};
  }

  if ($params{auc} eq 'abbrev') {
    $string .= " AUC";
  }
  else {
    $string .= " ab Urbe Condida";
  }

  return $string;
}




#private subroutines

# _parse_roman: takes a roman date string and returns a reference to
# an hash describing the corresponding roman date and ready to be
# blessed.

my $roman_date_regexp = qr/^(?:(b6|pd|\d+)\s+)?(kal|non|id)\s+(\d+)\s+(\d+)/i;

sub _parse_roman {
  my $datestring = shift;

  my %result = (bis => 0);
  unless ($datestring =~ /$roman_date_regexp/) {
    croak "Malformed roman date string: $datestring";
  }
  
  my ($prefix,$base,$mons,$annus) = map lc,($1,$2,$3,$4);

  if (!$prefix) {
    $result{ad} = 1;
  }
  elsif ($prefix eq 'pd') {
    $result{ad} = 2;
  }
  elsif ($prefix eq 'b6') {
    $result{ad} = 6;
    $result{bis} = 1;
  }
  else {
    $result{ad} = $prefix;
  }

  $result{base} = ($base eq 'kal') ? Kalendae : 
    (($base eq 'non') ? Nonae : Idibus);

  $result{mons} = $mons;
  $result{annus} = $annus;

  #sanity checks
  _check_roman(\%result) || carp "Malformed Roman date hash";

  return \%result;
  
}

# _check_roman: given a reference to an hash supposed to define a date
# in the Roman format (such the one returned by _parse_roman) it
# returns true if and only if the hash repesents a correct date.

sub _check_roman {
  my $rhr = shift;

  return undef unless $rhr->{base} >= Kalendae and $rhr->{base} <= Idibus; 
  return undef unless ($rhr->{mons} >= 1) and ($rhr->{mons} <= 12);
  return undef if $rhr->{bis} and ($rhr->{base} != Kalendae or 
				   $rhr->{mons} != 3 or 
				   ! _leap($rhr->{annus},'roman'));
  return undef unless $rhr->{ad} <= _days_before($rhr->{base},$rhr->{mons});
  return 1;
}


# _parse_ical: takes a ical date string and returns a reference to
# an hash describing the corresponding date.

my $ical_date_regexp = qr/^(-?\d+)(\d\d)(\d\d)(?:$|T)/;

sub _parse_ical {
  my $datestring = shift;
  my %result = ();

  unless (@result{'year','month','day'} = map {$_+0} ($datestring =~ /$ical_date_regexp/)) {
    croak "Malformed ical date string: $datestring";
  }

  #sanity check
  _check_ical(\%result) || carp "Malformed ical date hash";

  return \%result;
}

# _check_ical: given a reference to an hash supposed to define a date
# in the ical format (such the one returned by _parse_ical) it
# returns true if and only if the hash repesents a correct date.
sub _check_ical {
  my $ihr = shift;

  return undef if ($ihr->{month} < 1 or 
		   $ihr->{month} > 12);

  return undef if ($ihr->{day} <= 0  or 
		   $ihr->{day} > 31);

  return undef if ($ihr->{day} > 30 and 
		   ($ihr->{month} == 4 or $ihr->{month} == 6 or 
		    $ihr->{month} == 9 or $ihr->{month} == 11));

  return undef if ($ihr->{month} == 2 and 
		   ($ihr->{day} > 29 or 
		    ($ihr->{day} > 28 and !_leap($ihr->{year}))));
  return 1;
}


# _normalize_month: Given a month number, 'normalize' it, i.e. replace
# it in the 1..12 interval.

sub _normalize_month {
  use integer;

  my ($mons) = @_;
  my $result = (($_[0] - 1) % 12) + 1;

  unless (wantarray()) {
    return $result;
  }

  return ($result,$mons/12);
}

sub _normalize_roman_date {
  my $rhr = shift;

#   print "_normalize_roman_date({",
#     join(",", map {"$_ => $rhr->{$_}"} keys %{$rhr}),
#       "})\n";

  my ($mons,$deltay) = _normalize_month($rhr->{mons});

  $rhr->{mons} = $mons;
  $rhr->{annus} += $deltay;
  $rhr->{ad}++ if $rhr->{bis} or (($rhr->{mons} == 3) and
				  ($rhr->{base} == Kalendae) and
				  ($rhr->{ad} > 6) and 
				  (_leap($rhr->{annus},'roman')));
  $rhr->{bis} = 0;

#  print "After initialization:\n";
#  print "{",join(",", map {"$_ => $rhr->{$_}"} keys %{$rhr}),"}\n";

  while (($rhr->{ad} > _days_before($rhr->{base},$rhr->{mons}) - 1) or
	 (($rhr->{base} == Kalendae) and
	  ($rhr->{mons} == 3) and 
	  _leap($rhr->{annus},'roman') and
	  ($rhr->{ad} > 17))) {
    #decrement $rhr->{ad} and set mons and annus accordingly   
#    print "decrementing\n";

    $rhr->{ad} -= _days_before($rhr->{base},$rhr->{mons});
    $rhr->{ad}-- if (($rhr->{base} == Kalendae) and
		     ($rhr->{mons} == 3) and
		     _leap($rhr->{annus},'roman'));
    

    $rhr->{base} = ($rhr->{base} - 1) % 3;
    $rhr->{mons}-- if $rhr->{base} == Idibus;

    if ($rhr->{mons} == 0) {
      $rhr->{mons} = 12;
      $rhr->{annus}--;
    }
  }

  while ($rhr->{ad} < 1) {
#    print "Incrementing\n";
    #increment $rhr->{ad} and set mons and annus accordingly
    $rhr->{base} = ($rhr->{base} + 1) % 3;

    $rhr->{mons}++ if $rhr->{base} == Kalendae;

    if ($rhr->{mons} == 13) {
      $rhr->{mons} = 1;
      $rhr->{annus}++;
    }

    $rhr->{ad} += _days_before($rhr->{base},$rhr->{mons});
    
     $rhr->{ad}++ if (($rhr->{base} == Kalendae) and
 		     ($rhr->{mons} == 3) and
		     _leap($rhr->{annus},'roman'));
  }

  if (_leap($rhr->{annus},'roman') and
      ($rhr->{mons} == 3) and
      ($rhr->{base} == Kalendae) and
      ($rhr->{ad} > 6)) {
    $rhr->{bis} = 1 if $rhr->{ad} == 7;
    $rhr->{ad}--;
  }

  return $rhr;

}

# _days_before: Given a fixed day and a month returns the number of
# days existing in that month before that given fixed day. Reamrks
# that this is always the same, unregarding if the year is leap or
# not.

sub _days_before {
  my ($base,$month) = @_;
  return 8 if $base == Idibus;
  
  return _fixed_day(Nonae,$month) -1 if $base == Nonae;

  #Kalendas
  return _monthlength($month - 1) - _fixed_day(Idibus,$month - 1) + 1;
}

# _fixed_day: Given a fixed day and a month returns the 'position' of
# the fixed day in the month. Month is normalized.

sub _fixed_day {
  my ($fd,$mons) = @_;

  return 1 if $fd == Kalendae;

  $mons = _normalize_month($mons);

  if ($fd == Idibus) {
    return 15 if ($mons == 3) or ($mons == 5) or 
      ($mons == 7) or ($mons == 10);
    return 13;    
  }
  else {
    return 7 if ($mons == 3) or ($mons == 5) or 
	($mons == 7) or ($mons == 10);
    return 5;      
  }
}

# _monthlength: given a month number returns the length of the month. 
#
# Notes: 
#
# 1. for February we always returns 28. 
#
# 2. month is normalized.

sub _monthlength {
  my $month = _normalize_month(shift);

  return 28 if $month == 2;
  return 30 if ($month == 4 or $month == 6 or $month == 9 or $month == 11);
  return 31;
}

# _leap: is a given year leap?
sub _leap {
  my $year = shift;
  my $format = shift || 'christian';

  $year -= 753 if $format eq 'roman';
  
  return 0 if ($year % 4);
  return 1 if ($year <= LastJulian) or ($year % 100);
  return 0 if ($year  % 400);
  return 1;
}


# _ical_to_roman: Given a reference to an hash representing a date in
# the ical format (as returned by the _parse_ical sub) it returns a
# reference to an hash containing the corresponding Roman date, as
# returned by the _parse_roman sub.

sub _ical_to_roman {
  my $ihr = shift; #ical hash ref
  my %result = (bis => 0);
  my $fd;

  if ($ihr->{day} == 1) {
    $result{ad} = 1;
    $result{base} = Kalendae;
    $result{mons} = $ihr->{month};
    $result{annus} = $ihr->{year};
  }
  elsif ($ihr->{day} <= ($fd = _fixed_day(Nonae,$ihr->{month}))) {
    $result{ad} = $fd - $ihr->{day} + 1;
    $result{base} = Nonae;
    $result{mons} = $ihr->{month};
    $result{annus} = $ihr->{year};
  }
  elsif ($ihr->{day} <= ($fd = _fixed_day(Idibus,$ihr->{month}))) {
    $result{ad} = $fd - $ihr->{day} + 1;
    $result{base} = Idibus;
    $result{mons} = $ihr->{month};
    $result{annus} = $ihr->{year};
  }
  else {
    $result{base} = Kalendae;
    $result{mons} = ($ihr->{month} < 12) ? $ihr->{month} + 1 : 1;
    $result{annus} = ($result{mons} == 1) ? $ihr->{year} + 1 : $ihr->{year};

    if ($result{mons} != 3 or !_leap($ihr->{year}) or ($ihr->{day} < 24)) {
      $result{ad} = _monthlength($ihr->{month}) - $ihr->{day} + 2;
    }
    elsif ($ihr->{day} == 24) {
      $result{bis} = 1;
      $result{ad} = 6;
    }
    else {
      $result{ad} = 31 - $ihr->{day};
    }
  }

  $result{annus} += 753;

  return \%result;
}

# _roman_to_ical:
sub _roman_to_ical {
  my $rhr = shift; # roman hash ref
  my %result = ();


  $result{year} = (($rhr->{mons} == 1) and 
                   ($rhr->{base} == Kalendae) and 
		   ($rhr->{ad} > 1)) ? $rhr->{annus} - 1 : $rhr->{annus};
  
  $result{year} -= 753;

  $result{month} = (($rhr->{base} != Kalendae) or ($rhr->{ad} == 1)) ?
    $rhr->{mons} :
      (($rhr->{mons} > 1) ? $rhr->{mons} - 1 : 12);

  if ($rhr->{base} == Kalendae) {
    if ($rhr->{ad} == 1) {
      $result{day} = 1;
    }
    else {
      $result{day} = _monthlength($result{month}) - $rhr->{ad} + 2;
      if ($result{month} == 2 and 
	  ($rhr->{ad} < 6 or ($rhr->{ad} == 6 and !$rhr->{bis})) and
	  (_leap($result{year}))) {
	$result{day}++;
      }
    }
  }
  else {
    $result{day} = _fixed_day($rhr->{base},$rhr->{mons}) - $rhr->{ad} + 1;
  }

  return \%result;
}
1;
__END__


=head1 NAME

Date::Roman - Perl OO extension for handling roman style dates

=head1 SYNOPSIS

  use Date::Roman;

  $caesar_death = Date::Roman->new(roman => 'id 3 702');
  
  print $caesar_death->ical(),"\n"; #prints -520315

  

=head1 DESCRIPTION

This module defines a class for handling Roman dates as defined by
Julius Caesar in S<45 BC>.


=head1 METHODS

The following methods are defined for C<Date::Roman> objects:

=over

=item C<new>


This method is the class constructor. It can be invoked in quite a lot
of different ways:

=over

=item C<Date::Roman-E<gt>new()>

With no arguments, is the same that

  Date::Roman->new(epoch => time())

=item C<Date::Roman-E<gt>new($dateobj)>

where C<$dateobj> is a date objet. The only requested characteristic
for this object is to support either a C<roman> or a C<ical> method
behaving like the corresponding method of this class. For instance, it
could be a B<Date::Roman> or a B<Date::ICal> object.

=item C<Date::Roman-E<gt>new(format =E<gt> $datestring)>

where C<format> is one of I<roman> or I<ical> and C<$datestring> is a
date in the format specified by C<format> 
(L<see the DATE FORMATS section below|DATE FORMATS>).


=item C<Date::Roman-E<gt>new(dateelem =E<gt> $value,...)>

this form allows you to enter a date by giving its constitutive
elements. The given date can be either in the Roman or in the
Christian form. 

In the first case, you have to give the following mandatory elements:
'base' (the fixed day part of the date, can be one of 'kal', 'non' or
'id'), 'mons' (the month, must be a number between 1 and 12) and
'annus' (the year in the AUC count, must be a positive integer). You can
add the following optional elmements: 'ad' (the days before the given
fixed day, must be a positive integer, defaults to 1) and 'bis'
(boolean specifying if the given day is the 'leap day').

In the second case, you must specify all the following elements: 'day'
(the day of the month, starting at 1), 'month' (the month, must be a
number between 1 and 12) and 'year' (the year in the Christian era
format, year 0 is S<1 BC>).


=back


=item C<roman>

Called without arguments, it returns the date in the I<roman> format
(L<see the DATE FORMATS section below|DATE FORMATS>). 
If is called with one arguments it assumes it is a
date string in the I<roman> format, and sets the date to it.


=item C<ical>

Called without arguments, it returns the date in the I<ical> format
(L<see the DATE FORMATS section below|DATE FORMATS>). 
If is called with one arguments it assumes it is a
date string in the I<ical> format, and sets the date to it.


=item C<as_string>

This method returns a printable version of the date in the classical
Roman format. The format of the returned string can be controlled with
the parameters passed to the method. Parameters are passed to the
method using the classical 'hash like' approach:

   $date->as_string(name => value,...);

The method C<as_string> accepts the following parameters:

=over

=item B<prefix>

Controls how the "ante diem" or "pridie" part of the date is
written. Possible values are: B<abbrev>, which writes them as "a.d."
and "p.d." respectively, and B<complete> which writes them in
full. This parameter defaults to the value of the B<words> parameter
below if given, and to B<abbrev> otherwise.

=item B<die>

Controls how the number of the "ante diem" day is written. Possible
values are: B<Roman>, which writes it as an uppercase Roman numeral;
B<roman>, which writes it as a lowercase Roman numeral; and B<arabic>,
which writes it as an Arabic numeral. This parameter defaults to the
value of the B<num> parameter below if given, to B<Roman> otherwise.


=item B<fday>

Controls how the I<fixed day> appearing in the date is
written. Possible values are: B<abbrev>, which writes it abbreviated
to 'Kal.', 'Non.' or 'Id.'; and B<complete> which writes it in
full. This parameter defaults to the value of the B<words> parameter 
below if given, and to B<abbrev> otherwise.


=item B<mons>

Controls how the I<month> appearing in the date is
written. Possible values are: B<abbrev>, which writes it abbreviated
as 'Ian.', 'Feb.' an so on; and B<complete> which writes it in
full. This parameter defaults to the value of the B<words> parameter 
below if given, and to B<abbrev> otherwise.


=item B<annus>

Controls how the number of the year is written. Possible
values are: B<Roman>, which writes it as an uppercase Roman numeral;
B<roman>, which writes it as a lowercase Roman numeral; and B<arabic>,
which writes it as an Arabic numeral. This parameter defaults to the
value of the B<num> parameter below if given, to B<Roman> otherwise.


=item B<auc>

Controls how the "ab Urbe condita" formula is written. Possible values
are: B<abbrev>, which writes it as "AUC", and B<complete> which writes
it in full. This parameter defaults to the value of the B<words>
parameter below if given, and to B<abbrev> otherwise.


=item B<words>

This parameter permits to give a default value different from
B<abbrev> for the parameters B<prefix>, B<mons>, B<fday> and B<auc>.


=item B<num>

This parameter permits to give a default value different from
B<Romans> for the parameters B<die> and B<annus>.

=back

=item C<add>

Takes as argument an integer C<$n> and returns a I<new> B<Date::Roman>
object representig the date obtained adding C<$n> days to the present
date.

=item C<heri>

Returns the yesterday date. Calling

  $date->heri();

is the same thing as calling

  $date->add(-1);


=item C<postridie>

Returns the tomorrow date. Calling

  $date->postridie();

is the same thing as calling

  $date->add(1);


=back

=head1 TODO

=over

=item 1

Add time management. This will require to determine sunraise/sunset
time for the given day.


=item 2

Change the C<_leap> subroutine to reflect the fact that between 
S<45 BC> (S<709 AUC>) and S<9 BC> (S<745 AUC>) there was a leap year every
B<three> years, then between S<8 BC> (S<744 AUC>) and S<7 AD> 
(S<760 AUC>) there was no leap year to make up for the three exceeding leap
years.

=item 3

Add Ante Urbe Condida years.

=item 4

Rewrite the module in Latin using the B<Lingua::Romana::Perligata>
module.

=back

=head1 DATE FORMATS

Dates can be specified by a string in one of two formats: I<roman>
and I<ical>.


=head2 The I<roman> format.

It is a simplified version of the roman way to write dates 
(L<see the section THE ROMAN CALENDAR below|THE ROMAN CALENDAR>). 
It is defined by the following ABNF specification (see rfc2234):

   <roman date> = [<prefix><spaces>]<fixed day><spaces><mons><spaces><annus>
   <prefix>     = 1*2DIGIT     ; "1".."4" / "1".."6" / "1".."8" /
                               ; "1".."16" / "1".."17" /
                               ; "1".."18" / "1".."19"
                               ; according to <mons> <fixed day>
                               ; value.

   <prefix>    /= "b6"         ; only for <mons> equal to "3", <fixed day> 
                               ; equal to "kal" and <annus> equal to a 
                               ; leap year.
   <fixed day>  = "kal" / "non" / "id"
   <mons>       = 1*2DIGIT     ; "1".."12"
   <annus>      =  1*DIGIT
   <spaces>     =  1*WSP

We use the "b6" prefix to indicate the leap day (24th february)
introduced in leap tears. As it is stated below in section L<The days
in the Roman calendar>, this was again the 6th day before the Kalendae
of March, exatly as the day after.

=head2 The I<ical> format

The I<ical> format is a generalization of the format for dates defined
in rfc2445. The genralization consists in allowing a year in less than
4 digits and in allowing a prefixed "-" to represents years before 
S<1 BC>. More specifically, a I<ical> date string is defined by the
following ABNF specification (see rfc2234):

  <ical date>   = <year> <month> <day>
  <year>        = [<minus>] 1*DIGIT
  <month>       = 2DIGIT   ; "1".."12"
  <day>         = 2DIGIT   ; "1".."28" / "1".."29" /
                           ; "1".."30" / "1".."31" according 
                           ; to <month> <year> value
  <minus>       = %x2d

As it is customary, we use 0 to represent the year S<1 BC>, 
-1 to represent the year S<2 BC> and so on.



=head1 THE ROMAN CALENDAR


=head2 The Julian reform, the month length

Julius Caesar made his famous calendar reform in S<45 BC>. According to
this reform, the year was of 365 days, divided in 12 months:
Ianuarius, 31 days; Februaarius, 28 days, Martius, 31 days; Aprilis,
30 days; Maius, 31 days, Iunius, 30 days, Iulius, 31 days; Sextilis 31
days, September, 30 days, October, 31 days; November, 30 days; and
December, 31 days. Later, Sextilis became Augustus (to simplify, we
used Augustus as name of the 8th month trought the module).


=head2 The Julian reform, leap years

To make up with the fact that the tropical year is a little longer than
365 days, Julius Caesar decreed that one year in 4 should be longer by
one day, adding one day to Februarius. 

Due to a misunderstandig about what "one year in 4" meant, between 
S<45 BC> and S<9 BC> there was a leap year every I<three> years. 
To make up for the surplus of leap years so introduced, emperor 
Augustus decreed a 15 years period without leap years, so that the 
first leap year after S<9 BC> was S<8 AD>. Then there was a leap 
year every 4 years until the Gregorian Reform. This module take into 
account the Gregorian reform assuming that it took place in 
S<1582 AD>. It does not take into account the problems in determining 
leap years between S<45 BC> and S<8 AD> (at least it does not yet, 
L<see the section TODO above|TODO>).

=head2 The days in the Roman calendar

The Romans didn't number the days sequentially from 1. Instead they
had three fixed days in each month: 

=over

=item Kalendae

which was the first day of the month;

=item Idus

which was the 13th day of January, February, April, June, August,
September, November, and December and the 15th day of March, May,
July, or October;

=item Nonae

which was the 9th day befor the Idus (counting Idus itself as the
first day).

=back

The others days, where designed counting backward from these fixed
days. It should be remarked that, in counting backward, the romans
used an inclusive counting. That way, for instance,
the 2 Jan was the 4th day before the nones of January (the nones of
January being the 5th of January).

The day before a fixed day was designed by "pridie", abbreviated as
"p.d.". The other days was designed using the formula "ante diem",
abbreviated as "a.d.". For instance, the 16th of April was 
I<ante diem XVI Kalendas Maias>, abbreviated as I<a.d. Kal. Mai.>

In leap years, the supplemental day was obtained by counting two times
the 6th day before the Kalendae of March.

=head2 Counting the years

Romans counted years starting from the mitical foundation of Rome by
Romolus on 21st April, S<753 BC>. Fr instance, year S<2002 AD> 
is the year S<2755 AUC> (ab Urbe condita, after the foundation 
of the City).

=head2 What before the Julian reform?

Before Julius Caesar introduced the Julian calendar in S<709 AUC>, the
Roman calendar was a mess, and much of our so-called ``knowledge''
about it seems to be little more than guesswork. This module uses the
Julian calendar also for dates before the 1 Jan S<45 BC> (or, more
precisely, Kalendas Ianuariis S<DCCIX AUC>). This is the so called
'proleptic Julian calendar' and it is consistent with the historians'
habit to do so.


=head1 AUTHOR

Leo Cacciari, aka TheHobbit E<lt>thehobbit@altern.orgE<gt>

=head1 THANKS

I would like to thanks people who helped me to get this module right:

=over

=item *

The people on the datetime@perl.org mailing list, expecially Rich
Bowen E<lt>rbowen@rcbowen.comE<gt>, Elaine -HFB- Ashton
E<lt>elaine@chaos.wustl.eduE<gt> and Jean Forget
E<lt>J-FORGET@wanadoo.frE<gt>. 

=item *

The people on the iclp (it.comp.lang.perl) newsgroup, expecially Aldo
Calpini E<lt>dada@perl.itE<gt>.

=item *

Marco, aka `Diese|` from the #roma2 IRCnet channel, who helped me with
Latin. Any Latin error which is still there is mine, the ones that
went away did so thanks to him.


=back

=head1 COPYRIGHT AND  DISCLAIMER

This software is Copyright 2002 by Leo Cacciari.  This software is free
software; you can redistribute it and/or modify it under the terms of
the Perl Artistic License, either as stated in the enclosed LICENSE
file or (at your option) as given on the Perl home site: 
http://www.perl.com/language/misc/Artistic.html




=head2 Software documentation

=over

=item *

L<The perl(1) man page|perl(1)>.

=item *

L<The Roman(3) man page|Roman(3)>.

=item *

L<The Date::ICal(3) man page|Date::ICal(3)>.

=back



=head2 Books

Any Latin textbook.

=head2 Web

The very good Frequently Asked Questions about Calendars by Claus
Tondering. You can found it at 
http://www.tondering.dk/claus/calendar.html
See especially section 2.7.


=cut
