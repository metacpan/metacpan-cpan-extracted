# -*-cperl-*-
#
# Crypt::HashCash::Client - Client for HashCash digital cash
# Copyright (c) 2001-2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: lib/Crypt/HashCash/Client.pm v1.118 Sat Jun 10 13:59:10 PDT 2017 $

package Crypt::HashCash::Client;

use warnings;
use strict;

use Crypt::Random qw(makerandom);
use Bytes::Random::Secure;
use Crypt::RSA::Blind;
use Crypt::ECDSA::Blind;
use Crypt::HashCash::Coin;
use Crypt::HashCash::CoinRequest;
use Crypt::CBC;
use Persistence::Object::Simple;
use Crypt::EECDH;
use Crypt::HashCash qw (_dec _hex);
use Compress::Zlib;
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.118 $' =~ /\s+([\d\.]+)/;

sub new {
  my $class = shift;
  my %arg = @_;
  bless { RSAB           =>   new Crypt::RSA::Blind,
	  ECDSAB         =>   new Crypt::ECDSA::Blind,
	  SIGSCHEME      =>   'ECDSA',
	  VERSION        =>   "Crypt::HashCash::Client v$VERSION",
	  VAULTCONF      =>   $arg{VaultConfig} || '/tmp/vault.cfg',
	  DEBUG          =>   $arg{Debug} || 0,
	  XSIZE          =>   128
	}, $class;
}

sub loadkeys {
  my $self = shift;
  my %pkey;
  my $keydb = new Persistence::Object::Simple ('__Fn' => $self->vaultconf);
  $self->keydb($keydb); $self->sigscheme($keydb->{sigscheme});
  $self->denoms([sort { $a <=> $b } keys %{$self->keydb->{pub}}]);
  my $sigmod = 'Crypt::' . $self->sigscheme . '::Blind';
  no strict 'refs';
  for (@{$self->denoms}) {
    $pkey{$_} = &{$sigmod.'::PubKey::from_hex'}($self->keydb->{pub}->{$_});
  }
  $self->vaultkey(pack ('H*',$self->keydb->{vaultpub}));
  $self->mintkeys(\%pkey);
}

sub request_coin {
  my $self = shift; my %arg = @_;
  $self->_diag("CLIENT: request_coin()\n");
  return unless my $mintkey = $self->mintkeys->{$arg{Denomination}};
  my $x = makerandom( Size => $self->xsize, Strength => 1 );
  $self->_diag("x: $x\n");
  my $signer = $self->sigscheme eq 'RSA' ? $self->rsab : $self->ecdsab;
  my $req = $signer->request(Key => $mintkey, Message => $x, Init => $arg{Init});
  $self->_diag("req: $req\n");
  $self->_request($arg{Init} => $x);
  return ( bless { R => $req, D => $arg{Denomination}, Init => $arg{Init} }, 'Crypt::HashCash::CoinRequest' );
}

sub unblind_coin {
  my $self = shift;
  $self->_diag("CLIENT: unblind_coin()\n");
  my $bcoin = shift;
  return unless my $mintkey = $self->mintkeys->{$bcoin->{D}};
  my $signer = $self->sigscheme eq 'RSA' ? $self->rsab : $self->ecdsab;
  my $coin = $signer->unblind(Signature => $bcoin->{C}, Key => $mintkey, Init => $bcoin->{Init});
  $self->_diag("coin (bc / b): $coin\n");
  my $x = $self->_request($bcoin->{Init});
  return ( bless { X => $x, D => $bcoin->{D}, Z => $coin }, 'Crypt::HashCash::Coin' );
}

sub verify_coin {
  my $self = shift;
  $self->_diag ("CLIENT: verify_coin()\n");
  my $coin = shift;
  return unless ref $coin eq 'Crypt::HashCash::Coin';
  $self->_diag ("coin: $coin->{Z}\nX: $coin->{X}\nD: $coin->{D}\n");
  my $signer = $self->sigscheme eq 'RSA' ? $self->rsab : $self->ecdsab;
  $signer->verify(Key => $self->mintkeys->{$coin->{D}}, Signature => $coin->{Z}, Message => $coin->{X});
}

sub turingimg {         # Get turing image
  my $self = shift;
  my $res = $self->msgvault('hi');
  return undef if !$res or $res =~ /^-ERR/;
  my ($turingid, $turing) = split / /, $res;
  $self->turingid($turingid);
  my $turingimage = pack('H*',$turing);
}

