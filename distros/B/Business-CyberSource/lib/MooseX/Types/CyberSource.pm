package MooseX::Types::CyberSource;
use strict;
use warnings;
use Module::Runtime 'use_module';
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use MooseX::Types -declare => [
    qw(
      AVSResult
      ElectronicVerificationResult
      CardTypeCode
      CountryCode
      CvIndicator
      CvResults
      DCCIndicator

      Decision
      CommerceIndicator
      Items

      Item
      Card
      PurchaseTotals
      Service
      AuthService
      AuthReversalService
      CaptureService
      CreditService
      TaxService
      BillTo
      ShipTo
      BusinessRules
      InvoiceHeader
      OtherTax
      ShipFrom

      ResPurchaseTotals
      AuthReply
      TaxReply
      DCCReply
      Reply

      TaxReplyItems
      TaxReplyItem

      RequestID

      ExpirationDate

      DateTimeFromW3C

      Client

      ShippingMethod

      _VarcharOne
      _VarcharSeven
      _VarcharTen
      _VarcharFifteen
      _VarcharTwenty
      _VarcharFifty
      _VarcharSixty
      )
];

use MooseX::Types::Common::Numeric
  qw( PositiveOrZeroNum                       );
use MooseX::Types::Common::String qw( NonEmptySimpleStr SimpleStr             );
use MooseX::Types::Moose qw( Int Num Str HashRef ArrayRef            );
use MooseX::Types::Locale::Country
  qw( Alpha2Country Alpha3Country CountryName );
use MooseX::Types::DateTime qw(                                         );
use MooseX::Types::DateTime::W3C qw( DateTimeW3C                             );

my $varchar_message = 'string is empty or longer than ';
my $num_message = 'value is non Num, empty or longer than ';

enum Decision, [qw( ACCEPT REJECT ERROR REVIEW )];

enum CommerceIndicator, [
    qw(
      aesk
      aesk_attempted
      install
      install_internet
      internet
      js
      js_attempted
      moto
      moto_cc
      recurring
      recurring_internet
      retail
      spa
      spa_failure
      vbv
      vbv_attempted
      vbv_failure
      )
];

# can't find a standard on this, so I assume these are a cybersource thing
enum CardTypeCode, [
    qw(
      001
      002
      003
      004
      005
      006
      007
      014
      021
      024
      031
      033
      034
      035
      036
      037
      039
      040
      042
      043
      )
];

enum CvIndicator, [qw( 0 1 2 9 )];

enum CvResults, [ qw( D I M N P S U X 1 2 3 ), '' ];

enum AVSResult, [qw( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 1 2 )];

enum ElectronicVerificationResult, [qw( N P R S U Y 2)];

enum ShippingMethod,
  [qw(lowcost sameday oneday twoday threeday pickup other none)];

my $prefix = 'Business::CyberSource::';
my $req    = $prefix . 'RequestPart::';
my $res    = $prefix . 'ResponsePart::';

my $itc = $req . 'Item';
my $ptc = $req . 'PurchaseTotals';
my $cdc = $req . 'Card';
my $btc = $req . 'BillTo';
my $stc = $req . 'ShipTo';
my $brc = $req . 'BusinessRules';
my $ihc = $req . 'InvoiceHeader';
my $otc = $req . 'OtherTax';
my $sfc = $req . 'ShipFrom';
my $svc = $req . 'Service';

my $azs = $svc . '::Auth';
my $ars = $svc . '::AuthReversal';
my $cps = $svc . '::Capture';
my $cds = $svc . '::Credit';
my $txs = $svc . '::Tax';

my $res_pt_c = $res . 'PurchaseTotals';
my $res_ar_c = $res . 'AuthReply';
my $res_re_c = $res . 'Reply';
my $res_dc_c = $res . 'DCCReply';
my $res_tr_c = $res . 'TaxReply';
my $res_ti_c = $res . 'TaxReply::Item';

my $client = 'Business::CyberSource::Client';

class_type Item,                { class => $itc };
class_type PurchaseTotals,      { class => $ptc };
class_type Service,             { class => $svc };
class_type Card,                { class => $cdc };
class_type BillTo,              { class => $btc };
class_type ShipTo,              { class => $stc };
class_type BusinessRules,       { class => $brc };
class_type InvoiceHeader,       { class => $ihc };
class_type OtherTax,            { class => $otc };
class_type ShipFrom,            { class => $sfc };
class_type AuthService,         { class => $azs };
class_type AuthReversalService, { class => $ars };
class_type CaptureService,      { class => $cps };
class_type CreditService,       { class => $cds };
class_type TaxService,          { class => $txs };

class_type ResPurchaseTotals, { class => $res_pt_c };
class_type AuthReply,         { class => $res_ar_c };
class_type Reply,             { class => $res_re_c };
class_type DCCReply,          { class => $res_dc_c };
class_type TaxReply,          { class => $res_tr_c };
class_type TaxReplyItem,      { class => $res_ti_c };

class_type Client, { class => $client };

