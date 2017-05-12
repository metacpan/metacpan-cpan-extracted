#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

use Business::Fixflo::Client;

use_ok( 'Business::Fixflo::QuickViewPanel' );
isa_ok(
    my $QuickViewPanel = Business::Fixflo::QuickViewPanel->new(
        'Id'              => 1,
        'client'          => Business::Fixflo::Client->new(
            username      => 'foo',
            password      => 'bar',
            custom_domain => 'baz',
        ),
    ),
    'Business::Fixflo::QuickViewPanel'
);

can_ok(
    $QuickViewPanel,
    qw/
		url
		get
		to_hash
		to_json

        issue_summary
        issue_status_summary

        DataTypeName
        Explanation
        QVPTypeId
        Title
        Url
    /,
);

no warnings 'redefine';
*Business::Fixflo::Client::api_get = sub { [{ foo => 'bar' }] };

$QuickViewPanel->DataTypeName( 'IssueSummary' );

ok( ! $QuickViewPanel->issue_status_summary,'issue_status_summary' );
cmp_deeply(
    $QuickViewPanel->issue_summary,
    [{ foo => 'bar' }],
    'issue_summary',
);

cmp_deeply(
    $QuickViewPanel->get,
    [{ foo => 'bar' }],
    'get',
);

done_testing();

# vim: ts=4:sw=4:et
