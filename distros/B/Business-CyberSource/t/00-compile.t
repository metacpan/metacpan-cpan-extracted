use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 66 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Business/CyberSource.pm',
    'Business/CyberSource/Client.pm',
    'Business/CyberSource/Exception.pm',
    'Business/CyberSource/Exception/AttributeIsRequiredNotToBeSet.pm',
    'Business/CyberSource/Exception/ItemsOrTotal.pm',
    'Business/CyberSource/Exception/NotACreditCard.pm',
    'Business/CyberSource/Exception/Response.pm',
    'Business/CyberSource/Exception/SOAPFault.pm',
    'Business/CyberSource/Exception/UnableToDetectCardTypeCode.pm',
    'Business/CyberSource/Factory/Request.pm',
    'Business/CyberSource/Factory/Response.pm',
    'Business/CyberSource/Factory/Rule.pm',
    'Business/CyberSource/Message.pm',
    'Business/CyberSource/MessagePart.pm',
    'Business/CyberSource/Request.pm',
    'Business/CyberSource/Request/AuthReversal.pm',
    'Business/CyberSource/Request/Authorization.pm',
    'Business/CyberSource/Request/Capture.pm',
    'Business/CyberSource/Request/Credit.pm',
    'Business/CyberSource/Request/DCC.pm',
    'Business/CyberSource/Request/FollowOnCredit.pm',
    'Business/CyberSource/Request/Role/BillingInfo.pm',
    'Business/CyberSource/Request/Role/CreditCardInfo.pm',
    'Business/CyberSource/Request/Role/DCC.pm',
    'Business/CyberSource/Request/Role/TaxService.pm',
    'Business/CyberSource/Request/Sale.pm',
    'Business/CyberSource/Request/StandAloneCredit.pm',
    'Business/CyberSource/RequestPart/BillTo.pm',
    'Business/CyberSource/RequestPart/BusinessRules.pm',
    'Business/CyberSource/RequestPart/Card.pm',
    'Business/CyberSource/RequestPart/InvoiceHeader.pm',
    'Business/CyberSource/RequestPart/Item.pm',
    'Business/CyberSource/RequestPart/OtherTax.pm',
    'Business/CyberSource/RequestPart/PurchaseTotals.pm',
    'Business/CyberSource/RequestPart/Service.pm',
    'Business/CyberSource/RequestPart/Service/Auth.pm',
    'Business/CyberSource/RequestPart/Service/AuthReversal.pm',
    'Business/CyberSource/RequestPart/Service/Capture.pm',
    'Business/CyberSource/RequestPart/Service/Credit.pm',
    'Business/CyberSource/RequestPart/Service/Tax.pm',
    'Business/CyberSource/RequestPart/ShipFrom.pm',
    'Business/CyberSource/RequestPart/ShipTo.pm',
    'Business/CyberSource/Response.pm',
    'Business/CyberSource/Response/Role/Amount.pm',
    'Business/CyberSource/Response/Role/AuthCode.pm',
    'Business/CyberSource/Response/Role/Base.pm',
    'Business/CyberSource/Response/Role/DCC.pm',
    'Business/CyberSource/Response/Role/ElectronicVerification.pm',
    'Business/CyberSource/Response/Role/ProcessorResponse.pm',
    'Business/CyberSource/Response/Role/ReasonCode.pm',
    'Business/CyberSource/Response/Role/ReconciliationID.pm',
    'Business/CyberSource/Response/Role/RequestDateTime.pm',
    'Business/CyberSource/ResponsePart/AuthReply.pm',
    'Business/CyberSource/ResponsePart/DCCReply.pm',
    'Business/CyberSource/ResponsePart/PurchaseTotals.pm',
    'Business/CyberSource/ResponsePart/Reply.pm',
    'Business/CyberSource/ResponsePart/TaxReply.pm',
    'Business/CyberSource/ResponsePart/TaxReply/Item.pm',
    'Business/CyberSource/Role/Currency.pm',
    'Business/CyberSource/Role/ForeignCurrency.pm',
    'Business/CyberSource/Role/MerchantReferenceCode.pm',
    'Business/CyberSource/Role/Traceable.pm',
    'Business/CyberSource/Rule.pm',
    'Business/CyberSource/Rule/ExpiredCard.pm',
    'Business/CyberSource/Rule/RequestIDisZero.pm',
    'MooseX/Types/CyberSource.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


