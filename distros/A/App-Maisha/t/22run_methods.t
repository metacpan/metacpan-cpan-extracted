#!/usr/bin/perl -w
use strict;

use App::Maisha::Shell;

use vars qw(@commands);

BEGIN {
    @commands = qw/
        followers
        friends
        friends_timeline
        ft
        pt
        public_timeline
        say
        update
        replies
        re
        direct_messages
        dm
        send_message
        send
        sm
        user
        user_timeline
        ut
        follow
        unfollow

        about
        version
        debug

        help
        connect
        disconnect
        use
        exit
        quit
        q
    /;
}

my $tests = (2 + 3 * @commands);
use Test::More tests => (2 + 3 * @commands);

my $obj;
ok( $obj = App::Maisha::Shell->new(), "got object" );
isa_ok($obj,'App::Maisha::Shell');
$obj->networks('');

for my $k ( @commands ) {
    for my $m (qw(run)) {
        my $j = "${m}_$k";
        my $label = "[$j]";
        SKIP: {
            ok( $obj->can($j), "$label can" ) or skip "'$j' method missing", 1;


            if($k =~ /^(exit|quit|q|connect|disconnect|use|help)$/) {
                ok(1);
                ok(1);
                next;
            }

            my $ret = eval { $obj->$j() };
            is( $@,  '', "no exception for '$j'" );

            if($k =~ /^(debug|about|version)$/) {
               is( $ret, 1, "return value for '$j'" );
            } else {
               is( $ret, undef, "return value for '$j'" );
            }
        }
    }
}
