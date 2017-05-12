#!perl

use strict;
use warnings;

use Test::Most;
use Test::MockObject;

use Business::GoCardless::Client;

$ENV{GOCARDLESS_DEV_TESTING} = 1;

my $link = '<http://localhost/next>; rel="next", <http://localhost/first>; rel="first", <http://localhost/previous>; rel="previous", <http://localhost/last>; rel="last"';

use_ok( 'Business::GoCardless::Paginator' );
isa_ok(
    my $Paginator = Business::GoCardless::Paginator->new(
        client => Business::GoCardless::Client->new(
            token       => 'foo',
            app_id      => 'bar',
            app_secret  => 'baz',
            merchant_id => 'boz',
        ),
        links   => $link,
        info    => '{"records":15,"pages":2,"links":{"next":2,"last":2}}',
        objects => [ {},{},{} ],
        class   => 'Business::GoCardless::Bill',
    ),
    'Business::GoCardless::Paginator'
);

cmp_deeply(
    $Paginator->info,
    {
        'links' => {
            'last' => 2,
            'next' => 2,
        },
        'pages' => 2,
        'records' => 15,
    },
    'info'
);

# monkey patching LWP here to make this test work without
# having to actually hit the endpoints or use credentials
no warnings 'redefine';
no warnings 'once';
my $mock = Test::MockObject->new;
$mock->mock( 'is_success',sub { 1 } );
$mock->mock( 'header',sub {
    my ( $self,$want ) = @_;
    return {
        'link'         => $link,
        'x-pagination' => '{"records":15,"pages":2,"links":{"next":2,"last":2}}}'
    }->{ lc( $want ) };
} );
$mock->mock( 'content',sub { '[ {},{},{} ]' } );
*LWP::UserAgent::request = sub { $mock };

my @objects = $Paginator->next;
cmp_deeply( \@objects,[ {},{},{} ],'next' );

@objects = $Paginator->previous;
is( scalar( @objects ),3,'previous' );

@objects = $Paginator->first;
is( scalar( @objects ),3,'first' );

@objects = $Paginator->last;
is( scalar( @objects ),3,'last' );

$mock->mock( 'content',sub { '[]' } );
ok( $Paginator->next,'next (again)' );
ok( ! $Paginator->next,'next eventually reaches end' );

done_testing();

# vim: ts=4:sw=4:et