coerce Item,                from HashRef, via { use_module($itc)->new($_) };
coerce PurchaseTotals,      from HashRef, via { use_module($ptc)->new($_) };
coerce Service,             from HashRef, via { use_module($svc)->new($_) };
coerce AuthService,         from HashRef, via { use_module($azs)->new($_) };
coerce AuthReversalService, from HashRef, via { use_module($ars)->new($_) };
coerce CaptureService,      from HashRef, via { use_module($cps)->new($_) };
coerce CreditService,       from HashRef, via { use_module($cds)->new($_) };
coerce TaxService,          from HashRef, via { use_module($txs)->new($_) };
coerce Card,                from HashRef, via { use_module($cdc)->new($_) };
coerce BillTo,              from HashRef, via { use_module($btc)->new($_) };
coerce ShipTo,              from HashRef, via { use_module($stc)->new( $_ ) };
coerce BusinessRules,       from HashRef, via { use_module($brc)->new($_) };
coerce InvoiceHeader,       from HashRef, via { use_module($ihc)->new($_) };
coerce OtherTax,            from HashRef, via { use_module($otc)->new($_) };
coerce ShipFrom,            from HashRef, via { use_module($sfc)->new($_) };
coerce ResPurchaseTotals, from HashRef, via { use_module($res_pt_c)->new($_) };
coerce AuthReply,         from HashRef, via { use_module($res_ar_c)->new($_) };
coerce TaxReply,          from HashRef, via { use_module($res_tr_c)->new($_) };
coerce DCCReply,          from HashRef, via { use_module($res_dc_c)->new($_) };
coerce TaxReplyItem,      from HashRef, via { use_module($res_ti_c)->new($_) };
coerce Reply,             from HashRef, via { use_module($res_re_c)->new($_) };
coerce Client,            from HashRef, via { use_module($client)->new($_) };

subtype CountryCode,     as Alpha2Country;
subtype ExpirationDate,  as MooseX::Types::DateTime::DateTime;
subtype DateTimeFromW3C, as MooseX::Types::DateTime::DateTime;

subtype TaxReplyItems,   as ArrayRef [TaxReplyItem];
subtype Items,           as ArrayRef [Item];

coerce CountryCode, from Alpha3Country, via {
    use_module('Locale::Code');

    return uc Locale::Code::country_code2code(
        $_,
        Locale::Code::LOCALE_CODE_ALPHA_3(),
        Locale::Code::LOCALE_CODE_ALPHA_2(),
    );
};

coerce CountryCode, from CountryName, via {
    use_module('Locale::Code');
    return
      uc Locale::Code::country_code2code( $_,
        Locale::Code::LOCALE_CODE_ALPHA_2(),
      );
};

enum DCCIndicator, [qw( 1 2 3 )];

coerce ExpirationDate, from HashRef, via {
    return DateTime->last_day_of_month( %{$_} );
};

subtype RequestID, as NonEmptySimpleStr,
  where { length $_ <= 29 },
  message { $varchar_message . '29' };

coerce TaxReplyItems, from ArrayRef [HashRef], via {
    my $items = $_;

    my @items = map { use_module($res_ti_c)->new($_) } @{$items};
    return \@items;
};

coerce Items, from ArrayRef [HashRef], via {
    my $items = $_;

    my @items = map { use_module($itc)->new($_) } @{$items};
    return \@items;
};

coerce DateTimeFromW3C, from DateTimeW3C, via {
    return use_module('DateTime::Format::W3CDTF')->new->parse_datetime($_);
};

subtype _VarcharOne, as NonEmptySimpleStr,
  where { length $_ <= 1 },
  message { $varchar_message . '1' };

subtype _VarcharSeven, as NonEmptySimpleStr,
  where { length $_ <= 7 },
  message { $varchar_message . '7' };

subtype _VarcharTen, as SimpleStr,
  where { length $_ <= 10 },
  message { $varchar_message . '10' };

subtype _VarcharFifteen, as SimpleStr,
	where { length $_ <= 15 },
	message { $varchar_message . '15' };

subtype _VarcharTwenty, as NonEmptySimpleStr,
  where { length $_ <= 20 },
  message { $varchar_message . '20' };

subtype _VarcharFifty, as NonEmptySimpleStr,
  where { length $_ <= 50 },
  message { $varchar_message . '50' };

subtype _VarcharSixty, as NonEmptySimpleStr,
  where { length $_ <= 60 },
  message { $varchar_message . '60' };

1;

# ABSTRACT: Moose Types specific to CyberSource

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::CyberSource - Moose Types specific to CyberSource

=head1 VERSION

version 0.010008

=head1 SYNOPSIS

	{
		package My::CyberSource::Response;
		use Moose;
		use MooseX::Types::CyberSource qw( Decision );

		has decision => (
			is => 'ro',
			isa => Decision,
		);
		__PACKAGE__->meta->make_immutable;
	}

	my $response = My::CyberSource::Response->new({
		decison => 'ACCEPT'
	});

=head1 DESCRIPTION

This module provides CyberSource specific Moose Types.

=begin Pod::Coverage

LOCALE_CODE_ALPHA_2

LOCALE_CODE_ALPHA_3

=end Pod::Coverage

=head1 TYPES

=over

=item * C<Client>

L<Business::CyberSource::Client>

=item * C<Decision>

Base Type: C<enum>

CyberSource Response Decision

=item * C<CardTypeCode>

Base Type: C<enum>

Numeric codes that specify Card types. Codes denoted with an asterisk* are
automatically detected when using

=item * C<CommerceIndicator>

Base Type: C<enum>

Valid strings for for use in in the commerceIndicator field.

=item * C<CvResults>

Base Type: C<enum>

Single character code that defines the result of having sent a CVN. See
L<CyberSource's Documentation on Card Verification Results
|http://www.cybersource.com/support_center/support_documentation/quick_references/view.php?page_id=421>
for more information.

=item * C<AVSResults>

Base Type: C<enum>

Single character code that defines the result of having sent a CVN. See
L<CyberSource's Documentation on AVS Results
|http://www.cybersource.com/support_center/support_documentation/quick_references/view.php?page_id=423>
for more information.

=item * C<DCCIndicator>

Base Type: C<enum>

Single character code that defines the DCC status

=over

=item * C<1>

Converted - DCC is being used.

=item * C<2>

Non-convertible - DCC cannot be used.

=item * C<3>

Declined - DCC could be used, but the customer declined it.

=back

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hostgator/business-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Caleb Cushing <xenoterracide@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
