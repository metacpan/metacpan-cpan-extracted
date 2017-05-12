package Alvis::HTML;

use warnings;
use strict;

use Alvis::Document::Encoding;

$Alvis::HTML::VERSION = '0.31';

#############################################################################
#
#     Kimmo Valtonen, based on earlier work assisted by Ville Tuulos and
#     Antti Tuominen
#
#############################################################################

#############################################################################
#
#     Global variables & constants
#
##############################################################################

# Do we assert that our assumptions about the source hold? 
my $DEF_SRC_ASS=1;
# Do we check first to see if the document really looks like HTML?
my $DEF_ASSERT_HTML=1;
# Do we pass on even non-HTML documents?
my $DEF_KEEP_ALL=0;
# Do we replace character entities with actual characters?
my $DEF_CONVERT_CHAR_ENTS=1;
# Do we replace numerical character entities with actual characters?
my $DEF_CONVERT_NUM_ENTS=0;
# Do we try to clean extra whitespace?
my $DEF_CLEAN_WS=0;
# Source encoding
my $DEF_SRC_ENCODING='utf-8';

my $DEBUG=0;

###########################################################################
#
#     Symbolic character entity to Unicode (decimal) mapping
#
###########################################################################

my %Ent2Unicode=(
 quot =>'34',    #   "    HTML 2.0    quotation mark
 amp =>'38',    #   &    HTML 2.0    ampersand
 lt =>'60',    #   <    HTML 2.0    less-than sign
 gt =>'62',    #   >    HTML 2.0    greater-than sign
 nbsp =>'160',    #        HTML 3.2    no-break space
 iexcl =>'161',    #   ¡    HTML 3.2    inverted exclamation mark
 cent =>'162',    #   ¢    HTML 3.2    cent sign
 pound =>'163',    #   £    HTML 3.2    pound sign
 curren =>'164',    #   ¤    HTML 3.2    currency sign
 yen =>'165',    #   ¥    HTML 3.2    yen sign
 brvbar =>'166',    #   ¦    HTML 3.2    broken bar
 sect =>'167',    #   §    HTML 3.2    section sign
 uml =>'168',    #   ¨    HTML 3.2    diaeresis
 copy =>'169',    #   ©    HTML 3.2    copyright sign
 ordf =>'170',    #   ª    HTML 3.2    feminine ordinal indicator
 laquo =>'171',    #   «    HTML 3.2    left-pointing double angle quotation mark
 not =>'172',    #   ¬    HTML 3.2    not sign
 shy =>'173',    #   ­    HTML 3.2    soft hyphen
 reg =>'174',    #   ®    HTML 3.2    registered sign
 macr =>'175',    #   ¯    HTML 3.2    macron
 deg =>'176',    #   °    HTML 3.2    degree sign
 plusmn =>'177',    #   ±    HTML 3.2    plus-minus sign
 sup2 =>'178',    #   ²    HTML 3.2    superscript two
 sup3 =>'179',    #   ³    HTML 3.2    superscript three
 acute =>'180',    #   ´    HTML 3.2    acute accent
 micro =>'181',    #   µ    HTML 3.2    micro sign
 para =>'182',    #   ¶    HTML 3.2    pilcrow sign
 middot =>'183',    #   ·    HTML 3.2    middle dot
 cedil =>'184',    #   ¸    HTML 3.2    cedilla
 sup1 =>'185',    #   ¹    HTML 3.2    superscript one
 ordm =>'186',    #   º    HTML 3.2    masculine ordinal indicator
 raquo =>'187',    #   »    HTML 3.2    right-pointing double angle quotation mark
 frac14 =>'188',    #   ¼    HTML 3.2    vulgar fraction one quarter
 frac12 =>'189',    #   ½    HTML 3.2    vulgar fraction one half
 frac34 =>'190',    #   ¾    HTML 3.2    vulgar fraction three quarters
 iquest =>'191',    #   ¿    HTML 3.2    inverted question mark
 Agrave =>'192',    #   À    HTML 2.0    latin capital letter a with grave
 Aacute =>'193',    #   Á    HTML 2.0    latin capital letter a with acute
 Acirc =>'194',    #   Â    HTML 2.0    latin capital letter a with circumflex
 Atilde =>'195',    #   Ã    HTML 2.0    latin capital letter a with tilde
 Auml =>'196',    #   Ä    HTML 2.0    latin capital letter a with diaeresis
 Aring =>'197',    #   Å    HTML 2.0    latin capital letter a with ring above
 AElig =>'198',    #   Æ    HTML 2.0    latin capital letter ae
 Ccedil =>'199',    #   Ç    HTML 2.0    latin capital letter c with cedilla
 Egrave =>'200',    #   È    HTML 2.0    latin capital letter e with grave
 Eacute =>'201',    #   É    HTML 2.0    latin capital letter e with acute
 Ecirc =>'202',    #   Ê    HTML 2.0    latin capital letter e with circumflex
 Euml =>'203',    #   Ë    HTML 2.0    latin capital letter e with diaeresis
 Igrave =>'204',    #   Ì    HTML 2.0    latin capital letter i with grave
 Iacute =>'205',    #   Í    HTML 2.0    latin capital letter i with acute
 Icirc =>'206',    #   Î    HTML 2.0    latin capital letter i with circumflex
 Iuml =>'207',    #   Ï    HTML 2.0    latin capital letter i with diaeresis
 ETH =>'208',    #   Ð    HTML 2.0    latin capital letter eth
 Ntilde =>'209',    #   Ñ    HTML 2.0    latin capital letter n with tilde
 Ograve =>'210',    #   Ò    HTML 2.0    latin capital letter o with grave
 Oacute =>'211',    #   Ó    HTML 2.0    latin capital letter o with acute
 Ocirc =>'212',    #   Ô    HTML 2.0    latin capital letter o with circumflex
 Otilde =>'213',    #   Õ    HTML 2.0    latin capital letter o with tilde
 Ouml =>'214',    #   Ö    HTML 2.0    latin capital letter o with diaeresis
 times =>'215',    #   ×    HTML 3.2    multiplication sign
 Oslash =>'216',    #   Ø    HTML 2.0    latin capital letter o with stroke
 Ugrave =>'217',    #   Ù    HTML 2.0    latin capital letter u with grave
 Uacute =>'218',    #   Ú    HTML 2.0    latin capital letter u with acute
 Ucirc =>'219',    #   Û    HTML 2.0    latin capital letter u with circumflex
 Uuml =>'220',    #   Ü    HTML 2.0    latin capital letter u with diaeresis
 Yacute =>'221',    #   Ý    HTML 2.0    latin capital letter y with acute
 THORN =>'222',    #   Þ    HTML 2.0    latin capital letter thorn
 szlig =>'223',    #   ß    HTML 2.0    latin small letter sharp s
 agrave =>'224',    #   à    HTML 2.0    latin small letter a with grave
 aacute =>'225',    #   á    HTML 2.0    latin small letter a with acute
 acirc =>'226',    #   â    HTML 2.0    latin small letter a with circumflex
 atilde =>'227',    #   ã    HTML 2.0    latin small letter a with tilde
 auml =>'228',    #   ä    HTML 2.0    latin small letter a with diaeresis
 aring =>'229',    #   å    HTML 2.0    latin small letter a with ring above
 aelig =>'230',    #   æ    HTML 2.0    latin small letter ae
 ccedil =>'231',    #   ç    HTML 2.0    latin small letter c with cedilla
 egrave =>'232',    #   è    HTML 2.0    latin small letter e with grave
 eacute =>'233',    #   é    HTML 2.0    latin small letter e with acute
 ecirc =>'234',    #   ê    HTML 2.0    latin small letter e with circumflex
 euml =>'235',    #   ë    HTML 2.0    latin small letter e with diaeresis
 igrave =>'236',    #   ì    HTML 2.0    latin small letter i with grave
 iacute =>'237',    #   í    HTML 2.0    latin small letter i with acute
 icirc =>'238',    #   î    HTML 2.0    latin small letter i with circumflex
 iuml =>'239',    #   ï    HTML 2.0    latin small letter i with diaeresis
 eth =>'240',    #   ð    HTML 2.0    latin small letter eth
 ntilde =>'241',    #   ñ    HTML 2.0    latin small letter n with tilde
 ograve =>'242',    #   ò    HTML 2.0    latin small letter o with grave
 oacute =>'243',    #   ó    HTML 2.0    latin small letter o with acute
 ocirc =>'244',    #   ô    HTML 2.0    latin small letter o with circumflex
 otilde =>'245',    #   õ    HTML 2.0    latin small letter o with tilde
 ouml =>'246',    #   ö    HTML 2.0    latin small letter o with diaeresis
 divide =>'247',    #   ÷    HTML 3.2    division sign
 oslash =>'248',    #   ø    HTML 2.0    latin small letter o with stroke
 ugrave =>'249',    #   ù    HTML 2.0    latin small letter u with grave
 uacute =>'250',    #   ú    HTML 2.0    latin small letter u with acute
 ucirc =>'251',    #   û    HTML 2.0    latin small letter u with circumflex
 uuml =>'252',    #   ü    HTML 2.0    latin small letter u with diaeresis
 yacute =>'253',    #   ý    HTML 2.0    latin small letter y with acute
 thorn =>'254',    #   þ    HTML 2.0    latin small letter thorn
 yuml =>'255',    #   ÿ    HTML 2.0    latin small letter y with diaeresis
 OElig =>'338',    #      HTML 4.0    latin capital ligature oe
 oelig =>'339',    #      HTML 4.0    latin small ligature oe
 Scaron =>'352',    #      HTML 4.0    latin capital letter s with caron
 scaron =>'353',    #      HTML 4.0    latin small letter s with caron
 Yuml =>'376',    #      HTML 4.0    latin capital letter y with diaeresis
 fnof =>'402',    #      HTML 4.0    latin small letter f with hook
 circ =>'710',    #      HTML 4.0    modifier letter circumflex accent
 tilde =>'732',    #      HTML 4.0    small tilde
 Alpha =>'913',    #      HTML 4.0    greek capital letter alpha
 Beta =>'914',    #      HTML 4.0    greek capital letter beta
 Gamma =>'915',    #      HTML 4.0    greek capital letter gamma
 Delta =>'916',    #      HTML 4.0    greek capital letter delta
 Epsilon =>'917',    #      HTML 4.0    greek capital letter epsilon
 Zeta =>'918',    #      HTML 4.0    greek capital letter zeta
 Eta =>'919',    #      HTML 4.0    greek capital letter eta
 Theta =>'920',    #      HTML 4.0    greek capital letter theta
 Iota =>'921',    #      HTML 4.0    greek capital letter iota
 Kappa =>'922',    #      HTML 4.0    greek capital letter kappa
 Lambda =>'923',    #      HTML 4.0    greek capital letter lamda
 Mu =>'924',    #      HTML 4.0    greek capital letter mu
 Nu =>'925',    #      HTML 4.0    greek capital letter nu
 Xi =>'926',    #      HTML 4.0    greek capital letter xi
 Omicron =>'927',    #      HTML 4.0    greek capital letter omicron
 Pi =>'928',    #      HTML 4.0    greek capital letter pi
 Rho =>'929',    #      HTML 4.0    greek capital letter rho
 Sigma =>'931',    #      HTML 4.0    greek capital letter sigma
 Tau =>'932',    #      HTML 4.0    greek capital letter tau
 Upsilon =>'933',    #      HTML 4.0    greek capital letter upsilon
 Phi =>'934',    #      HTML 4.0    greek capital letter phi
 Chi =>'935',    #      HTML 4.0    greek capital letter chi
 Psi =>'936',    #      HTML 4.0    greek capital letter psi
 Omega =>'937',    #      HTML 4.0    greek capital letter omega
 alpha =>'945',    #      HTML 4.0    greek small letter alpha
 beta =>'946',    #      HTML 4.0    greek small letter beta
 gamma =>'947',    #      HTML 4.0    greek small letter gamma
 delta =>'948',    #      HTML 4.0    greek small letter delta
 epsilon =>'949',    #      HTML 4.0    greek small letter epsilon
 zeta =>'950',    #      HTML 4.0    greek small letter zeta
 eta =>'951',    #      HTML 4.0    greek small letter eta
 theta =>'952',    #      HTML 4.0    greek small letter theta
 iota =>'953',    #      HTML 4.0    greek small letter iota
 kappa =>'954',    #      HTML 4.0    greek small letter kappa
 lambda =>'955',    #      HTML 4.0    greek small letter lamda
 mu =>'956',    #      HTML 4.0    greek small letter mu
 nu =>'957',    #      HTML 4.0    greek small letter nu
 xi =>'958',    #      HTML 4.0    greek small letter xi
 omicron =>'959',    #      HTML 4.0    greek small letter omicron
 pi =>'960',    #      HTML 4.0    greek small letter pi
 rho =>'961',    #      HTML 4.0    greek small letter rho
 sigmaf =>'962',    #      HTML 4.0    greek small letter final sigma
 sigma =>'963',    #      HTML 4.0    greek small letter sigma
 tau =>'964',    #      HTML 4.0    greek small letter tau
 upsilon =>'965',    #      HTML 4.0    greek small letter upsilon
 phi =>'966',    #      HTML 4.0    greek small letter phi
 chi =>'967',    #      HTML 4.0    greek small letter chi
 psi =>'968',    #      HTML 4.0    greek small letter psi
 omega =>'969',    #      HTML 4.0    greek small letter omega
 thetasym =>'977',    #      HTML 4.0    greek theta symbol
 upsih =>'978',    #      HTML 4.0    greek upsilon with hook symbol
 piv =>'982',    #      HTML 4.0    greek pi symbol
 ensp =>'8194',    #      HTML 4.0    en space [1]
 emsp =>'8195',    #      HTML 4.0    em space [2]
 thinsp =>'8201',    #      HTML 4.0    thin space [3]
 zwnj =>'8204',    #      HTML 4.0    zero width non-joiner
 zwj =>'8205',    #      HTML 4.0    zero width joiner
 lrm =>'8206',    #      HTML 4.0    left-to-right mark
 rlm =>'8207',    #      HTML 4.0    right-to-left mark
 ndash =>'8211',    #      HTML 4.0    en dash
 mdash =>'8212',    #      HTML 4.0    em dash
 lsquo =>'8216',    #      HTML 4.0    left single quotation mark
 rsquo =>'8217',    #      HTML 4.0    right single quotation mark
 sbquo =>'8218',    #      HTML 4.0    single low-9 quotation mark
 ldquo =>'8220',    #      HTML 4.0    left double quotation mark
 rdquo =>'8221',    #      HTML 4.0    right double quotation mark
 bdquo =>'8222',    #      HTML 4.0    double low-9 quotation mark
 dagger =>'8224',    #      HTML 4.0    dagger
 Dagger =>'8225',    #      HTML 4.0    double dagger
 bull =>'8226',    #      HTML 4.0    bullet
 hellip =>'8230',    #      HTML 4.0    horizontal ellipsis
 permil =>'8240',    #      HTML 4.0    per mille sign
 prime =>'8242',    #      HTML 4.0    prime
 Prime =>'8243',    #      HTML 4.0    double prime
 lsaquo =>'8249',    #      HTML 4.0    single left-pointing angle quotation mark
 rsaquo =>'8250',    #      HTML 4.0    single right-pointing angle quotation mark
 oline =>'8254',    #      HTML 4.0    overline
 frasl =>'8260',    #      HTML 4.0    fraction slash
 euro =>'8364',    #      HTML 4.0    euro sign
 image =>'8465',    #      HTML 4.0    black-letter capital i
 weierp =>'8472',    #      HTML 4.0    script capital p
 real =>'8476',    #      HTML 4.0    black-letter capital r
 trade =>'8482',    #      HTML 4.0    trade mark sign
 alefsym =>'8501',    #      HTML 4.0    alef symbol
 larr =>'8592',    #      HTML 4.0    leftwards arrow
 uarr =>'8593',    #      HTML 4.0    upwards arrow
 rarr =>'8594',    #      HTML 4.0    rightwards arrow
 darr =>'8595',    #      HTML 4.0    downwards arrow
 harr =>'8596',    #      HTML 4.0    left right arrow
 crarr =>'8629',    #      HTML 4.0    downwards arrow with corner leftwards
 lArr =>'8656',    #      HTML 4.0    leftwards double arrow
 uArr =>'8657',    #      HTML 4.0    upwards double arrow
 rArr =>'8658',    #      HTML 4.0    rightwards double arrow
 dArr =>'8659',    #      HTML 4.0    downwards double arrow
 hArr =>'8660',    #      HTML 4.0    left right double arrow
 forall =>'8704',    #      HTML 4.0    for all
 part =>'8706',    #      HTML 4.0    partial differential
 exist =>'8707',    #      HTML 4.0    there exists
 empty =>'8709',    #      HTML 4.0    empty set
 nabla =>'8711',    #      HTML 4.0    nabla
 isin =>'8712',    #      HTML 4.0    element of
 notin =>'8713',    #      HTML 4.0    not an element of
 ni =>'8715',    #      HTML 4.0    contains as member
 prod =>'8719',    #      HTML 4.0    n-ary product
 sum =>'8721',    #      HTML 4.0    n-ary summation
 minus =>'8722',    #      HTML 4.0    minus sign
 lowast =>'8727',    #      HTML 4.0    asterisk operator
 radic =>'8730',    #      HTML 4.0    square root
 prop =>'8733',    #      HTML 4.0    proportional to
 infin =>'8734',    #      HTML 4.0    infinity
 ang =>'8736',    #      HTML 4.0    angle
 and =>'8743',    #      HTML 4.0    logical and
 or =>'8744',    #      HTML 4.0    logical or
 cap =>'8745',    #      HTML 4.0    intersection
 cup =>'8746',    #      HTML 4.0    union
 int =>'8747',    #      HTML 4.0    integral
 there4 =>'8756',    #      HTML 4.0    therefore
 sim =>'8764',    #      HTML 4.0    tilde operator
 cong =>'8773',    #      HTML 4.0    congruent to
 asymp =>'8776',    #      HTML 4.0    almost equal to
 ne =>'8800',    #      HTML 4.0    not equal to
 equiv =>'8801',    #      HTML 4.0    identical to
 le =>'8804',    #      HTML 4.0    less-than or equal to
 ge =>'8805',    #      HTML 4.0    greater-than or equal to
 sub =>'8834',    #      HTML 4.0    subset of
 sup =>'8835',    #      HTML 4.0    superset of
 nsub =>'8836',    #      HTML 4.0    not a subset of
 sube =>'8838',    #      HTML 4.0    subset of or equal to
 supe =>'8839',    #      HTML 4.0    superset of or equal to
 oplus =>'8853',    #      HTML 4.0    circled plus
 otimes =>'8855',    #      HTML 4.0    circled times
 perp =>'8869',    #      HTML 4.0    up tack
 sdot =>'8901',    #      HTML 4.0    dot operator
 lceil =>'8968',    #      HTML 4.0    left ceiling
 rceil =>'8969',    #      HTML 4.0    right ceiling
 lfloor =>'8970',    #      HTML 4.0    left floor
 rfloor =>'8971',    #      HTML 4.0    right floor
 lang =>'9001',    #      HTML 4.0    left-pointing angle bracket
 rang =>'9002',    #      HTML 4.0    right-pointing angle bracket
 loz =>'9674',    #      HTML 4.0    lozenge
 spades =>'9824',    #      HTML 4.0    black spade suit
 clubs =>'9827',    #      HTML 4.0    black club suit
 hearts =>'9829',    #      HTML 4.0    black heart suit
 diams=>'9830',    #      HTML 4.0    black diamond suit
);




