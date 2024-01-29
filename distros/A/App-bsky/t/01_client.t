use Test2::V0;
use v5.38;
#
use lib '../lib';
use App::bsky;
use Path::Tiny;
use Test2::Tools::Warnings qw[warns];
use Text::Wrap;
use Capture::Tiny;
#
my $tmp = Path::Tiny->tempfile('.bsky.XXXXX');
subtest 'internal say/err' => sub {
    my $client = App::bsky::CLI->new( config_file => $tmp );
    my ( $stdout, $stderr, $count ) = Capture::Tiny::capture(
        sub {
            $client->run(qw[config wrap 10]);
            $client->say( 'XXXXX YYY A ' x 10 );
            $client->err( 'Y' x 50 );
        }
    );
    like $stdout, qr[^A XXXXX$]m, 'wraps';
    like $stderr, qr[^Y{50}$]m,   'does not wrap without whitespace';
    ( $stdout, $stderr, $count ) = Capture::Tiny::capture(
        sub {
            $client->run(qw[config wrap 10]);
            $client->say("    Indent\nTry");
        }
    );
    like $stdout, qr[^    Try$]m, 'indents';
};
my ( @err, @say );
my $mock = mock 'App::bsky::CLI' => (
    override => [
        err => sub ( $self, $msg, $fatal //= 0 ) {
            note $msg;
            push @err, $msg;
            !$fatal;
        },
        say => sub ( $self, $msg, @etc ) {
            $msg = @etc ? sprintf $msg, @etc : $msg;
            note $msg;
            push @say, $msg;
            1;
        }
    ]
);
{
    no experimental 'signatures';

    sub is_err(&) {
        my $code = shift;
        @err = ();
        $code->();
        my $msg = join "\n", @say;
        note $msg;
        wantarray ? @say : $msg if @say;
    }

    sub is_say(&) {
        my $code = shift;
        @say = ();
        $code->();
        return 0 if !$say[0];
        my $msg = join "\n", @say;
        note $msg;
        wantarray ? @say : $msg if @say;
    }
}
#
sub client { CORE::state $client //= App::bsky::CLI->new( config_file => $tmp ); $client; }
isa_ok client(), ['App::bsky::CLI'];
#
ok !client->run(),                     '(no params)';
ok !client->run('fdsaf'),              'fdsaf';
ok client->run('-V'),                  '-V';
ok client->run('--version'),           '--version';
ok client->run('-h'),                  '-h';
ok client->run('help'),                'help';
ok client->run(qw[help show-profile]), 'config show-profile';
ok client->run('config'),              'config';
ok !client->run(qw[config fake]),      'config fake';
ok client->run(qw[config wrap 100]),   'config wrap 100';
is is_say { client->run(qw[config wrap]) }, 100, 'config wrap == 100';
ok client->run(qw[config wrap 0]), 'config wrap 0';
is is_say { client->run(qw[config wrap]) }, 0, 'config wrap == 0';
#
subtest 'live' => sub {
    my $todo = todo 'Rate limit or another login info error...';
    todo 'using the web... things may go wrong that are not our fault' => sub {
        subtest 'login ... ... (error)' => sub {
            my $client;
            like warning {
                $client = App::bsky::CLI->new( config_file => $tmp )->run(qw[login fake aaaa-aaaa-aaaa-aaaa])
            }, qr[Error creating session], 'warns on bad auth info';
            ok !$client, 'client is undef';
        };
        ok client->run(qw[login atperl.bsky.social qbhd-opac-arvg-j7ol]), 'login ... ...';
        ok client->run(qw[tl]),                                           'timeline';
        like is_say { client->run(qw[tl --json]) },                                qr[^\[\{],              'timeline --json';
        like is_say { client->run(qw[show-profile]) },                             qr[atperl.bsky.social], 'show-profile';
        like is_say { client->run(qw[show-profile --json]) },                      qr[^{],                 'show-profile --json';
        like is_say { client->run(qw[show-profile --handle sankor.bsky.social]) }, qr[sankor.bsky.social], 'show-profile --handle sankor.bsky.social';
        like is_say { client->run(qw[show-profile --json --handle sankor.bsky.social]) }, qr["sankor],
            'show-profile --json --handle sankor.bsky.social';
        like is_say { client->run(qw[show-profile --json -H sankor.bsky.social]) }, qr["sankor], 'show-profile --json -H sankor.bsky.social';
        subtest 'follows' => sub {
            like is_say { client->run(qw[follows]) },                                    qr[atproto.com], 'follows';
            like is_say { client->run(qw[follows --json]) },                             qr[^\[\{],       'follows --json';
            like is_say { client->run(qw[follows --handle sankor.bsky.social]) },        qr[atproto.com], 'follows --handle sankor.bsky.social';
            like is_say { client->run(qw[follows --json --handle sankor.bsky.social]) }, qr["bsky.app"], 'follows --json --handle sankor.bsky.social';
            like is_say { client->run(qw[follows --json -H sankor.bsky.social]) },       qr["bsky.app"], 'follows --json -H sankor.bsky.social';
        };
        subtest 'followers' => sub {    # These tests might fail! I cannot control who follows the test account
            my $todo = todo 'I cannot control who follows the test account';
            like is_say { client->run(qw[followers]) },                             qr[deal.bsky.social], 'followers';
            like is_say { client->run(qw[followers --json]) },                      qr[^\[\{],            'followers --json';
            like is_say { client->run(qw[followers --handle sankor.bsky.social]) }, qr[atproto.com],      'followers --handle sankor.bsky.social';
            like is_say { client->run(qw[followers --json --handle sankor.bsky.social]) }, qr["bsky.app"],
                'followers --json --handle sankor.bsky.social';
            like is_say { client->run(qw[followers --json -H sankor.bsky.social]) }, qr["bsky.app"], 'followers --json -H sankor.bsky.social';
        };
        subtest 'follow/unfollow' => sub {
            skip_all 'sankor.bsky.social is already followed; might be a race condition with another smoker'
                if is_say { client->run(qw[follows]) } =~ qr[sankor.bsky.social];
            skip_all 'sankor.bsky.social is blocked and cannot be followed; might be a race condition with another smoker'
                if is_say { client->run(qw[blocks]) } =~ qr[sankor.bsky.social];
            sleep 1;
            like is_say { client->run(qw[follow sankor.bsky.social]) }, qr[at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.graph.follow],
                'follow sankor.bsky.social';
            sleep 1;
            like is_say { client->run(qw[follows]) }, qr[sankor.bsky.social], 'follows';
            sleep 1;    # sometimes the service has to catch up
            like is_say { client->run(qw[unfollow sankor.bsky.social]) }, qr[at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.graph.follow],
                'unfollow sankor.bsky.social';
            sleep 1;
            unlike is_say { client->run(qw[follows]) }, qr[sankor.bsky.social], 'follows';
            sleep 1;    # sometimes the service has to catch up
            like is_say { client->run(qw[follow did:plc:2lk3pbakx2erxgotvzyeuyem]) },
                qr[at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.graph.follow], 'follow did:plc:2lk3pbakx2erxgotvzyeuyem';
            sleep 1;    # sometimes the service has to catch up
            like is_say { client->run(qw[follows]) }, qr[sankor.bsky.social], 'follows';
            sleep 1;    # sometimes the service has to catch up
            like is_say { client->run(qw[unfollow did:plc:2lk3pbakx2erxgotvzyeuyem]) },
                qr[at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.graph.follow], 'unfollow did:plc:2lk3pbakx2erxgotvzyeuyem';
        };
        todo 'using random images pulled from the web... things may go wrong' => sub {
            like is_say {
                client->run(qw[update-profile --avatar https://cataas.com/cat?width=100 --banner https://cataas.com/cat?width=1000])
            }, qr[did:plc:pwqewimhd3rxc4hg6ztwrcyj], 'update-profile --avatar ... --banner ...';
        };
        subtest 'block/unblock' => sub {
            skip_all 'sankor.bsky.social is already blocked; might be a race condition with another smoker'
                if is_say { client->run(qw[blocks]) } =~ qr[sankor.bsky.social];

            #~ skip_all 'testing!';
            todo 'service might be low updating profile info...' => sub {
                like is_say { client->run(qw[block sankor.bsky.social]) }, qr[at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.graph.block],
                    'block sankor.bsky.social';
            };
            sleep 1;    # sometimes the service has to catch up
            like is_say { client->run(qw[blocks]) }, qr[sankor.bsky.social], 'blocks';
            like is_say { client->run(qw[unblock sankor.bsky.social]) }, qr[at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.graph.block],
                'unblock sankor.bsky.social';
        };
        subtest 'post/like/repost/reposts/delete' => sub {
            like my $uri = is_say { client->run(qw[post Demo]) }, qr[at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.post], 'post Demo';
            sleep 1;    # sometimes the service has to catch up
            ok client->run( 'like', $uri ), 'like at://...';
            sleep 1;
            like is_say { client->run( 'likes', $uri ) }, qr[atperl.bsky.social], 'likes at://...';
            sleep 1;
            ok client->run( 'like', $uri ), 'like at://...';
            sleep 1;
            like my $repost = is_say { client->run( 'repost', $uri ) }, qr[at://did:plc:pwqewimhd3rxc4hg6ztwrcyj/app.bsky.feed.repost],
                'repost at://';
            sleep 1;
            like is_say { client->run( 'reposts', $uri, '--json' ) }, qr[atperl.bsky.social], 'reposts at://... --json';
            ok client->run( 'delete', $repost ), 'delete at://... [delete repost]';
            ok client->run( 'delete', $uri ),    'delete at://... [delete post]';
        };
        like is_say { client->run(qw[thread at://did:plc:qdvyf5jhuxqx667ay7k7nagl/app.bsky.feed.post/3kju327qezs2n]) },
            qr[did:plc:qvzn322kmcvd7xtnips5xaun], 'thread at://...';
        like is_say { client->run(qw[thread at://did:plc:qdvyf5jhuxqx667ay7k7nagl/app.bsky.feed.post/3kju327qezs2n --json]) }, qr[^{],
            'thread --json at://...';
        like is_say { client->run(qw[list-app-passwords]) },        qr[Test Suite - bsky],                'list-app-passwords';
        like is_say { client->run(qw[list-app-passwords --json]) }, qr[^\[\{],                            'list-app-passwords --json';
        like is_say { client->run(qw[notifications]) },             qr[did:plc:],                         'notifications';
        like is_say { client->run(qw[notifications --json]) },      qr[^\[\{],                            'notifications --json';
        like is_say { client->run(qw[show-session]) },              qr[did:plc:pwqewimhd3rxc4hg6ztwrcyj], 'show-session';
        like is_say { client->run(qw[show-session --json]) },       qr[^{],                               'show-session --json';
    }
};
done_testing;
__END__
=pod

=encoding utf-8

=head1 NAME

App::bsky::t - Test

=head1 Commands

Test.

=head2 login

Here we go.

=head2 show-profile

Here we go again.

=cut
