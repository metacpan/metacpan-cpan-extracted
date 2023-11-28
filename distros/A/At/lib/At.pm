package At 0.02 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use DateTime::Tiny;
    #
    class At 1.00 {
        field $http //= Mojo::UserAgent->can('start') ? At::UserAgent::Mojo->new() : At::UserAgent::Tiny->new();
        method http {$http}
        #
        field $host : param = ();
        #
        field $repo : param = ();

        method repo {
            @_ ? At::Lexicon::AtProto::Repo->new( client => $self, @_ ) : $repo;
        }
        method _repo { $repo = shift; }
        field $server : param = ();
        method server {$server}
        #
        method host {
            return $host if defined $host;
            use Carp qw[confess];
            confess 'You must provide a host or perhaps you wanted At::Bluesky';
        }
        ## Internals
        sub _timestamp {
            my @t = gmtime time;    # standardize around Zulu
            DateTime::Tiny->new( year => $t[5] + 1900, month => $t[4] + 1, day => $t[3], hour => $t[2], minute => $t[1], second => $t[0] );
        }

        sub _now {
            _timestamp()->as_string . 'Z';
        }
        ADJUST {
            require At::Lexicons::app::bsky::feed::post;
            require At::Lexicons::app::bsky::richtext::facet;
            #
            my $host = $self->host;
            $host   = 'https://' . $host unless $host =~ /^https?:/;
            $host   = URI->new($host)    unless builtin::blessed $host;
            $server = At::Lexicon::AtProto::Server->new( client => $self, host => $host );
        }
    }

    class At::Lexicon::AtProto::Server {
        field $client : param;
        field $host : param;

        # https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/
        method createSession (%args) {
            my $session = $client->http->post( sprintf( '%s/xrpc/%s', $client->host, 'com.atproto.server.createSession' ), { content => \%args } );
            $client->http->session($session);
            $client->_repo( At::Lexicon::AtProto::Repo->new( client => $client, did => $client->http->session->did->raw ) );
            $session;
        }

        method describeServer {
            $client->http->get( sprintf( '%s/xrpc/%s', $client->host, 'com.atproto.server.describeServer' ) );
        }
    }

    class At::Lexicon::AtProto::Repo {
        field $client : param;
        field $did : param;
        method did {$did}
        ADJUST {
            $did = At::Protocol::DID->new( uri => $did ) unless builtin::blessed $did
        }

        method createRecord (%args) {    # https://atproto.com/blog/create-post
            use Carp qw[confess];
            $client->http->session // confess 'creating a post requires an authenticated client';
            my $res = $client->http->post( sprintf( '%s/xrpc/%s', $client->host(), 'com.atproto.repo.createRecord' ),
                { content => { repo => $did->raw, %args } } );
            $res->{uri} = URI->new( $res->{uri} ) if defined $res->{uri};
            $res;
        }
    }

    class At::Protocol::DID {    # https://atproto.com/specs/did
        field $uri : param;
        ADJUST {
            use Carp qw[carp croak];
            croak 'malformed DID URI: ' . $uri unless $uri =~ /^did:([a-z]+:[a-zA-Z0-9._:%-]*[a-zA-Z0-9._-])$/;
            use URI;
            $uri = URI->new($1) unless builtin::blessed $uri;
            my $scheme = $uri->scheme;
            carp 'unsupported method: ' . $scheme if $scheme ne 'plc' && $scheme ne 'web';
        };

        method raw {
            'did:' . $uri->as_string;
        }
    }

    class At::Protocol::Session {
        field $accessJwt : param;
        field $did : param;
        field $didDoc : param         = ();    # spec says 'unknown' so I'm just gonna ignore it for now even with the dump
        field $email : param          = ();
        field $emailConfirmed : param = ();
        field $handle : param;
        field $refreshJwt : param;

        # waiting for perlclass to implement accessors with :reader
        method accessJwt {$accessJwt}
        method did       {$did}
        #
        ADJUST {
            $did            = At::Protocol::DID->new( uri => $did ) unless builtin::blessed $did;
            $emailConfirmed = !!$emailConfirmed if defined $emailConfirmed;
        }
    }

    class At::UserAgent {
        method session ( $s = () ) { ...; }

        method get ( $url, $req = () ) {
            ...;
        }

        method post ( $url, $req = () ) {
            ...;
        }
    }

    class At::UserAgent::Tiny : isa(At::UserAgent) {

        # TODO: Error handling
        use HTTP::Tiny;
        use JSON::Tiny qw[decode_json encode_json];
        field $agent : param = HTTP::Tiny->new(
            agent           => sprintf( 'At.pm/%1.2f;Tiny ', $At::VERSION ),
            default_headers => { 'Content-Type' => 'application/json', Accept => 'application/json' }
        );
        field $session : param = ();

        method session ( $s = () ) {
            $s // return $session;
            $session = At::Protocol::Session->new(%$s);
            $agent->{default_headers}{Authorization} = 'Bearer ' . $s->{accessJwt};
        }

        method get ( $url, $req = () ) {
            my $res = $agent->get( $url, defined $req->{content} ? { content => encode_json $req->{content} } : () );
            $res->{content} = decode_json $res->{content} if defined $res->{content};
            return $res->{content};
        }

        method post ( $url, $req = () ) {
            my $res = $agent->post( $url, defined $req->{content} ? { content => encode_json $req->{content} } : () );
            $res->{content} = decode_json $res->{content} if defined $res->{content};
            return $res->{content};
        }
    }

    class At::UserAgent::Mojo : isa(At::UserAgent) {

        # TODO - Required for websocket based Event Streams
        #~ https://atproto.com/specs/event-stream
        # TODO: Error handling
        field $agent : param = sub {
            my $ua = Mojo::UserAgent->new;
            $ua->transactor->name( sprintf( 'At.pm/%1.2f;Mojo ', $At::VERSION ) );
            $ua;
            }
            ->();
        field $session : param = ();

        method session ( $s = () ) {
            $s // return $session;
            $session = At::Protocol::Session->new(%$s);
        }

        method get ( $url, $req = () ) {
            my $res = $agent->get(
                $url,
                defined $session        ? { Authorization => 'Bearer ' . $session->accessJwt } : (),
                defined $req->{content} ? ( json => $req->{content} )                          : ()
            )->result;

            # todo: error handling
            if    ( $res->is_success )  { return $res->json }
            elsif ( $res->is_error )    { say $res->message }
            elsif ( $res->code == 301 ) { say $res->headers->location }
            else                        { say 'Whatever...' }
        }

        method post ( $url, $req = () ) {
            my $res = $agent->post(
                $url,
                defined $session        ? { Authorization => 'Bearer ' . $session->accessJwt } : (),
                defined $req->{content} ? ( json => $req->{content} )                          : ()
            )->result;

            # todo: error handling
            if    ( $res->is_success )  { return $res->json }
            elsif ( $res->is_error )    { say $res->message }
            elsif ( $res->code == 301 ) { say $res->headers->location }
            else                        { say 'Whatever...' }
        }
    }
}
1;
__END__

