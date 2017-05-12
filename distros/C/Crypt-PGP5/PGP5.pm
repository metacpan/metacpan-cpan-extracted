# -*-cperl-*-
#
# Crypt::PGP5 - A module for accessing PGP 5 functionality.
# Copyright (c) 1999-2000 Ashish Gulhati <hash@netropolis.org>
#
# All rights reserved. This code is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: PGP5.pm,v 1.38 2000/10/13 14:56:54 cvs Exp $

package Crypt::PGP5;

=pod

=head1 NAME 

Crypt::PGP5 - An Object Oriented Interface to PGP5.

=head1 SYNOPSIS

  use Crypt::PGP5;
  $pgp = new Crypt::PGP5;

  $pgp->secretkey ($keyid);        # Set ID of default secret key.
  $pgp->passphrase ($passphrase);  # Set passphrase.
  $pgp->armor ($boolean);          # Switch ASCII armoring on/off.
  $pgp->detach ($boolean);         # Switch detached signatures on/off.
  $pgp->encryptsafe ($boolean);    # Switch paranoid encryption on/off.
  $pgp->version ($versionstring);  # Set version string.
  $pgp->debug ($boolean);          # Switch debugging output on/off.

  $signed = $pgp->sign (@message);
  @recipients = $pgp->msginfo (@ciphertext);
  $ciphertext = $pgp->encrypt ([@recipients], @plaintext);
  ($signature, $plaintext) = $pgp->verify (@ciphertext);
  ($signature, $plaintext) = $pgp->dverify ([@signature], [@message]);

  (Most of the methods below will be encapsulated into the
  Crypt::PGP5::Key class by next release, bewarned!)

  $pgp->addkey ($keyring, @key);
  $pgp->delkey ($keyid);
  $pgp->disablekey ($keyid);
  $pgp->enablekey ($keyid);
  @keys = $pgp->keyinfo (@ids);
  $keystring = $pgp->extractkey ($userid, $keyring);
  $pgp->keypass ($keyid, $oldpasswd, $newpasswd);
  $status = $pgp->keygen 
    ($name, $email, $keytype, $keysize, $expire, $pass);

=head1 DESCRIPTION

The Crypt::PGP5 module provides near complete access to PGP 5
functionality through an object oriented interface. It provides
methods for encryption, decryption, signing, signature verification,
key generation, key export and import, and most other key management
functions.

=cut

use Carp;
use 5.005;
use Fcntl;
use Expect;
use strict;
use POSIX qw( tmpnam );
use vars qw( $VERSION $AUTOLOAD );
use Time::HiRes qw( sleep );

( $VERSION ) = '$Revision: 1.38 $' =~ /\s+([\d\.]+)/;

=pod

=head1 CONSTRUCTOR

=over 2

=item B<new ()>

Creates and returns a new Crypt::PGP5 object.

=back

=cut

sub new {
  bless { PASSPHRASE     =>   0,
	  ARMOR          =>   1,
	  DETACH         =>   1,
	  ENCRYPTSAFE    =>   1,
	  SECRETKEY      =>   0,
	  DEBUG          =>   1,
	  VERSION        =>   "Version: Crypt::PGP5 v$VERSION\n",
	}, shift;
}

=pod

=head1 DATA METHODS

=over 2

=item B<secretkey ()>

Sets the B<SECRETKEY> instance variable which may be a KeyID or a
username. This is the ID of the default key to use for signing.

=item B<passphrase ()>

Sets the B<PASSPHRASE> instance variable, required for signing and
decryption.

=item B<armor ()>

Sets the B<ARMOR> instance variable. If set to 0, Crypt::PGP5 doesn't
ASCII armor its output. Else, it does. Default is to use
ascii-armoring. I haven't tested this without ASCII armoring yet.

=item B<detach ()>

Sets the B<DETACH> instance variable. If set to 1, the sign method
will produce detached signature certificates, else it won't. The
default is to produce detached signatures.

=item B<encryptsafe ()>

