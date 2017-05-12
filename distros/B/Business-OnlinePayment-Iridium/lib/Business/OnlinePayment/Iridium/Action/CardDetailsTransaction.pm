package Business::OnlinePayment::Iridium::Action::CardDetailsTransaction;

use Moose;

with 'Business::OnlinePayment::Iridium::Action';

has 'OrderID' => (
    isa      => 'Str',
    is       => 'rw',
    required => '1'
);

has 'OrderDescription' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'TransactionType' => (
    isa      => 'Str',
    is       => 'rw',
    required => '1'
);

has 'CardName' => (
    isa      => 'Str',
    is       => 'rw',
    required => '1'
);

has 'CardNumber' => (
    isa      => 'Int',
    is       => 'rw',
    required => '1'
);

has 'ExpireMonth' => (
    isa      => 'Int',
    is       => 'rw',
    required => '1'
);

has 'ExpireYear' => (
    isa      => 'Int',
    is       => 'rw',
    required => '1'
);

has 'CV2' => (
    isa => 'Int',
    is  => 'rw',
);

has 'IssueNumber' => (
    isa => 'Int',
    is  => 'rw',
);

has 'Amount' => (
    isa      => 'Int',
    is       => 'rw',
    required => '1'
);

has 'EchoCardType' => (
    isa      => 'Bool',
    is       => 'rw',
    required => '0'
);

has 'EchoAVSCheckResult' => (
    isa      => 'Bool',
    is       => 'rw',
    required => '0'
);

has 'EchoCV2CheckResult' => (
    isa      => 'Bool',
    is       => 'rw',
    required => '0'
);

has 'EchoAmountReceived' => (
    isa      => 'Bool',
    is       => 'rw',
    required => '0'
);

has 'DuplicateDelay' => (
    isa      => 'Int',
    is       => 'rw',
    required => '0'
);

has 'AVSOverridePolicy' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'CV2OverridePolicy' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'ThreeDSecureOverridePolicy' => (
    isa      => 'Bool',
    is       => 'rw',
    required => '0'
);

has 'Address1' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'Address2' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'Address3' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'Address4' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'City' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'State' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'PostCode' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'CountryCode' => (
    isa      => 'Int',
    is       => 'rw',
    required => '0'
);

has 'EmailAddress' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'PhoneNumber' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has 'PassOutData' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

sub _build__type { return 'CardDetailsTransaction' }

sub template {
    return <<DATA;
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:xsd="http://www.w3.org/2001/XMLSchema"
               xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
  <CardDetailsTransaction xmlns="https://www.thepaymentgateway.net/">
    <PaymentMessage>
      <MerchantAuthentication MerchantID="[% MerchantID %]" Password="[% Password %]" />
      <TransactionDetails Amount="[% Amount %]" CurrencyCode="[% CurrencyCode %]">
        <MessageDetails TransactionType="[% TransactionType %]" />
        <OrderID>[% OrderID %]</OrderID>
        <OrderDescription>[% OrderDescription %]</OrderDescription>
        <TransactionControl>
          [% IF EchoCardType.defined %]<EchoCardType>TRUE</EchoCardType>[% END %]
          [% IF EchoAVSCheckResult.defined %]<EchoAVSCheckResult>TRUE</EchoAVSCheckResult>[% END %]
          [% IF EchoCV2CheckResult.defined %]<EchoCV2CheckResult>TRUE</EchoCV2CheckResult>[% END %]
          [% IF EchoAmountReceived.defined %]<EchoAmountReceived>TRUE</EchoAmountReceived>[% END %]
          [% IF DuplicateDelay.defined %]<DuplicateDelay>[% DuplicateDelay %]</DuplicateDelay>[% END %]
          [% IF AVSOverridePolicy.defined %]<AVSOverridePolicy>[% AVSOverridePolicy %]</AVSOverridePolicy>[% END %]
          [% IF CV2OverridePolicy.defined %]<CV2OverridePolicy>[% CV2OverridePolicy %]</CV2OverridePolicy>[% END %]
          [% IF ThreeDSecureOverridePolicy.defined %]<ThreeDSecureOverridePolicy>FALSE</ThreeDSecureOverridePolicy>[% END %]
        </TransactionControl>
      </TransactionDetails>
      <CardDetails>
        <CardName>[% CardName %]</CardName>
        <CardNumber>[% CardNumber %]</CardNumber>
        <ExpiryDate Month="[% ExpireMonth %]" Year="[% ExpireYear %]" />
        <StartDate Month="[% StartMonth %]" Year="[% StartYear %]" />
        [% IF CV2.defined %]<CV2>[% CV2 %]</CV2>[% END %]
        [% IF IssueNumber.defined %]<IssueNumber>[% IssueNumber %]</IssueNumber>[% END %]
      </CardDetails>
      <CustomerDetails>
        <BillingAddress>
          <Address1>[% Address1 %]</Address1>
          <Address2>[% Address2 %]</Address2>
          <Address3>[% Address3 %]</Address3>
          <Address4>[% Address4 %]</Address4>
          <City>[% City %]</City>
          <State>[% State %]</State>
          <PostCode>[% PostCode %]</PostCode>
          <CountryCode>[% CountryCode %]</CountryCode>
        </BillingAddress>
        <EmailAddress>[% EmailAddress %]</EmailAddress>
        <PhoneNumber>[% PhoneNumber %]</PhoneNumber>
      </CustomerDetails>
      <PassOutData>[% PassOutData %]</PassOutData>
    </PaymentMessage>
  </CardDetailsTransaction>
</soap:Body>
</soap:Envelope>
DATA
}

1;
