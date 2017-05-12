##
## Arabic tables
##

package DateTime::Calendar::Coptic::Language::Arabic;

BEGIN
{
use utf8;
use strict;

use DateTime::Language;
use vars qw(@ISA @DayNames @DayAbbreviations @MonthNames @MonthAbbreviations @AMPM);
@ISA = qw(DateTime::Language);

#
#  Day names in Arabic are under investigation, for the time being
#  I'd rather not guess transcriptions.
#
@DayNames = qw(Πιογαι Πιϲναγ Πιϣομτ Πιφτοογ Πιτιογ Πιϲοογ Πιϣαϣϥ);
@MonthNames = ( "تﻮﺗ",
                "ﻪﺑﺎﺑ",
                "رﻮﺗﺎﻫ",
                "ﻚﻬﻴﻛ",
                "طﻮﺒﻫ",
                "ﺮﻴﺸﻣأ",
                "تﺎﻬﻣﺮﺑ",
                "هدﻮﻣﺮﺑ",
                "ﺲﻨﺸﺑ",
                "ﻪﻧؤﻮﺑ",
                "ﺐﻴﺑأ",
                "ىﺮﺴﻣ",
                "ﺮﻴﻐﺼﻟا ﺮﻬﺸﻟا"
              );

@DayAbbreviations = map { substr($_,0,3) } @DayNames;
@MonthAbbreviations = map { substr($_,0,3) } @MonthNames;

@AMPM = qw(AM PM);
}


1;
__END__
