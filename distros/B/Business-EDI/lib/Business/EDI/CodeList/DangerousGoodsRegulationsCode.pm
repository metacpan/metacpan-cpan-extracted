package Business::EDI::CodeList::DangerousGoodsRegulationsCode;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {8273;}
my $usage       = 'B';

# 8273  Dangerous goods regulations code                        [B]
# Desc: Code specifying a dangerous goods regulation.
# Repr: an..3

my %code_hash = (
'ADR' => [ 'European agreement on the international carriage of',
    'dangerous goods on road (ADR) European agreement on the international carriage of dangerous goods on road. ADR is the abbreviation of "Accord europeen relatif au transport international des marchandises dangereuses par route".' ],
'ADS' => [ 'NDR European agreement for the transport of dangerous goods',
    'on the river Rhine European agreement giving regulations for the transport of dangerous goods on the river Rhine, officially known as: "Accord europeen relatif au transport international des marchandises dangereuses par navigation sur le Rhin.".' ],
'ADT' => [ "CA, Transport Canada's dangerous goods requirements",
    'Canadian transport of dangerous goods requirements as published by Transport Canada in the Canadian Gazette, Part II.' ],
'ADU' => [ 'JP, Japanese maritime safety agency dangerous goods',
    'regulation code Regulation regarding the handling of dangerous goods on vessels issued by Japanese maritime safety agency.' ],
'ADV' => [ 'MARPOL 73/78',
    'International Convention for the Prevention of Pollution from Ships, 1973, as modified by the Protocol of 1978 relating.' ],
'AGS' => [ 'DE, ADR and GGVS combined regulations for combined',
    'transport Combined German and European regulations for the transportation of dangerous goods on German and other European roads. ADR means: Accord Europeen relatif au Transport international des marchandises Dangereuses par Route. GGVS means: Gefahrgutverordnung Strasse.' ],
'ANR' => [ 'ADNR, Autorisation de transport de matieres Dangereuses',
    'pour la Navigation sur le Rhin Regulations for dangerous goods transportation on the Rhine.' ],
'ARD' => [ 'DE, ARD and RID - Combined regulations for combined',
    'transport Combined European regulations for the combined transportation of dangerous goods on roads and rails. ARD means: Autorisation de transport par Route de matieres dangereuses. RID means: Reglement International concernant le transport des marchandises Dangereuses par chemin de fer.' ],
'CFR' => [ 'US, 49 Code of federal regulations',
    'United States federal regulations issued by the US Department of transportation covering the domestic transportation of dangerous goods by truck, rail, water and air.' ],
'COM' => [ 'DE, ADR, RID, GGVS and GGVE - Combined regulations for',
    'combined transport Combined German and European regulations for the combined transportation of dangerous goods on German and other European roads and rails. ADR means: Accord Europeen relatif au transport international des marchandises Dangereuse par Route. RID means: Reglement International concernant le transport des marchandises Dangereuses par chemin de fer. GGVS means: Gefahrgutverordnung Strasse. GGVE means: Gefahrgutverordnung Eisenbahn.' ],
'GVE' => [ 'DE, GGVE (Gefahrgutverordnung Eisenbahn)',
    'German regulation for the transportation of dangerous goods on rail.' ],
'GVS' => [ 'DE, GGVS (Gefahrgutverordnung Strasse)',
    'German regulation for the transportation of dangerous goods on road.' ],
'ICA' => [ 'IATA ICAO',
    'Regulations covering the international transportation of dangerous goods issued by the International Air Transport Association and the International Civil Aviation Organization.' ],
'IMD' => [ 'IMO IMDG code',
    'Regulations regarding the transportation of dangerous goods on ocean-going vessels issued by the International Maritime Organization.' ],
'RGE' => [ 'DE, RID and GGVE, Combined regulations for combined',
    'transport on rails Combined German and European regulations for the transportation of dangerous goods on German and other European rails. RID means: Reglement International concernant le transport des marchandises Dangereuses par chemin de fer. GGVE means: Gefahrgutverordnung Eisenbahn.' ],
'RID' => [ 'Railroad dangerous goods book (RID)',
    'International regulations concerning the international carriage of dangerous goods by rail. RID is the abbreviation of "Reglement International concernant le transport des marchandises Dangereuses par chemin de fer".' ],
'UI' => [ 'UK IMO book',
    'The United Kingdom (UK) version of the International Maritime Organisation (IMO) book on dangerous goods.' ],
'ZZZ' => [ 'Mutually defined',
    'Additional and/or other information for the transportation of dangerous goods which are mutually defined.' ],
);
sub get_codes { return \%code_hash; }

1;
