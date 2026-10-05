package Airlock;

# ABSTRACT: Embeddable device authorization (RFC 8628) with step-up second factors

use Moo;
with 'Airlock::Role::Endpoints';
use Airlock::Code;
use Airlock::Policy;
use Airlock::Result;
use Airlock::Store::Memory;
use Carp qw( croak );
use Types::Standard qw( ArrayRef CodeRef ConsumerOf HashRef InstanceOf Int Str );
use namespace::autoclean;

our $VERSION = '0.001';


has clients => (
  is       => 'ro',
  isa      => HashRef | CodeRef,
  required => 1
);


has verification_uri => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has store => (
  is  => 'lazy',
  isa => HashRef[CodeRef]
);

sub _build_store { Airlock::Store::Memory->new->as_subs }


has policy => (
  is     => 'lazy',
  isa    => InstanceOf['Airlock::Policy'],
  coerce => sub { ref $_[0] eq 'HASH' ? Airlock::Policy->new( $_[0] ) : $_[0] }
);

sub _build_policy { Airlock::Policy->new }


has factors => (
  is      => 'ro',
  isa     => ArrayRef[ConsumerOf['Airlock::Factor']],
  default => sub { [] }
);


has issuer => (
  is        => 'ro',
  isa       => CodeRef,
  predicate => 'has_issuer'
);


has on_event => (
  is        => 'ro',
  isa       => CodeRef,
  predicate => 'has_on_event'
);


has now => (
  is      => 'ro',
  isa     => CodeRef,
  default => sub { sub { time } }
);


has expires_in => (
  is      => 'ro',
  isa     => Int,
  default => 600
);


has interval => (
  is      => 'ro',
  isa     => Int,
  default => 5
);


has token_ttl => (
  is      => 'ro',
  isa     => Int,
  default => 3600
);


has max_factor_failures => (
  is      => 'ro',
  isa     => Int,
  default => 5
);


has code => (
  is  => 'lazy',
  isa => InstanceOf['Airlock::Code']
);

sub _build_code { Airlock::Code->new }


has _factor_index => (
  is       => 'lazy',
  init_arg => undef
);

sub _build__factor_index {
  my ( $self ) = @_;
  return { map { $_->name => $_ } @{ $self->factors } };
}

sub BUILD {
  my ( $self ) = @_;
  for (qw( insert find update )) {
    croak __PACKAGE__.'->new store needs a '.$_.' sub' unless ref $self->store->{$_} eq 'CODE';
  }
  return;
}

sub row_fields {
  return qw(
    hash kind user_code client_id scope state created expires poll_interval last_poll
    subject amr acr auth_time approved origin_ip origin_ua factor_failures
  );
}


sub client {
  my ( $self, $id ) = @_;
  return unless defined $id && length $id;
  my $clients = $self->clients;
  my $client  = ref $clients eq 'CODE' ? $clients->($id) : $clients->{$id};
  return unless ref $client eq 'HASH';
  return { name => $id, %$client, id => $id };
}


sub factor {
  my ( $self, $name ) = @_;
  return $self->_factor_index->{$name} // croak __PACKAGE__.'->factor unknown factor '.$name;
}


sub open {
  my ( $self, %arg ) = @_;
  my $client = $self->client( $arg{client_id} ) or return $self->_fail('invalid_client');
  my @scopes = grep { length } split /\s+/, $arg{scope} // '';
  my %allowed = map { $_ => 1 } @{ $client->{scopes} || [] };
  for my $scope (@scopes) {
    return $self->_fail('invalid_scope') unless $scope =~ /\A[\x21\x23-\x5B\x5D-\x7E]+\z/;
    return $self->_fail('invalid_scope') if $client->{scopes} && !$allowed{$scope};
  }
  my $now         = $self->_time;
  my $device_code = $self->code->secret;
  my $user_code   = $self->_free_user_code($now);
  my $origin      = {
    ip => $self->_clip( $arg{origin}{ip}, 64 ),
    ua => $self->_clip( $arg{origin}{ua}, 255 )
  };
  $self->store->{insert}->( {
    hash            => $self->code->hash($device_code),
    kind            => 'request',
    user_code       => $user_code,
    client_id       => $client->{id},
    scope           => join( ' ', @scopes ),
    state           => 'pending',
    created         => $now,
    expires         => $now + $self->expires_in,
    poll_interval   => $self->interval,
    last_poll       => undef,
    subject         => undef,
    amr             => undef,
    acr             => undef,
    auth_time       => undef,
    approved        => undef,
    origin_ip       => $origin->{ip},
    origin_ua       => $origin->{ua},
    factor_failures => 0
  } );
  $self->_emit( 'opened', client_id => $client->{id}, origin => $origin );
  my $shown = $self->code->display($user_code);
  my $uri   = $self->verification_uri;
  return $self->_ok( 'opened', data => {
    device_code               => $device_code,
    user_code                 => $shown,
    verification_uri          => $uri,
    verification_uri_complete => $uri.( $uri =~ /\?/ ? '&' : '?' ).'user_code='.$shown,
    expires_in                => $self->expires_in,
    interval                  => $self->interval
  } );
}


