package Date::Christmas;

use strict;
use integer;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(christmasday);
$VERSION = '1.02';

sub christmasday {           
   my $y = shift;  
   my $dow=(50 + $y%100 + $y/400 + ($y%100)/4 - 2*($y/100))%7;
   my @xdays = @_ ? @_ : qw:Sunday Monday Tuesday Wednesday Thursday Friday Saturday:;
   return $xdays[$dow];
}

1;
__END__

=head1 NAME

Date::Christmas - Calculates the day of the week Christmas falls upon given the year.

=head1 SYNOPSIS

=over 4

=item * 

Getting the Christmas Day of the Week in English.

  use Date::Christmas qw(christmasday);
 
  my $year = "2010"; 
  my $dow = christmasday $year;
  print "Christmas day falls on $dow in the year $year\n";

  -or-

  perl -MDate::Christmas -le 'print christmasday (2010)';

=item * 

Getting the Christmas Day of the Week in any other language.
  
  use Date::Christmas qw(christmasday);

  my $year = 2004;
  $xmasdow = christmasday ($year, qw:sunnuntai maanantai tiistai keskiviikko torstai perjantai lauantai:);
  print "Christmas is on $xmasdow in the year $year\n";

  -or-

  perl -MDate::Christmas -le 'print christmasday (2000, qw:Sonntag Montag Dienstag Mittwoche Donnerstag Freitag Sonnabend:)'

=back

=head1 DESCRIPTION

Date::Christmas calculates the day of the week that Christmas will 
fall upon in any given year after the year 1600AD, including leap years 
when using a Gregorian Calendar. The algorithm is based on "The 
Formula for Christmas Day" on pages 261-262 in the book _The Physics 
of Christmas_ by Roger Highfield. 

"Other prognostications, not only of the weather, were based on the day
of the week on which Christmas fell:

 Sunday
 If the natiuity of our Lorde come on Sunday, Winter shall 
 be good, the spring windy, sweet & hot, Vintage flourishing,
 Oxen and Sheepe multiplied: Hony & milke plentifull, peace 
 and accord in the Land, yea, all the Sundayes in the yeere 
 following profitable: They that bee borne shall be strong, 
 great and shining: and he that flieth shall be found.
 
 Monday
 If it fall on the Monday, Winter shall bee indifferent, 
 Sommer dry, or clean contrary, so that if it be rainy and 
 tempestuous, vintage shall be doubtfull; in each Munday of 
 the said yeere, to enterprise any thing is shall bee prosperous
 and sstrong. Who that flieth shall soone be found: theft done 
 shall be proued, and hee that falleth into his bed, soone recouer.
 
 Tuesday
 If it come on the Tuesday, Winter shall be good, the spring 
 windy, Summer fruitfull, Vintage laboursome, Weomen die and 
 shippes perish on the Seas. In each Tuesday of this same yeere,
 to beginne a worke, it will prosper: hee that is borne shall be 
 strong and couteous, dreames pertaine to age. Hee that flieth 
 shall soone bee found; theft done shall be proued.
 
 Wednesday
 If it come on the Wednesday, Winter shall be sharpe and hard, 
 the Spring windy and euill, summer good, Vintage plentifull, 
 good wit easily found, young men die, hony sparing, men desire
 to trauell, and ship-men saile with great hazard that yeere. 
 In each Wednesday to begin a worke is good.
 
 Thursday
 If it come on the Thursday, Winter shall bee good, the Spring 
 windy, Summer fruitfull, Vintage plentifull. Kings and Princes 
 in hazard. And in each Thursday to beginne a new worke, 
 prosperous. Hee that is borne shall be of faire speech and 
 worshipfull, hee that flieth shall soone be found: theft done 
 by weomen shall be proued. Hee that falleth in his bed shall
 soone recouer.
 
 Friday
 If it come on the Friday, winter shall be maruellous, the Spring
 windy and good, Summer dry, Vintage plenteous: There shall be 
 trouble of the aire, Sheepe and Bees perish, Oates deare. In each
 Friday to begin a worke it shall prosper; hee that is borne shall 
 be profitabe and lecherous. Hee that flieth shall soone be found;
 theft done by a Childe shall bee proued.
 
 Saturday
 If it come on the Saturday, Winter shall be dark, snow great, 
 fruit plentious, the spring windy, Summer euill, Vintage sparing 
 in many places: Oates shall be deare, Men waxe sicke, and Bees die.
 In no Saturday to begin a worke shall be good, except in the course 
 of the Moone alter it: Theft done shall be found, hee that flieth 
 shall turne againe to his owne; those that are sicke, shall long 
 waile, and vnneath they shall escape death. 
 'Godfridus', The knowledge of things vnknowne, 1-3"
 [The Oxford Companion to the Year, pp. 516-517.]
 
 Happy Holidays
 + 
 + 
 XXX 
 XXXXX 
 XXXXXXX 
 XXXXXXXXX 
 BOAS FESTAS 
 JOYEUX NOEL 
 VESELE VANOCE 
 MELE KALIKIMAKA 
 NODLAG SONA DHUIT 
 BLWYDDYN NEWYDD DDA 
 GOD JUL 
 BUON ANNO 
 FELIZ NATAL 
 HYVAA JOULUA
 FELIZ NAVIDAD 
 MERRY CHRISTMAS 
 KALA CHRISTOUGENA 
 VROLIJK KERSTFEEST 
 FROHLICHE WEIHNACHTEN 
 BUON NATALE-GODT NYTAR 
 HUAN YING SHENG TAN CHIEH 
 WESOLYCH SWIAT-SRETAN BOZIC 
 MOADIM LESIMH0-LINKSMU KALEDU 
 HAUSKAA JOULU0-AID SAID MOUBARK 
 'N PRETTIG KERSTMIS 
 ONNZLLISTA UUTTA VUOTTA 
 Z ROZHDESTYOM KHRYSTOVYM 
 ADOLIG LLAWEN-GOTT NYTTSAR 
 FELIC NADAL-GOJAN KRISTNASKON 
 S NOVYM GODOM-FELIZ ANO NUEVO 
 GLEDILEG JOL-NOELINIZ KUTLU OLSUM 
 EEN GELUKKIG NIEUWJAAR-SRETAN BOSIC 
 KRIHSTLINDJA GEZUAR-KALA CHRISTOUGENA 
 SELAMAT HARI NATAL - LAHNINGU NAJU METU 
 SARBATORI FERICITE-BUON ANNO
 ZORIONEKO GABON-HRISTOS SE RODI 
 BOLDOG KARACSONNY-VESELE VIANOCE 
 MERRY CHRISTMAS - - HAPPY NEW YEAR 
 ROOMSAID JOULU PUHI -KUNG HO SHENG TEN 
 FELICES PASUAS-EIN GLUCKICHES NEWJAHR 
 PRIECIGUSZIEMAN SVETKUS SARBATORI VESLLE 
 BONNE ANNEBLWYDDYN NEWYDD DDADRFELIZ NATAL 
 XXXXX 
 XXXXX 
 XXXXX 
 XXXXXXXXXXXXX

=head1 AUTHOR

HFB, hfb@cpan.org

=head1 SEE ALSO

perl(1), Date::Calc, Date::Manip.

=cut