=encoding utf-8

=head1 NAME

At - The AT Protocol for Social Networking

=head1 SYNOPSIS

    use At;
    use Time::Piece;
    my $at = At->new( host => 'https://fun.example' );
    $at->server->createSession( identifier => 'sanko', password => '1111-aaaa-zzzz-0000' );
    $at->repo->createRecord(
        collection => 'app.bsky.feed.post',
        record     => { '$type' => 'app.bsky.feed.post', text => "Hello world! I posted this via the API.", createdAt => gmtime->datetime . 'Z' }
    );

=head1 DESCRIPTION

The AT Protocol is a 'social networking technology created to power the next generation of social applications.' At.pm
currently supports session creation and simple text posts. It's like day two, so...

At.pm uses perl's new class system which requires perl 5.38.x or better.

=head2 At::Bluesky

    my $bsky = At::Bluesky->new( identifier => 'sanko', password => ... );
    $bsky->post( text => 'Easy!' );

Creates an At object with the host set to C<https://bluesky.social>, loads all the lexicon extensions related to the
social networking site, and exposes a lot of sugar (such as simple post creation).

=head1 Methods

Honestly, to keep to the layout of the underlying protocol, almost everything is handled in members of this class.

=head2 C<new( ... )>

Creates an AT client and initiates an authentication session.

    my $client = At->new( host => 'https://bsky.social' );

