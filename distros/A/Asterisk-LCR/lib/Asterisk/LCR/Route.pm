#!/usr/bin/perl
=head1 NAME

Asterisk::LCR::Route - Route objects for Asterisk::LCR


=head1 SYNOPSIS

  use Asterisk::LCR::Route;
  my $rate =  Asterisk::LCR::Route->new (
      provider        => 'someprovider',
      connection_fee  => 0,
      first_increment => 30,
      increment       => 6,
      rate            => 10.125,
      currency        => 'EUR',
      label           => 'The Moon - Mobile Services',
  );


=head1 SUMMARY

Represents a rate, i.e. amounts of currency to pay, for a
given destination prefix.

Note that this might not always be true.

For example:

  +262 is supposed to be 'reunion island' but
  +262692 is 'reunion island mobiles'

For this reason, when looking for a rate for a given
destination, LCR engines must find rates with the longest
possible prefix that matches a given number.


=head1 ATTRIBUTES

=head2 connection_fee (numeric scalar)

Fee which might be applied for any successful
call, regardless of its length.

=head2 first_increment (numeric scalar)

Incompressible first length of time billed.

=head2 increment (numeric scalar)

Incompressible subsequent lengths of time billed.

=head2 currency (scalar)

Currency which is used for this rate, i.e. EUR, USD,
GBP...

=head2 rate (numeric scalar)

Amounts of currency per minute

=head2 provider (scalar)

Provider which provides this rate.

=head2 label (scalar)

Destination of this rate. This is a string, not an object.

=head1 METHODS

=cut
package Asterisk::LCR::Route;
use base qw /Asterisk::LCR::Object/;
use warnings;
use strict;