sub inspect {
  my ( $self, $input, %arg ) = @_;
  my $row = $self->_pending($input);
  return $self->_view($row) if $row;
  $self->_miss( $arg{subject} );
  return;
}


sub requirements {
  my ( $self, $view, $subject ) = @_;
  return $self->policy->required( $view, $subject );
}


sub approve {
  my ( $self, $input, %arg ) = @_;
  my $subject = $self->_subject( 'approve', $arg{subject} );
  my $row     = $self->_pending($input);
  return $self->_ok('approved') if !$row && $self->_approved_by( $input, $subject );
  return $self->_miss($subject) unless $row;
  my $now     = $self->_time;
  return $self->_fail('reauth_required') unless $self->policy->fresh( $subject, $now );
  my $proofs  = $arg{proofs} || {};
  my @factors = map { $self->factor($_) } @{ $self->policy->required( $self->_view($row), $subject ) };
  my @amr     = @{ $subject->{amr} || [] };
  my @missing;
  for my $factor (@factors) {
    return $self->_fail( 'factor_unavailable', missing => [ $factor->name ] )
      unless $factor->available_for($subject);
    if ( $factor->needs_proof ) {
      my $proof = $proofs->{ $factor->name };
      push @missing, $factor->name unless defined $proof && length $proof;
      next;
    }
    return $self->_fail( 'reauth_required', missing => [ $factor->name ] ) unless $factor->verify($subject);
    push @amr, $factor->amr;
  }
  return $self->_fail( 'factor_required', missing => \@missing ) if @missing;
  my @proven = grep { $_->needs_proof } @factors;
  for my $factor (@proven) {
    return $self->_factor_failed( $row, $subject, $factor )
      unless $factor->verify( $subject, $proofs->{ $factor->name } );
  }
  for my $factor (@proven) {
    return $self->_factor_failed( $row, $subject, $factor )
      unless $factor->commit( $subject, $proofs->{ $factor->name } );
    push @amr, $factor->amr;
  }
  my %seen;
  my $approved = $self->store->{update}->( $row->{hash}, 'pending', {
    state     => 'approved',
    subject   => $subject->{id},
    amr       => join( ' ', grep { !$seen{$_}++ } @amr ),
    acr       => $subject->{acr},
    auth_time => $subject->{auth_time},
    approved  => $now
  } );
  return $self->_miss($subject) unless $approved;
  $self->_emit( 'approved', client_id => $row->{client_id}, subject => $subject->{id} );
  return $self->_ok('approved');
}


sub deny {
  my ( $self, $input, %arg ) = @_;
  my $subject = $self->_subject( 'deny', $arg{subject} );
  my $row     = $self->_pending($input) or return $self->_miss($subject);
  my $denied  = $self->store->{update}->( $row->{hash}, 'pending', {
    state     => 'denied',
    user_code => undef,
    subject   => $subject->{id}
  } );
  return $self->_miss($subject) unless $denied;
  $self->_emit( 'denied', client_id => $row->{client_id}, subject => $subject->{id} );
  return $self->_ok('denied');
}