Expected parameters include:

=over

=item C<host> - required

Host for the account. If you're using the 'official' Bluesky, this would be 'https://bsky.social' but you'll probably
want C<At::Bluesky-E<gt>new(...)> because that client comes with all the bits that aren't part of the core protocol.

=back

=head2 C<repo( [...] )>

    my $repo = $at->repo; # Grab default
    my $repo = $at->repo( did => 'did:plc:ju7kqxvmz8a8k5bapznf1lto2gkki6miw3' ); # You have permissions?

Returns an AT repository. Without arguments, this returns the repository returned by AT in the session data.

=head2 C<server( )>

Returns an AT service.

=head1 Repo Methods

Repo methods generally require an authorized session. The AT Protocol treats 'posts' and other data as records stored
in repositories.

=head2 C<createRecord( ... )>

Create a new record.

    $at->repo->createRecord(
        collection => 'app.bsky.feed.post',
        record     => { '$type' => 'app.bsky.feed.post', text => "Hello world! I posted this via the API.", createdAt => gmtime->datetime . 'Z' }
    );

Expected parameters include:

=over

=item C<collection> - required

The NSID of the record collection.

=item C<record> - required

Depending on the type of record, this could be anything. It's undefined in the protocol itself.

=back

=head1 Server Methods

Server methods may require an authorized session.

=head2 C<createSession( ... )>

    $at->server->createSession( identifier => 'sanko', password => '1111-2222-3333-4444' );

Expected parameters include:

=over

=item C<identifier> - required

Handle or other identifier supported by the server for the authenticating user.

=item C<password> - required

You know this!

=back

=head2 C<describeServer( )>

Get a document describing the service's accounts configuration.

    $at->server->describeServer();

This method does not require an authenticated session.

=begin todo

=head1 Services

Currently, there are 3 sandbox At Protocol services:

=over

=item PLC

    my $at = At->new( host => 'plc.bsky-sandbox.dev' );

This is the default DID provider for the network. DIDs are the root of your identity in the network. Sandbox PLC
functions exactly the same as production PLC, but it is run as a separate service with a separate dataset. The DID
resolution client in the self-hosted PDS package is set up to talk the correct PLC service.

=item BGS

    my $at = At->new( host => 'bgs.bsky-sandbox.dev' );

BGS (Big Graph Service) is the firehose for the entire network. It collates data from PDSs & rebroadcasts them out on
one giant websocket.

BGS has to find out about your server somehow, so when we do any sort of write, we ping BGS with
com.atproto.sync.requestCrawl to notify it of new data. This is done automatically in the self-hosted PDS package.

If you’re familiar with the Bluesky production firehose, you can subscribe to the BGS firehose in the exact same
manner, the interface & data should be identical

=item BlueSky Sandbox

    my $at = At->new( host => 'api.bsky-sandbox.dev' );

The Bluesky App View aggregates data from across the network to service the Bluesky microblogging application. It
consumes the firehose from the BGS, processing it into serviceable views of the network such as feeds, post threads,
and user profiles. It functions as a fairly traditional web service.

When you request a Bluesky-related view from your PDS (getProfile for instance), your PDS will actually proxy the
request up to App View.

Feel free to experiment with running your own App View if you like!

=back

You may also configure your own personal data server (PDS).

    my $at = At->new( host => 'your.own.com' );

PDS (Personal Data Server) is where users host their social data such as posts, profiles, likes, and follows. The goal
of the sandbox is to federate many PDS together, so we hope you’ll run your own.

We’re not actually running a Bluesky PDS in sandbox. You might see Bluesky team members' accounts in the sandbox
environment, but those are self-hosted too.

The PDS that you’ll be running is much of the same code that is running on the Bluesky production PDS. Notably, all
of the in-pds-appview code has been torn out. You can see the actual PDS code that you’re running on the
atproto/simplify-pds branch.

=end todo

=head1 See Also

https://atproto.com/

https://en.wikipedia.org/wiki/Bluesky_(social_network)

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