# list of known currencies, taken from
# http://www.xe.com/iso4217.htm
our %CURRENCY = ( 
    AED => 'United Arab Emirates, Dirhams',
    AFA => 'Afghanistan, Afghanis',
    ALL => 'Albania, Leke',
    AMD => 'Armenia, Drams',
    ANG => 'Netherlands Antilles, Guilders (also called Florins)',
    AOA => 'Angola, Kwanza',
    ARS => 'Argentina, Pesos',
    AUD => 'Australia, Dollars',
    AWG => 'Aruba, Guilders (also called Florins)',
    AZM => 'Azerbaijan, Manats',
    BAM => 'Bosnia and Herzegovina, Convertible Marka',
    BBD => 'Barbados, Dollars',
    BDT => 'Bangladesh, Taka',
    BGN => 'Bulgaria, Leva',
    BHD => 'Bahrain, Dinars',
    BIF => 'Burundi, Francs',
    BMD => 'Bermuda, Dollars',
    BND => 'Brunei Darussalam, Dollars',
    BOB => 'Bolivia, Bolivianos',
    BRL => 'Brazil, Brazil Real',
    BSD => 'Bahamas, Dollars',
    BTN => 'Bhutan, Ngultrum',
    BWP => 'Botswana, Pulas',
    BYR => 'Belarus, Rubles',
    BZD => 'Belize, Dollars',
    CAD => 'Canada, Dollars',
    CDF => 'Congo/Kinshasa, Congolese Francs',
    CHF => 'Switzerland, Francs',
    CLP => 'Chile, Pesos',
    CNY => 'China, Yuan Renminbi',
    COP => 'Colombia, Pesos',
    CRC => 'Costa Rica, Colones',
    CSD => 'Serbia, Dinars',
    CUP => 'Cuba, Pesos',
    CVE => 'Cape Verde, Escudos',
    CYP => 'Cyprus, Pounds',
    CZK => 'Czech Republic, Koruny',
    DJF => 'Djibouti, Francs',
    DKK => 'Denmark, Kroner',
    DOP => 'Dominican Republic, Pesos',
    DZD => 'Algeria, Algeria Dinars',
    EEK => 'Estonia, Krooni',
    EGP => 'Egypt, Pounds',
    ERN => 'Eritrea, Nakfa',
    ETB => 'Ethiopia, Birr',
    EUR => 'Euro Member Countries, Euro',
    FJD => 'Fiji, Dollars',
    FKP => 'Falkland Islands (Malvinas), Pounds',
    GBP => 'United Kingdom, Pounds',
    GEL => 'Georgia, Lari',
    GGP => 'Guernsey, Pounds',
    GHC => 'Ghana, Cedis',
    GIP => 'Gibraltar, Pounds',
    GMD => 'Gambia, Dalasi',
    GNF => 'Guinea, Francs',
    GTQ => 'Guatemala, Quetzales',
    GYD => 'Guyana, Dollars',
    HKD => 'Hong Kong, Dollars',
    HNL => 'Honduras, Lempiras',
    HRK => 'Croatia, Kuna',
    HTG => 'Haiti, Gourdes',
    HUF => 'Hungary, Forint',
    IDR => 'Indonesia, Rupiahs',
    ILS => 'Israel, New Shekels',
    IMP => 'Isle of Man, Pounds',
    INR => 'India, Rupees',
    IQD => 'Iraq, Dinars',
    IRR => 'Iran, Rials',
    ISK => 'Iceland, Kronur',
    JEP => 'Jersey, Pounds',
    JMD => 'Jamaica, Dollars',
    JOD => 'Jordan, Dinars',
    JPY => 'Japan, Yen',
    KES => 'Kenya, Shillings',
    KGS => 'Kyrgyzstan, Soms',
    KHR => 'Cambodia, Riels',
    KMF => 'Comoros, Francs',
    KPW => 'Korea (North), Won',
    KRW => 'Korea (South), Won',
    KWD => 'Kuwait, Dinars',
    KYD => 'Cayman Islands, Dollars',
    KZT => 'Kazakhstan, Tenge',
    LAK => 'Laos, Kips',
    LBP => 'Lebanon, Pounds',
    LKR => 'Sri Lanka, Rupees',
    LRD => 'Liberia, Dollars',
    LSL => 'Lesotho, Maloti',
    LTL => 'Lithuania, Litai',
    LVL => 'Latvia, Lati',
    LYD => 'Libya, Dinars',
    MAD => 'Morocco, Dirhams',
    MDL => 'Moldova, Lei',
    MGA => 'Madagascar, Ariary',
    MKD => 'Macedonia, Denars',
    MMK => 'Myanmar (Burma), Kyats',
    MNT => 'Mongolia, Tugriks',
    MOP => 'Macau, Patacas',
    MRO => 'Mauritania, Ouguiyas',
    MTL => 'Malta, Liri',
    MUR => 'Mauritius, Rupees',
    MVR => 'Maldives (Maldive Islands), Rufiyaa',
    MWK => 'Malawi, Kwachas',
    MXN => 'Mexico, Pesos',
    MYR => 'Malaysia, Ringgits',
    MZM => 'Mozambique, Meticais',
    NAD => 'Namibia, Dollars',
    NGN => 'Nigeria, Nairas',
    NIO => 'Nicaragua, Cordobas',
    NOK => 'Norway, Krone',
    NPR => 'Nepal, Nepal Rupees',
    NZD => 'New Zealand, Dollars',
    OMR => 'Oman, Rials',
    PAB => 'Panama, Balboa',
    PEN => 'Peru, Nuevos Soles',
    PGK => 'Papua New Guinea, Kina',
    PHP => 'Philippines, Pesos',
    PKR => 'Pakistan, Rupees',
    PLN => 'Poland, Zlotych',
    PYG => 'Paraguay, Guarani',
    QAR => 'Qatar, Rials',
    ROL => 'Romania, Lei',
    RUB => 'Russia, Rubles',
    RWF => 'Rwanda, Rwanda Francs',
    SAR => 'Saudi Arabia, Riyals',
    SBD => 'Solomon Islands, Dollars',
    SCR => 'Seychelles, Rupees',
    SDD => 'Sudan, Dinars',
    SEK => 'Sweden, Kronor',
    SGD => 'Singapore, Dollars',
    SHP => 'Saint Helena, Pounds',
    SIT => 'Slovenia, Tolars',
    SKK => 'Slovakia, Koruny',
    SLL => 'Sierra Leone, Leones',
    SOS => 'Somalia, Shillings',
    SPL => 'Seborga, Luigini',
    SRD => 'Suriname, Dollars',
    STD => 'São Tome and Principe, Dobras',
    SVC => 'El Salvador, Colones',
    SYP => 'Syria, Pounds',
    SZL => 'Swaziland, Emalangeni',
    THB => 'Thailand, Baht',
    TJS => 'Tajikistan, Somoni',
    TMM => 'Turkmenistan, Manats',
    TND => 'Tunisia, Dinars',
    TOP => 'Tonga, Pa\'anga',
    TRL => 'Turkey, Liras [being phased out]',
    TRY => 'Turkey, New Lira',
    TTD => 'Trinidad and Tobago, Dollars',
    TVD => 'Tuvalu, Tuvalu Dollars',
    TWD => 'Taiwan, New Dollars',
    TZS => 'Tanzania, Shillings',
    UAH => 'Ukraine, Hryvnia',
    UGX => 'Uganda, Shillings',
    USD => 'United States of America, Dollars',
    UYU => 'Uruguay, Pesos',
    UZS => 'Uzbekistan, Sums',
    VEB => 'Venezuela, Bolivares',
    VND => 'Viet Nam, Dong',
    VUV => 'Vanuatu, Vatu',
    WST => 'Samoa, Tala',
    XAF => 'Communauté Financière Africaine BEAC, Francs',
    XAG => 'Silver, Ounces',
    XAU => 'Gold, Ounces',
    XCD => 'East Caribbean Dollars',
    XDR => 'International Monetary Fund (IMF) Special Drawing Rights',
    XOF => 'Communauté Financière Africaine BCEAO, Francs',
    XPD => 'Palladium Ounces',
    XPF => 'Comptoirs Français du Pacifique Francs',
    XPT => 'Platinum, Ounces',
    YER => 'Yemen, Rials',
    ZAR => 'South Africa, Rand',
    ZMK => 'Zambia, Kwacha',
    ZWD => 'Zimbabwe, Zimbabwe Dollars',
);


