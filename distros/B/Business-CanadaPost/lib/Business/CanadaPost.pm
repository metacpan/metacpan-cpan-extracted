package Business::CanadaPost;
BEGIN {
  $Business::CanadaPost::AUTHORITY = 'cpan:YANICK';
}
{
  $Business::CanadaPost::VERSION = '1.06';
}
# ABSTRACT: Fetch shipping costs for Canada Post

use strict;
use LWP;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;

@ISA		= qw(Exporter);
@EXPORT		= qw();


sub new # {{{
{
	my ($class, %data) = @_;

	my $self = {
		language	=> 'en',	#canada post supports english (en) and french (fr)
		frompostalcode	=> '',		#canada post says to send a space if we have no entry...
		turnaroundtime  => '',
		merchantid	=> '',
		totalprice	=> '0.00',
		units		=> 'metric',	#allows for metric (cm and kg) or imperial (in and lb) measurements.
		items		=> [],
		testing		=> 0
	};

	foreach (keys %data)
	{
		$self->{$_} = $data{$_};
	}

	bless $self, $class;

	return $self;
} # }}}


sub geterror # {{{
{
	my $self = shift;
	my $error = $self->{'error'};
	$self->{'error'} = ''; #clear it once we've sent it.
	return $error;
} # }}}

sub setlanguage # {{{
{
	my ($self, $lang) = @_;

	$lang = lc($lang);
	return $self->_error(4) unless $lang eq 'fr' or $lang eq 'en' or $lang eq '';

	$self->{'language'} = $lang || 'en';
} # }}}


sub settocity # {{{

{
	my ($self, $city) = @_;
	$self->{'city'} = $city;
} # }}}


sub settesting # {{{
 
{
	my ($self, $testing) = @_;

	$self->{'testing'} = $testing;
} # }}}


sub setcountry # {{{

{
	my ($self, $country) = @_;
	$self->{'country'} = $country;
} # }}}


sub setmerchantid # {{{

{
	my ($self, $id) = @_;
	
	$self->{'merchantid'} = $id || ' ';
} # }}}


sub setunits # {{{

{
	my ($self, $units) = @_;

#FIXME -- make it go through each item and convert to/from metric if they change!
	$units = lc($units);
	return $self->_error(5) unless $units eq 'metric' or $units eq 'imperial';
	$self->{'units'} = $units;
} # }}}


sub setfrompostalcode # {{{

{
	my ($self, $code) = @_;

	$self->{'frompostalcode'} = $code || ' ';
} # }}}


sub settopostalzip # {{{

{
	my ($self, $code) = @_;

	$self->{'postalcode'} = $code || ' ';
} # }}}


sub setprovstate # {{{

{
	my ($self, $province) = @_;
	$self->{'provstate'} = $province || ' ';
} # }}}


sub setturnaroundtime # {{{

{
	my ($self, $code) = @_;
	$self->{'turnaroundtime'} = $code || ' ';
} # }}}


sub settotalprice # {{{

{
	my ($self, $price) = @_;
	$self->{'totalprice'} = sprintf('%01.2f', $price) || '0.00';
} # }}}


sub additem # {{{
{
	my ($self, %item) = @_;

	$item{'length'} and $item{'width'} and $item{'height'} or
		return $self->_error(6);

	my @currentitems = @{$self->{'items'}} if ref $self->{'items'};

	#canadapost specifies that the longest dimension is the length,
	#second longest is the width and shortest is height.
	my @dimensions = ($item{'length'}, $item{'height'}, $item{'width'});
	($item{'length'}, $item{'width'}, $item{'height'}) = reverse sort @dimensions;

	my $metric = $self->{'units'} eq 'imperial' ? 0 : 1;

	push (@currentitems, $item{'quantity'} || 1,
				$metric ? $item{'weight'} : $item{'weight'} * .45359237, # 1lb = .45359237kg
				$metric ? $item{'length'} : $item{'length'} * 2.54,	 # 1in = 2.54cm
				$metric ? $item{'width'}  : $item{'width'}  * 2.54,
				$metric ? $item{'height'} : $item{'height'} * 2.54,
				$item{'description'} || ' ',
				$item{'readytoship'} ? '<readyToShip />' : '');

	$self->{'items'} = \@currentitems;
} # }}}


