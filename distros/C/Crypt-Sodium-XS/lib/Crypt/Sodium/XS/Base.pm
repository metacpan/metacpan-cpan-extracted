package Crypt::Sodium::XS::Base;
use warnings;
use strict;

sub sodium_op {
  my $module = shift;
  die "Invalid sodium module name '$module'" unless $module =~ /^\A[A-Z0-9a-z_]+\z/;
  my $pkg = "Crypt::Sodium::XS::OO::$module";
  my $path = "Crypt/Sodium/XS/$module.pm";
  die "Failed to load module '$path'" unless CORE::require($path);
  return $pkg->new(@_);
}

sub aead { shift; sodium_op(aead => @_) }
sub auth { shift; sodium_op(auth => @_) }
sub box { shift; sodium_op(box => @_) }
sub curve25519 { shift; sodium_op(curve25519 => @_) }
sub generichash { shift; sodium_op(generichash => @_) }
sub hash { shift; sodium_op(hash => @_) }
sub hkdf { shift; sodium_op(hkdf => @_) }
sub ipcrypt { shift; sodium_op(ipcrypt => @_) }
sub kdf { shift; sodium_op(kdf => @_) }
sub kx { shift; sodium_op(kx => @_) }
sub onetimeauth { shift; sodium_op(onetimeauth => @_) }
sub pwhash { shift; sodium_op(pwhash => @_) }
sub scalarmult { shift; sodium_op(scalarmult => @_) }
sub secretbox { shift; sodium_op(secretbox => @_) }
sub secretstream { shift; sodium_op(secretstream => @_) }
sub shorthash { shift; sodium_op(shorthash => @_) }
sub sign { shift; sodium_op(sign => @_) }
sub stream { shift; sodium_op(stream => @_) }

1;
