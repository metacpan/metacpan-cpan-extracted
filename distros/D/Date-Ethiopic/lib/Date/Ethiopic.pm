package Date::Ethiopic;
use base (Date::ICal);
use utf8;

BEGIN
{
	require 5.000;
	use strict;
	use warnings;

	use vars qw(
		$VERSION
		$EPOCH

		@Tabots
		@PagumeTabots
		@PagumeTabotsTranscribed

		@YearNames

		@KokebDayNames
		@KokebDayNamesTranscribed
		@KokebMonthNames
		@KokebMonthNamesTranscribed
		@KokebYearNames
		@KokebYearNamesTranscribed

		@EthiopicSeasonNames
		@EthiopicSeasonNamesTranscribed

		@VariableTsomes
		@VariableTsomesTranscribed
		%VariableTsomes
		%MiscellaneousTsomes
		%MiscellaneousTsomesTranscribed
		%MiscellaneousTsomes2
		%MiscellaneousTsomes2Transcribed
		%AnnualTsomes
		%AnnualTsomesTranscribed
		%LikaneTsomes
		%LikaneTsomesTranscribed
		%HawaryaTsomes
		%HawaryaTsomesTranscribed
		%StMaryTsomes
		%StMaryTsomesTranscribed
		%AksumTsomes
		%AksumTsomesTranscribed

		$true
		$false

		@GregorianDaysPerMonth

		$n
	);

	$VERSION = "0.15";

	$EPOCH = 2796;

	($false,$true) = (0,1);

	require Convert::Number::Ethiopic;
	$n = new Convert::Number::Ethiopic;

	@GregorianDaysPerMonth = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

	@Tabots =(
		[ "ልደታ",			"Lideta"                  ],
		[ "ታዴዎስና፡አባጉባ",			"Tadiosna Abaguba"        ],
		[ "በአታ",			"Beata"                   ],
		[ "ዮሐንስ፡ሐዋርያው፡ወልደነጎድጓድ",	"Yohannes : Hawariyaw : Weldenegodgwad" ],
		[ "አቦ (አቡነ ገብረ ቅዱስ)",		"Abo (Abune Gebre Kidus)" ],
		[ "ኢያሱስ",			"Yesus"                   ],
		[ "ሥላሴ",			"Selassie"                ],
		[ "አባ፡ኪሮስ",			"Aba Kiros"               ],
		[ "ጨርቆስ",			"Cherkos"                 ],
		[ "መስቀል፡ኢየሱስ",			"Meskel Yesus"            ],
		[ "ሐና፡ማርያም",			"Hanna Mariam"            ],
		[ "ሚካኤል",			"Michael"                 ],
		[ "እግዚሐርአብ",			"Egzihar Ab"              ],
		[ "አቡነ፡አረጋዊ",			"Abune Aregawi"           ],
		[ "ጨርቆስ",			"Cherkos"                 ],
		[ "ኪዳነ፡ምሕረት",			"Kidane Mihret"           ],
		[ "እስጢፋኖስ",			"Estifanos"               ],
		[ "ቶማስ",			"Tomas"                   ],
		[ "ገብርኤል",			"Gabriel"                 ],
		[ "ሕንፅተ፡ቤተ፡ለማርያም",		"Hinste Bete Lemariam"    ],
		[ "ማርያም",			"Mariam"                  ],
		[ "ኡራኤል",			"Urael"                   ],
		[ "ጊዮርጊስ",			"Giorgis"                 ],
		[ "ተክለ፡ሐይማኖት",			"Tekle Haimanot"          ],
		[ "መርቆሪዎስ",			"Merkoriwos"              ],
		[ "ዮሴፍ",			"Yosef"                   ],
		[ "መድኀኔ ዓለም",			"Medehani Alem"           ],
		[ "አማኑኤል",			"Amanuel"                 ],
		[ "ባለ፡እግዚአብሔር",			"Bale Egziabher"          ],
		[ "ዮሐንስ፡እና፡ማርቆስ",		"Yohannes Ina Markos"     ]
	);
	@PagumeTabots =(
		"አሮጊቷ፡ልደታ",
		"አሮጌ፡ታዴዎስና፡አባጉባ",           #  usual name
		"ሩፋኤል",
		"አሮጌ፡ዮሐንስ፡ሐዋርያው፡ወልደነጎድጓድ",  #  usual name
		"አሮጌ፡አቦ (አቡነ፡ገብረ፡ቅዱስ)",     #  usual name
		"አሮጌ፡ኢያሱስ"                  #  usual name
	);
	@PagumeTabotsTranscribed =(
	);
	@VariableTsomes =(
		"ነነዌ",
		"በአታ ጾመ (ሁዳዴ የሚገባበት)",
		"ደብረ ዘይት",
		"ሆሣዕና",
        	"ስቅለት",
		"ትንሣኤ",
		"ረክበ ካህናት",
		"ዕርገት",
		"ጰራቅሊጦስ (ጰንጠቆስጤ)",
		"ጾመ ሐዋርያት (የሰኔ ጾም)",
		"ጾመ ድኅነት"
	);
	@VariableTsomesTranscribed =(
	);
	%VariableTsomes =(
		"ነነዌ"				=>   0,
		"በአታ ጾመ (ሁዳዴ የሚገባበት)"		=>  14,
		"ደብረ ዘይት"	  		=>  41,
		"ሆሣዕና"		  		=>  62,
		"ስቅለት"		  		=>  67,
		"ትንሣኤ"		  		=>  69,
		"ረክበ ካህናት"			=>  93,
		"ዕርገት"				=> 108,
		"ጰራቅሊጦስ (ጰንጠቆስጤ)"		=> 118,
		"ጾመ ሐዋርያት (የሰኔ ጾም)"		=> 119,
		"ጾመ ድኅነት"			=> 121
	);
	%MiscellaneousTsomes =(
		#
		# ጾመ ገሀድ depends on the day ጥምቀት or ገና 
		# fall on (wed or fri), fix later. 
		# 
		"ጾመ ገሀድ"			=> [10,5],
		"ማርያም"				=> [21,3]
	);
	%MiscellaneousTsomesTranscribed =(
	);
	%MiscellaneousTsomes2 =(
		#
		#  we need a 2nd hash to avoid key clashes...
		#
		"ማርያም"				=> [21,9]
	);
	%MiscellaneousTsomes2Transcribed =(
	);
	#
	# ዓመታዊ በዓል
	#
	%AnnualTsomes =(
		"ርእስ ዓውደ ዓመት (እንቍጣጣሽ)"		=>   [1,1],
		"መስቀል (የመጣበት)"			=>  [10,1],
		"ደመራ"				=>  [16,1],
		"መስቀል (የተገኘበት)"			=>  [17,1],
		"ሚካአል"				=>  [12,3],
		"ጾመ ስብከት (የገና/የነቢያት ጾም)"	=>  [15,3],
		"ገብርኤል"				=>  [19,4],
		"ልደት"				=>  [29,4],
		"ግዝረት"				=>   [6,5],
		"ሥላሴ"				=>   [7,5],
		"ጥምቀት/ኤጲፋንያ"			=>  [11,5],
		"ቃና ዘገሊላ"			=>  [12,5],
		"ስምዖን"				=>   [8,6],
		"ገብርኤል"				=>  [19,7],
		"በዓለ መስቀል"			=>  [10,7],
		"መድኃኔ ዓለም"			=>  [27,7],
		"ትስብእት/በዓለ ወልድ"			=>  [29,7],
		"ጊዮርጊስ"				=>  [23,8],
		"ደብረ ታቦር (ቡሄ)"			=> [13,12]
	);
	%AnnualTsomesTranscribed =(
	);
	#
	# የሊቃነ መላእክ ዕለት
	#
	%LikaneTsomes =(
		"ራጉኤል"				=>   [1,1],
		"አፍኒን"				=>   [8,3],
		"ሚካኤል"				=>  [12,3],
		"ፋኑኤል"				=>   [3,4],
		"ሱርያል"				=>  [27,5],
		"ሳቁኤል"				=>  [5,11],
		"ኡራኤል"				=> [21,11],
		"ሩፋኤል"				=>  [3,13],
		"አርባዕቱ እንስሳ"			=>   [8,3],
		"24ቱ ካህናተ ሰማይ"			=>  [3,12],
	);
	%LikaneTsomesTranscribed =(
	);
	#
	# የሐዋርያ/ወንጌላዊ በዓል
	#
	%HawaryaTsomes =(
		"በርተሎሜዎስ"			=>   [1,1],
		"ማቴዎስ"				=>  [12,2],
		"እስጢፋኖስ"			=>  [17,2],
		"ሉቃስ"				=>  [22,2],
		"ፊሊጶስ"				=>  [18,3],
		"እንድርያስ"			=>   [4,4],
		"ዮሐንስ"				=>   [4,5],
		"ያዕቆብ ወልደ እልፍዮስ"		=>  [10,6],
		"ማትያስ"				=>   [8,7],
		"ያዕቆብ ወልደ ዘብዴዎስ"		=>  [17,8],
		"ማርቆስ"				=>  [30,8],
		"ቶማስ"				=>  [26,9],
		"ታዴዎስ"				=>  [2,11],
		"ጴጥሮስ ወጳውሎስ (የጾም ሐዋርያት ጾም መፍቻ)"	=>  [5,11],
		"ናትናኤል"				=> [10,11],
		"ያዕቆብ የጌታ ወንድም"			=> [18,11]
	);
	%HawaryaTsomesTranscribed =(
	);
	#
	# የቅድስት ማርያም በዓል =(
	#
	%StMaryTsomes =(
		"ጼዴንያ"				=>  [10,1],
		"ደብረ ቍስቋም"			=>   [6,3],
		"በአታ"				=>   [3,4],
		"ድቅስዮስ"				=>  [22,4],
		"ገና"				=>  [28,4],
		"ልደት (ክርስቶስ የወለደችበት ዕለት)"	=>  [29,4],
		"ዕረፍት"				=>  [21,5],
		"ኪዳነ ምሕረት"			=>  [16,6],
		"ፅንሰት"				=>  [29,7],
		"ልደታ"				=>   [1,9],
		# genbot 24, 25?
		# sene 8, 20 ?
		"ጾም ፍልሰታ (የመቤታችን ጾም)"		=>  [1,12],  # check with ethiopica
		"ቍጽረታ"				=>  [7,12],
		"ፍልሰታ (ኪዳነ ምሕረት) - የጾም መፍቻ"	=> [16,12],  # check with book
		"ሩፋኤል"				=>  [3,13]   # check with seattle group
	);
	%StMaryTsomesTranscribed =(
	);
	%AksumTsomes =(
		"ጰንጠሌዎን"			=>  [6,2],
		"አረጋዊ/ዘሚካኤል"			=> [14,2],
		"ይምአታ"				=> [28,2],
		"ሊቃኖስ"				=> [25,3],
		"ዖፅ"				=>  [4,4],
		"ሊባኖስ/መጣዕ"			=>  [3,5],
		"ጽሕማ"				=> [16,5],
		"አሌፍ"				=> [11,7],
		"አፍጼ"				=> [29,9],
		"ጉባ"				=> [29,9],
		"ይሥሐቅ/ገሪማ"			=> [17,10]
	);
	%AksumTsomesTranscribed =(
	);
	@YearNames =(
		[ "ማቴዎስ", "Mateos"   ],
		[ "ማርቆስ", "Markos"   ],
		[ "ሉቃስ",  "Lukas"    ],
		[ "ዮሐንስ", "Yohannes" ]  # Leap Year 
	);
	@KokebYearNames =(
		"ምልክኤል",
		"ሕልመልሜሌክ",
		"ምልኤል",
		"ናርኤል"
	);
	@KokebYearNamesTranscribed =(
	);
	@KokebDayNames =(
		"አጣርድ",
		"ዙሕራ",
		"መሪሕ",
		"መሽተሪ",
		"ዙሐል",
		"ኡራኑስ",
		"ነይጡን"
	);
	@KokebDayNamesTranscribed =(
	);
	@KokebMonthNames =(
		"ሚዛን",
		"አቅራብ",
		"ቀውስ",
		"ጀደይ",  #  ጀዲ
		"ደለው",  #  ደለዌ
		"ሑት",
		"ሐመል",
		"ሠውር",
		"ጀውዛ",  #  ገውዝ
		"ሸርጣን",
		"አሰድ",
		"ሰንቡላ",
		"ሰንቡላ"  #  Don't really know for ጳጉሜን
	);
	@KokebMonthNamesTranscribed =(
	);
	@EthiopicSeasonNames =(
		"መጸው",  #  ከመስከረም ፳፭ እስከ ታኅሣሥ  ፳፭
		"ሐጋይ",  #  ክታኅሣሥ  ፳፭ እስከ መጋቢት  ፳፭
		"ጸደይ",  #  ከመጋቢት  ፳፭ እስከ ሰኔ    ፳፭
		"ክረምት"  #  ከሰኔ    ፳፭ እስከ መስከረም ፳፭  # check this, its seems a
		                                   # a bit long for ክረምት
	);
	@EthiopicSeasonNamesTranscribed =(
	);

	#
	# Look into these later and how to calculate the days
	#
	#
	# Islamic Holidays in Ethiopia
	#
	# የነቢዩ መሐመድ ልደት (መውሊድ)       Birthday of Prophet Mohammed (Maulid)
	# ኢድ አል ፈጥር (ረመዳን)           Id Al Fetir (Remedan)
	# ኢድ አል አድሐ (አረፋ)            Id Al Adaha (Arefa)
	#
	# Islamic Holidays in Eritrea
	#
	# ልደተ ነቢዩ መሓመድ (መውሊድ)        Birthday of Prophet Mohammed (Maulid)
	# ዒድ ኣል ፈጥር (ረመዳን)           Id Al-Fetir (Remedan)
	# ዒድ ኣል ኣድሓ (ዓሪፋ)            Id Al Adaha (Arefa)

	# ታቦት = \&tabot;
	# ዘመነ = \&zemene;
	# ጾመ  = \&tsom;
}