sub getrequest # {{{
{
	my $self = shift;
	my $xmlfile = $self->buildXML() or return $self->_error($self->{'error'});

	my $lwp = LWP::UserAgent->new();
	my $result = $lwp->post("http://sellonline.canadapost.ca:30000", { 'XMLRequest' => $xmlfile });
	return $self->_error(8) unless $result->is_success;

	my $raw_data = $result->content();

	return $self->parseXML($raw_data);
} # }}}

sub parseXML # {{{

{
	my ($self, $xml) = @_;

	my ($parcel) = $xml =~ /<eparcel>(.+)<\/eparcel>/s;
	my ($resultcode) = $parcel =~ /<statusCode>([^<]+)<\/statusCode>/s;
	unless ($resultcode == 1)
	{
		my ($resultmessage) = $parcel =~ /<statusMessage>([^<]+)<\/statusMessage>/s;
		return $self->_error($resultmessage);
	}
	my ($products) = $parcel =~ /<product(.+)<\/product>/s; #should be greedy and get them all..
	my @options;
	foreach my $product (split /<\/product>\s+<product/s, $products)
	{
		my ($name)	= $product =~ /<name>([^<]+)<\/name>/s;
		my ($rate)	= $product =~ /<rate>([^<]+)<\/rate>/s;
		my ($shipdate)	= $product =~ /<shippingDate>([^<]+)<\/shippingDate>/s;
		my ($delvdate)	= $product =~ /<deliveryDate>([^<]+)<\/deliveryDate>/s;
		my ($dayofweek)	= $product =~ /<deliveryDayOfWeek>([^<]+)<\/deliveryDayOfWeek>/s;
		my ($nextdayam)	= $product =~ /<nextDayAM>([^<]+)<\/nextDayAM>/s;
		my $estdays     = _getdaysbetween($shipdate, $delvdate);
		$estdays = 'Unknown' if $estdays == -1;
		$nextdayam = $nextdayam eq 'true' ? 1 : 0;
		push (@options, $name, $rate, $shipdate, $delvdate, $dayofweek, $nextdayam, $estdays);
	}

	$self->{'shippingoptioncount'} = scalar(@options) / 7;
	$self->{'shiprates'} = \@options;

	my ($soptions) = $parcel =~ /<shippingOptions>(.+)<\/shippingOptions>/s;
	if ($soptions =~ /<insurance>([^<]+)<\/insurance>/)
	{
		$self->{'shipinsurance'} = $1 eq 'No' ? 0 : 1;
	}
	if ($soptions =~ /<deliveryConfirmation>([^<]+)<\/deliveryConfirmation>/)
	{
		$self->{'shipconfirm'} = $1 eq 'No' ? 0 : 1;
	}
	if ($soptions =~ /<signature>([^<]+)<\/signature>/)
	{
		$self->{'signature'} = $1 eq 'No' ? 0 : 1;
	}

	$self->{'shipcomments'} = $1 if $parcel =~ /<comment>([^<]+)<\/comment>/s;
	return 1;
} # }}}


sub getoptioncount # {{{
{
	my $self = shift;
	return $self->{'shippingoptioncount'};
} # }}}



sub getsignature # {{{

{
	my $self = shift;
	return $self->{'signature'};
} # }}}


sub getinsurance # {{{

{
	my $self = shift;
	return $self->{'shipinsurance'};
} # }}}



sub getshipname # {{{

{
	my $self = shift;
	my $shipmentnum = shift || 1;
	$shipmentnum--; #we're looking for the offset in the array...

	my @options = @{$self->{'shiprates'}};
	return $options[$shipmentnum * 7]
} # }}}


sub getshiprate # {{{

