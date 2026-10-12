use v5.40;
use Test2::V0;
use blib;
use File::Temp qw[tempdir];
use Bluesky;

# Unit tests for the session persistence and authentication convenience methods:
#   save_session, load_session, ensure_auth
# A stateful At mock stands in for the network so no live service or STDIN is touched.
my %state;
sub reset_state { %state = () }
sub set_active { $state{active} = $_[0] }

package Mock::SessionObj {    # Simulates a blessed At::Protocol::Session with a _raw method
    sub new { my ( $class, $args ) = @_; bless { $args ? %$args : () }, $class }
    sub _raw { my $self = shift; +{%$self} }
}
my $mock_at = mock 'At' => (
    override => [
        did    => sub {'did:plc:session-mock'},
        host   => sub {'https://bsky.social'},
        resume => sub ( $self, @args ) {
            $state{active} = {
                accessJwt    => $args[0],
                refreshJwt   => $args[1],
                token_type   => $args[2] // 'Bearer',
                dpop_key_jwk => $args[3],
                client_id    => $args[4],
                handle       => $args[5],
                pds          => $args[6],
                scope        => $args[7]
            };
            $state{resumed}++;
            return 1;
        },
        session => sub { $state{active} }
    ]
);
my $bsky = Bluesky->new();

sub read_json {
    open my $fh, '<', $_[0] or die "read $_[0]: $!";
    local $/;
    return JSON::PP::decode_json(<$fh>);
}
subtest 'save_session writes the active session to a JSON file' => sub {
    reset_state();
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = "$dir/session.json";
    set_active(
        {   accessJwt    => 'acc1',
            refreshJwt   => 'ref1',
            token_type   => 'DPoP',
            handle       => 'me.bsky.social',
            dpop_key_jwk => '{"kty":"EC"}',
            client_id    => 'http://localhost',
            pds          => 'me.example.com',
            scope        => 'atproto'
        }
    );
    is $bsky->save_session($file), $bsky, 'save_session returns $self';
    ok -e $file, 'file written';
    my $data = read_json($file);
    is $data->{accessJwt},    'acc1',           'accessJwt persisted';
    is $data->{refreshJwt},   'ref1',           'refreshJwt persisted';
    is $data->{handle},       'me.bsky.social', 'handle persisted';
    is $data->{dpop_key_jwk}, '{"kty":"EC"}',   'dpop key persisted';
    is $data->{scope},        'atproto',        'scope persisted';
};
subtest 'save_session serializes a blessed session via _raw' => sub {
    reset_state();
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = "$dir/session.json";
    set_active( Mock::SessionObj->new( { accessJwt => 'A', refreshJwt => 'R', handle => 'obj.bsky.social' } ) );
    $bsky->save_session($file);
    my $data = read_json($file);
    is $data->{accessJwt}, 'A',               '_raw branch: accessJwt persisted';
    is $data->{handle},    'obj.bsky.social', '_raw branch: handle persisted';
};
subtest 'save_session without an active session carps and writes nothing' => sub {
    reset_state();
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = "$dir/session.json";
    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        is $bsky->save_session($file), undef, 'returns undef';
    }
    ok !-e $file, 'no file written';
    like join( '', @warn ), qr/No active session/, 'warns';
};
subtest 'load_session resumes from a stored config' => sub {
    reset_state();
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = "$dir/session.json";
    open my $fh, '>', $file or die $!;
    print {$fh} '{"accessJwt":"sto1","refreshJwt":"str1","token_type":"DPoP","dpop_key_jwk":"KEY","client_id":"CL",
                 "handle":"me.bsky.social","pds":"pds.example.com","scope":"atproto"}';
    close $fh;
    ok $bsky->load_session($file), 'load_session returns truthy resume result';
    is $state{resumed}, 1, 'resume was called';
    my $active = $state{active};
    is $active->{accessJwt},    'sto1',            'accessJwt passed positionally';
    is $active->{refreshJwt},   'str1',            'refreshJwt passed positionally';
    is $active->{token_type},   'DPoP',            'token_type passed positionally';
    is $active->{dpop_key_jwk}, 'KEY',             'dpop_key_jwk passed positionally';
    is $active->{client_id},    'CL',              'client_id passed positionally';
    is $active->{handle},       'me.bsky.social',  'handle passed positionally';
    is $active->{pds},          'pds.example.com', 'pds passed positionally';
    is $active->{scope},        'atproto',         'scope passed positionally';
};
subtest 'load_session persists rotated tokens after resume' => sub {
    reset_state();
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = "$dir/session.json";
    open my $fh, '>', $file or die $!;
    print {$fh} '{"accessJwt":"OLD","refreshJwt":"OLDREF","token_type":"DPoP","dpop_key_jwk":"K",
                 "client_id":"C","handle":"me.bsky.social","pds":"p","scope":"atproto"}';
    close $fh;
    local *At::resume = sub( $self, @args ) {
        set_active(
            {   accessJwt    => $args[0] . '-rotated',
                refreshJwt   => $args[1] . '-rotated',
                token_type   => 'DPoP',
                dpop_key_jwk => 'K',
                client_id    => 'C',
                handle       => 'me.bsky.social',
                pds          => 'p',
                scope        => 'atproto'
            }
        );
        return 1;
    };
    ok $bsky->load_session($file), 'load_session returns truthy';
    my $data = read_json($file);
    is $data->{accessJwt},  'OLD-rotated',    'rotated accessJwt persisted';
    is $data->{refreshJwt}, 'OLDREF-rotated', 'rotated refreshJwt persisted';
};
subtest 'load_session safely handles missing or unparseable files' => sub {
    reset_state();
    my $dir = tempdir( CLEANUP => 1 );
    is $bsky->load_session("$dir/missing.json"), undef, 'missing file returns undef';
    is $state{resumed} // 0,                     0,     'no resume attempted';
    my $junk = "$dir/junk.json";
    open my $fh, '>', $junk or die $!;
    print {$fh} 'this is not json';
    close $fh;
    is $bsky->load_session($junk), undef, 'garbage file returns undef without dying';
    is $state{resumed} // 0,       0,     'still no resume attempted';
};
subtest 'ensure_auth restores a stored session and re-saves (rotating tokens)' => sub {
    reset_state();
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = "$dir/session.json";
    open my $fh, '>', $file or die $!;
    print {$fh} '{"accessJwt":"OLD","refreshJwt":"OLDREF","token_type":"DPoP","dpop_key_jwk":"K",
                 "client_id":"C","handle":"me.bsky.social","pds":"p","scope":"atproto"}';
    close $fh;
    local *At::resume = sub( $self, @args ) {
        set_active(
            {   accessJwt    => $args[0] . '-rotated',
                refreshJwt   => $args[1] . '-rotated',
                token_type   => 'DPoP',
                dpop_key_jwk => 'K',
                client_id    => 'C',
                handle       => 'me.bsky.social',
                pds          => 'p',
                scope        => 'atproto'
            }
        );
        return 1;
    };
    my $oauth_called = 0;
    local *Bluesky::oauth_helper = sub { $oauth_called++; };
    is $bsky->ensure_auth( file => $file, handle => 'me.bsky.social' ), $bsky, 'returns $self';
    is $oauth_called,                                                   0,     'interactive oauth not needed when session resumes';
    ok -e $file, 'session re-saved after resume';
    my $data = read_json($file);
    is $data->{accessJwt},  'OLD-rotated',    'rotated accessJwt persisted (bug fix)';
    is $data->{refreshJwt}, 'OLDREF-rotated', 'rotated refreshJwt persisted (bug fix)';
};
subtest 'ensure_auth falls back to oauth_helper on first run' => sub {
    reset_state();
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = "$dir/session.json";
    my @oauth_args;
    local *Bluesky::oauth_helper = sub {
        my ( $self, %a ) = @_;
        push @oauth_args, \%a;
        set_active( { accessJwt => 'fresh', refreshJwt => 'freshref', handle => $a{handle}, token_type => 'DPoP' } );
        $a{on_success}->($self) if $a{on_success};
    };
    is $bsky->ensure_auth( file => $file, handle => 'new.bsky.social', scope => 'atproto chat.bsky:send', listen => 0 ), $bsky, 'returns $self';
    is scalar @oauth_args,     1,                        'oauth_helper invoked once';
    is $oauth_args[0]{handle}, 'new.bsky.social',        'handle forwarded';
    is $oauth_args[0]{scope},  'atproto chat.bsky:send', 'scope forwarded';
    is $oauth_args[0]{listen}, 0,                        'listen forwarded';
    ok -e $file, 'session saved from on_success';
    my $data = read_json($file);
    is $data->{accessJwt}, 'fresh',           'freshly minted accessJwt persisted';
    is $data->{handle},    'new.bsky.social', 'handle persisted';
    reset_state();
    local *Bluesky::oauth_helper = sub { die 'should not reach interactive auth' };
    eval { $bsky->ensure_auth( file => "$dir/none.json" ); 1 } or like( $@, qr/handle/, 'dies with guidance when no session and no handle' );
};
#
done_testing();