Sets the B<ENCRYPTSAFE> instance variable. If set to 1, encryption
will fail if trying to encrypt to a key which is not trusted. This is
the default. Switch to 0 if you want to encrypt to untrusted keys.

=item B<version ()>

Sets the B<VERSION> instance variable which can be used to change the
Version: string on the PGP output to whatever you like.

=item B<debug ()>

Sets the B<DEBUG> instance variable which causes the raw output of
Crypt::PGP5's interaction with the PGP binary to be dumped to STDOUT.

=back

=cut

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  if ($auto =~ /^(passphrase|secretkey|armor|
                  detach|encryptsafe|version|debug)$/x) {
    $self->{"\U$auto"} = shift;
  }
  else {
    croak "Could not AUTOLOAD method $auto.";
  }
}

=pod

=head1 OBJECT METHODS

=over 2

=item B<sign (@message)>

Signs B<@message> with the secret key specified with B<secretkey ()>
and returns the result as a string.

=cut

sub sign {
  my $self = shift; my ($secretkey, $detach, $armor) = ();
  $detach = "-b" if $self->{DETACH}; $armor = "-a" if $self->{ARMOR}; 
  $secretkey = "-u " . $self->{SECRETKEY} if $self->{SECRETKEY};
  my $expect = Expect->spawn ("pgps $armor $detach $secretkey"); 
  $expect->log_stdout($self->{DEBUG});
  my $message = join ('', @_); $message .= "\n" unless $message =~ /\n$/s;
  $expect->expect (undef, "No files specified."); 
  sleep (0.2); print $expect ("$message\x04"); 
  $expect->expect (undef, 'Enter pass phrase:'); 
  sleep (0.2); print $expect "$self->{PASSPHRASE}\r";
  $expect->expect (undef, '-re', 'phrase is good.\s*', '-re', 'pass phrase:\s*');
  return undef if ($expect->exp_match_number==2);
  sleep (0.2); $expect->expect (undef); my $info = $expect->exp_before(); 
  $info =~ s/\r//sg; $info =~ s/^Version:.*\n/$self->{VERSION}/m; return $info;
}

=pod

=item B<verify (@message)>

Verifies or decrypts the message in B<@message> and returns the
Crypt::PGP5::Signature object corresponding to the signature on the
message (if any, or undef otherwise), and a string containing the
decrypted message.

=cut

sub verify {
  my $self = shift; my $tmpnam;
  do { $tmpnam = tmpnam() } until sysopen(FH, $tmpnam, O_RDWR|O_CREAT|O_EXCL);
  print FH join '',@_; close FH;
  my $expect = Expect->spawn ("pgpv $tmpnam -o-"); $expect->log_stdout($self->{DEBUG});
  $expect->expect (undef, '-re', 'type binary.\s*', '-re', 'pass phrase:\s*',
		          '-re', 'File to check signature against');
  unlink $tmpnam, return undef if ($expect->exp_match_number==3);
  if ($expect->exp_match_number==2) {
    sleep (0.2); print $expect "$self->{PASSPHRASE}\r";
    $expect->expect (undef, '-re', 'type binary.\s*', '-re', 'pass phrase:\s*');
    unlink $tmpnam, return undef if ($expect->exp_match_number==2)
  }
  sleep (0.2); $expect->expect (undef); my $info = $expect->exp_before(); unlink $tmpnam;
  $info =~ s/\r//sg; my $trusted = ($info !~ /WARNING: The signing key is not trusted/s);
  return (undef, $info) 
    unless $info =~ /^(.*)(Good|BAD)\ signature\ made\ (\S+\s+\S+\s+\S+)\ by\ key:
	             \s+(\S+)\s+bits,\ Key\ ID\ (\S+),\ Created\ (\S+)\s+\"([^\"]+)\"/sx;
  my $signature = {'Validity' => $2, 'UID' => $7, 'KeyID' => $5, 'Time' => $3, 
	 'Keytime' => $6, Keysize => $4, 'Trusted' => $trusted};
  bless $signature, 'Crypt::PGP5::Signature';
  return ($signature, $1);
}