#############################################################################
#
#     Error message stuff
#
#############################################################################

my $ErrStr;
my ($ERR_OK,
    $ERR_EMPTY_DOC,
    $ERR_UNK_DOCTYPE,
    $ERR_NO_SIGNATURE,
    $ERR_ENC,
    $ERR_UTF8_CONV,
    $ERR_TARGET_CONV,
    $ERR_SRC_NOT_IN_UTF8,
    $ERR_GUESS_ENC_UTF8_CONV
    )=(0..8);
my %ErrMsgs=($ERR_OK=>"",
	     $ERR_EMPTY_DOC=>"No document (although only HTML expected)",
	     $ERR_UNK_DOCTYPE=>"Unrecognized DOCTYPE (only HTML/WML expected)",
	     $ERR_NO_SIGNATURE=>"No signature (only HTML expected)",
	     $ERR_ENC=>"Unable to instantiate Alvis::Document::Encoding.",
	     $ERR_UTF8_CONV=>"Converting from source encoding to UTF-8 failed.",
	     $ERR_TARGET_CONV=>"Converting to the output encoding failed.",
	     $ERR_SRC_NOT_IN_UTF8=>"The source is not in UTF-8.",
	     $ERR_GUESS_ENC_UTF8_CONV=>"Guessing the source encoding and " .
	     "then converting it to UTF-8 failed."
	     );

