package Authen::DigestMD5;

use 5.006;

our $VERSION = '0.04';

package Authen::DigestMD5::Packet;
use strict;
use warnings;

my %quote=map{$_=>1} qw(username realm nonce cnonce digest-uri qop cipher);

sub _quote($$) {
    shift;
    my ($k, $v)=@_;
    return () unless defined $v;
    if ($quote{$k}) {
	$v =~ s/([\\"])/\\$1/g;
	return qq|$k="$v"|;
    }
    "$k=$v";
}

sub _split {
    shift;
    my $str=shift;
    my %pair;
    while ($str=~/\G\s*([\w\-]+)\s*=\s*("([^\\"]+|\\.)*"|[^,]+)\s*(?:,|$)/g) {
	$pair{$1}=$2;
    }
    my ($k, $v);
    while(($k, $v)=each %pair) {
	if ($v=~/^"(.*)"$/) {
	    $v=$1;
	    $v=~s/\\(.)/$1/g;
	    $pair{$k}=$v;
	}
    }
    %pair
}

sub _join {
    my $this=shift;
    my %pair=@_;
    delete $pair{password};
    join(',', map { $this->_quote($_, $pair{$_}) } sort keys %pair)
}

sub new {
    my $class=shift;
    my $input=shift if @_ & 1;
    my $this={ @_ };
    bless $this, $class;
    $this->input($input) if defined $input;
    return $this;
}

sub clone {
    my $this=shift;
    my $clone={ %$this };
    bless $clone, ref($this);
}

sub _public {
    my $this=shift;
    return grep /^[a-z]/i, keys(%$this);
}

sub input {
    my ($this, $str)=@_;
    return unless defined $str;
    $this->set($this->_split($str));
}

sub output {
    my $this=shift;
    return $this->_join(map { $_, $this->{$_} } $this->_public);
}

sub set {
    my $this=shift;
    while (@_) {
	my $k=shift;
	my $v=shift;
	$this->{$k}=$v;
    }
}

sub get {
    my $this=shift;
    return wantarray
	? (map { $this->{$_} } @_)
	    : $this->{$_[0]};
}

sub reset {
    my $this=shift;
    for my $k ($this->_public) {
	delete $this->{$k}
    }
}

package Authen::DigestMD5::Request;
our @ISA=qw(Authen::DigestMD5::Packet);

use strict;
use warnings;

sub auth_ok {
    my $this=shift;
    return defined $this->{rspauth};
}

package Authen::DigestMD5::Response;
our @ISA=qw(Authen::DigestMD5::Packet);

use strict;
use warnings;

use Digest::MD5 qw(md5_hex md5);
use Carp;

sub new {
    my $this=shift->SUPER::new(@_);
    $this->{_nc}={};
    return $this;
}

sub _public {
    my $this=shift;
    return grep { $_=~/^[a-z]/i and
		      $_ ne 'password' } keys(%$this);
}

sub got_request {
    my $this=shift;
    my $req=shift;
    # $this->{_r}=$req;
    for my $k (qw(nonce realm charset)) {
	$this->{$k}=$req->{$k} if exists $req->{$k};
    }
    #$this->{nc}=sprintf("%08d", ++$this->{_nc}{$req->{nonce}})
    #  if exists $req->{nonce};
    if (exists $req->{qop}) {
	my @qop=split(/\s*,\s*/, $req->{qop});
	if (grep {$_ eq 'auth-int'} @qop) {
	    $this->{qop}='auth-int'
	}
	elsif (grep {$_ eq 'auth'} @qop) {
	    $this->{qop}='auth'
	}
	else { croak "not supported qop found ($req->{qop})" }
    }
}

sub add_digest {
    my $this=shift;

    $this->{cnonce}=md5_hex(join(':', time, rand, $$));
      # unless defined $this->{cnonce};

    $this->{nc}=sprintf("%08d", ++$this->{_nc}{$this->{nonce}})
	if exists $this->{nonce};

    my %pair=((map { $_, $this->{$_} } $this->_public), @_);

    my $A1=join (":",
		 md5(join (":", @pair{qw(username realm password)}, )),
		 @pair{qw(nonce cnonce)} );

    my $A2 = "AUTHENTICATE:" . $pair{'digest-uri'};

    $A2 .= ":00000000000000000000000000000000"
	if (defined $pair{'qop'} and
	    $pair{'qop'} =~ /^auth-(conf|int)$/);

    $this->{response} =
	md5_hex(join (":", md5_hex($A1),
		      @pair{qw(nonce nc cnonce qop)},
		      md5_hex($A2)) );
}


1;
__END__

=head1 NAME

Authen::DigestMD5 - SASL DIGEST-MD5 authentication (RFC2831)

=head1 SYNOPSIS

  use Authen::DigestMD5;

  use OnLDAP;
  $ld=OnLDAP::Client->new($host);
  ($rc, $id)=$ld->sasl_bind(undef, 'DIGEST-MD5');
  ($rc, $msg)=$ld->result($id);
  ($rc, $req)=$ld->parse_sasl_bind_result($msg);

  print "IN: |$req|\n";
  my $request=Authen::DigestMD5::Request->new($req);
  my $response=Authen::DigestMD5::Response->new;
  $response->got_request($request);
  $response->set(username => $user,
	         realm => $realm,
	         'digest-uri' => "ldap/$host");
  $response->add_digest(password=>$passwd);
  my $res=$response->output;
  print "OUT: |$res|\n";

  ($rc, $id)=$ld->sasl_bind(undef, 'DIGEST-MD5', $res);
  ($rc, $msg)=$ld->result($id);
  ($rc, $req)=$ld->parse_sasl_bind_result($msg);

  $request->input($req);
  print $request->auth_ok ? "AUTH OK\n" : "AUTH FAILED\n"

=head1 ABSTRACT

This module supports DIGEST-MD5 SASL authentication as defined on
RFC-2831.

=head1 DESCRIPTION

This module implements three classes:

=over 4

=item Authen::DigestMD5::Packet

base class implementing common methods to process SASL DIGEST-MD5
strings or objects:

=over 4

=item Authen::DigestMD5::Packet-E<gt>new(%props)

=item Authen::DigestMD5::Packet-E<gt>new($input, %props)

create a new object with the properties in C<%props>. If C<$input> is
passed it is parsed and the values obtained from it added to the
object.

=item $pkt-E<gt>input($input)

parses the properties on the string C<$input> and adds them to the
object.

=item $pkt-E<gt>output()

packs all the properties on the object as a string suitable for
sending to a SASL DIGEST-MD5 server or client.

=item $pkg-E<gt>set($k1=>$v1, $k2=>$v2, ...)

=item $pkg-E<gt>set(%props)

set object properties.

=item ($v1, $v2, ...)=$pkg-E<gt>get($k1, $k2, ...) 

gets object properties.

=item $pkg-E<gt>reset()

clears public object properties. Some internal properties like nc
counters are retained.

=back

=item Authen::DigestMD5::Request

class to represent SASL DIGEST-MD5 requests as obtained from a server.

=over 4

=item $req-E<gt>auth_ok()

returns a true value if the request object contains a valid
authentication token.

=back

=item Authen::DigestMD5::Response

class to represent and generate SASL DIGEST-MD5 responses suitables
for sending to a server.

=over 4

=item $res-E<gt>got_request($req)

adds certain properties to the response C<$res> object generated from
the request C<$req> ones.

=item $res-E<gt>add_digest(password => $password)

adds the C<response> property containing the MD5 digest to the
response object.

=back

=back


=head1 SEE ALSO

Be sure to look at L<Authen::SASL> because it is very likely that it
is what you are looking for (C<Authen::DigestMD5> is only suitable
when you need a finer control over the authentication procedure).

SASL DIGEST-MD5 RFC L<http://www.ietf.org/rfc/rfc2831.txt>.

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Salvador Fandiño.

Portions of this module have been copied from the L<Authen::SASL>
package by Graham Barr.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
