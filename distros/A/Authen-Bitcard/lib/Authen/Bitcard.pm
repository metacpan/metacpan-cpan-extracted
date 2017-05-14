package Authen::Bitcard;
BEGIN {
  $Authen::Bitcard::VERSION = '0.90';
}
use strict;
use base qw( Class::ErrorHandler );

use Math::BigInt;
use MIME::Base64 qw( decode_base64 );
use Digest::SHA qw( sha1 sha1_hex );
use LWP::UserAgent;
use HTTP::Status qw( RC_NOT_MODIFIED );
use URI;
use URI::QueryParam;
use Carp qw(croak);
use JSON qw(decode_json);

sub new {
    my $class = shift;
    my $bc = bless { }, $class;
    $bc->skip_expiry_check(0);
    $bc->expires(600);
    $bc->bitcard_url('https://www.bitcard.org/');
    $bc->version(4);
    $bc->token('');
    my %args = @_;
    for my $k (keys %args) {
      next unless $bc->can($k);
      $bc->$k($args{$k});
    }
    $bc;
}

sub _var {
    my $bc = shift;
    my $var = shift;
    $bc->{$var} = shift if @_;
    $bc->{$var};
}

sub key_cache         { shift->_var('key_cache',         @_) }
sub skip_expiry_check { shift->_var('skip_expiry_check', @_) }
sub expires           { shift->_var('expires',           @_) }
sub token             { shift->_var('token',             @_) }
sub api_secret        { shift->_var('api_secret',        @_) }
sub version           { shift->_var('version',           @_) }
sub ua                { shift->_var('ua',                @_) }
sub bitcard_url       { shift->_var('bitcard_url',       @_) }
sub info_optional     { shift->_var('io',                @_) }
sub info_required     { shift->_var('ir',                @_) }

sub _url {
  my ($bc, $url) = (shift, shift);
  my $args = ($_[0] && ref $_[0]) ? $_[0] : { @_ };
  $args->{"bc_$_"} = delete $args->{$_} for keys %$args;
  $args->{bc_t} = $bc->token;
  $args->{bc_v} = $bc->version;
  $args->{bc_io} = ref $bc->info_optional ? join ",", @{$bc->info_optional} : $bc->info_optional; 
  $args->{bc_ir} = ref $bc->info_required ? join ",", @{$bc->info_required} : $bc->info_required; 
  delete $args->{bc_io} unless $args->{bc_io};
  delete $args->{bc_ir} unless $args->{bc_ir};
  my $base = $bc->bitcard_url;
  $base = "$base/" unless $base =~ m!/$!;
  my $uri = URI->new($base . $url);
  unless ($url =~ m/regkey.txt/) {
      if ($url =~ m!^api/!) {
          croak "Bitcard API Secret required for API calls" unless $bc->api_secret;
          $args->{bc_ts} = time;
          my @fields = sort keys %$args;
          $args->{bc_fields} = join ",", @fields, 'bc_fields';
          my $string = join "::", (map { "$args->{$_}" } @fields, 'bc_fields'), $bc->api_secret;
          warn "ST: $string";
          $args->{bc_sig} = sha1_hex($string);
      }
      $uri->query_form_hash($args);
  }
  $uri->as_string;
}

sub key_url{
  shift->_url("regkey.txt");
}

sub login_url {
  shift->_url('login', @_)
}

sub logout_url {
  shift->_url('logout', @_)
}

sub account_url {
  shift->_url('account', @_)
}

sub register_url {
  shift->_url('register', @_)
}

sub _api_url {
  my ($self, $method) = (shift, shift);
  $self->_url("api/$method", @_);
}


