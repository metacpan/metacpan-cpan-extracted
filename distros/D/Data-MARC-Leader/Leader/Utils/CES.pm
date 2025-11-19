package Data::MARC::Leader::Utils::CES;

use strict;
use warnings;

use Readonly;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Hash our %BIBLIOGRAPHIC_LEVEL => (
	'a' => decode_utf8('analytická část (monografická)'),
	'b' => decode_utf8('analytická část (seriálová)'),
	'c' => decode_utf8('sbírka'),
	'd' => decode_utf8('podjednotka'),
	'i' => decode_utf8('integrační zdroj m monografie'),
	'm' => decode_utf8('monografie'),
	's' => decode_utf8('seriál'),
);
Readonly::Hash our %CHAR_CODING_SCHEME => (
	' ' => 'MARC-8',
	'a' => 'UCS/Unicode',
);
Readonly::Hash our %DESCRIPTIVE_CATALOGING_FORM => (
	' ' => decode_utf8('jiná než ISBD'),
	'a' => 'AACR 2',
	'c' => decode_utf8('vynechána interpunkce ISBD'),
	'i' => decode_utf8('přítomna interpunkce ISBD'),
	'n' => decode_utf8('vynechána interpunkce jiná než ISBD'),
	'u' => decode_utf8('není znám'),
);
Readonly::Hash our %ENCODING_LEVEL => (
	' ' => decode_utf8('úplná úroveň'),
	'1' => decode_utf8('úplná úroveň, bez dokumentu v ruce'),
	'2' => decode_utf8('méně než úplná úroveň, bez dokumentu v ruce'),
	'3' => decode_utf8('zkrácený záznam'),
	'4' => decode_utf8('základní úroveň'),
	'5' => decode_utf8('částečně zpracovaný záznam'),
	'7' => decode_utf8('minimální úroveň'),
	'8' => decode_utf8('před vydáním dokumentu'),
	'u' => decode_utf8('není znám'),
	'z' => decode_utf8('nelze použít'),
);
Readonly::Hash our %IMPL_DEF_PORTION_LEN => (
	'0' => decode_utf8('délka implementačně definované části'),
);
Readonly::Hash our %INDICATOR_COUNT => (
	'2' => decode_utf8('délka indikátorů'),
);
Readonly::Hash our %LENGTH_OF_FIELD_PORTION_LEN => (
	'4' => decode_utf8('počet znaků délky pole'),
);
Readonly::Hash our %MULTIPART_RESOURCE_RECORD_LEVEL => (
	' ' => decode_utf8('není specifikována, nelze použít'),
	'a' => decode_utf8('soubor'),
	'b' => decode_utf8('část/svazek s nezávislým názvem'),
	'c' => decode_utf8('část/svazek se závislým názvem'),
);
Readonly::Hash our %STARTING_CHAR_POS_PORTION_LEN => (
	'5' => decode_utf8('délka počáteční znakové pozice'),
);
Readonly::Hash our %STATUS => (
	'a' => decode_utf8('doplněný záznam'),
	'c' => decode_utf8('opravený záznam'),
	'd' => decode_utf8('zrušený záznam'),
	'n' => decode_utf8('nový záznam'),
	'p' => decode_utf8('doplněný prozatímní záznam'),
);
Readonly::Hash our %SUBFIELD_CODE_COUNT => (
	'2' => decode_utf8('délka označení podpole'),
);
Readonly::Hash our %TYPE => (
	'a' => decode_utf8('textový dokument'),
	'c' => decode_utf8('hudebnina'),
	'd' => decode_utf8('rukopisná hudebnina'),
	'e' => decode_utf8('kartografický dokument'),
	'f' => decode_utf8('rukopisný kartografický dokument'),
	'g' => decode_utf8('projekční médium'),
	'i' => decode_utf8('nehudební zvukový záznam'),
	'j' => decode_utf8('hudební zvukový záznam'),
	'k' => decode_utf8('dvojrozměrná neprojekční grafika'),
	'm' => decode_utf8('počítačový soubor/elektronický zdroj'),
	'o' => decode_utf8('souprava, soubor (kit)'),
	'p' => decode_utf8('smíšený dokument'),
	'r' => decode_utf8('trojrozměrný předmět, přírodní objekt'),
	't' => decode_utf8('rukopisný textový dokument'),
	'z' => decode_utf8('záznam souboru autorit'),
);
Readonly::Hash our %TYPE_OF_CONTROL => (
	' ' => decode_utf8('není specifikován'),
	'a' => decode_utf8('archivní dokument'),
);
Readonly::Hash our %UNDEFINED => (
	'0' => decode_utf8('není definován'),
);

our $VERSION = 0.07;

1;

__END__
