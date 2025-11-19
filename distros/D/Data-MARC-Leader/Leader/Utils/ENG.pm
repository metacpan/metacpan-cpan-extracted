package Data::MARC::Leader::Utils::ENG;

use strict;
use warnings;

use Readonly;

Readonly::Hash our %BIBLIOGRAPHIC_LEVEL => (
	'a' => 'Monographic component part',
	'b' => 'Serial component part',
	'c' => 'Collection',
	'd' => 'Subunit',
	'i' => 'Integrating resource',
	'm' => 'Monograph/Item',
	's' => 'Serial',
);
Readonly::Hash our %CHAR_CODING_SCHEME => (
	' ' => 'MARC-8',
	'a' => 'UCS/Unicode',
);
Readonly::Hash our %DESCRIPTIVE_CATALOGING_FORM => (
	' ' => 'Non-ISBD',
	'a' => 'AACR 2',
	'c' => 'ISBD punctuation omitted',
	'i' => 'ISBD punctuation included',
	'n' => 'Non-ISBD punctuation omitted',
	'u' => 'Unknown',
);
Readonly::Hash our %ENCODING_LEVEL => (
	' ' => 'Full level',
	'1' => 'Full level, material not examined',
	'2' => 'Less-than-full level, material not examined',
	'3' => 'Abbreviated level',
	'4' => 'Core level',
	'5' => 'Partial (preliminary) level',
	'7' => 'Minimal level',
	'8' => 'Prepublication level',
	'u' => 'Unknown',
	'z' => 'Not applicable',
);
Readonly::Hash our %IMPL_DEF_PORTION_LEN => (
	'0' => 'Number of characters in the implementation-defined portion of a Directory entry',
);
Readonly::Hash our %INDICATOR_COUNT => (
	'2' => 'Number of character positions used for indicators',
);
Readonly::Hash our %LENGTH_OF_FIELD_PORTION_LEN => (
	'4' => 'Number of characters in the length-of-field portion of a Directory entry',
);
Readonly::Hash our %MULTIPART_RESOURCE_RECORD_LEVEL => (
	' ' => 'Not specified or not applicable',
	'a' => 'Set',
	'b' => 'Part with independent title',
	'c' => 'Part with dependent title',
);
Readonly::Hash our %STARTING_CHAR_POS_PORTION_LEN => (
	'5' => 'Number of characters in the starting-character-position portion of a Directory entry',
);
Readonly::Hash our %STATUS => (
	'a' => 'Increase in encoding level',
	'c' => 'Corrected or revised',
	'd' => 'Deleted',
	'n' => 'New',
	'p' => 'Increase in encoding level from prepublication',
);
Readonly::Hash our %SUBFIELD_CODE_COUNT => (
	'2' => 'Number of character positions used for a subfield code',
);
Readonly::Hash our %TYPE => (
	'a' => 'Language material',
	'c' => 'Notated music',
	'd' => 'Manuscript notated music',
	'e' => 'Cartographic material',
	'f' => 'Manuscript cartographic material',
	'g' => 'Projected medium',
	'i' => 'Nonmusical sound recording',
	'j' => 'Musical sound recording',
	'k' => 'Two-dimensional nonprojectable graphic',
	'm' => 'Computer file',
	'o' => 'Kit',
	'p' => 'Mixed materials',
	'r' => 'Three-dimensional artifact or naturally occurring object',
	't' => 'Manuscript language material',
);
Readonly::Hash our %TYPE_OF_CONTROL => (
	' ' => 'No specified type',
	'a' => 'Archival',
);
Readonly::Hash our %UNDEFINED => (
	'0' => 'Undefined',
);

our $VERSION = 0.07;

1;

__END__