sub _set_err_state
{
    my $self=shift;
    my $errcode=shift;
    my $errmsg=shift;

    if (!defined($errcode))
    {
        confess("set_err_state() called with an undefined argument.");
    }

    if (exists($ErrMsgs{$errcode}))
    {
        if ($errcode==$ERR_OK)
        {
            $self->{errstr}="";
        }
        else
        {
            $self->{errstr}.=" " . $ErrMsgs{$errcode};
            if (defined($errmsg))
            {
                $self->{errstr}.=" " . $errmsg;
            }
        }
    }
    else
    {
        confess("Internal error: set_err_state() called with an " .
                "unrecognized argument ($errcode).")
    }
}

sub errmsg
{
    my $self=shift;

    return $self->{errstr};
}

sub clearerr
{
    my $self=shift;

    $self->{errstr}="";
}

sub new
{
    my $proto=shift;

    my $class=ref($proto)||$proto;
    my $parent=ref($proto)&&$proto;
    my $self={};
    bless($self,$class);

    $self->_init(@_);

    $self->{encodingWiz}=Alvis::Document::Encoding->new();
    if (!defined($self->{encodingWiz}))
    {
	$self->_set_err_state($ERR_ENC);
	return undef;
    }

    $self->_set_err_state($ERR_OK);

    return $self;
}

