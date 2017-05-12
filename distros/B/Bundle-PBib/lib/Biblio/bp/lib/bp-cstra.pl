#
# bibliography package for Perl
#
# CSTRA format
#
# Dana Jacobsen (dana@acm.org)
# 17 January 1996 (last modified 17 January 1996)
#
# This format is the one used by the Computer Science Technical Reports
# Archive Sites list (<http://www.rdt.monash.edu.au/tr/siteslist.html>).
# The format definition can be found in:
#   <ftp://rdt.monash.edu.au/pub/techreports/reports/README>
#

package bp_cstra;

$version = "cstra (dj 17 jan 96)";

######

&bib'reg_format(
  'cstra',    # name
  'tra',      # short name
  'bp_cstra', # package name
  'none',     # default character set
  'suffix is cstr',
# our functions
  'options  is standard',
  'open     is standard',
  'close    is standard',
  'read     is standard',
  'write    is standard',
  'clear    is standard',
  'explode',
  'implode',
  'tocanon',
  'fromcanon',
);

######

# Ordering isn't too important except that TI must come first.
$opt_order = "TI AU RT LT OR AB AV GP DA DY MN YR PA PL PU LA KW";

# We ought to read directly from the file, but here is the ORGCODES file.

$orgcodes =<<"EoORGS";