sub redeem {
  my ( $self, %arg ) = @_;
  for (qw( device_code client_id )) {
    return $self->_fail('invalid_request') unless defined $arg{$_} && length $arg{$_};
  }
  my $store = $self->store;
  my $hash  = $self->code->hash( $arg{device_code} );
  my $row   = $store->{find}->( 'hash', $hash );
  return $self->_fail('invalid_grant')
    unless $row && $row->{kind} eq 'request' && $row->{client_id} eq $arg{client_id};
  my $now   = $self->_time;
  my $state = $row->{state};
  if ( ( $state eq 'pending' || $state eq 'approved' ) && $row->{expires} <= $now ) {
    $store->{update}->( $hash, $state, { state => 'expired', user_code => undef } );
    $state = 'expired';
  }
  return $self->_fail('expired_token') if $state eq 'expired';
  return $self->_fail('access_denied') if $state eq 'denied';
  return $self->_fail('invalid_grant') unless $state eq 'pending' || $state eq 'approved';
  if ( defined $row->{last_poll} && $now - $row->{last_poll} < $row->{poll_interval} ) {
    $store->{update}->( $hash, $state, { poll_interval => \5, last_poll => $now } );
    return $self->_fail('slow_down');
  }
  if ( $state eq 'pending' ) {
    $store->{update}->( $hash, 'pending', { last_poll => $now } );
    return $self->_fail('authorization_pending');
  }
  return $self->_fail('invalid_grant')
    unless $store->{update}->( $hash, 'approved', { state => 'redeemed', user_code => undef, last_poll => $now } );
  my $grant = {
    subject   => $row->{subject},
    client_id => $row->{client_id},
    scope     => $row->{scope},
    scopes    => [ split / /, $row->{scope} ],
    amr       => [ split / /, $row->{amr} // '' ],
    acr       => $row->{acr},
    auth_time => $row->{auth_time}
  };
  my $token = $self->has_issuer ? $self->issuer->($grant) : $self->_issue_opaque( $grant, $now );
  croak __PACKAGE__.'->redeem issuer must return a hash' unless ref $token eq 'HASH';
  $self->_emit( 'redeemed', client_id => $row->{client_id}, subject => $row->{subject} );
  return $self->_ok( 'granted', data => $token );
}


sub verify_token {
  my ( $self, $token ) = @_;
  return unless defined $token && length $token;
  my $row = $self->store->{find}->( 'hash', $self->code->hash($token) ) or return;
  return unless $row->{kind} eq 'token' && $row->{state} eq 'active';
  return unless $row->{expires} > $self->_time;
  return {
    subject   => $row->{subject},
    client_id => $row->{client_id},
    scope     => $row->{scope},
    scopes    => [ split / /, $row->{scope} ],
    amr       => [ split / /, $row->{amr} // '' ],
    acr       => $row->{acr},
    auth_time => $row->{auth_time},
    expires   => $row->{expires}
  };
}


sub revoke_token {
  my ( $self, $token ) = @_;
  return 0 unless defined $token && length $token;
  return $self->store->{update}->( $self->code->hash($token), 'active', { state => 'revoked' } ) ? 1 : 0;
}


sub purge {
  my ( $self ) = @_;
  my $purge = $self->store->{purge} or return 0;
  return $purge->( $self->_time );
}


sub _time { $_[0]->now->() }

sub _ok {
  my ( $self, $status, %arg ) = @_;
  return Airlock::Result->new( ok => 1, status => $status, %arg );
}

sub _fail {
  my ( $self, $status, %arg ) = @_;
  return Airlock::Result->new( ok => 0, status => $status, %arg );
}

sub _miss {
  my ( $self, $subject ) = @_;
  $self->_emit( 'code_miss', subject => $subject ? $subject->{id} : undef );
  return $self->_fail('unknown_code');
}

sub _emit {
  my ( $self, $event, %data ) = @_;
  return unless $self->has_on_event;
  $self->on_event->( { event => $event, time => $self->_time, %data } );
  return;
}

sub _clip {
  my ( $self, $text, $max ) = @_;
  return defined $text ? substr( $text, 0, $max ) : undef;
}

sub _subject {
  my ( $self, $method, $subject ) = @_;
  croak __PACKAGE__.'->'.$method.' needs a subject with an id'
    unless ref $subject eq 'HASH' && defined $subject->{id} && length $subject->{id};
  croak __PACKAGE__.'->'.$method.' subject id is longer than 255 characters' if length $subject->{id} > 255;
  return $subject;
}

sub _free_user_code {
  my ( $self, $now ) = @_;
  for ( 1 .. 10 ) {
    my $code = $self->code->user_code;
    my $row  = $self->store->{find}->( 'user_code', $code ) or return $code;
    next if $row->{expires} > $now;
    $self->store->{update}->( $row->{hash}, $row->{state}, { state => 'expired', user_code => undef } );
    return $code;
  }
  croak __PACKAGE__.'->open found no free user code';
}

sub _pending {
  my ( $self, $input ) = @_;
  my $code = $self->code->normalize($input) or return;
  my $row  = $self->store->{find}->( 'user_code', $code ) or return;
  return unless $row->{kind} eq 'request' && $row->{state} eq 'pending';
  return $row if $row->{expires} > $self->_time;
  $self->store->{update}->( $row->{hash}, 'pending', { state => 'expired', user_code => undef } );
  return;
}

sub _approved_by {
  my ( $self, $input, $subject ) = @_;
  my $code = $self->code->normalize($input) or return 0;
  my $row  = $self->store->{find}->( 'user_code', $code ) or return 0;
  return 0 unless $row->{kind} eq 'request' && $row->{state} eq 'approved';
  return 0 unless $row->{expires} > $self->_time;
  return $row->{subject} eq $subject->{id} ? 1 : 0;
}

sub _view {
  my ( $self, $row ) = @_;
  my $client = $self->client( $row->{client_id} ) || { name => $row->{client_id} };
  my $now    = $self->_time;
  return {
    user_code   => $self->code->display( $row->{user_code} ),
    client_id   => $row->{client_id},
    client_name => $client->{name},
    scopes      => [ split / /, $row->{scope} ],
    origin      => { ip => $row->{origin_ip}, ua => $row->{origin_ua} },
    created     => $row->{created},
    age         => $now - $row->{created},
    expires_in  => $row->{expires} - $now
  };
}

sub _factor_failed {
  my ( $self, $row, $subject, $factor ) = @_;
  my $store = $self->store;
  # counted in the store, not from the row read earlier: parallel wrong guesses
  # must each count
  $store->{update}->( $row->{hash}, 'pending', { factor_failures => \1 } );
  my $current = $store->{find}->( 'hash', $row->{hash} );
  my $final   = $current && $current->{factor_failures} >= $self->max_factor_failures;
  $store->{update}->( $row->{hash}, 'pending', { state => 'denied', user_code => undef } ) if $final;
  $self->_emit( 'factor_failed', client_id => $row->{client_id}, subject => $subject->{id}, factor => $factor->name );
  return $self->_fail( $final ? 'too_many_failures' : 'factor_failed', missing => [ $factor->name ] );
}

sub _issue_opaque {
  my ( $self, $grant, $now ) = @_;
  my $token = $self->code->secret;
  $self->store->{insert}->( {
    hash            => $self->code->hash($token),
    kind            => 'token',
    user_code       => undef,
    client_id       => $grant->{client_id},
    scope           => $grant->{scope},
    state           => 'active',
    created         => $now,
    expires         => $now + $self->token_ttl,
    poll_interval   => undef,
    last_poll       => undef,
    subject         => $grant->{subject},
    amr             => join( ' ', @{ $grant->{amr} } ),
    acr             => $grant->{acr},
    auth_time       => $grant->{auth_time},
    approved        => undef,
    origin_ip       => undef,
    origin_ua       => undef,
    factor_failures => 0
  } );
  return {
    access_token => $token,
    token_type   => 'Bearer',
    expires_in   => $self->token_ttl,
    scope        => $grant->{scope}
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock - Embeddable device authorization (RFC 8628) with step-up second factors

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $airlock = Airlock->new(
      clients          => { 'my-cli' => { name => 'My CLI', scopes => [qw( read admin )] } },
      verification_uri => 'https://my.example.org/airlock',
      store            => { insert => sub {...}, find => sub {...}, update => sub {...}, purge => sub {...} },
      policy           => { step_up => { admin => ['totp'] } },
      factors          => [ Airlock::Factor::Callback->new( name => 'totp', amr => 'otp', verify => sub {...} ) ],
    );

    # machine side: mount the two JSON endpoints
    my $app = $airlock->to_app;

    # human side: the host application renders its own page
    my $view  = $airlock->inspect( $typed_code, subject => $subject ) or return not_found();
    my $needs = $airlock->requirements( $view, $subject );            # ['totp']
    my $done  = $airlock->approve( $typed_code, subject => $subject, proofs => { totp => $typed_totp } );

=head1 DESCRIPTION

Airlock approves a waiting request from an already trusted session: the server
side of the OAuth 2.0 Device Authorization Grant (RFC 8628), with an optional
second factor before the approval counts.

It is a core to embed. The host application supplies who is logged in, the
approval page and where rows are kept. Airlock supplies codes, the state
machine, poll rules, one-time redemption, step-up policy, second factors and
the two machine endpoints.

A request moves C<pending> to C<approved>, C<denied> or C<expired>, and
C<approved> to C<redeemed> exactly once.

=head2 clients

Required. Who may ask. A hash of client id to C<< { name => ..., scopes => [...] } >>,
or a coderef called with a client id that returns such a hash or nothing. A
client without C<scopes> may ask for any scope.

=head2 verification_uri

Required. Where the host application serves its approval page.

=head2 store

Hash of four coderefs: C<insert>, C<find>, C<update> and optionally C<purge>.
In the changes given to C<update>, a reference to a number means "add this to
the column", which the store has to do atomically.
The contract is documented in L<Airlock::Store::Memory> and checked by
L<Airlock::Test::Store>. Default: an in-process store.

=head2 policy

An L<Airlock::Policy> or the hash to build one from. Default: no factors.

=head2 factors

The L<Airlock::Factor> objects a policy may name.

=head2 issuer

Optional. Coderef called with the grant, returning the token response as a
hash. Without it Airlock issues an opaque random token, keeps its hash in the
store and checks it with L</verify_token>.

=head2 on_event

Optional. Coderef called with a hash for C<opened>, C<approved>, C<denied>,
C<redeemed>, C<factor_failed> and C<code_miss>. Hang the audit log and rate
limits here. Events never carry codes, tokens or proofs.

=head2 now

Coderef returning the current epoch. For tests.

=head2 expires_in

Seconds a request lives. Default 600.

=head2 interval

Seconds a client has to wait between polls. Default 5.

=head2 token_ttl

Seconds an opaque token lives. Default 3600.

=head2 max_factor_failures

Wrong proofs after which a request is denied. Default 5.

=head2 code

The L<Airlock::Code> that generates and normalizes codes.

=head2 row_fields

    my @columns = Airlock->row_fields;

Every key of a row the store sees. All values are plain scalars or undef.

=head2 client

    my $client = $airlock->client('my-cli');   # { id => ..., name => ..., scopes => [...] }

The registered client, or nothing.

=head2 factor

    my $upstream = $airlock->factor('upstream');

The factor of that name. Croaks when a policy names a factor that was never
configured.

=head2 open

    my $result = $airlock->open( client_id => 'my-cli', scope => 'read admin', origin => { ip => $ip, ua => $ua } );

Starts a request. On success C<data> is the device authorization response of
RFC 8628 section 3.2. Fails with C<invalid_client> or C<invalid_scope>.

=head2 inspect

    my $view = $airlock->inspect( $typed_code, subject => $subject ) or return not_found();

What an approval page has to show: C<user_code>, C<client_id>, C<client_name>,
C<scopes>, C<origin> (C<ip>, C<ua>), C<created>, C<age> and C<expires_in>.
Returns nothing when the code is unknown, used up or expired. Looking never
approves anything.

=head2 requirements

    my $names = $airlock->requirements( $view, $subject );   # ['totp']

The factor names this approval needs, so the page can ask for them.

=head2 approve

    my $result = $airlock->approve( $typed_code, subject => $subject, proofs => { totp => '123456' } );

Approves a pending request on behalf of the subject, a hash with at least
C<id> and optionally C<amr>, C<acr> and C<auth_time>. An empty proof counts as
no proof. Approving a second time
with the same subject, as a double click does, succeeds again. Fails with
C<unknown_code>, C<reauth_required>, C<factor_unavailable>, C<factor_required>
(C<missing> names what to ask for), C<factor_failed> or C<too_many_failures>.
Croaks without a subject id.

=head2 deny

    my $result = $airlock->deny( $typed_code, subject => $subject );

Refuses a pending request. The client's next poll gets C<access_denied>.

=head2 redeem

    my $result = $airlock->redeem( device_code => $device_code, client_id => 'my-cli' );

One poll of the client. Succeeds exactly once per approved request, with the
token response in C<data>. Otherwise fails with C<authorization_pending>,
C<slow_down>, C<access_denied>, C<expired_token>, C<invalid_grant> or
C<invalid_request>. An exception from the issuer propagates; the request is
used up by then.

=head2 verify_token

    my $grant = $airlock->verify_token($bearer) or return unauthorized();

For opaque tokens: the grant behind a token that is known, active and not
expired, or nothing.

=head2 revoke_token

    $airlock->revoke_token($bearer);

Ends an opaque token. Returns 1 when there was an active one.

=head2 purge

    my $removed = $airlock->purge;

Removes expired requests and tokens through the store's C<purge> sub. Call it
from a timer or a cron job.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-airlock/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