=pod

=item B<dverify ([@message], [@signature])>

Verifies the detactched signature B<@signature> on B<@message> and
returns a Crypt::PGP5::Signature object corresponding to the signature
on the message, along with a string containing the plaintext message.

=cut

sub dverify { # TODO **** TODO ******* Merge this into verify() ******* TODO **** TODO
  my $self = shift;
  my $message = join '', @{$_[0]}; my $sign = join '', @{$_[1]};
  $message .= "\n" unless $message =~ /\n$/s;
# $message =~ s/\n/\r\n/sg;
  my $tmpnam; do { $tmpnam = tmpnam() } until sysopen(FH, $tmpnam, O_RDWR|O_CREAT|O_EXCL);
  my $tmpnam2; do { $tmpnam2 = tmpnam() } until sysopen(FH2, $tmpnam2, O_RDWR|O_CREAT|O_EXCL);
  print FH $sign; close FH; print FH2 $message; close FH2;
  my $expect = Expect->spawn ("pgpv $tmpnam"); $expect->log_stdout($self->{DEBUG});
  $expect->expect(undef, "File to check signature against"); 
  sleep (0.2); print $expect "$tmpnam2\r"; 
  sleep (0.2); $expect->expect(undef); my $info = $expect->exp_before();
  unlink $tmpnam; unlink $tmpnam2; 
  my $trusted = ($info !~ /WARNING: The signing key is not trusted/s);
  return (undef, $message) 
    unless $info =~ /(Good|BAD)\ signature\ made\ (\S+\s+\S+\s+\S+)\ by\ key:
		     \s+(\S+)\s+bits,\ Key\ ID\ (\S+),\ Created\ (\S+)\s+\"([^\"]+)\"/sx;
  my $signature = {'Validity' => $1, 'UID' => $6, 'KeyID' => $4, 'Time' => $2, 
		   'Keytime' => $5, Keysize => $3, 'Trusted' => $trusted};
  bless $signature, 'Crypt::PGP5::Signature';
  return ($signature, $message);
}

=pod

=item B<msginfo (@ciphertext)>

Returns a list of the recipient key IDs that B<@ciphertext> is
encrypted to.

=cut

sub msginfo {
  my $self = shift; my @return = (); my $tmpnam; 
  my $home = $ENV{'HOME'}; $ENV{'HOME'} = '/dev/null';
  do { $tmpnam = tmpnam() } until sysopen(FH, $tmpnam, O_RDWR|O_CREAT|O_EXCL);
  print FH join '',@_; close FH;
  my $expect = Expect->spawn ("pgpv $tmpnam"); $expect->log_stdout($self->{DEBUG});
  sleep (0.2); $expect->expect (undef); my $info = $expect->exp_before();
  $info =~ s/Key ID (0x.{8})/{push @return, $1}/sge; $ENV{'HOME'} = $home; unlink $tmpnam;
  return @return;
}

=pod

=item B<encrypt ([$keyid1, $keyid2...], @plaintext)>

Encrypts B<@plaintext> with the public keys of the recipients listed
in the arrayref passed as the first argument and returns the result in
a string, or B<undef> if there was an error while processing. Returns
ciphertext if the message could be encrypted to at least one of the
recipients.

=cut

