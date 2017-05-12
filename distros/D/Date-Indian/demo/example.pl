# Test and demo program for Date::Indian module.
use Indian;
use strict;

# Names.
my $tithiid = [ qw(
  su.padyami su.vidiya su.tadiya su.chaviti su.panchami 
  su.shasthi su.saptami su.astami su.navami su.dasami
  su.ekadasi su.dwadasi su.triodasi su.chaturdasi pournami
  kr.padyami kr.vidiya kr.tadiya kr.chaviti kr.panchami 
  kr.shasthi kr.saptami kr.astami kr.navami kr.dasami
  kr.ekadasi kr.dwadasi kr.triodasi kr.chaturdasi amavasya
  ) ];

my $nkid = [ qw(
 Aswini  Bharani  Krittika  Rohini  Mrigasira  Aridra
 Punarvasu Pushya Aslesha Makha Pubba Uttara 
 Hasta Chitta Swati Visakha Anuradha Jyeshta
 Moola Poorvashadha Uttarashadha Sravana Dhanishta
 Satabhisha Poorvabhadra Uttarabhadra Revati     
) ];

my $yogaid = [ qw(
  Vishkambha   Prithi   Ayushman  Saubhagya Sobhana   Atiganda
  Sukarman     Dhrithi  Soola     Ganda     Vridhi    Dhruva 
  Vyaghata     Harshana Vajra     Siddhi    Vyatipata Variyan
  Parigha      Siva     Siddha    Sadhya    Subha     Sukla
  Bramha       Indra    Vaidhruthi
)];

my $karanaid = [ qw(
  Bava Balava Kaulava Taitula Garija Vanija 
  Visti Sakuna Chatuspada Naga Kimstughna
)];

# Hyderabad 78.30E 17.20N  tz = 5.5;
# Raleigh   78:39W 35:46N  tz = -4.0;
# Rajahmundry 81:48E 17:00N 17:02
my $ymd  = $ARGV[0];
my $tz   = $ARGV[1];
my $locn = $ARGV[2] . ' '. $ARGV[3]  ;
print " args: $ymd, $tz, $locn \n";
my  $d = Indian -> new ( ymd=>    $ymd,
	                 tz =>    $tz,
			 locn =>  $locn, 
		 );
my ($sr, $ss, $fl) = $d->sunriseset();
print "Sun  rise:	",hms($sr),"\n";
print "Sun  transit:	",hms(($sr+$ss)/2), "\n";
print "Sun  set :	",hms($ss),"\n";

my ($mr, $ms, $fl) = $d->moonriseset();
print "Moon rise:	",hms($mr),"\n"  if $mr;
print "Moon set :	",hms($ms),"\n"  if $ms;


my %th = $d->tithi_endings();
for my $t (sort keys %th){
  print "Tithi ", $tithiid->[$t], " ends at ", hms($th{$t}), "\n";
}

my %nk = $d->nakshyatra_endings();
for my $t (sort keys %nk){
  print "Nakshyatra ", $nkid->[$t] , " ends at ", hms($nk{$t}), "\n" 
     if $nk{$t} > 0 && $nk{$t} <= 24.0;
}

#my $sun = $d -> sun()-> n_long();
#print "Sun's longitude = $sun\n";

# Return hh:mm form string for the number.
sub hms{
  my $arg = shift;
  my $sign = '';
  $sign = '-' if $arg < 0;
  $arg *= -1 if $arg < 0;
  my $h = int($arg);
  my $m = int(($arg - $h)*60.0);
  my $s = int($arg*3600.0)%60;
  $m += 1 if $s >= 30;
  if ($m == 60){
    $m = 0;
    $h += 1;
  }
  $h = '0'.$h if $h < 10;
  $m = '0'.$m if $m < 10;
  return $sign.$h . ':' . $m;
}

# Sun chara tracking.

my ($nav, $t ) = $d->sunchara();
if ($nav){
  if ( $nav % 9 != 0 ){ # Change of start & navamsa case.
    print "Sun's in ", $nkid->[int($nav/4)], " ", $nav % 4, " at:	",hms($t),"\n";
  }else{# Change of sign case.
    print "Solar ingress to ", int($nav/9)," at:	",hms($t), "\n";
  }
}
print "Length of the day:	", hms($d->daylength()), "\n";

# New moon calculations:

my $td = Indian -> new ( jdate => $d->newmoon(), tz => '5:30');
my ($yr,$mn,$dt,$tm) = $td->ymd();
print "Prev new Moon:	$yr-$mn-$dt ", hms($tm), "\n";

$td = Indian -> new ( jdate => $d->newmoon(1), tz => '5:30');
($yr,$mn,$dt,$tm) = $td->ymd();
print "Next new Moon:	$yr-$mn-$dt ", hms($tm), "\n";

# Rahu, Gulika and Yamaganda kalam.
my ($from, $to) = $d->rahu_kalam();
print "Rahu kalam	", hms($from), " to ", hms($to), "\n";
($from, $to) = $d->gulika_kalam();
print "Gulika kalam	", hms($from), " to ", hms($to), "\n";
($from, $to) = $d->yamaganda_kalam();
print "Yamaganda kalam	", hms($from), " to ", hms($to), "\n";

# Durmuhurtas.
my ($d1_s, $d1_e, $d2_s, $d2_e) = $d->durmuhurtam();
print "Durmurtam	", hms($d1_s), " to ", hms($d1_e), "\n";
print "Durmurtam	", hms($d2_s), " to ", hms($d2_e), "\n"
 if $d2_s;


#Varjyam.
my @out = $d->varjyam();
foreach my $vs ( @out){
	print "varjyam from ", hms($vs)," till ", hms($vs+1.6),"\n";
}

# Karanam:
my %th = $d->karana_endings();
for my $t (sort keys %th){
  my $k;
  $k = 10 if $t == 0;
  $k = $t - 50 if $t >= 57;
  $k = ($t-1) % 7 if ($t >0) & ($t <57);
  print "Karana ", $karanaid->[$k], " ends at ", hms($th{$t}), "\n";
}

# Compute traditional saka date for the gregorian calendar date.
# Takes care of inter calary months.
sub greg2saka{
   my $self = shift;
   my $sun  = $self->sun();
   my ($sr, $ss, $flag) = $self -> sunriseset();
   my $day = int($self->tithi($sr/24.0)) % 30;
   my $td = Indian -> new ( jdate => $self->newmoon(), tz => '5:30');
   my ($yr,$mn,$dt,$tm) = $td->ymd();
   $sun = $td ->sun();
   my $sl = $sun->n_long();
   my $m = int($sl/30);
   my $year = $yr - 78;
   $year -= 1 if int($sl/30) < 11;
   my $mon = int($sl/30 + 1) % 12;
   $td = Indian -> new ( jdate => $self->newmoon(1), tz => '5:30');
   ($yr,$mn,$dt,$tm) = $td->ymd();
   $sun = $td ->sun();
   $sl = $sun->n_long();
   $mon = $mon + 0.1 if $mon == int($sl/30 + 1) % 12;
   print "year = $year,  month = $mon,  day = $day\n";
}
greg2saka( $d );
