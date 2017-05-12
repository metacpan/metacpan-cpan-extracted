#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;

# this makes Business::Fixflo::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{FIXFLO_DEBUG} = 1;

use Business::Fixflo::Issue;

use_ok( 'Business::Fixflo' );
isa_ok(
    my $Fixflo = Business::Fixflo->new(
        username      => 'foo',
        password      => 'bar',
        custom_domain => 'baz',
    ),
    'Business::Fixflo'
);

can_ok(
    $Fixflo,
    qw/
        username
        password
        custom_domain
        client
        issues
        agencies
        properties
        issue
        agency
        property
        property_address
    /,
);

foreach my $method ( qw/
    issues agencies properties property_addresses quick_view_panels landlords
/ ) {

    my @items = $method =~ /prop|land/
        ? ( { Address => {} } ) : ( qw/ url1 url2 url3 / );

    no warnings 'redefine';
    *Business::Fixflo::Client::_api_request = sub {
        return $method =~ /quick/
        ? [ {} ]
        : {
            NextURL     => 'foo',
            PreviousURL => 'bar',
            Items       => [ @items ],
        }
    };

    ok( my $Paginator = $Fixflo->$method,"$method" );

    next if $method eq 'quick_view_panels';

    isa_ok( $Paginator,'Business::Fixflo::Paginator' );

    my $class =
          $method eq 'issues'     ? 'Business::Fixflo::Issue'
        : $method eq 'agencies'   ? 'Business::Fixflo::Agency'
        : $method eq 'properties' ? 'Business::Fixflo::Property'
        : $method eq 'landlords'  ? 'Business::Fixflo::Landlord'
        : 'Business::Fixflo::PropertyAddress';

    cmp_deeply(
        $Paginator->objects,
        [
            map { $class->new(
                client => $Fixflo->client,
                ( $method =~ /prop|land/
                    ? ( Address => {} )
                    : ( url     => "url" . $_ )
                )
            ) } ( $method =~ /prop|land/ ? ( 1 ) : ( 1 .. 3 ) ),
        ],
        $method,
    );
}

no warnings 'redefine';
*Business::Fixflo::Client::_api_request = sub {
	return {
        'Id'        => 1,
	}
};

foreach my $method ( qw/
    issue agency property property_address landlord issue_draft issue_draft_media
/ ) {

    my $class =
          $method eq 'issue'    ? 'Business::Fixflo::Issue'
        : $method eq 'agency'   ? 'Business::Fixflo::Agency'
        : $method eq 'property' ? 'Business::Fixflo::Property'
        : $method eq 'landlord' ? 'Business::Fixflo::Landlord'
        : $method eq 'issue_draft'       ? 'Business::Fixflo::IssueDraft'
        : $method eq 'issue_draft_media' ? 'Business::Fixflo::IssueDraftMedia'
        : 'Business::Fixflo::PropertyAddress';

    isa_ok( my $Object = $Fixflo->$method( 1 ),$class );
    is( $Object->Id,1,"$method (Id)" );

    isa_ok( $Object = $Fixflo->$method( 1,1 ),$class );
    is( $Object->Id,1,"$method (Id with external Id)" );
}

done_testing();

# vim: ts=4:sw=4:et