=head2 $self->validate();

Validates this object to avoid constructing objects which are
in an inconsistent state.

returns 1 if the object validates, 0 otherwise.

=cut
sub validate
{
    my $self = shift;
    my $res  = eval {
        $self->validate_connection_fee()  &
        $self->validate_first_increment() &
        $self->validate_increment()       &
	$self->validate_currency()        &
	$self->validate_rate()            &
	$self->validate_provider()        &
	$self->validate_label()           &
	$self->validate_prefix()
    };
    $@ and do {
        print $@ . "\n\n";
        use Data::Dumper;
        die Dumper ($self);
    };
    
    return $res;
}


=head2 $self->validate_connection_fee();

Validate this object's 'connection_fee' attribute.

returns 1 if the attribute validates, 0 otherwise.

=cut
sub validate_connection_fee
{
    my $self = shift;
    
    my $val  = $self->connection_fee();

    defined $val or do {
        die 'asterisk/lcr/rate/connection_fee/undefined';
	return 0;
    };
    
    is_number ($val) or do { 
        die "asterisk/lcr/rate/connection_fee/not_a_number : $val";
	return 0;
    };

    return 1; 
}


=head2 $self->set_connection_fee ($fee);

Sets the current object's 'connection_fee' attribute.

=cut
sub set_connection_fee
{
    my $self = shift;
    $self->{connection_fee} = shift;
}


=head2 $self->connection_fee();

Returns the current object's 'connection_fee' attribute.

=cut
sub connection_fee
{
    my $self = shift;
    return $self->{connection_fee};
}


=head2 $self->validate_first_increment();

Validate this object's 'first_increment' attribute.

Returns 1 if the attribute validates, 0 otherwise.

=cut
sub validate_first_increment
{
    my $self = shift;
    
    my $val  = $self->first_increment();

    defined $val or do {
        die 'asterisk/lcr/rate/first_increment/undefined';
	return 0;
    };

    is_number ($val) or do { 
        die 'asterisk/lcr/rate/first_increment/not_a_number';
	return 0;
    };

    return 1; 
}


=head2 $self->set_first_increment ($fee);

Sets the current object's 'first_increment' attribute.

=cut
sub set_first_increment
{
    my $self = shift;
    $self->{first_increment} = shift;
}


=head2 $self->first_increment();

Returns the current object's 'first_increment' attribute.

=cut
sub first_increment
{
    my $self = shift;
    return $self->{first_increment};
}


=head2 $self->validate_increment();

Validate this object's 'increment' attribute.

Returns 1 if the attribute validates, 0 otherwise.

=cut
sub validate_increment
{
    my $self = shift;
    
    my $val  = $self->increment();

    defined $val or do {
        die 'asterisk/lcr/rate/increment/undefined';
	return 0;
    };
    
    is_number ($val) or do { 
        die 'asterisk/lcr/rate/increment/not_a_number';
	return 0;
    };

    return 1; 
}



=head2 $self->set_increment ($fee);