sub verify {
    my $bc = shift;
    my %data;
    my $fields;
    if (@_ == 1) {
      my $q = $_[0];
      if (ref $q eq 'HASH') {
	$fields = $_[0]->{bc_fields} || '';
	%data = map { $_ => $_[0]->{$_} } grep { defined $_[0]->{$_} } split(/,/, $fields), 'bc_sig';
      }
      else {
	$fields = $q->param('bc_fields') || '';
	%data = map { $_ => $q->param($_) } grep { defined $q->param($_) } split(/,/, $fields), 'bc_sig';
      }
    }
    else {
      ## Later we could process arguments passed in a hash.
      return $bc->error("usage: verify(\$query)");
    }

    #warn Data::Dumper->Dump([\%data], [qw(data)]);

    for ($data{bc_email}, $data{bc_sig}) {
      defined $_ and tr/ /+/;
    }
    return $bc->error("Bitcard data has expired")
        unless $bc->skip_expiry_check or ($data{bc_ts}||0) + $bc->expires >= time;

    my $key = $bc->_fetch_key($bc->key_url) or return;
    my($r, $s) = split /:/, $data{bc_sig};
    my $sig = {};
    $sig->{r} = Math::BigInt->new("0b" . unpack("B*", decode_base64($r)));
    $sig->{s} = Math::BigInt->new("0b" . unpack("B*", decode_base64($s)));
    my $msg = join '::', (map { $data{$_} || '' } split /,/, $data{bc_fields} ), $bc->token;
    unless ($bc->_verify($msg, $key, $sig)) {
        return $bc->error("Bitcard signature verification failed");
    }

    for my $k (keys %data) {
      my $nk = $k;
      $nk =~ s/^bc_//;
      $data{$nk} = delete $data{$k};
    }

    if ($bc->version >= 4) {
      unless ($data{version} == $bc->version) {
        $data{version} =~ s/\D//g; 
        return $bc->error(sprintf "Expected Bitcard protocol version [%i], got version [%i].", $bc->version, $data{version});
      }

      unless ($data{confirmed}) {
        return $bc->error('Account not confirmed');
      }
    }

    \%data;
}

sub _verify {
    my $bc = shift;
    my($msg, $key, $sig) = @_;
    my $u1 = Math::BigInt->new("0b" . unpack("B*", sha1($msg)));
    $sig->{s}->bmodinv($key->{q});
    $u1 = ($u1 * $sig->{s}) % $key->{q};
    $sig->{s} = ($sig->{r} * $sig->{s}) % $key->{q};
    $key->{g}->bmodpow($u1, $key->{p});
    $key->{pub_key}->bmodpow($sig->{s}, $key->{p});
    $u1 = ($key->{g} * $key->{pub_key}) % $key->{p};
    $u1 %= $key->{q};
    $u1 == $sig->{r};
}

sub _get_ua {
    shift->ua || LWP::UserAgent->new;
}

sub _fetch_key {
    my $bc = shift;
    my($uri) = @_;
    my $cache = $bc->key_cache;
    ## If it's a callback, call it and return the return value.
    return $cache->($bc, $uri) if $cache && ref($cache) eq 'CODE';
    ## Otherwise, load the key.
    my $data;
    my $ua = $bc->_get_ua;
    if ($cache) {
        my $res = $ua->mirror($uri, $cache);
        return $bc->error("Failed to fetch key: " . $res->status_line)
            unless $res->is_success || $res->code == RC_NOT_MODIFIED;
        open my $fh, $cache
            or return $bc->error("Can't open $cache: $!");
        $data = do { local $/; <$fh> };
        close $fh;
    } else {
        my $res = $ua->get($uri);
        return $bc->error("Failed to fetch key: " . $res->status_line)
            unless $res->is_success;
        $data = $res->content;
    }
    chomp $data;
    my $key = {};
    for my $f (split /\s+/, $data) {
        my($k, $v) = split /=/, $f, 2;
        $key->{$k} = Math::BigInt->new($v);
    }
    $key;
}

sub add_invite {
    my $self  = shift;
    my $url = $self->_api_url('invite/add_invite', @_);
    warn "URL: $url\n";
    my $res = $self->_get_ua->get($url);
    return $self->error("Failed to retrive invitation code: " . $res->status_line)
      unless $res->is_success;
    my $data = decode_json($res->content);
    $data;
}

1;
__END__

=head1 NAME

Authen::Bitcard - Bitcard authentication verification

=head1 SYNOPSIS

    use CGI;
    use Authen::Bitcard;
    my $q = CGI->new;
    my $bc = Authen::Bitcard->new;
    $bc->token('bitcard-token');
    # send user to $bc->login_url(r => $return_url);
    # when the user comes back, get the user id with:
    my $user = $bc->verify($q) or die $bc->errstr;

=head1 DESCRIPTION

I<Authen::Bitcard> is an implementation of verification for signatures
generated by Bitcard authentication. For information on the Bitcard
protocol and using Bitcard in other applications, see
I<http://www.bitcard.org/api>.

The module and the protocol are heavily based on I<Authen::Typekey>.
(In fact, the Bitcard authentication server also supports the TypeKey
API!)

=head1 USAGE

=head2 Authen::Bitcard->new

Create a new I<Authen::Bitcard> object.

=head2 $bc->token([ $bitcard_token ])

Your Bitcard token, which you passed to Bitcard when creating the original
sign-in link.

This must be set B<before> calling I<verify> or I<login_url> (etc).

=head2 $bc->bitcard_url( [ $url ])

