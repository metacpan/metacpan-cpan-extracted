package Business::EDI::CodeList::ControllingAgencyCoded;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {return "0051";}
my $usage       = 'B';

# 0051  Controlling agency, coded
# Desc: Code identifying a controlling agency.
# Repr: an..3

my %code_hash = (
'AA' => [ 'EDICONSTRUCT',
    'French construction project.' ],
'AB' => [ 'DIN (Deutsches Institut fuer Normung)',
    'German standardization institute.' ],
'AC' => [ 'ICS (International Chamber of Shipping)',
    'The International Chamber of Shipping.' ],
'AD' => [ 'UPU (Union Postale Universelle)',
    'Universal Postal Union.' ],
'AE' => [ 'United Kingdom ANA (Article Numbering Association)',
    'Identifies the Article Numbering Association of the United Kingdom.' ],
'AF' => [ 'ANSI ASC X12 (American National Standard Institute',
     ],
'Accredited' => [ 'Standards Committee X12)',
    'Identifies the United States electronic data interchange standards body.' ],
'AG' => [ 'US DoD (United States Department of Defense)',
    'The United States Department of Defense is the entity controlling the message specification.' ],
'AH' => [ 'US Federal Government',
    'The United States Federal Government is the entity controlling the message specification.' ],
'AI' => [ 'EDIFICAS',
    'European EDI association for financial, informational, cost, accounting, auditing and social areas.' ],
'CC' => [ 'CCC (Customs Co-operation Council)',
    'The Customs Co-operation Council.' ],
'CE' => [ "CEFIC (Conseil Europeen des Federations de l'Industrie",
     ],
'EDI' => [ 'project for chemical industry.',
     ],
'EC' => [ 'EDICON',
    'UK Construction project.' ],
'ED' => [ 'EDIFICE (Electronic industries project)',
    'EDI Forum for companies with Interest in Computing and Electronics (EDI project for EDP/ADP sector).' ],
'EE' => [ 'EC + EFTA (European Communities and European Free Trade',
     ],
'The' => [ 'European Communities and the European Free Trade',
    'Association.' ],
'EN' => [ 'GS1',
    'Partner identification code assigned by GS1, an international organization of GS1 Member Organizations that manages the GS1 System.' ],
'ER' => [ 'UIC (International Union of railways)',
    'European railways.' ],
'EU' => [ 'European Union',
    'The European Union.' ],
'EW' => [ 'UN/EDIFACT Working Group (EWG)',
    'United Nations working group responsible for UN/EDIFACT (United Nations, Electronic Data Interchange for Administration, Commerce and Transport).' ],
'EX' => [ 'IECC (International Express Carriers Conference)',
    'The International Express Carriers Conference.' ],
'IA' => [ 'IATA (International Air Transport Association)',
    'The International Air Transport Association.' ],
'KE' => [ 'KEC (Korea EDIFACT Committee)',
    'The Korea EDIFACT Committee.' ],
'LI' => [ 'LIMNET',
    'UK Insurance project.' ],
'OD' => [ 'ODETTE (Organization for Data Exchange through Tele-',
     ],
'Transmission' => [ 'in Europe)',
    'European automotive industry project.' ],
'RI' => [ 'RINET (Reinsurance and Insurance Network)',
    'The Reinsurance and Insurance Network.' ],
'RT' => [ "UN/ECE/TRADE/WP.4/GE.1/EDIFACT Rapporteurs' Teams",
    "United Nations Economic UN Economic Commission for Europe (UN/ECE), Committee on the development of trade (TRADE), Working Party on facilitation of international trade procedures (WP.4), Group of Experts on data elements and automatic data interchange (GE.1), EDIFACT Rapporteurs' Teams." ],
'UN' => [ 'UN/CEFACT',
    'United Nations Centre for Trade Facilitation and Electronic Business (UN/CEFACT).' ],
);
sub get_codes { return \%code_hash; }

1;