Sets the current object's 'increment' attribute.

=cut
sub set_increment
{
    my $self = shift;
    $self->{increment} = shift;
}


=head2 $self->increment();

Returns the current object's 'increment' attribute.

=cut
sub increment
{
    my $self = shift;
    return $self->{increment};
}


=head2 $self->validate_rate();

Validate this object's 'rate' attribute.

Returns 1 if the attribute validates, 0 otherwise.

=cut
sub validate_rate
{
    my $self = shift;
    
    my $val  = $self->rate();

    defined $val or do {
        die 'asterisk/lcr/rate/rate/undefined';
	return 0;
    };
    
    is_number ($val) or do { 
        die 'asterisk/lcr/rate/rate/not_a_number';
	return 0;
    };

    return 1; 
}


=head2 $self->set_rate ($fee);

Sets the current object's 'rate' attribute.

=cut
sub set_rate
{
    my $self = shift;
    $self->{rate} = shift;
}


=head2 $self->rate();

Returns the current object's 'rate' attribute.

=cut
sub rate
{
    my $self = shift;
    return $self->{rate};
}


=head2 $self->validate_currency();

Validate this object's 'currency' attribute.

Returns 1 if the attribute validates, 0 otherwise.

=cut
sub validate_currency
{
    my $self = shift;
    
    my $val  = $self->currency();

    defined $val or do {
        die 'asterisk/lcr/rate/currency/undefined';
	return 0;
    };

    $CURRENCY{$val} or do {
        die 'asterisk/lcr/rate/currency/unknown';
	return 0;
    };

    return 1; 
}


=head2 $self->set_currency ($fee);

Sets the current object's 'currency' attribute.

=cut
sub set_currency
{
    my $self = shift;
    $self->{currency} = shift;
}


=head2 $self->currency();

Returns the current object's 'currency' attribute.

=cut
sub currency
{
    my $self = shift;
    return $self->{currency};
}


=head2 $self->validate_provider();

Validate this object's 'provider' attribute.

Returns 1 if the attribute validates, 0 otherwise.

=cut
sub validate_provider
{
    my $self = shift;
    
    my $val  = $self->provider();

    defined $val or do {
        die 'asterisk/lcr/rate/provider/undefined';
	return 0;
    };

    return 1; 
}


=head2 $self->set_provider ($fee);

Sets the current object's 'provider' attribute.

=cut
sub set_provider
{
    my $self = shift;
    $self->{provider} = shift;
}


=head2 $self->provider();

Returns the current object's 'provider' attribute.

=cut
sub provider
{
    my $self = shift;
    return $self->{provider};
}


=head2 $self->validate_label();

Validate this object's 'label' attribute.

Returns 1 if the attribute validates, 0 otherwise.

=cut
sub validate_label
{
    my $self = shift;
    
    my $val  = $self->label();

    defined $val or do {
        die 'asterisk/lcr/rate/label/undefined';
	return 0;
    };

    return 1; 
}


=head2 $self->set_label ($fee);

Sets the current object's 'label' attribute.

=cut
sub set_label
{
    my $self = shift;
    $self->{label} = shift;
}


=head2 $self->label();

Returns the current object's 'label' attribute.

=cut

sub label
{
    my $self = shift;
    return $self->{label} || '?';
}


=head2 $self->validate_prefix();

Validate this object's 'prefix' attribute.

Returns 1 if the attribute validates, 0 otherwise.

=cut
sub validate_prefix
{
    my $self = shift;
    
    my $val  = $self->prefix();

    defined $val or do {
        die 'asterisk/lcr/rate/prefix/undefined';
	return 0;
    };

    return 1; 
}


=head2 $self->set_prefix ($fee);

Sets the current object's 'prefix' attribute.

=cut
sub set_prefix
{
    my $self = shift;
    $self->{prefix} = shift;
}


=head2 $self->prefix();

Returns the current object's 'prefix' attribute.

=cut
sub prefix
{
    my $self = shift;
    return $self->{prefix};
}


sub is_number
{
    local ($_) = shift;
    if (/^\d+$/) { return 1 }
    if (/^-?\d+$/) { return 1 }
    if (/^[+-]?\d+$/) { return 1 }
    if (/^-?\d+\.?\d*$/) { return 1 }
    if (/^-?(?:\d+(?:\.\d*)?|\.\d+)$/) { return 1 }
    if (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) { return 1 }
    return;
}


1;


__END__