{
	my $self = shift;
	my $shipmentnum = shift || 1;
	$shipmentnum--;
	my @options = @{$self->{'shiprates'}};
	return $options[$shipmentnum * 7 + 1]
} # }}}



sub getshipdate # {{{

{
	my $self = shift;
	my $shipmentnum = shift || 1;
	$shipmentnum--;
	my @options = @{$self->{'shiprates'}};
	return $options[$shipmentnum * 7 + 2]
} # }}}


sub getdelvdate # {{{

{
	my $self = shift;
	my $shipmentnum = shift || 1;
	$shipmentnum--;
	my @options = @{$self->{'shiprates'}};
	return $options[$shipmentnum * 7 + 3]
} # }}}



sub getdayofweek # {{{

{
	my $self = shift;
	my $shipmentnum = shift || 1;
	$shipmentnum--;
	my @options = @{$self->{'shiprates'}};
	return $options[$shipmentnum * 7 + 4]
} # }}}



sub getnextdayam # {{{

{
	my $self = shift;
	my $shipmentnum = shift || 1;
	$shipmentnum--;
	my @options = @{$self->{'shiprates'}};
	return $options[$shipmentnum * 7 + 5]
} # }}}



sub getestshipdays # {{{

{
	my $self = shift;
	my $shipmentnum = shift || 1;
	$shipmentnum--;
	my @options = @{$self->{'shiprates'}};
	return $options[$shipmentnum * 7 + 6]
} # }}}



sub getconfirmation # {{{

{
	my $self = shift;
	return $self->{'shipconfirm'};
} # }}}


sub getcomments # {{{

{
	my $self = shift;
	return $self->{'shipcomments'};
} # }}}

sub _error # {{{

{
	my ($self, $msgnum) = @_;
	my @englishmessages = ('You need to specify some items to ship!',
				'You must specify a valid postal code for Canadian shipments!',
				'You must specify a state for American shipments!',
				'You must specify the country being shipped to!',
				'Valid languages are English and French',
				'Valid units are metric (cm and kg) or imperial (in and lb)',
				'You must specify a height, width, and length for each item.',
				'You must specify your Canada Post merchant ID!',
				'Failed sending to Canada Posts servers!');
	my @frenchmessages  = ('Vous devez indiquer quelques pour transporter!',
				'Vous devez indiquer un code postal valide pour les expéditions Canadiannes!',
				'Vous devez indiquer un état pour les expéditions américaines!',
				'Vous devez indiquer le pays que vous voulez embarquer à!',
				'Les langues valides sont Anglaises et Françaises',
				'Les unités valides sont métriques (cm et kg) ou impériales (po et lv)',
				'Vous devez indiquer une taille, une largeur, et une longueur pour chaque article.',
				'Vous devez indiquer votre identification du Postes Canada!',
				'Envoi échoué aux serveurs du Postes Canada!');

	if ($msgnum == 0)
	{
		push (@englishmessages, $msgnum);
		push (@frenchmessages, $msgnum);
		$msgnum = scalar(@englishmessages) - 1;
	}

	$self->{'error'} = sprintf("%s\n",
			$self->{'language'} eq 'fr' ? $frenchmessages[$msgnum] :
							$englishmessages[$msgnum]);
	return 0;
} # }}}

sub _getdaysbetween # {{{

