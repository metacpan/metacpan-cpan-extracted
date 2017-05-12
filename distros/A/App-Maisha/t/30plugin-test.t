#!/usr/bin/perl -w
use strict;

use Test::More tests => 30;
use App::Maisha::Plugin::Test;

ok( my $obj = App::Maisha::Plugin::Test->new(), "got object" );
isa_ok($obj,'App::Maisha::Plugin::Test');

my $ret = $obj->login({username => 'blah', password => 'blah'});
is($ret, 1, '.. login done');

my $api = $obj->api();
isa_ok($api,'App::Maisha::Plugin::Test');

foreach my $k ( qw/
    followers
    friends
    friends_timeline
    public_timeline
    update

    replies
    direct_messages_from
    direct_messages_to
    send_message

    user
    user_timeline
    follow
    unfollow

/ ){
  for my $m (qw(api)) {
    my $j = "${m}_$k";
    my $label = "[$j]";
    SKIP: {
      ok( $obj->can($j), "$label can" ) or skip "'$j' method missing", 2;
      is($obj->$j(), undef, "$label returns nothing" );
    }
  };
}
