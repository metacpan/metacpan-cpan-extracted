##
## Coptic tables
##

package DateTime::Calendar::Coptic::Languages::Coptic;

BEGIN
{
use utf8;
use strict;
use warnings;

use DateTime::Languages;
use vars qw(@ISA @DayNames @DayAbbreviations @MonthNames @MonthAbbreviations @AMPM $VERSION);
@ISA = qw(DateTime::Languages);

$VERSION = "0.05";

@DayNames = qw(Πιογαι Πιϲναγ Πιϣομτ Πιφτοογ Πιτιογ Πιϲοογ Πιϣαϣϥ);
@MonthNames = ( "ϴωογτ",
                "Παοπι",
                "Αθορ",
                "Χοιακ",
                "Τωβι",
                "Μεϣιρ",
                "Παρεμϩατ",
                "Φαρμοθι",
                "Παϣανϲ",
                "Παωνι",
                "Επηπ",
                "Μεϲωρη",
                "Πικογϫι μαβοτ"
              );

@DayAbbreviations = map { substr($_,0,3) } @DayNames;
@MonthAbbreviations = map { substr($_,0,3) } @MonthNames;

@AMPM = qw(AM PM);
}

1;
__END__