sub _init
{
    my $self=shift;

    $self->{assertHTML}=$DEF_ASSERT_HTML;
    $self->{keepAll}=$DEF_KEEP_ALL;
    $self->{assertSourceAssumptions}=$DEF_SRC_ASS;;
    $self->{convertCharEnts}=$DEF_CONVERT_CHAR_ENTS;
    $self->{convertNumEnts}=$DEF_CONVERT_NUM_ENTS;
    $self->{cleanWhitespace}=$DEF_CLEAN_WS;
    $self->{sourceEncoding}=$DEF_SRC_ENCODING;

    if (defined(@_))
    {
        my %args=@_;
        @$self{ keys %args }=values(%args);
    }
}

#############################################################################
#
#      Public methods
#
##############################################################################
 
#
# Returns (<contents as text>,<header hash ref>)
#
sub clean
{
    my $self=shift;
    my $html=shift;
    my $opts=shift;    # if a title/base URL is wished for as well
                       # returned in a header hash with keys
                       # title, baseURL

    my %header=(title=>undef,
		baseURL=>undef);

    $self->_set_err_state($ERR_OK);  # clean the slate

    # Make it utf-8 if not already
    my $src_enc;
    if ($opts->{sourceEncoding})
    {
	$src_enc=$opts->{sourceEncoding};
    }
    elsif (!exists($opts->{sourceEncoding}) && $self->{sourceEncoding})
    {
	$src_enc=$self->{sourceEncoding};
    }
    if ($src_enc)
    {
	if ($src_enc!~/^\s*utf-?8\s*$/)
	{
	    $html=$self->{encodingWiz}->convert($html,
						$src_enc,
						'utf8');
	    if (!defined($html))
	    {
		$self->_set_err_state($ERR_UTF8_CONV,
				      $self->{encodingWiz}->errmsg());
		return (undef,\%header);  # signals "do not pass on"
	    }
	}
    }
    else # try guessing the encoding
    {
	$html=$self->{encodingWiz}->guess_and_convert($html,
						      'text',
						      'html',
						      'utf8');
	if (!defined($html))
	{
	    $self->_set_err_state($ERR_GUESS_ENC_UTF8_CONV,
				  $self->{encodingWiz}->errmsg());
	    return (undef,\%header);  # signals "do not pass on"
	}
    }

    # ex nihilo nihil 
    #
    if (!defined($html) || $html=~/^\s*$/sgo)
    {
	if ($self->{keepAll})
	{
	    return ("\n",\%header);
	}
	else
	{
	    $self->_set_err_state($ERR_EMPTY_DOC);
	    return (undef,\%header);  # signals "do not pass on"
	}  
    }

    # Check if this really looks like "HTML" 
    #
    if ($self->{assertHTML})
    {
	#
	# If we're lucky...
	#
	if ($html=~/<!DOCTYPE\s+(\S+)/isgo)
	{
	    my $type=$1;
	    if ($type!~/(?:html|wml)/igo)
	    {
		if ($self->{keepAll})
		{
		    return ("\n",\%header);
		}
		else
		{
		    $self->_set_err_state($ERR_UNK_DOCTYPE,"($type)");
		    return (undef,\%header);  # signals "do not pass on"
		}
	    }
	}
	# Otherwise, use a weaker way of checking... a single 
	# signature start tag will do. 
	#
	if ($html!~/<(?:(?i)html|body)\W/sgo)
	{
	    if ($self->{keepAll})
	    {
		return ("\n",\%header);
	    }
	    else
	    {
		$self->_set_err_state($ERR_NO_SIGNATURE);
		return (undef,\%header);  # signals "do not pass on"
	    }
	} 
    }

    if ($self->{assertSourceAssumptions})
    {
	my %err;
	if (!$self->{encodingWiz}->is_utf8($html,\%err))
	{
	    $self->_set_err_state($ERR_SRC_NOT_IN_UTF8,
				  $self->{encodingWiz}->errmsg());
	    return (undef,\%header);  # signals "do not pass on"
	}
	# Remove '\0's just in case. Replace by a ' ' just in case they 
	# separated something meaningful in the original. 
	$html=~s/[\0]+/ /sgo;
    }

    # Remove comments
    #
    $html=~s/<\!\-\-.*?\-\->//sgo;

    # Remove some MS & declaration crap  Loses some (very little) maybe, 
    # but suffices for Alvis purposes.
    #
    $html=~s/<\!.*?>//sgo;

    # Extract the title if any, if desired
    #
    if (defined($opts->{title}))
    {
	my $title_cand;
	if ($html=~/<title\W(.*?)<\/title>/isgo)
	{
	    #
	    # Extract it
	    #
	    $title_cand=$1;
	    $title_cand=~s/=\s*([\"\'])(.*?)\1/&_neutralize_trouble($1,$2)/sgoe;
	    $title_cand=~s/^.*?>//sgo;
	     
	    #
	    # Clean it
	    #
	    my $c;
	    $title_cand=~s/(?:&\#(\d+);?)/$1<256 && $1>0 ? chr($1) : ""/ego;
	    $title_cand=~s/(?:&\#[xX]([0-9a-fA-F]+);?)/$c=hex($1); $c<256 && $c>0 ? chr($c) : ""/ego;
	    $title_cand=~s/(?:&(\w+);?)/$self->_char_ent2char($1)/ego;
	    
	    $title_cand=~s/\s+/ /sgo;
	    $title_cand=~s/^\s+//sgo;
	    $title_cand=~s/\s+$//sgo;
	    
	    $title_cand=~s/[^A-Za-zÆÁÂÀÅÃÄÇÐÉÊÈËÍÎÌÏÑÓÔÒØÕÖÞÚÛÙÜÝáâæàåãäçéêèðëíîìïñóôòøõößþúûùüýÿ¦¨´¸¼½¾ ,\.\-:\?]//isgo;
	}	    

	
	$header{title}=$title_cand;
    }

    # Extract the base URL if any, if desired
    #
    if (defined($opts->{baseURL}))
    {
	my $base_cand;
	if ($html=~/<base\W(.*?)>/isgo)
	{
	    #
	    # Extract the base URL
	    #
	    my $base_pars=$1;
	    $base_pars=~s/=\s*([\"\'])(.*?)\1/&_neutralize_trouble($1,$2)/sgoe;
	    
	    if ($base_pars=~/href\s*=\s*([\"\'])(.*?)\1/isgo)
	    {
		my $href=$2;
		$href=~s/\&/\&amp;/go;
		$base_cand=$href;
	    }
	}
	$header{baseURL}=$base_cand;
    }

    # Decapitation to avoid including the title at least
    # and to make the following faster.
    #
    $html=~s/<head\W.*?<\/head>//isgo;

    # Remove the entire elements STYLE, (NO)SCRIPT  
    #
    $html=~s/<style.*?<\/style>//isgo;
    $html=~s/<script.*?<\/script>//isgo;
    $html=~s/<noscript.*?<\/noscript>//isgo;

    # Tag removal. Optimized for speed.
    # Hangs on the assumption that the input cannot contain '\0's.
    # Algorithm:
    #           1. Mark & replace legal tag starts with '\0'.
    #           2. Go from the start of a tag to the beginning of
    #              the next one, neutralizing any confusing chars
    #              inside possible attribute values.
    #           3. Pick the leftmost '>' before the start of the next
    #              tag as the end of the tag.
    #           4. Remove all tags.               
    #
    if ($self->{alvisKeep})
    { 
	$html=~s/<\/?(?:(?i)a|frame|iframe|h[1-6]|p|div|dl|ul|ol|table|li|dd|dt|th|td|caption)(?=\W)/\0/sgo;
    }
    if ($self->{alvisRemove})
    {
	$html=~s/<\/?(?:(?i)tr|blockquote|hr|br|dir|menu|form|fieldset|legend|label|input|select|option|textarea|isindex|noframes|frameset|tfoot|body|tbody|html|head|abbr|acronym|address|applet|area|b|base|basefont|bdo|big|button|center|cite|code|col|colgroup|del|dfn|em|font|i|img|ins|kbd|link|map|ismap|meta|object|param|pre|q|s|samp|small|span|strike|strong|sub|sup|target|title|tt|u|var|\!doctype|\?xml)(?=\W)/\0/sgo;
    }
    if ($self->{obsolete})
    {
	$html=~s/<\/?(?:(?i)header|nextid|section|listing|xmp|plaintext)(?=\W)/\0/sgo;
    }
    if ($self->{proprietary})
    {
	$html=~s/<\/?(?:(?i)align|blink|embed|ilayer|keygen|layer|multicol|noembed|nolayer|nosave|spacer|inlineinput|sound|audioscope|blackface|animate|bgsound|comment|marquee|xml|o:p|csaction|csactions|csactiondict|csscriptdict|csactionitem|csobj|wbr|nobr|\/)(?=\W)/\0/sgo;
    }
    if ($self->{xhtml})
    {
	$html=~s/<\/?(?:(?i)ruby|rbc|rtc|rb|rt|rp)(?=\W)/\0/sgo;
    }
    if ($self->{wml})
    {
	$html=~s/<\/?(?:(?i)access|card|template|wml|anchor|do|onevent|postfield|go|noop|prev|refresh|fieldset|optgroup|select|setvar|timer)(?=\W)/\0/sgo;
    }

#    $html=~s/=\s*([\"\'])([^\0]*?)\1/&_neutralize_trouble($1,$2)/sgoe;
    $html=~s/(?<=\0).*?>//sgo;
    $html=~s/\0/ /go;
    
    # We have removed those tags we wanted to now
    
    # If we have some tags left, do some fixing 
    if (!$self->{alvisKeep}||!$self->{alvisRemove}||!$self->{obsolete}||
	!$self->{proprietary}||!$self->{xhtml}||!$self->{wml})
    {
	# Often we have <TAG ... </TAG>. Fix that.
	$html=~s/(<\/?(?:(?i)a|frame|iframe|h[1-6]|p|div|dl|ul|ol|table|li|dd|dt|th|td|caption|tr|blockquote|hr|br|dir|menu|form|fieldset|legend|label|input|select|option|textarea|isindex|noframes|frameset|tfoot|body|tbody|html|head|abbr|acronym|address|applet|area|b|base|basefont|bdo|big|button|center|cite|code|col|colgroup|del|dfn|em|font|i|img|ins|kbd|link|map|ismap|meta|object|param|pre|q|s|samp|small|span|strike|strong|sub|sup|target|title|tt|u|var|\!doctype|\?xml|header|nextid|section|listing|xmp|plaintext|align|blink|embed|ilayer|keygen|layer|multicol|noembed|nolayer|nosave|spacer|inlineinput|sound|audioscope|blackface|animate|bgsound|comment|marquee|xml|o:p|csaction|csactions|csactiondict|csscriptdict|csactionitem|csobj|wbr|nobr|\/|ruby|rbc|rtc|rb|rt|rp|access|card|template|wml|anchor|do|onevent|postfield|go|noop|prev|refresh|fieldset|optgroup|select|setvar|timer))(?=\W)/\0$1/sgo;
	$html=~s/(?<=\0)([^>]*?)(?=\0)/$1>/sgo;
	$html=~s/(?<=\0)([^\0>]*?)$/$1>/sgo;
	$html=~s/\0/ /go;
    }

    # Alvis needs some finer tuning
    if (!$self->{alvisKeep})
    { 
	# Fix attributes of interest
	$html=~s/(<a\W[^>]*?href\s*=\s*)([\"\'])(\S*?)(\s.*?)?>/$self->_fix_attr($1,$2,$3,$4)/isgoe;
	# Fix attributes of interest
	$html=~s/(<(?:frame|iframe|img)\W[^>]*?src\s*=\s*)([\"\'])(\S*?)(\s.*?)?>/$self->_fix_attr($1,$2,$3,$4)/isgoe;

	# Sometimes "HTML" contains Alvis tags...double safeguard them
	$html=~s/<(\/?(?:(?i)section|list|item|ulink).*?)>/\&lt;$1\&gt;/sgo;
    }
	
    if ($DEBUG)
    {
	warn $html;
    }

    # If wished for, convert character entities 
    if ($self->{convertCharEnts})
    {
	$html=~s/(?:&(\w+);)/$self->_char_ent2char($1)/ego;
    }

    # If wished for, convert numerical character entities 
    if ($self->{convertNumEnts})
    {
	#
	# Numerical entities depend on the presumed character set
        # of the source HTML. You had better be sure it is UTF-8 or
        # should we check here?
	#
	$html=~s/(?:&\#(\d+);?)/$self->_num_ent2char($1)/ego;
	$html=~s/(?:&\#[xX]([0-9a-fA-F]+);?)/$self->_hex_ent2char($1)/ego;
    }

    if ($self->{cleanWhitespace})
    {
	# Might look overcomplicated but is 3-4x faster than the
	# first, obvious versions and does not have artificial limits on the
	# number of consecutive non-\n ws compressed.
	$html=~s/\n/\0/go;
	$html=~s/\s+/ /go;
	$html=~s/[ ](?=\0)//go;
	$html=~s/(?<=\0)[ ]//go;
	$html=~s/^\0+//sgo;
	$html=~s/\0+$//sgo;
	$html=~s/\0{3,}/\n\n/go;
	$html=~s/\0/\n/go;
    }

    return ($html,\%header);
}

###########################################################################
#
# Private methods
#
###########################################################################

sub _num_ent2char
{
    my $self=shift;
    my $num=shift;

    # check for invalid codes 
    if (!$self->{encodingWiz}->code_is_utf8($num))
    {
	# must be an error, don't try to fix typos atm
	return "&#$num;";
    }

    my $str=pack("U",$num);

    return $str;
}

sub _hex_ent2char
{
    my $self=shift;
    my $num=shift;

    $num=hex($num);
    return $self->_num_ent2char($num);
}

sub _char_ent2char
{
    my $self=shift;
    my $name=shift;

    if (defined($Ent2Unicode{$name}))
    {
	return $Ent2Unicode{$name};
    }
    else
    {
	return "&${name};";
    }
}

#
# Fix a relevant broken attribute value so it ends with the same
# quote char it starts with
#
sub _fix_attr
{
    my $self=shift;
    my $prefix=shift;
    my $quote=shift;
    my $attr_value=shift;
    my $suffix=shift;
    
    my $txt=$prefix . $quote . $attr_value;
    if ($attr_value!~/$quote/sgo)
    {
	# Add the ending quote
	$txt.=$quote;
    }

    if (defined($suffix))
    {
	# the attr value breaks at a space, where the closing > should be
	$txt.=$suffix;
    }

    $txt.='>';

    return $txt;
}

#  Transform all chars with structural meaning to character entities
#  inside quotes.
sub _neutralize_trouble
{
    my $quote_char=shift;
    my $attr_value=shift;

    $attr_value=~s/</\&lt;/go;
    $attr_value=~s/>/\&gt;/go;
    $attr_value=~s/\"/\&quot;/go;
    $attr_value=~s/\'/\&apos;/go;
   
    return "= $quote_char$attr_value$quote_char";
}

1;
__END__

=head1 NAME

Alvis::HTML - Perl extension for converting documents in dirty HTML into
"clean" HTML suitable for Alvis purposes

=head1 SYNOPSIS

 use Alvis::HTML;

 # Create a new instance and specify that we want to remove uninteresting 
 # HTML tags, keep and fix tags of interest to Alvis::Convert and
 # convert both symbolic and numerical characters entities
 # to UTF-8 characters.
 #
 my $C=Alvis::HTML->new(alvisKeep=>0,
		        alvisRemove=>1,
		        obsolete=>1,
		        proprietary=>1,
		        xhtml=>1,
		        wml=>1,
		        keepAll=>1,
		        assertHTML=>0,
                        convertCharEnts=>1,
                        convertNumEnts=>1,
                        cleanWhitespace=>0
		        );

 my ($txt,$header)=$C->clean($html,
	 		     {title=>1,
			      baseURL=>1});
 if (!defined($txt))
 {
     die "Instantiating Alvis::HTML failed.";
 }

 #
 # Remove all HTML tags from the document. Assert that the document actually
 # is HTML. HTML is in 'iso-8859-1', (output is always in UTF-8).
 # Assert that the source assumptions (UTF-8, no '\0') hold before
 # trying to convert.
 #
 $C=Alvis::HTML->new(alvisKeep=>1,
                     alvisRemove=>1,
                     obsolete=>1,
                     proprietary=>1,
		     xhtml=>1,
	             wml=>1,
		     keepAll=>1,
		     assertHTML=>0,
		     convertCharEnts=>1,
		     convertNumEnts=>1,
                     sourceEncoding=>'iso-8859-1',
                     assertSourceAssumptions=>1
		    );


=head1 DESCRIPTION

Assumes the input is in UTF-8 and does NOT contain '\0's (or rather that 
they carry no meaning and are removable). 

=head1 METHODS

=head2 new()

Options available:
    assertHTML         if 1, try to check if the source really
                       is in any of the recognized dialects.
    keepAll            if 1, pass all documents on regardless of
                       their HTMLness. Non-HTML goes forward as '\n'.

 Options to specify HTML subsets whose tags to remove: (set to defined)

    alvisKeep          W3's HTML 4.01 tags Alvis::Convert
                       is interested in
    alvisRemove        4.01 tags Alvis::Convert is NOT interested in
    obsolete           HTML <4.01
    proprietary        Net-escape,Exploder,...
    xhtml              XHTML 1.1
    wml                WML

     Note: alvisKeep + alvisRemove == remove all HTML 4.01 tags

    convertCharEnts    convert symbolic character entities to UTF-8 characters.
    convertNumEnts     convert numerical character entities to UTF-8 
                       characters.  

    sourceEncoding     encoding of the source HTML text (default: 'utf-8')
                       If not 'utf-8', HTML is converted to UTF-8.
                       If undefined, the encoding is guessed first.

    assertSourceAssumptions
 
                       make sure that before any operations the source is
                       in UTF-8 and contains no null bytes.

=head2 clean(html,options)

Remove unwanted tags from $html (text). $options is
a mechanism for returning the title and base URL of the document and
setting call-specific parameters.

If their extraction is desired, set fields 'title' and 'baseURL'
to a defined value. e.g. 

  my ($txt,$header)=$C->clean($html,
                              {title=>1,
         		       baseURL=>1});

In $options you can also set the source and target encodings
(sourceEncoding,targetEncoding).

   my ($txt,$header)=$C->clean($html,
                              {title=>1,
         		       baseURL=>1,
                               sourceEncoding=>'iso-8859-1'});

This will guess the encoding first:

   my ($txt,$header)=$C->clean($html,
                              {title=>1,
         		       baseURL=>1,
                               sourceEncoding=>undef});

will convert from 'iso-8859-1' to default output encoding (UTF-8).

=head2 errmsg()

Returns a stack of error messages, if any. Empty string otherwise.

=head1 SEE ALSO

Alvis::Canonical

=head1 AUTHOR

Kimmo Valtonen, E<lt>kimmo.valtonen@hiit.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kimmo Valtonen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut


