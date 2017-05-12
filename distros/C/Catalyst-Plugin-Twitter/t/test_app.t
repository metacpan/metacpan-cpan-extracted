use strict;
use warnings;

use lib qw( lib t );

use Test::More tests => 6;

use Net::Twitter;
use Sub::Override;
use Test::WWW::Mechanize::Catalyst 'TestApp';

# Capture the updates
my $update_args = undef;
my $override    = Sub::Override->new(
    'Net::Twitter::update',
    sub {
        my ( $twitter, $args ) = @_;
        $update_args = $args;
        return 1;
    }
);

# go to the home page
my $mech = Test::WWW::Mechanize::Catalyst->new();
$mech->get_ok('http://localhost/');
is_deeply $update_args, undef, "no update sent yet";

# send an update (as string)
$mech->get_ok('/tweet/as_string');
is_deeply $update_args,    #
    { status => 'as_string' },    #
    "captured update via params";

# send an update (as params)
$mech->get_ok('/tweet?status=params&in_reply_to_status_id=123');
is_deeply $update_args,           #
    { status => 'params', in_reply_to_status_id => 123, },    #
    "captured update via params";

