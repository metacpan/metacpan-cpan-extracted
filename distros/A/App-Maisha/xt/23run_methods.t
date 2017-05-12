#!/usr/bin/perl -w
use strict;

use App::Maisha::Shell;
use Test::Effects;

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

my $tests = (4 + 2 * @commands);
use Test::More tests => (4 + 2 * @commands);

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
                    next;
                }

                if($k =~ /^(about)$/) {
                    effects_ok { $obj->$j() }
                        {
                            return => 1,
                            stdout => qr/Maisha/,
                        }
                    => "Test '$j' response";
                    next;
                }

                if($k =~ /^(version)$/) {
                    effects_ok { $obj->$j() }
                        {
                            return => 1,
                            stdout => qr/Version:/,
                        }
                    => "Test '$j' response";
                    next;
                }

                if($k =~ /^(update|send_message|say|send|sm)$/) {
                    effects_ok { $obj->$j() }
                        {
                            return => undef,
                            stdout => qr/cannot send an empty message/,
                        }
                    => "Test '$j' response";
                    next;
                }

                if($k =~ /^(follow|unfollow|user|user_timeline|ut)$/) {
                    effects_ok { $obj->$j() }
                        {
                            return => undef,
                            stdout => qr/no user specified/,
                        }
                    => "Test '$j' response";
                    next;
                }

                if($k =~ /^(debug)$/) {
                    effects_ok { $obj->$j() }
                        {
                            return => 1,
                            stdout => qr/Please use 'on' or 'off' with debug command/,
                        }
                    => "Test '$j' response";
                    next;
                }

                effects_ok { $obj->$j() }
                    {
                        return => undef,
                        stdout => '',
                    }
                => "Test '$j' response";
        }
    };
}

{
    $obj->cmd('update this is a message');
    effects_ok { $obj->run_update() }
        {
            return => undef,
            stdout => '',
        }
    => 'Test update with message response';

    $obj->cmd('update 1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890');
    effects_ok { $obj->run_update() }
        {
            return => undef,
            stdout => qr/message too long/,
        }
    => 'Test update with long message response';
}
