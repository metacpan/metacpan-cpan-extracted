##
## English tables
##

package DateTime::Calendar::Coptic::Language::English;

BEGIN
{
use strict;

use DateTime::Language;
use vars qw(@ISA @DayNames @DayAbbreviations @MonthNames @MonthAbbreviations @AMPM);
@ISA = qw(DateTime::Language);

#
# These are naive transcriptions here temporarily for day names,
# the original data is also somewhat suspect, note that the abbreviated
# names are broken
#
@DayNames = qw(Piouai Pisnau Pishomt Piftoou Pitiou Pisoou Pishashf);
@MonthNames = ( "Tout",
                "Baba",
                "Hator",
                "Kiahk",
                "Toba",
                "Amshir",
                "Baramhat",
                "Baramouda",
                "Bashans",
                "Paona",
                "Epep",
                "Mesra",
		"Nasie"
              );

@DayAbbreviations = map { substr($_,0,3) } @DayNames;
@MonthAbbreviations = map { substr($_,0,3) } @MonthNames;
$MonthAbbreviations[6] = "Bmh";
$MonthAbbreviations[7] = "Bmd";

@AMPM = qw(AM PM);
}


1;
__END__