sub new
{
my $class = shift;
my %args  = @_ if ($#_);
my $self;


	if ( ref($_[0]) && $_[0]->isa ("Date::ICal") ) {
		#
		#  We assume a Gregorian calscale, though we should check it.
		#  Proposal a universal toGregorian or gregorian method to group.
		#
		my $ical = $_[0];
		my $et = {}; bless $et, $class;
		( $args{day}, $args{month}, $args{year} )
		= $et->fromGregorian ( $ical->day, $ical->month, $ical->year );
		$self = $class->SUPER::new ( %args );
	}
	elsif ( $args{calscale} ) {
		#
		#  A calender system has been specified:
		#
		if ( $args{calscale} =~ /gregorian/i ) {
			#
			# We have been given dates in the Gregorian system
			# so we must convert into Ethiopic
			#
			my $et = {}; bless $et, $class;
			if ( $args{ical} || $args{epoch} ) {
				my $temp = $class->SUPER::new ( %args );
				( $args{day}, $args{month}, $args{year} )
				= $et->fromGregorian ( $temp->day, $temp->month, $temp->year );
				delete ( @args{'ical', 'epoch'} );
			}
			elsif ( $args{day} && $args{month} && $args{year} ) {
				( $args{day}, $args{month}, $args{year} )
				= $et->fromGregorian ( $args{day}, $args{month}, $args{year} );
			}
			else {
			 	die ( "Useless Gregorian context, no date args passed.\n" );
			}
			$self = $class->SUPER::new ( %args );
		}
		elsif ( $args{calscale} =~ /ethio/i ) {
			$self = $class->SUPER::new ( %args );
			$self->_isBogusEthiopicDate;
		}
		else {
			die ( "Aborting: unknown calscale '$args{calscale}'\n" );
		}
	}
	else {
		#
		#  The Ethiopic calender system is assumed when unspecified:
		#
		$self = $class->SUPER::new ( %args );
		$self->_isBogusEthiopicDate;
	}

	$self->{_trans} = $false;
	$self->{_is_tsome} = $false;

	bless $self, $class;
}


#
#
#  Calender System Conversion Methods Below Here:
#
#
sub _AbsoluteToEthiopic 
{
my ( $self, $absolute ) = @_;

	my  $year = quotient ( 4 * ( $absolute - $EPOCH ) + 1463, 1461 );
	my $month = 1 + quotient ( $absolute - $self->_EthiopicToAbsolute ( 1, 1, $year ), 30 );
	my   $day = ( $absolute - $self->_EthiopicToAbsolute ( 1, $month, $year ) + 1 );

	( $day, $month, $year );
}


sub fromGregorian
{
my $self = shift;

	die ( "Bogus Ethiopic Date!!" ) if ( $self->_isBogusGregorianDate ( @_ ) );

	$self->_AbsoluteToEthiopic ( $self->_GregorianToAbsolute ( @_ ) );
}


sub gregorian
{
my $self = shift;

	$self->_AbsoluteToGregorian ( $self->_EthiopicToAbsolute ( @_ ) );
}


sub _isBogusEthiopicDate 
{
my $self = shift;

	my($day, $month, $year) = (@_) ? @_ : ($self->day, $self->month, $self->year);

	( !( 1 <= $day && $day <= 30 )
		|| !(  1 <= $month && $month <= 13 )
		|| ( $month ==  13 && $day > 6 )
		|| ( $month ==  13 && $day == 6 && !$self->isLeapYear )
	)
	?
	$true : $false;

}


sub _isBogusGregorianDate 
{
my $self = shift;

	my($day, $month, $year) = (@_) ? @_ : ($self->day, $self->month, $self->year);

	( !( 1 <= $month && $month <= 12 )
		|| !( 1 <= $day  && $day  <= $GregorianDaysPerMonth[$month-1] )
		|| ( $day == 29  && $month == 2 && !$self->_isGregorianLeapYear($year) )
	)
	?
	$true : $false;

}


sub _EthiopicToAbsolute
{
my $self = shift;
my ( $date, $month, $year ) = ( @_ ) ? @_ : ($self->day,$self->month,$self->year);

	( $EPOCH - 1 + 365 * ( $year - 1 ) + quotient ( $year, 4 ) + 30 * ( $month - 1 ) + $date );
}


sub _GregorianYear
{
my ( $a ) = @_;

	my $b = $a - 1;
	my $c = quotient ( $b, 146097 );
	my $d =      mod ( $b, 146097 );
	my $e = quotient ( $d, 36524  );
	my $f =      mod ( $d, 36524  );
	my $g = quotient ( $f, 1461   );
	my $h =      mod ( $f, 1461   );
	my $i = quotient ( $h, 365    );
	my $j = ( 400 * $c ) + ( 100 * $e ) + ( 4 * $g ) + $i;

	( ( $e == 4 ) || ( $i == 4 ) )
	  ? $j
	  : ( $j + 1 )
	;
}


sub _AbsoluteToGregorian
{
my ( $self, $absolute ) = @_;

	my $year = _GregorianYear ( $absolute );

	my $priorDays = ( $absolute - $self->_GregorianToAbsolute ( 1, 1, $year ) );

	my $correction 
	= ( $absolute < $self->_GregorianToAbsolute ( 1, 3, $year ) )
	  ? 0
	  : ( $self->_isGregorianLeapYear ( $year ) )
	    ? 1
	    : 2
	;

	my $month = quotient ( ( ( 12 * ( $priorDays + $correction ) + 373 ) / 367 ), 1 );
	my $day = $absolute - $self->_GregorianToAbsolute ( 1, $month, $year ) + 1;

	( $day, $month, $year );
}


sub _GregorianToAbsolute
{
my $self = shift;
my ( $date, $month, $year ) = ( @_ ) ? @_ : ($self->day,$self->month,$self->year);

	my $correction 
	= ( $month <= 2 )
	  ? 0
	  : ( $self->_isGregorianLeapYear ( $year ) )
	    ? -1
	    : -2
	;

	my $absolute =(
		365 * ( $year - 1 )
		    + quotient ( $year - 1, 4   )
		    - quotient ( $year - 1, 100 )
		    + quotient ( $year - 1, 400 )
		    + ( 367 * $month - 362 ) / 12
			+ $correction + $date
	);

	quotient ( $absolute, 1 );
}


sub _isGregorianLeapYear
{
shift;

	(
		( ( $_[0] % 4 ) != 0 )
		|| ( ( $_[0] % 400 ) == 100 )
		|| ( ( $_[0] % 400 ) == 200 )
		|| ( ( $_[0] % 400 ) == 300 )
	)
	  ? 0
	  : 1
	;
}


#
# argument is an ethiopic year
#
sub isLeapYear
{
my $self = shift;
my ( $year ) = ( @_ ) ? shift : $self->year;

	( ( $year + 1 ) % 4 ) ? 0 : 1 ;
}


sub quotient
{
	$_ = $_[0] / $_[1];

	s/\.(.*)//;

	$_;
}


sub mod 
{
	( $_[0] - $_[1] * quotient ( $_[0], $_[1] ) );
}


#
# calscale and toGregorian and are methods I recommend every non-Gregorian
# based ICal package provide to identify itself and to convert the
# calendar system it handles into a normalized form.
#
sub calscale
{
	"ethiopic";
}


sub toGregorian
{
my $self = shift;

	my ($day,$month,$year) = $self->gregorian;

	new Date::ICal ( day => $day, month => $month, year => $year );
}


sub format
{
my $self = shift;

print "Ethiopic extended formatting is not yet implemented\n";
print "See: http://libeth.sourceforge.net/0.40/Dates.html\n";
return;

	$_ = shift;

#
#  see what's on libeth webpage
#
#  http://libeth.sourceforge.net/0.40/Dates.html
#

	s/%M//;  # replace with locale equivalent
	s/%H//;
	s/%Y//;
	s/%EY//;
	s/%m//;
	s/%s//;
	s/%EC//;
	s/%Ey//;
	s/%EY//;
	s/%Od//;
	s/%Oe//;
	s/%OH//;
	s/%OI//;
	s/%Om//;
	s/%Ou//;
	s/%OU//;
	s/%OV//;
	s/%Ow//;
	s/%OW//;
	s/%Oy//;

	s/%-q//;
	s/%-ta//;
	s/%-ts//;
	s/%-tsm//;
	s/%-EN//;
	s/%-ms//;
	s/%-ys//;
	s/%-sdm//;
	s/%-sds//;

}


sub full_date
{
my ($self) = shift;

	(@_)
	?
	$self->day_name.$self->_sep.$self->month_name." ".$n->convert($self->day).$self->_daysep.$n->convert($self->year)." ".$self->ad
	:
        ( $self->{_trans} )
	  ?
	  $self->day_name(@_).$self->_sep.$self->month_name(@_)." ".$self->day.$self->_daysep.$self->year." ".$self->ad(@_)
	  :
	  $self->day_name.$self->_sep.$self->month_name." ".$self->day.$self->_daysep.$n->convert($self->year)." ".$self->ad
	;
}
sub long_date
{
my ($self) = shift;

	(@_)
	?
	$n->convert($self->day)."-".$self->month_name."-".$n->convert($self->year)
        :
	( $self->{_trans} )
	  ?
	  $self->day."-".$self->month_name(@_)."-".$self->year
	  :
	  $self->day."-".$self->month_name."-".$n->convert($self->year)
	;
}
sub medium_date
{
my ($self) = @_;
	
	my $year = $self->year;
	$year =~ s/^\d\d//;

	($#_)
	?
	$self->day."-".$self->month_name."-".$n->convert($year)
	:
	( $self->{_trans} )
	  ?
	  $self->day."-".$self->month_name(@_)."-".$year
	  :
	  $n->convert($self->day)."-".$self->month_name."-".$n->convert($year)
	;
}
sub short_date
{
	$self->day."/".$self->month."/".$self->year
}
sub full_time
{
}
sub medium_time
{
}
sub short_time
{
}
sub date_time
{
}


sub day_name
{
my ( $self, $day ) = @_;

	$day ||= $self->_EthiopicToAbsolute;

	$day %= 7;

	my $pkg = ref($self);

	${"${pkg}::Days"}[$day][$self->{_trans}];
}


sub short_day_name
{
my ( $self, $day ) = @_;

	$day ||= $self->_EthiopicToAbsolute;

	$day %= 7;

	my $pkg = ref($self);

	${"${pkg}::ShortDays"}[$day][$self->{_trans}];
}


sub month_name
{
my ( $self, $month ) = @_;

	$month ||= $self->month;

	$month -= 1;

	my $pkg = ref($self);

	${"${pkg}::Months"}[$month][$self->{_trans}];
}


sub short_month_name
{
my ( $self, $month ) = @_;

	$month ||= $self->month;

	$month -= 1;

	my $pkg = ref($self);

	${"${pkg}::ShortMonths"}[$month][$self->{_trans}];
}

#
#
#  Methods for Language Independent Date Properites:
#
#


sub isTsomes
{
	$_[0]->{_is_tsome};
}


sub tsomes
{
my $self = shift;
my ( $year ) = ( @_ ) ? shift : $self->year;

	my @Tsomes;
	$#Tsomes = 50;
	my $i = 0;

	my $pkg = ref($self);

	#  Fixed Tsomes First
	#
	#  Yuck... Lets simplify this later and get the tsomes sorted.
	#
	foreach my $key (keys %MiscellaneousTsomes) {
		my $dm = $MiscellaneousTsomes{$key};	
		my $tsome = $pkg->new ( day => $dm->[0], month => $dm->[1], year => $year );
		$tsome->{_tsome_name} = $key;
		$tsome->{_tsome_category} = "misc";  # fix later
		$tsome->{_is_tsome} = $true;
		$Tsomes[$i++] = $tsome;
	}
	foreach my $key (keys %MiscellaneousTsomes2) {
		my $dm = $MiscellaneousTsomes2{$key};	
		my $tsome = $pkg->new ( day => $dm->[0], month => $dm->[1], year => $year );
		$tsome->{_tsome_name} = $key;
		$tsome->{_tsome_category} = "misc";  # fix later
		$tsome->{_is_tsome} = $true;
		$Tsomes[$i++] = $tsome;
	}
	foreach my $key (keys %AnnualTsomes) {
		my $dm = $AnnualTsomes{$key};	
		my $tsome = $pkg->new ( day => $dm->[0], month => $dm->[1], year => $year );
		$tsome->{_tsome_name} = $key;
		$tsome->{_tsome_category} = "ዓመታዊ በዓል";
		$tsome->{_is_tsome} = $true;
		$Tsomes[$i++] = $tsome;
	}
	foreach my $key (keys %LikaneTsomes) {
		my $dm = $LikaneTsomes{$key};	
		my $tsome = $pkg->new ( day => $dm->[0], month => $dm->[1], year => $year );
		$tsome->{_tsome_name} = $key;
		$tsome->{_tsome_category} = "የሊቃነ መላእክ ዕለት";
		$tsome->{_is_tsome} = $true;
		$Tsomes[$i++] = $tsome;
	}
	foreach my $key (keys %HawaryaTsomes) {
		my $dm = $HawaryaTsomes{$key};	
		my $tsome = $pkg->new ( day => $dm->[0], month => $dm->[1], year => $year );
		$tsome->{_tsome_name} = $key;
		$tsome->{_tsome_category} = "የሐዋርያ/ወንጌላዊ በዓል";
		$tsome->{_is_tsome} = $true;
		$Tsomes[$i++] = $tsome;
	}
	foreach my $key (keys %StMaryTsomes) {
		my $dm = $StMaryTsomes{$key};	
		my $tsome = $pkg->new ( day => $dm->[0], month => $dm->[1], year => $year );
		$tsome->{_tsome_name} = $key;
		$tsome->{_tsome_category} = "የቅድስት ማርያም በዓል";
		$tsome->{_is_tsome} = $true;
		$Tsomes[$i++] = $tsome;
	}
	foreach my $key (keys %AksumTsomes) {
		my $dm = $AksumeTsomes{$key};	
		my $tsome = $pkg->new ( day => $dm->[0], month => $dm->[1], year => $year );
		$tsome->{_tsome_name} = $key;
		$tsome->{_tsome_category} = "የአክሱም ዘመነ";
		$tsome->{_is_tsome} = $true;
		$Tsomes[$i++] = $tsome;
	}

	#
	#  Computer Variable Tsomes
	#
	my $aa  = 5500 + $year;                   #  ዓመተ ዓለም
	my $w   = ($aa - 1) % 19;                 #  ወምበር
	my $ab  = ($w * 11) % 30;                 #  አበቅቴ
	my $m   = 30 - $ab;                       #  መጥቅዕ

	my $wr  = ($m < 15) ? 2 : 1;              #  ወር

	my $ly  = int (($aa - 1) / 4);            #  leap year

	my $p   = ($year % 4) ? 0 : 1 ;

	my $td  = ($aa - 1) * 365 + $ly + $p;
	my $s   = (($td + 1) % 7) + 1;
	my $tdm = $td + ($wr - 1) * 30 + $m;
	my $d   = (($tdm % 7) + 1);
	my $f   = 129 - ((($d + 1) % 7) + 1);

	foreach my $key (@VariableTsomes) {
		my $tdbi = $tdm + $f + $VariableTsomes{$key};
		my $wri = int(($tdbi - $td) / 30);
		my $di = (($tdbi - $td) % 30);
		$di ||= 30;
		$wri = $wri + 1 if ($di > 0);

		my $is = (($tdbi % 7) + 1);
 
		my $tsome = $pkg->new ( day => $di, month => $wri, year => $year );
		$tsome->{_tsome_name} = $key;
		$Tsomes[$i++] = $tsome;
	}

	@Tsomes;
}


sub dayStar
{
my $self = shift;
my ( $day ) = ( @_ ) ? shift : $self->day;

	( $self->{_trans} ) ? $KokebDayNamesTranscribed[$day%7] : $KokebDayNames[$day%7] ;

}


sub monthStar
{
my $self = shift;
my ( $month ) = ( @_ ) ? shift : $self->month;

	( $self->{_trans} ) ? $KokebMonthNamesTranscribed[$month%13] : $KokebMonthNames[$month%13] ;
}


sub yearStar
{
my $self = shift;
my ( $year ) = ( @_ ) ? shift : $self->year;

	( $self->{_trans} ) ? $KokebYearNamesTranscribed[$year%4] : $KokebYearNames[$year%4] ;
}


sub season
{
my $self = shift;

	my ($day,$month) = ($self->day,$self->month);
	my $season;
	my $daysThusFar = ($month-1)*30 + $day;

	( $daysThusFar < 25 )
	?  "ክረምት"
	: ( $daysThusFar < (3*30+24) )
	  ? "መጸው"
	  : ( $daysThusFar < (6*30+24) )
	    ? "ሐጋይ"
	    : ( $daysThusFar < (9*30+24) )
	      ? "ጸደይ"
	      :	"ክረምት"
	;

}


sub tabot
{
my $self = shift;

	my ($day,$month) = ($self->day,$self->month);

	( $month == 13 )
	? ( $self->{_trans} )
	  ? $PagumeTabotsTranscribed[$day]
	  : $PagumeTabots[$day]
	:  $Tabots[$day][$self->{_trans}]
	;
}


sub zemene
{
my $self = shift;
my ( $year ) = ( @_ ) ? shift : $self->year;

	$YearNames[($year%4)][$self->{_trans}];
}


sub yearName { zemene(@_); }


sub useTranscription
{
my $self = shift;

	$self->{_trans} = shift if (@_);

	$self->{_trans};
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Date::Ethiopic - ICalendar for the Ethiopic Calendar System.

=head1 SYNOPSIS

 use Date::Ethiopic;
 #
 #  typical instantiation:
 #
 my $ethio = new Date::Ethiopic ( day => 29, month => 6, year => 1995 );
 $ethio    = new Date::Ethiopic ( ical => '19950629' );  # the same

 #
 # Get Gregorian Date:
 #
 my ($d,$m,$y) = $ethio->gregorian;

 #
 #  instantiate with a Gregorian date, date will be converted.
 #
 $ethio = new Date::Ethiopic ( ical => '20030308', calscale => 'gregorian' );

 #
 #  instantiate with a Date::ICal object, assumed to be in Gregorian
 #
 my $grego = new Date::ICal ( ical => '20030308' );
 $ethio = new Date::Ethiopic ( $grego );

 #
 #  get a Date::ICal object in the Gregorian calendar system
 #
 $grego = $ethio->toGregorian;  


=head1 DESCRIPTION

The Date::Ethiopic module provides methods for accessing date information
in the Ethiopic calendar system.  The module will also convert dates to
and from the Gregorian system.

=head2 Limitations

In the Gregorian system the rule for adding a 29th day to February during
leap year follows as per;  February will have a 29th day:

(((((every 4 years) except every 100 years) except every 400 years) except every 2,000) except (maybe every 16,000 years))

The Ethiopic calendar gets an extra day at the end of the 13th month on leap
year (which occurs the year before Gregorian leap year).
It is not known however if the Ethiopic calendar follows the 2,000 year rule.
If it does NOT follow the 2,000 year rule the consequence would be that the
difference between the two calendar systems will increase by a single day.
Hence if you reckon your birthday in the Ethiopic system, that date in
Gregorian may change in five years.  The algorithm here here assumes that
the Ethiopic system will follow the 2,000 year rule.

This may however become a moot point when we consider:


=head2 The Impending Calamity at the End of Time

Well, it is more of a major reset.  Recent reports from reliable sources
indicate that every
1,000 years the Ethiopic calendar goes thru a major upheaval whereby
the calendar gets resyncronized with either September 1st or possibly
even October 1st.  Accordingly Nehasse would then either end on the 25th
day or Pagumen would be extend to 25 days.  Noone will know their birthday
any more, Christmas or any other date that ever once had meaning.  Chaos
will indeed rule the world.

Unless everyone gets little calendar converting applets running on their wrist
watches, that would rule.  But before you start coding applets for future
embeded systems, lets get this clarified.  Consider that the Gregorian
calendar system is less than 500 years old, so this couldn't have happend
a 1,000 years ago, perhaps with the Julian calendar.  Since the Ethiopic
calendar is still in sync with the Coptic, the Copts must have gone thru
the same upheaval.

We are following this story closely, stay tuned to these man pages
for updates as they come in.


=head1 CREDITS

=over 4

=item * Calendrical Calculations: L<http://www.calendarists.com/>

=item * Bahra Hasab: L<http://www.hmml.org/events/>

=item * LibEth: L<http://libeth.sourceforge.net/>

=item * Ethiopica: L<http://ethiopica.sourceforge.net/>

=item * Saint Gebriel Ethiopian Orthodox Church of Seattle: L<http://www.st-gebriel.org/>

=item * Aklile Birhan Wold Kirkos, Metsaheit Tibeb, Neged Publishers, Addis Ababa, 1955 (1948 EC).

=back

=head1 REQUIRES

Date::ICal and L<Convert::Number::Ethiopic>.  It should work with
any version of Perl.  L<Convert::Number::Ethiopic> is only required
if you want to display years and days in Ethiopic numerals.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

The conversion algorithms are derived from the original work in Emacs
Lisp by Reingold, Dershowitz and Clamen which later grew into the
excellent reference Calendrical Calculations.  The Emacs package carries
the following message:

 ;; The Following Lisp code is from ``Calendrical
 ;; Calculations'' by Nachum Dershowitz and Edward
 ;; M. Reingold, Software---Practice & Experience, vol. 20,
 ;; no. 9 (September, 1990), pp. 899--928 and from
 ;; ``Calendrical Calculations, II: Three Historical
 ;; Calendars'' by Edward M.  Reingold, Nachum Dershowitz,
 ;; and Stewart M. Clamen, Software---Practice & Experience,
 ;; vol. 23, no. 4 (April, 1993), pp. 383--404.

 ;; This code is in the public domain, but any use of it
 ;; should publically acknowledge its source.

Otherwise, this module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

Ethiopica L<http://ethiopica.sourceforge.net>

=cut