sub encrypt {
  my $self = shift; my $recipients = shift; my $info = ''; my $tmpnam;
  my $armor = "-a" if $self->{ARMOR}; my $rcpts = join ( ' ', map "-r$_", @{ $recipients } );
  do { $tmpnam = tmpnam() } until sysopen(FH, $tmpnam, O_RDWR|O_CREAT|O_EXCL);
  my $message = join ('',@_); $message .= "\n" unless $message =~ /\n$/s; 
  print FH $message; close FH;
  my $expect = Expect->spawn ("pgpe $tmpnam $armor -o- $rcpts"); 
  $expect->log_stdout($self->{DEBUG});
  while (1) {
    $expect->expect (undef, '-----BEGIN PGP', 'key with this name? [y/N]', 'No valid keys');
    if ($expect->exp_match_number==2) {
      sleep (0.2);
      if ($self->{ENCRYPTSAFE}) {
	print $expect "n\n";
	$expect->expect (undef);
	return undef;
      }
      else {
	print $expect "y\n";
      }	
    }
    elsif ($expect->exp_match_number==3) {
      unlink $tmpnam;
      return undef;
    }
    else {
      $info = $expect->exp_match();
      last;
    }
  }
  sleep (0.2); $expect->expect (undef);
  $info .= $expect->exp_before(); $info =~ s/.*\n(-----BEGIN)/$1/s;
  unlink $tmpnam;
  $info =~ s/\r//sg; $info =~ s/^Version:.*\n/$self->{VERSION}/m; return $info;
}

=pod

=item B<addkey ($key, $pretend)>

Adds the keys given in B<$key> to the user's key ring and returns a
list of Crypt::PGP::Key objects corresponding to the keys that were
added. If B<$pretend> is true, it pretends to add the key and creates
the key object, but doesn't actually perform the key addition.

=cut

sub addkey {
  my $self = shift; my $key = shift; my $pretend = shift; my $tmpnam;
  do { $tmpnam = tmpnam() } until sysopen(FH, $tmpnam, O_RDWR|O_CREAT|O_EXCL);
  print FH $key; close FH; my $reallyadd=$pretend?'n':'y';
  my $expect = Expect->spawn ("pgpk -a $tmpnam"); $expect->log_stdout($self->{DEBUG});
  $expect->expect (undef, '-re', '(Unable|to your)');
  my $x = $expect->exp_match(); return undef unless $x =~ /to your/; print "$x\n";
  my $info = $expect->exp_before(); sleep (0.2); print $expect ("$reallyadd\r");
  sleep (0.2); $expect->expect (undef); unlink $tmpnam;
  $info =~ s/.*Key ring:[^\n]*\n(.*found\s*\n).*/$1/s; my @r = split (/\r\n?/, $info); 
  return parsekeys (@r);
}

=pod

=item B<delkey ($keyid)>

Deletes the key with B<$keyid> from the user's key ring.

=cut

sub delkey {
  my $self = shift; my $key = shift;
  my $expect = Expect->spawn ("pgpk -r $key"); $expect->log_stdout($self->{DEBUG});
  $expect->expect (undef, "[y/N]? "); my $info = $expect->exp_before(); 
  sleep (0.2); print $expect ("y\r"); sleep (0.2); $expect->expect (undef);
}

=pod

=item B<disablekey ($keyid)>

Disables the key with B<$keyid>.

=cut

sub disablekey {
  my $self = shift; my $key = shift;
  my $keyinfo = $self->keyinfo($key);
  return if ${$keyinfo}{Type} =~ /\@$/;
  my $expect = Expect->spawn ("pgpk -d $key"); $expect->log_stdout($self->{DEBUG});
  $expect->expect (undef, "[y/N] "); my $info = $expect->exp_before(); 
  sleep (0.2); print $expect ("y\r"); sleep (0.2); $expect->expect (undef);
}

=pod

=item B<enablekey ($keyid)>

Enables the key with B<$keyid>.

=cut

sub enablekey {
  my $self = shift; my $key = shift;
  my $keyinfo = $self->keyinfo($key);
  return unless ${$keyinfo}{Type} =~ /\@$/;
  my $expect = Expect->spawn ("pgpk -d $key"); $expect->log_stdout($self->{DEBUG});
  $expect->expect (undef, "[y/N] "); my $info = $expect->exp_before(); 
  sleep (0.2); print $expect ("y\r"); sleep (0.2); $expect->expect (undef);
}

=pod

=item B<keyinfo (@keyids)>

Returns an array of Crypt::PGP5::Key objects corresponding to the
keyids listed in B<@keyids>.

=cut

