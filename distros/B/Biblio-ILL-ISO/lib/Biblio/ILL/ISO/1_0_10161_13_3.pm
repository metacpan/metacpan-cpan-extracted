package Biblio::ILL::ISO::1_0_10161_13_3;

our $VERSION = '0.01';
#---------------------------------------------------------------------------
# Mods
# 0.01 - 2003.07.15 - original version
#---------------------------------------------------------------------------

our $desc = <<'_END_OF_ASN_';

--ILL-APDU-Delivery-Info DEFINITIONS  ::= 
-- the object identifier for this extension, registered with
-- the Interlibrary Loan Application Standards Maintenance
-- Agency, is 1.0.10161.13.3

--BEGIN

--IMPORTS System-Address, System-Id from ISO-10161-ILL-1;

APDU-Delivery-Info ::= SEQUENCE {
	sender-info           [0] IMPLICIT SEQUENCE OF APDU-Delivery-Parameters,
        recipient-info        [1] IMPLICIT SEQUENCE OF APDU-Delivery-Parameters,
        transponder-info      [2] IMPLICIT SEQUENCE OF APDU-Delivery-Parameters OPTIONAL
        }

APDU-Delivery-Parameters ::= SEQUENCE {
        encoding        [0] IMPLICIT SEQUENCE OF APDU-Encoding,  -- SIZE (1..3) 
                            --provides, in preferred order, the types
                            --of encoding acceptable at the address
                            --indicated in transport
        transport       [1] IMPLICIT System-Address,
        aliases         [2] IMPLICIT SEQUENCE OF System-Id OPTIONAL
                            --provides in unsorted order, the several
                            --System-Ids associated with this
                            --System-Address
        }

APDU-Encoding ::= ENUMERATED {
        eDIFACT         (1),
        bER-IN-MIME     (2),
        bER             (3)
        }


-- DC Start of faked IMPORT

System-Address ::= SEQUENCE {
	telecom-service-identifier	[0]	ILL-String OPTIONAL,
	telecom-service-address		[1]	ILL-String OPTIONAL
	}

System-Id ::= SEQUENCE {
	--at least one of the following must be present
	person-or-institution-symbol	[0]	Person-Or-Institution-Symbol OPTIONAL,
	name-of-person-or-institution	[1]	Name-Of-Person-Or-Institution OPTIONAL
	}

ILL-String ::= CHOICE {
	generalstring	GeneralString,
	-- may contain any ISO registered G (graphic) and C
	-- (control) character set
	edifactstring	EDIFACTString
	}
	-- may not include leading or trailing spaces
	-- may not consist only of space (" ") or non-printing 
	-- characters

Name-Of-Person-Or-Institution ::= CHOICE {
	name-of-person	      [0]	ILL-String,
	name-of-institution   [1]	ILL-String
	}

Person-Or-Institution-Symbol ::= CHOICE {
	person-symbol	     [0]	ILL-String,
	institution-symbol   [1]	ILL-String
	}

EDIFACTString ::= VisibleString 
	-- (FROM ("A"|"B"|"C"|"D"|"E"|"F"|"G"|"H"|
	-- "I"|"J"|"K"|"L"|"M"|"N"|"O"|"P"|"Q"|"R"|"S"|"T"|"U"|
	-- "V"|"W"|"X"|"Y"|"Z"|"a"|"b"|"c"|"d"|"e"|"f"|"g"|"h"|
	-- "i"|"j"|"k"|"l"|"m"|"n"|"o"|"p"|"q"|"r"|"s"|"t"|"u"|
	-- "v"|"w"|"x"|"y"|"z"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|
	-- "9"|"0"|" "|"."|","|"-"|"("|")"|"/"|"="|"!"|"""|"%"|"&"|
	-- "*"|";"|"<"|">"|"'"|"+"|":"|"?"))

-- DC End of faked import

--END
_END_OF_ASN_

1;