ALBRT:University of Alberta:university-of-alberta
ARIAI:Austrian Research Institute for Artificial Intelligence:
BERN:University of Bern:university-of-bern
BLKNT:Bilkent University:bilkent-university
BRAUN:Technical University of Braunschweig, Germany:technical-university-of-braunschweig
BOSTN:Boston University:boston-university
BROWN:Brown University:brown-university
CALGY:University of Calgary:university-of-calgary
CAST:Centre for Advanced Study in Telecommunications (Ohio State Uni):
CHORUS:The Chorus Operating system:chorus
CITI:Centre for Information Technology Integration (Uni of Michigan):centre-for-information-technology-integration--university-of-michigan
CITY:City University:city-university
CLOUDS:The Clouds Project:clouds
CMU:Carnegie Mellon University:carnegie-mellon-university
COLUM:University of Columbia:university-of-columbia
CORN:Cornell University:cornell-university
CRG:CRG ?:crg
CTECH:California Institute of Technology:california-institute-of-technology
CWI:Centrum voor Wiskunde en Informatica:centrum-voor-wiskunde-en-informatica
DARTM:Dartmouth College:dartmouth-college
DUKE:Duke University:
DWARE:University of Delaware:university-of-delaware
EDRC:Engineering Design Research Centre:engineering-design-research-centre
FKI:Forschungsberichte Kuenstliche Intelligenz:forschungsberichte-kuenstliche-intelligenz
FNAL:Fermi National Accelerator Laboratory:fermi-national-accelerator-laboratory
FSU:Florida State University:florida-state-university
GINS:Matt Ginsford:matt-ginsford--stanford-university
GLASG:Glasgow University:glasgow-university
HUT:Helsinki University of Technology:helsinki-university-of-technology
UNIGE:University of Geneva:university-of-geneva
GTECH:Georgia Institute of Technology:georgia-institute-of-technology
IAST:Iowa State University:iowa-state-university
IBMAR:International Business Machines, Almaden Research Centre:international-business-machines-almaden-research-centre
ICSI:International Computer Science Institute:international-computer-science-institute
IMAG:Institut de Mathematiques Appliques de Grenoble (the Grenoble's Institute of Applied Mathematics (France)):institut-de-mathematiques-appliques-de-grenoble
INDIU:Indiana University:indiana-university
INDAI:Indiana University, Artificial Intelligence:indiana-university-artificial-intelligence
INRIA:Institut National de Recherche en Informatique et Automatique (National Institute for Research in Computer and Control Sciences):national-institute-for-research-in-computer-and-control-sciences
INTERV:Interviews:interviews-stanford
IPC:Institute for Parallel Computation:institute-for-parallel-computation
ISRI:Information Science Research Institute:information-science-research-institute
KFA:KFA Research Centre, Juelich:kfa-research-centre-juelich
KRR:Knowledge Representation and Reasoning (University of Toronto):knowledge-representation-and-reasoning
KSU:Kent State University:kent-state-university
LARC:NASA - Langley Research Centre:nasa-langley-ames-research-centre
LMU:Ludwig-Maximilians-Universitaet Muenchen:university-of-munich
MCNC:Microelectronic Centre of North Carolina:microelectronic-centre-of-north-carolina
MIT:Massachusetts Institute of Technology:massachusetts-institute-of-technology
MPI:Max Planck Insitute:max-planck-institute
MRG:Mechanized Reasoning Group:
NADA:The Royal Institute of Tecnology, Numerical Analysis and Computing Science:
NEURO:Neuroprose:neuro-prose
NYU:New York University:new-york-university
OGI:Oregon Graduate Institute:oregon-graduate-institute
PRINC:Princeton University:princeton-university
PRL:Digital Equipment Corporation Paris Research Labs:dec-paris-research-labs
PUC:Puc Rio, Brazil:puc-rio--brazil
PURDU:Purdue University:purdue-university
QUT:Queensland Institute of Technology:
RDT:Monash University, Department of Robotics and Digital Technology:monash-university
REYNLD:John Reynold's collection:john-reynolds
ROCH:University of Rochester:university-of-rochester
RTGRS:Rutgers University:rutgers-university
RWTH:Technical University of Aachen (RWTH Aachen):university-of-technology-aachen
SEI:Software Engineering Institute (Carnegie Mellon University):software-engineering-institute--carnegie-mellon-university
SERC:Software Engineering Research Centre:software-engineering-research-centre
SFU:Simon Fraser University:simon-fraser-university
SMU:Southern Methodist University:southern-methodist-university
SRC:Digital Equipment Corporation, Systems Research Centre:dec-systems-research-centre
STANF:Stanford University:stanford-university
STRTH:University of Strathclyde:university-of-strathclyde
SUNY:Sate University of New York, Stony Brook:state-university-new-york--stony-brook
TANDM:Tandem Computers Incorporated:tandem-computers-incorporated
TCD:Trinity College, Dublin:trinity-college
TMC:Thinking Machines Corporation:thinking-machines-corporation
TMPRE:University of Tampere:university-of-tampere
TRANS:Transis:transis
TUDELFT:Delft University of Technology, Department of Technical Mathematics and Informatics:delft-university-of-technology
TUE:Eindhoven University of Technology:
UADEL:University of Adelaide:university-of-adelaide
UARIZ:University of Arizona:university-of-arizona
UCB:University of California, Berkekley:university-of-california-berkeley
UCLA:University of California, Los Angeles:university-of-california-los-angeles
UCSC:University of California, Santa Cruz:university-of-california-santa-cruz
UFL:University of Florida:university-of-florida
UGA:University of Georgia:university-of-georgia
UIUC:University of Illinois, Urbana Champagne:university-of-illinois-urbana-champagne
UKC:University of Kent, Canterbury:university-of-kent
UKTKY:University of Kentucky:university-of-kentucky
UMASS:University of Massachusetts:university-of-massachusetts
UMCS:University of Manchester, Computer Science Department:university-of-manchester
UMD:University of Maryland, College Park:university-of-maryland
UNC:University of North Carolina:university-of-north-carolina
UNISA:University of South Australia:university-of-south-australia
UTA:University of Texas, Austin:university-of-texas--austin
UTEP:University of Texas, El Paso:
UTOR:University of Toronto:university-of-toronto
UTSA:University of Texas, San Antonio:
UULM:University of Ulm:university-of-ulm
UWASH:University of Washington:university-of-washington
VIRGI:University of Virginia:university-of-virginia
WASHU:Washington University:washington-university
WATER:University of Waterloo Computer Science Department:university-of-waterloo
WISCN:University of Wisconsin:university-of-wisconsin
WRL:Digital Equipment Corporation, Western Research Labs:dec-western-research-labs
WSU:Washington State University:washington-state-university
YALE:Yale University:yale-university
EoORGS

# We make the map on demand, since it's unlikely we'll need more than one.
# This also should use less memory.
%orgmap = ();

sub maporg {
  local($org) = @_;
  local($fullname, $codename);

  ($fullname, $codename) = ($orgcodes =~ /\n$org:([^:]*):([^\n]*)\n/);
  if (!defined $fullname) {
    &bib'gotwarn("Unknown organization code: $org");
    $fullname = $org;
  }
  $orgmap{$org} = $fullname;
}

######

# This is modelled on the refer explode method.

sub explode {
  local($rec) = @_;
  local(%entry);
  local($field, $value);
  local(@lines);

  substr($rec, 0, 0) = "\n";
  @lines = split(/\n\%/, $rec);
  shift @lines;
  foreach (@lines) {
    $field = substr($_, 0, 2);
    if (length($_) < 4) {
      &bib'gotwarn("CSTRA explode got empty field \%$field");
      next;
    }
    $value = substr($_, 3);
    $value =~ s/\n+/ /g;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    if (defined $entry{$field}) {
      $entry{$field} .= $bib'cs_sep . $value;
    } else {
      $entry{$field} = $value;
    }
  }
  %entry;
}

######


sub implode {
  local(%entry) = @_;

  $ent = '';

  local(@keys) = sort { index($opt_order,$a) <=> index($opt_order,$b) }
                 keys(%entry);
  local($unknown_ent) = '';
  # unknown fields are at the top
  foreach $field (@keys) {
    last if index($opt_order,$field) >= $[;
    &bib'gotwarn("CSTRA implode: unknown field identifier: $field");
    $unknown_ent .= "\%$field $entry{$field}\n" if length($field) == 1;
    shift @keys;
  }
  foreach $field (@keys) {
    $entry{$field} =~ s/$bib'cs_sep/\n\%$field /go;
    $ent .= "\%$field $entry{$field}\n";
  }
  $ent .= $unknown_ent;

  $ent =~ s/$bib'cs_sep/ /go;
  $ent;
}

######

%tra_to_can_fields = (
 'TI',  'Title',
  # AU
 'RT',  'ReportType',
 'LT',  'ReportNumber',
  # OR
 'AB',  'Abstract',
  # AV
  # GP
  # DA
  # DY
 'MN',  'Month',
 'YR',  'Year',
 'PA',  'PagesWhole',
 'PL',  'PubAddress',
  # PU
 'LA',  'Language',
 'KW',  'KeyWords',
);

sub tocanon {
  local(%entry) = @_;
  local(%can);
  local($field);
  local($tag, $val);

  # AU
  if (defined $entry{'AU'}) {
    local(@cname) = ();
    foreach $field (split(/$bib'cs_sep/o, $entry{AU})) {
      push( @cname, &bp_util'name_to_canon($field, 0) );
    }
    $can{'Authors'} = join($bib'cs_sep, @cname);
    delete $entry{'AU'};
  }

  if (defined $entry{'AV'}) {
    local($sourceurl) = '';
    local($sourceoth) = '';
    foreach $field (split(/$bib'cs_sep/o, $entry{'AV'})) {
      ($tag, $val) = split(/\s+/, $field, 2);
      if ($tag =~ /^url$/i) {
        $sourceurl .= $bib'cs_sep . $val;
      } elsif ($tag =~ /^ftp$/i) {
        $sourceurl .= $bib'cs_sep . "ftp://" . $val;
      } else {
        $sourceoth .= $bib'cs_sep . "Available by $tag at $val.";
      }
    }
    if ($sourceurl =~ s/^$bib'cs_sep//o) {
      $can{'Source'} = $sourceurl;
    }
    if ($sourceoth =~ s/^$bib'cs_sep//o) {
      $can{'Note'} = $sourceoth;
    }
    delete $entry{'AV'};
  }

  # XXXXX GP?

  if (defined $entry{'DA'}) {
    if ( (!defined $entry{'YR'}) && (!defined $entry{'MN'}) && (!defined $entry{'DY'}) ) {
      ($can{'Month'}, $can{'Year'}) = &bp_util'parsedate($entry{'DA'});
      if ( (!defined $can{'Month'}) || ($can{'Month'} eq '') ) {
        delete $can{'Month'};
      }
      if ( (!defined $can{'Year'}) || ($can{'Year'} eq '') ) {
        delete $can{'Year'};
      }
    }
    delete $entry{'DA'};
  }

  if (defined $entry{'DY'}) {
    if (defined $entry{'MN'}) {
      $entry{'MN'} .= " " . $entry{'DY'};
    } else {
      &bib'gotwarn("CSTRA: day with no month?");
      $entry{'MN'} = $entry{'DY'};
    }
    delete $entry{'DY'};
  }

  &maporg($entry{'OR'}) if (defined $entry{'OR'}) && (!defined $orgmap{$entry{'OR'}});

  # Set the CiteType, and also put OR in the right place
  if ( (defined $entry{'RT'}) && ($entry{'RT'} =~ /thesis|diploma|dissertat/i) ) {
    $can{'CiteType'} = 'thesis';
    if (defined $entry{'OR'}) {
      $can{'School'} = $orgmap{$entry{'OR'}};
      delete $entry{'OR'};
    }
  } else {
    $can{'CiteType'} = 'report';
    if (defined $entry{'OR'}) {
      if ( $orgmap{$entry{'OR'}} =~ /university|college|institut/i ) {
        $can{'School'}       = $orgmap{$entry{'OR'}};
      } else {
        $can{'Organization'} = $orgmap{$entry{'OR'}};
      }
      delete $entry{'OR'};
    }
  }

  # XXXXX PU?
 
  foreach $field (keys %entry) {
    if (!defined $tra_to_can_fields{$field}) {
      &bib'gotwarn("Unknown field: $field");
    } elsif ($tra_to_can_fields{$field}) {
      $can{$tra_to_can_fields{$field}} = $entry{$field};
    }
  }

  $can{'OrigFormat'} = $version;
  %can;
}

######

sub fromcanon {
  local(%reccan) = @_;
  &bib'goterror("CSTRA fromcanon is not yet implemented");
}

#######################
# end of package
#######################

1;