sub keyinfo {
  my $self = shift; my $ids = join '|',@_;
  my @keylist = `pgpk -ll 2>/dev/null`; 
  return (parsekeys (@keylist)) unless $ids;
  return grep { $_->{ID} =~ /^($ids)$/ or $_->{ID2} =~ /^($ids)$/ } parsekeys (@keylist);
}

=pod

=item B<parsekeys (@keylist)>

Parses a raw PGP formatted key listing and returns a list of
Crypt::PGP5::Key objects.

=cut

sub parsekeys {
  my @keylist = @_;
  $keylist[0] = "\n"; pop @keylist; my $i=-1; 
  my @keys; my $subkey=0; my $sign; my $uid;
  my $newkey = undef;
  foreach (@keylist) {
    if ($newkey) {
      $sign=0; $uid=0;
      /(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.+)/;
      $keys[++$i] = { 
		     Type       =>    $1,
		     Bits       =>    $2,
		     ID         =>    $3,
		     Created    =>    $4,
		     Expires    =>    $5,
		     Algorithm  =>    $6,
		     Use        =>    $7
		    };
    }
    else {
      if (/^f16\s+Fingerprint16 = (.*)$/) {
	$keys[$i]{Fingerprint}  =     $1;
      }
      if (/^f20\s+Fingerprint20 = (.*)$/) {
	if ($subkey) {
	  $keys[$i]{Fingerprint2}  =     $1;
	  $subkey                  =     0;
	}
	else {
	  $keys[$i]{Fingerprint}   =     $1;
	}
      }
      elsif (/^sub\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/) {
	$subkey                    =     1;
	$keys[$i]{Bits2}           =     $1;
	$keys[$i]{ID2}             =     $2;
	$keys[$i]{Created2}        =     $3;
	$keys[$i]{Expires2}        =     $4;
	$keys[$i]{Algorithm2}      =     $5;
      }
      elsif (/^(sig|SIG)(.)\s+(\S+)\s+(\S+)\s+(.*)/) {
	push (@{$keys[$i]{SIGNS}}, 
	      {	ID    =>     $3,
		Date  =>     $4,
		UID   =>     $5
	      }
	     );
      }
      elsif (/^uid\s+(.*)/) {
	push (@{$keys[$i]{UIDS}}, $1);
      }
    }
    $newkey = /^$/;
  }
  return map {bless $_, 'Crypt::PGP5::Key'} @keys;
}

=pod

=item B<keypass ($keyid, $oldpass, $newpass)>

Change the passphrase for a key. Returns true if the passphrase change
succeeded, false if not.

=cut

sub keypass {
  my $self = shift; my ($keyid, $oldpass, $newpass) = @_;
  my $keyinfo = $self->keyinfo($keyid);
  return unless ${$keyinfo}{Type} =~ /^sec/;
  my $expect = Expect->spawn ("pgpk -e $keyid"); $expect->log_stdout($self->{DEBUG});
  $expect->expect (undef, '[y/N]? '); sleep (0.2); print $expect ("\r"); 
  $expect->expect (undef, '[y/N]? '); sleep (0.2); print $expect ("\r"); 
  $expect->expect (undef, '(y/N)? '); sleep (0.2); print $expect ("y\r"); 
  $expect->expect (undef, 'phrase: '); sleep (0.2); print $expect ("$oldpass\r"); 
  $expect->expect (undef, 'phrase: '); sleep (0.2); print $expect ("$newpass\r"); 
  $expect->expect (undef, 'phrase: '); sleep (0.2); print $expect ("$newpass\r"); 
  $expect->expect (undef, '[y/N]? '); sleep (0.2); print $expect ("y\r"); 
  sleep (0.2); $expect->expect (undef); my $info = $expect->exp_before();
  $info =~ /Keyrings updated.$/s;
}

=pod

=item B<extractkey ($userid, $keyring)>

Extracts the key for B<$userid> from B<$keyring> and returns the
result. The B<$keyring> argument is optional and defaults to the
public keyring set with B<pubring ()>.

=cut