sub cancelturing {
  my $self = shift;
  $self->msgvault('dt ' . $self->turingid);
}

sub getaddress {
  my ($self, %arg) = @_;
  my $res = $self->msgvault('id ' . $self->turingid . " $arg{Turing} $arg{Amt} $arg{Numcoins}");
  return undef if !$res or $res =~ /^-ERR/;
  return $res;
}

sub initbuy {           # Initializa a buy
  my ($self, %arg) = @_;
  my $res = $self->msgvault("id $arg{Address} $arg{Amt} $arg{Numcoins}");
  return undef if !$res or $res =~ /^-ERR/;
  my $inits = [ split / /, $res ]
}

sub buy {               # Buy HashCash
  my ($self, %arg) = @_;
  my @reqstrs = map { $_->as_string } @{$arg{Requests}};
  my $res = $self->msgvault("d $arg{Address} @reqstrs");
  return undef if !$res or $res =~ /^-ERR/;
  my $coins = [ map { Crypt::HashCash::Coin::Blinded->from_string($_) } split / /, $res ];
}

sub sell {
  my ($self, %arg) = @_;
  my @coins = map { $_->as_string } @{$arg{Coins}};
  my $res = $self->msgvault("w $arg{Address} $arg{Amount} $arg{BTCFee} $arg{Change} @coins");
}

sub initexchange {
  my ($self, %arg) = @_;
  my ($coins, $denoms, $chgdenoms, $d, $feecoins) = @arg{qw(Coins ReqDenoms ChangeDenoms ReplaceDenoms FeeCoins)};
  my $res = $self->msgvault('ie ' .                                                                # Init Exchange
		     (join ',', map { "$_:$coins->{$_}" } keys %$coins) . ' ' .                    # Denominations of coins being exchanged
		     (join ',', map { "$_:$denoms->{$_}" } keys %$denoms) . ' ' .                  # Denominations of coins being requested
		     ((join ',', map { "$_:$chgdenoms->{$_}" } keys %$chgdenoms) || '0:0') . ' ' . # Denominations of change coins from fee payment
		     ((join ',', map { "$_:$d->{$_}" } keys %$d) || '0:0') . ' ' .                 # Denominations of exchange coins replaced by change coins
		     (join ' ', map { $_->as_string } @$feecoins));                                # The fee coins
}

sub exchange {
  my ($self, %arg) = @_;
  my ($coins, $feecoins, $requests, $changereqs) = @arg{qw(Coins FeeCoins Requests ChangeRequests)};
  my $chgreqs = '';
  if (scalar @$changereqs) {
    my @creqstrs = map { $_->as_string } @$changereqs; $chgreqs = " c @creqstrs";
  }
  my @reqstrs = map { $_->as_string } @$requests;
  my $res = $self->msgvault('e ' . (join ',', map { "$_:$feecoins->{$_}" } keys %$feecoins) . ' ' .
			    (join ' ', map { $_->as_string } @$coins) . " r @reqstrs" . $chgreqs);
}

sub msgvault {          # Encrypt and send a message to the vault, decrypt and return the response
  my ($self, $msg) = @_;
  my $eecdh = new Crypt::EECDH;
  my ($encrypted, $seckey) = $eecdh->encrypt( PublicKey => $self->vaultkey, Message => $msg);  # Encrypt message with the vault's public key
  return unless my $res = $self->offline ? $self->_msgvault_offline(_dec(unpack 'H*', $encrypted)) :
    $self->_msgvault(_dec(unpack 'H*', $encrypted));
  $self->_diag("R: $res\n");
  my ($decrypted) = $eecdh->decrypt( Key => $seckey, Ciphertext => (pack 'H*', _hex($res))); # Decrypt the response
  return $decrypted;
}

sub _msgvault {
  my ($self, $msg) = @_;
  require IO::Socket::INET;
  $self->_diag("MV:connecting\n");
  return unless (my $vault = IO::Socket::INET->new(PeerAddr => 'localhost:20203'));
  print $vault "$msg\n";
  $self->_diag("MV:waiting\n");
  no warnings;
  my $res = <$vault>;
  $self->_diag("MV:$res\n");
  $res =~ s/\s*$//; $vault->close;
  use warnings;
  $res;
}