{
	my ($fromdate, $todate) = @_;
	my @daysinmonth = (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

	my ($fromyear, $frommon, $fromday) = split /-/, $fromdate;
	my ($toyear, $tomon, $today) = split /-/, $todate;

	return 0 if $fromyear == $toyear and $frommon == $tomon and $fromday == $today;
	return -1 unless $fromyear and $frommon and $fromday and $toyear and $tomon and $today;

	my $days;
	
	do
	{
		$days++;
		$fromday++;
		$daysinmonth[2] = _isleapyear($fromyear) ? 29 : 28;
		$fromday = 1, $frommon++ if $fromday > $daysinmonth[$frommon];
		$frommon = 1, $fromyear++ if $frommon == 13;
	} until $fromyear == $toyear and $frommon == $tomon and $fromday == $today;

	return $days;
} # }}}

sub _isleapyear # {{{

{
	my $year = shift;

        return 1 if $year % 4 == 0 and $year % 400 == 0;
        return 0 if $year % 100 == 0;
        return 1 if $year % 4 == 0;
        return 0;
} # }}}

sub buildXML # {{{

{
	my $self = shift;
	
	my @items = @{$self->{'items'}};
	return $self->_error(0) unless @items;

	# language can be en or fr (this is Canada!)
	my $xmlfile = sprintf('<?xml version="1.0" ?>
<eparcel>
	<language>%s</language>
	<ratesAndServicesRequest>
		<merchantCPCID>%s</merchantCPCID>
		%s
		%s
		<itemsPrice>%.2f</itemsPrice>%s',
		$self->{'language'} || 'en',
		$self->{'merchantid'} || return $self->_error(7),
		$self->{'frompostalcode'} ? "<fromPostalCode>" . $self->{'frompostalcode'} . "</fromPostalCode>\n" : '',
		$self->{'turnaroundtime'} ? "<turnAroundTime>" . $self->{'turnaroundtime'} . "</turnAroundTime>\n" : '',
		$self->{'totalprice'} || '0.00',
	   	"\n");

	
	$xmlfile .= "		<lineItems>\n";
	for (my $n = 0; $n < @items; $n += 7)
	{
		$xmlfile .= sprintf("			<item>
				<quantity>%d</quantity>
				<weight>%01.2f</weight>
				<length>%01.2f</length>
				<width>%01.2f</width>
				<height>%01.2f</height>
				<description>%s</description>
				%s
			</item>\n",
			@items[$n .. $n+6]);
	}
	$xmlfile .= "		</lineItems>\n";

	if (!$self->{'country'} or $self->{'country'} =~ /^\s*$/) # no country specified...
	{
		return $self->_error(3);
	}
	elsif (uc($self->{'country'}) eq 'CANADA' or uc($self->{'country'}) eq 'CA')
	{
		#canada post docs state that only postal code must exist for canadian shipments
		$self->{'postalcode'} =~ s/[^\d\w]//g;
		$self->{'postalcode'} =~ /^\w\d\w\d\w\d$/ 
			or return $self->_error(1);

	}
	elsif (uc($self->{'country'}) eq 'UNITED STATES' or uc($self->{'country'} eq 'US')
			or uc($self->{'country'}) eq 'ÉTATS-UNIS')
	{
		#canada post says that all they require for now is country and provorstate; however,
		#zipcodes will be used in the future...
		$self->{'provstate'} or return $self->_error(2);
		$self->{'postalcode'} ||= ' ';
		$self->{'postalcode'} =~ s/\D//g;
	}
			
	$xmlfile .= sprintf("		<city>%s</city>
		<provOrState>%s</provOrState>
		<country>%s</country>
		<postalCode>%s</postalCode>
	</ratesAndServicesRequest>
</eparcel>",
	$self->{'city'} || ' ',
	$self->{'provstate'} || ' ',
	$self->{'country'},
	$self->{'postalcode'} || ' ');

	return $xmlfile;
} # }}}

1;



=pod

=head1 NAME

Business::CanadaPost - Fetch shipping costs for Canada Post

=head1 VERSION

version 1.06

=head1 SYNOPSIS

	use Business::CanadaPost;
	
	#initialise object - specifying from postal code, and canada post merchant id
	my $shiprequest = Business::CanadaPost->new(	merchantid => 'CPC_DEMO_XML',
							frompostal => 'M1P1C0',
							testing	   => 1			);

	# add an item to be shipped
	$shiprequest->additem(quantity 		=> 1,
				height 		=> 60,
				width  		=> 15,
				length 		=> 60,
				weight 		=> 7,
				description 	=> 'box o stuff',
				readytoship 	=> 1);

	# set more parameters on the item being shipped
	$shiprequest->setcountry('United States');
	$shiprequest->setprovstate('New York');
	$shiprequest->settopostalzip('11726');
	$shiprequest->settocity('New York');
	$shiprequest->getrequest() || print "Failed sending request: " . $shiprequest->geterror() . "\n"; 
	print "There are " . $shiprequest->getoptioncount() . " available shipping methods.\n";

=head1 DESCRIPTION

Business::CanadaPost is a Perl library created to allow users to fetch real-time options and pricing quotes
on shipments sent from Canada using Canada Post.

To get off of the development server, you'll need to get an account from Canada Post's "Sell Online" service.
While testing, use user id CPC_DEMO_XML and specify a parameter of 'testing' with a value of 1 to the new()
constructor, so it knows to use Canada Post's devel server.  If you don't, and don't have an account, you'll
only receive errors.

=head1 PREREQUISITES

This module requires C<strict>, C<Exporter>, and C<LWP>.

=head1 EXPORT

None.

=head1 CONSTRUCTOR

=head2 C<new(options)>

Creates a new Business::CanadaPost object.  Different objects available are:

=over 8

=item language

'en' for English, and 'fr' for French. (Default: en)

=item frompostalcode

This is used to override the setting in our sell online profile for the from
address you would be shipping from.  Format is A1A1A1 (A being any upper-case
character between A-Z, and 1 being any digit 0-9)

If not specified, it will default to your setting in your Canada Post Sell
Online(tm) profile.

=item turnaroundtime

Your turnaround time in hours.  This is the amount of time between receiving
the order and shipping it out.  It is used to create a shipping and delivery
date for the item.  If none is specified, it will default to what you have set
in your profile.

If you have nothing set in your profile, it will assume you are shipping next-day.

(Default: none)

=item merchantid

This is your merchant ID assigned to you by Canada Post.  It usually begins with
CPC_.  You can use CPC_DEMO_XML if you're testing and using Canada Post's test
servers. (Default: none.  You need to set this or the module will return a fatal
error.)

=item totalprice

Total value of the shipment you're mailing.  This is used to calculate whether or
not a signature will be required, and whether it will need to include more insurance
to cover the item (beyond the $100 included in the original shipment.) (Default: 0.00)

=item units

Possible values are 'metric' and 'imperial'.

If set to metric, you will be specifying height, length, and width in cm, and
weight in kg.

If set to imperial, you will be specifying height, length, and width in in, and
weight in lb.

(Default: metric)

=item testing

Possible values: 1 or 0.

Specifies whether you're using a production account, or a testing account.  If you're
in testing mode, you'll be connecting to Canada Post's test servers, which run on
less stable hardware, on a slower link to the Internet, and are rate-throttled.

(Default: 0)

=item items

An array containing the items in your shipment.  Array elements are:

(quantity, weight, length, width, height, description, readytoship [1 or 0])

readytoship specifies that you have the item already boxed or prepared for shipment.

If this is set to 0, then Canada Post server's will calculate the most appropriate box
listed in your account profile, and use it for its dimensions and shipping cost.

=back

=head1 OBJECT METHODS

Most errors are fatal.  The tool tries to guess for you if a value seems
out of whack.

=head2 C<geterror>

Used to fetch the error set when a function return 0 for failure.

Example:

	$object->getrequest or print "Error: " . $object->geterror() . "\n";

=head2 C<setlanguage>

Used to change the language.

Example:

	$object->setlanguage('fr'); # changes messages to french.

=head2 C<settocity>

Specifies city being shipped to.

Example:

	$object->settocity('New York');

=head2 C<settesting>

Specifies whether account is in testing.

Example:

	$object->settesting(1);

=head2 C<setcountry>

Specifies country being mailed to.

Example:

	$object->setcountry('United States');

=head2 C<setmerchantid>

Specifies Canada Post merchant ID.

Example:

	$object->setmerchantid('CPC_DEMO_XML');

=head2 C<setunits>

Specifies imperial or metric measurements.

Example:

	$object->setunits('imperial');

=head2 C<setfrompostalcode>

Specifies postal code item is being shipped from.

Example:

	$object->setfrompostalcode(''); # will reset postal code back to default set in canada post profile

=head2 C<settopostalcode>

Specifies postal code/zip code item is being shipped to.

Example:

	$object->settopostalcode('N2G5M4');

=head2 C<setprovstate>

Specifies province/state being shipped to.

Example:

	$object->settopostalcode('Ontario');

=head2 C<setturnaroundtime>

Specifies turnaround time in hours.

Example:

	$object->setturnaroundtime(24);

=head2 C<settotalprice>

Specifies total value of items being shipped.

Example:

	$object->settotalprice(5.50);

=head2 C<additem>

Adds an item to be shipped to the request.

Example:

	$object->additem(length => 5,
			 height => 3,
			 width  => 2,
			 weight => 5,
			 description => "box of cookies",
			 readytoship => 1,
			 quantity => 1);

Weight, length, height, and width are the only requirements.

If not specified, quantity will default to 1, readytoship will
default to 0, and description will default to an empty string.

=head2 C<getrequest>

Builds request, sends it to Canada Post, and parses the results.

Example:

	$object->getrequest();

returns 1 on success.

=head2 C<getoptioncount>

Returns number of available shipping options.

Example:

	my $available_options = $object->getoptioncount();

=head2 C<getsignature>

Returns 1 or 0 based on whether or not a signature would be required for these deliveries.

Example:

	my $signature_required = $object->getsignature();

=head2 C<getinsurance>

Returns 1 or 0 based on whether or not extra insurance coverage is required (and included) in prices.

Example:

	my $insurance_included = $object->getinsurance();

=head2 C<getshipname>

Receives an option number between 1 and $object->getoptioncount() and returns that
option's name.

Example:

	print "First option available is: " . $object->getshipname(1) . "\n";

=head2 C<getshiprate>

Operates the same as C<getshipname>, but returns cost of that shipping method.

Example:

	print "First option would cost: " . $object->getshiprate(1) . " to ship.\n";

returns 1 on success.

=head2 C<getshipdate>

Operates the same as C<getshipname>, but returns assumed shipment date.

Example:

	print "Item would be shipped out on " . $object->getshipdate(1) . "\n";

=head2 C<getdelvdate>

Operates the same as C<getshipname>, but returns when the approximate
delivery date would be based on a shipping date of $object->getshipdate();

Example:

	print "Assuming a delivery date of " . $object->getshipdate(1) .
		", this item would arrive on: " . $object->getdelvdate(1) . "\n";

=head2 C<getdayofweek>

Operates the same as C<getshipname>, but returns which day of the week
$object->getdelvdate() lands on numerically. (1 .. 6; 1 == Sunday,
6 == Saturday)

Example:

	print "Your item would likely be delivered on the " .
		$object->getdayofweek(1) . " day of the week.\n";

=head2 C<getnextdayam>

Operates the same as C<getshipname>, but returns whether or not
the current option provides for next day AM delivery service.

Example:

	printf("This item is %savailable for next day delivery\n",
			$object->getnextdayam(1) == 1 ? '' : 'NOT ');

=head2 C<getestshipdays>

Operates the same as C<getshipname>, but returns estimated
number of days required to ship the item.

Example:

	print "This shipping method would take approximately: " . $object->getestshipdays() .
		" days to arrive.\n";

=head2 C<getconfirmation>

Returns whether or not delivery confirmation is included in price quotes.

Example:

	my $confirmation_included = $object->getconfirmation();

=head2 C<getcomments>

Returns any extra comments Canada Post might include with your quote.

Example:

	my $extra_info = $object->getcomments();

=head1 SEE ALSO

For more information on how Canada Post's XML shipping system works, please
see http://206.191.4.228/DevelopersResources

=head1 AUTHORS

=over 4

=item *

Justin Wheeler

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Justin Wheeler.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__