sub extractkey {
  my $self = shift; my $userid = shift; my $keyring = shift; my $armor = '';
  $keyring = "-o $keyring" if $keyring; $armor = "-a" if $self->{ARMOR}; 
  my $expect = Expect->spawn ("pgpk -x $armor \"$userid\" $keyring 2>/dev/null"); 
  $expect->log_stdout($self->{DEBUG});
  sleep (0.2); $expect->expect (undef); my $info = $expect->exp_before();
  $info =~ s/\r//sg; $info =~ s/^Version:.*\n/$self->{VERSION}/m; split /\n/, $info; 
}

=pod

=item B<keygen ($name, $email, $keytype, $keysize, $expire, $pass)>

Creates a new keypair with the parameters specified. B<$keytype> may
be one of 'RSA' or 'DSS'. B<$keysize> can be any of 768, 1024, 2048,
3072 or 4096 for DSS keys, and 768, 1024 or 2048 for RSA type
keys. Returns undef if there was an error, otherwise returns a
filehandle that reports the progress of the key generation process
similar to the way PGP does. The key generation is not complete till
you read an EOF from the returned filehandle.

=cut

sub keygen {
  my $self = shift; my ($name, $email, $keytype, $keysize, $expire, $pass) = @_;
  my $pid = open(PGP, "-|");
  return undef unless (defined $pid);
  if ($pid) {
    $SIG{CHLD} = 'IGNORE';
    return \*PGP;
  }
  else {
    my $expect = Expect->spawn ("pgpk -g"); $expect->log_stdout($self->{DEBUG});
    my $kt = $keytype='DSS'?1:2; return undef if $keysize > 4096 or $kt == 2 and $keysize > 2048;
    $expect->expect (undef, '1 or 2: '); sleep (0.2); print $expect ( "$kt\r"); print ".\n";
    $expect->expect (undef, '): '); sleep (0.2); print $expect ("$keysize\r"); print ".\n";
    $expect->expect (undef, 'key: '); sleep (0.2); print $expect ("$name <$email>\r"); print ".\n";
    $expect->expect (undef, 'default): '); sleep (0.2); print $expect ("$expire\r"); print ".\n";
    $expect->expect (undef, 'phrase: '); sleep (0.2); print $expect ("$pass\r"); print ".\n";
    $expect->expect (undef, 'phrase: '); sleep (0.2); print $expect ("$pass\r"); print ".\n";
    $expect->expect (undef, '-re', '([\*\.]|successfully\.)'); print ".\n";
    my $x = $expect->exp_match(); 
    while ($x !~ /successfully/) {
      print "$x\n";
      $expect->expect (undef, '-re', '([\*\.]|successfully\.)'); 
      $x = $expect->exp_match(); 
    }	
    print "|\n";
    sleep (0.2); $expect->expect (undef, 'nothing.');
    exit();
  }
}

=pod

=back

=head1 BUGS

=over 2

=item * 

Error checking needs work. 

=item * 

Some key manipulation functions are missing. 

=item * 

May not work with versions of PGP other than PGPfreeware 5.0i. 

=item * 

The method call interface is subject to change in future versions,
specifically, key manipulation methods will be encapsulated into the
Crypt::PGP5::Key class in a future version.

=item * 

The current implementation will probably eat up all your RAM if you
try to operate on huge messages. In future versions, this will be
addressed by reading from and returning filehandles, rather than using
in-core data.

=back

=head1 AUTHOR

Crypt::PGP5 is Copyright (c) 1999-2000 Ashish Gulhati
<hash@netropolis.org>. All Rights Reserved.

=head1 ACKNOWLEDGEMENTS

Thanks to Barkha for inspiration and lots of laughs; to Rex Rogers at
Laissez Faire City for putting together a great environment to hack on
freedom technologies; and of-course, to Phil Zimmerman, Larry Wall,
Richard Stallman, and Linus Torvalds.

=head1 LICENSE

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

It would be nice if you would mail your patches to me, and I would
love to hear about projects that make use of this module.

=head1 DISCLAIMER

This is free software. If it breaks, you own both parts.

=cut

'True Value';
