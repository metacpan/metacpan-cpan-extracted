package Apache::CryptHash;

#require 5.005_62;
use strict;
#use warnings;

BEGIN {
#  use Apache;
  use MIME::Base64;
  use Crypt::CapnMidNite;
  use vars qw($VERSION);
  $VERSION = do { my @r = (q$Revision: 3.03 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
}


sub init() {
  my ($proto, $crypt) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  $self->{NAME} = 'Secret';		# default header name
  $self->{CRYPT} = $crypt || do {	# default password is hostname
    require Sys::Hostname;		# 'no, NO' turns encryption off
    &Sys::Hostname::hostname;
  };
  bless ($self, $class);
  return $self;
}

sub name {
  &_readNset(\shift->{NAME},@_);
}

sub passcode {
  &_readNset(\shift->{CRYPT},@_);
}   

sub _readNset {
  my($var,$new) = @_;
  my $rv = $$var;
  $$var = $new if defined $new;
  return $rv;
}

#####################################################
# md5_hex
#
# input:	string
# returns:	md5 hex hash of string
#
sub md5_hex($$) {
  my ($self, $string) = @_;
  return Crypt::CapnMidNite->new->md5_hex($string);
}

#####################################################
# md5_b64
#
# input:        string
# returns:      md5 base 64 of string
#
sub md5_b64($$) {
  my ($self, $string) = @_;
  return Crypt::CapnMidNite->new->md5_base64($string);
}

#####################################################
# encode
# create an encrypted cookie from data values passed in hash
# input:	pointer to hash,	# \%p
#  (optional)	pointer to keys 	# \@k
#			(array) of values to include in MAC
#			these must be invarient and will 
#			fail to decrypt otherwise
#
sub encode($$$) {
  my ( $self, $state, $k ) = @_;	# get my self
  &_MAC($self, $state, $k, 'generate');	# add MAC to state
  my $cipher = Crypt::CapnMidNite->new_md5_rc4($self->{CRYPT});
  my %s = %$state;
  foreach (keys %s) {
    $s{$_} =~ s/:/%58/g;
  }
  my $cook = $self->{NAME};
  if ( $self->{CRYPT} =~ /^no$/i ) {
    $cook .= '.Debug:' . join ':', %s;
  } else {
    $cook .= ':' . MIME::Base64::encode($cipher->encrypt(join ':', %s),"");
  }
  $cook =~ tr/=/$/;
  return $cook;
}

#####################################
#
# input:	pointer to cookie value	 # \$string
#		pointer to state hash 	 # \%state to fill
#		pointer key arrau in MAC # \@keys
# return:	true or undef, fill hash with state values if true
#
sub decode ($$$) {
  my ($self, $cook, $state, $ck) = @_;
  my %s;
  $$cook =~ tr/$/=/;
  my $rv = &_decrypt($self, $cook, \%s, $ck);
  return undef unless $rv;
  %$state = %s;
  $rv;
}

sub _decrypt {
  my ($self, $cook, $state, $ck) = @_;
  my $cipher = Crypt::CapnMidNite->new_md5_rc4($self->{CRYPT});
  my ($flag, $realcook) = split(':', $$cook, 2);
  $realcook =~ tr/$/=/;
  if ( $flag =~ /.Debug$/ ) {
    %$state = &_evensplit(':', $realcook);
  } else {
    %$state = &_evensplit(':',$cipher->decrypt(MIME::Base64::decode($realcook)));
  }
  return undef unless exists ${$state}{MAC};	# punt if decode failure
  foreach (keys %$state) {
    ${$state}{$_} =~ s/%58/:/g;
  }
# invalid if the cookie was tampered with
  
  return undef unless &_MAC($self, $state, $ck, 'check');
  foreach ( @$ck ) {
    return undef unless exists ${$state}{$_};
  }
  $flag;		# return true
}

sub checkMAC {
  my ( $self, $s, $k ) = @_;
  return _MAC($self, $s, $k, 'check');
}

sub _MAC {
  my ( $self, $s, $k, $action ) = @_;
  @_ = ($k) ? sort @$k : ();
  my @fields = @{$s}{@_};
  my $md5 = Crypt::CapnMidNite->new_md5;
  my $newmac = $md5->md5_base64($self->{CRYPT} . 
	$md5->md5_base64(join '', $self->{CRYPT}, @fields));
  return $s->{MAC} = $newmac if $action eq 'generate';
  return 1 if ($newmac eq $s->{MAC} && $action eq 'check');
  return undef;
}

# split to an even number of fields
# this will split to a hash when the trailing value is null
#
sub _evensplit {
  my ( $m, $s ) = @_;
  @_ = split(/$m/, $s, -1);
  push ( @_, '') if @_ % 2;
  @_;
}

1;
__END__

=head1 NAME

Apache::CryptHash - Encrypted tokens for cookies

=head1 SYNOPSIS

use Apache::CryptHash;

=head1 DESCRIPTION

Creates an encrypted cookie-like string with a MAC (checksum) 
from a hash of critical and non-critical values. The MAC is 
created on only the critical values. Decryption will fail if
the string has been altered and the MAC does not match when 
the string is decrypted.

Particularly useful when using COOKIES and will do all the 
hard work for Apache::AuthCookie

=over 4

=item C<init()>

Create class reference and set passcode to the value
returned by Sys::Hostname::hostname;

  my $c = Apache::CryptHash->init;	# default passcode = hostname

init takes an optional parameter 

  my $c = Apache::CryptHash->init('no');

  $c->passcode('no'}		# will turn encryptation off
				# and put in Debug mode

Optionally, the passcode or debug may be set by

  $c->passcode('no')		# will turn encryptation off
                                # and put in Debug mode
  $c->passcode('newpasscode');	# change the passcode

=item C<name & passcode>


Hash Header may be set to any string

  $c->name('some_string');	# default 'Secret'

Just remember to obey the rules for allowed characters in cookie strings for
both B<name & passcode>

=item C<encode()>

Generate an encrypted cookie-like value from a hash. Optional invarient
values may be specified for a MAC

  $c->encode(\%state, \@mac_keys).

Only the crypt secret and the mac_keys valuess are present in the MAC. What
is returned is 

  NAME:crypted_string (NAME.Debug:crypted_string)

where $c->pascode(I<somename>) (default 'Secret')

=item C<decode($$$)>

Decrypt and generate state hash from the encrypted hash

  $c->decode(\$cookie,\%state, \@mac_keys);

Return false if decode or MAC fails

=item C<md5_hex($)>

Return the md5 hash of input string.

=item C<md5_b64($)>

Return the md5 base 64 hash of input string.

=item C<checkMAC>

  $c = Apache::CryptHash->init('some password');
  $c->checkMAC(\%state, \@mac_keys)

Does a comparison of the MAC in the B<%state> vs the calculated value based
on B<@mac_keys> and returns a boolean result.

Don't forget to set the B<passcode> or the check will fail!

=back

=head1 SEE ALSO

L<Crypt::CapnMidNite>
L<Crypt::RC4>
L<Digest::MD5>
L<MIME::Base64>

=head1 COPYRIGHT and LICENSE

  Copyright 2003 Michael Robinton, BizSystems.

This module is free software; you can redistribute it and/or modify it
under the terms of either:

  a) the GNU General Public License as published by the Free Software
  Foundation; either version 1, or (at your option) any later version,
  
  or

  b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=cut