Get/set the base URL for the Bitcard service.  The default URL is
I<https://www.bitcard.org/>.  The other *_url methods are build based
on the C<bitcard_url> value.

=head2 $bc->login_url( r => $return_url )

Returns the URL for the user to login.  Takes a hash or hash ref with
extra parameters to put in the URL.  One of them must be the C<r>
parameter with the URL the user will get returned to after logging in
(or canceling the login).

=head2 $bc->logout_url( r => $return_url )

Returns the URL you can send the user if they wish to logout.  Also
needs the C<r> parameter for the URL the Bitcard server should send
the user back to after logging out.

=head2 $bc->account_url( r => $return_url )

Returns the URL the user can edit his Bitcard account information at.
Also needs the C<r> parameter like C<login_url> and C<logout_url>.

=head2 $bc->register_url( r => $return_url )

Returns the URL for a user to register a new Bitcard account.  Also
needs the C<r> parameter as above.

=head2 $bc->key_url()

Get the URL from which the Bitcard public key can be obtained.

=head2 $bc->info_required(  $string | [ array ref ] )

With info_required you specify what user data you require.  The
possible fields are "username", "name" and "email" (see C<verify> for
more information).

The method takes either a comma separated string or a reference to an
array.

This must be called before C<login_url>.

NOTE: "name" is currently not implemented well in the Bitcard server,
so we recommend you require "username", but mark "name" as optional if
you want the "display name" of the user returned.

=head2 $bc->info_optional( $string | [ array ref ] )

As C<info_required> except the Bitcard server will ask the user to
allow the information to be forwarded, but not require it to proceed.

The Bitcard server will always have a confirmed email address on file
before letting a user login.

=head2 $bc->verify($query)

Verify a Bitcard signature based on the other parameters given. The signature
and other parameters are found in the I<$query> object, which should be
either a hash reference, or any object that supports a I<param> method--for
example, a I<CGI> or I<Apache::Request> object.

If the signature is successfully verified, I<verify> returns a reference to
a hash containing the following values.

=over 4

=item * id

The unique user id of the Bitcard user on your site.  It's a 128bit
number as a 40 byte hex value.

The id is always returned when the verification was successful (all
other user data fields are optional, see C<info_required> and
C<info_optional>).

=item * username

The unique username of the Bitcard user.

=item * name

The user's display name.

=item * email

The user's email address. 

=item * ts

The timestamp at which the signature was generated, expressed as seconds
since the epoch.

=back

If verification is unsuccessful, I<verify> will return C<undef>, and the
error message can be found in C<$bc-E<gt>errstr>.

=head2 $bc->key_cache([ $cache ])

Provide a caching mechanism for the public key.

If I<$cache> is a CODE reference, it is treated as a callback that should
return the public key. The callback will be passed two arguments: the
I<Authen::TypeKey> object, and the URI of the key. It should return a
hash reference with the I<p>, I<g>, I<q>, and I<pub_key> keys set to
I<Math::BigInt> objects representing the pieces of the DSA public key.

Otherwise, I<$cache> should be the path to a local file where the public
key will be cached/mirrored.

If I<$cache> is not set, the key is not cached. By default, no caching
occurs.

=head2 $bc->skip_expiry_check([ $boolean ])

Get/set a value indicating whether I<verify> should check the expiration
date and time in the TypeKey parameters. The default is to check the
expiration date and time.

=head2 $bc->expires([ $secs ])

Get/set the amount of time at which a Bitcard signature is intended to expire.
The default value is 600 seconds, i.e. 10 minutes.


=head2 $bc->ua([ $user_agent ])

Get/set the LWP::UserAgent-like object which will be used to retrieve the
regkeys from the network.  Needs to support I<mirror> and I<get> methods. 
By default, LWP::UserAgent is used, and this method as a getter returns
C<undef> unless the user agent has been previously set.

=head2 $bc->version([ $version ])

Get/set the version of the Bitcard protocol to use. The default version
is C<3>.

=head2 $bc->api_secret( $secret )

Get/set the api_secret (needed for some API calls, add_invite for
example).

=head2 $bc->add_invite

Returns a hashref with C<invite_url> and C<invite_key>.  Can be used
for "invitation only" sites where you have to login before you can
access the site.


=head1 LICENSE

I<Authen::Bitcard> is distributed under the Apache License; see the
LICENSE file in the distribution for details.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<Authen::Bitcard> is Copyright
2004-2010 Develooper LLC, ask@develooper.com.

Parts are Copyright 2004 Six Apart Ltd, cpan@sixapart.com.

All rights reserved.

=cut