sub _msgvault_offline {
  require Wx;
  import Wx qw(:everything);
  my ($self, $msg) = @_;
  my $qrfh; my $level; my $qr;
  my $info = "Copy message from below and send to vault,\nthen replace with vault's response.";
  my $len = length($msg); my $version;
  my $dialog = Wx::TextEntryDialog->new( $self->frame, $info, "Communicate with Vault", $msg);
  my $dialog_height = $dialog->GetSize->GetHeight;
  my $fontheight = $self->frame->GetCharHeight;
  if ($len < 7090 ) {
    Wx::InitAllImageHandlers();
    my @version = qw( 0 41 77 127 187 255 322 370 461 552 652 772 883 1022 1101 1250 1408 1548 1725 1903 2061 2232 
		      2409 2620 2812 3057 3283 3517 3669 3909 4158 4417 4686 4965 5253 5529 5836 6153 6479 6743 7089 );
    for (1..40) { next if $len > $version[$_]; $version = $_; last; }
    my $qrxpm = GD::Barcode::QRcode->new($msg, { Version => $version, Ecc => 'L', ModuleSize => 2 })->barcode;
    $qrxpm =~ /^(.*)$/m; my $qrsize = length($1);
    $qr = Wx::Bitmap->newFromXPM([ split /\n/, "$qrsize $qrsize 2 1\n0 c #FFFFFF\n1 c #000000\n$qrxpm" ]);
    $info = "\n" x ($qr->GetHeight / $fontheight) . "\n\nScan QR code or copy message from below and send\n" .
      "to vault, then enter vault's response below.";
  }
  $dialog = Wx::TextEntryDialog->new( $self->frame, $info, "Communicate with Vault", $msg);
  if (defined $qr) {
    my $dialogwidth = $dialog->GetSize->GetWidth;
    my $qrheight = $qr->GetHeight; my $width = $qrheight + 20 > $dialogwidth ? $qrheight + 20 : $dialogwidth;
    my $adjust = 10 unless $^O eq 'MSWin32' or $^O eq 'darwin';
    my $qrpos = ($width-$qrheight)/2 + ($width == 300 ? $adjust : 0);
    $dialog->SetSize([$width,$dialog_height+$qrheight+$fontheight*2+10]);
    $dialog->SetMinSize([$width,$dialog_height+$qrheight+$fontheight*2+10]);
    $dialog->SetMaxSize([$width,$dialog_height+$qrheight+$fontheight*2+10]);
    my $st = Wx::StaticBitmap->new( $dialog, -1, $qr, [$qrpos,10] );
  }
  if($dialog->ShowModal == wxID_CANCEL()) {
    return;
  }
  $dialog->GetValue();
}

sub _request {
  my $self = shift;
  my $Rp = $_[0]; my $ret;
  if ($_[1]) {
    $self->{Requests}->{$Rp} = $_[1];
  }
  else {
    $ret = $self->{Requests}->{$Rp};
    delete $self->{Requests}->{$Rp};
  }
  return $ret;
}

sub _diag {
  my $self = shift;
  print STDERR @_ if $self->debug;
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(vaultconf|vaultkey|mintkeys|xsize|debug|version|hash|rsab|ecdsab|denoms|keydb|sigscheme|turingid|frame|offline)$/x) {
    $self->{"\U$auto"} = shift if (defined $_[0]);
    return $self->{"\U$auto"};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

1;

__END__

=head1 NAME

Crypt::HashCash::Client - Client for HashCash digital cash

=head1 VERSION

 $Revision: 1.118 $
 $Date: Sat Jun 10 13:59:10 PDT 2017 $

=head1 SYNOPSIS

  use Crypt::HashCash::Client;;

  my $client = new Crypt::HashCash::Client;

  $client->loadkeys;                           # Load vault keys

  my $request = $client->request_coin          # Request a coin
    ( Denomination => $denomination,
      Init => $init );

  my $coin = $client->unblind_coin($blindcoin) # Unblind a blinded coin

  print "OK\n" if $client->verify_coin($coin)  # Verify coin's signature

=head1 DESCRIPTION

This module implements a client for the HashCash digital cash
system. It provides methods to request, unblind and verify the
signature on HashCash coins.

=head1 METHODS

=head2 new

Creates and returns a new Crypt::HashCash::Vault::Bitcoin object.

=head2 loadkeys

=head2 request_coin

=head2 unblind_coin

=head2 verify_coin

=head2 turingimg

=head2 cancelturing

=head2 getaddress

=head2 initbuy

=head2 buy

=head2 sell

=head2 initexchange

=head2 exchange

=head2 msgvault

=head1 ACCESSORS

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-hashcash at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-hashcash at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-HashCash>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::HashCash::Client

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-HashCash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-HashCash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-HashCash>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-HashCash/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2001-2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
