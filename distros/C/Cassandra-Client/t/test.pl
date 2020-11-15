use v5.10;
use warnings;
use strict;
use blib;
use Cassandra::Client;
use Devel::Peek;

my $client= Cassandra::Client->new(
    contact_points => ['localhost'],
    authentication => S2SAuth->new(
        username => 'cassandra',
        password => 'cassandra',
    ),
);
$client->connect;
Dump($client->execute("LIST ALL;"));

package S2SAuth;
use 5.010;
use strict;
use warnings;
use Devel::Peek;

sub new {
    my ($class, %args)= @_;

    return bless {
        username => $args{username},
        password => $args{password},
    }, $class;
}

sub begin {
    my ($self, $authenticator)= @_;
    return bless {
        %$self,
        authenticator => $authenticator,
    }, ref($self);
}

sub evaluate {
    my ($self, $callback, $challenge)= @_;
    if ($self->{authenticator} eq 'org.apache.cassandra.auth.PasswordAuthenticator') {
        my $user= $self->{username};
        my $pass= $self->{password};
        utf8::encode($user) if utf8::is_utf8($user);
        utf8::encode($pass) if utf8::is_utf8($pass);
        return $callback->(undef, "\0$user\0$pass");
    }

    if ($self->{authenticator} eq 'com.booking.cassandra.plugins.BookingS2SAuthenticator') {
        if (!$challenge) {
            return $callback->(undef, "S2S:request-service");

        } else {
            use HTTP::Tiny;
            my $response= HTTP::Tiny->new->get('http://localhost:228/s2s_auth/issue_token/' . $challenge);
            return $callback->(undef, "S2S:token:$response->{content}");
        }
    }

    ...
}

sub success {
    my ($self)= @_;
    # Ignored
}

1;
