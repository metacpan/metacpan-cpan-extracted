# -*-cperl-*-
#
# Crypt::HashCash::Vault::Bitcoin - Bitcoin Vault for HashCash Digital Cash
# Copyright (c) 2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: lib/Crypt/HashCash/Vault/Bitcoin.pm v1.129 Tue Oct 16 16:56:38 PDT 2018 $

package Crypt::HashCash::Vault::Bitcoin;

use 5.008001;
use warnings;
use strict;

use Crypt::HashCash qw (_dec breakamt);
use Crypt::HashCash::Mint;
use Crypt::Random qw(makerandom);
use Digest::MD5 qw(md5_hex);
use Crypt::EECDH;
use Business::Bitcoin;
use Authen::TuringImage;
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.129 $' =~ /\s+([\d\.]+)/;

sub new {
  my ($class, %arg) = @_;
  return unless my $bizbtc = new Business::Bitcoin
    ( DB => $arg{DB} || '/tmp/vault.db',
      XPUB => 'xpub661MyMwAqRbcFQ9fsPhf2sW7VmLm3XqSLSGAgDRfR4BuENFerQC9pP7BW5cJG2z15dj9gQ9Zj5rSYMQy7GXMyceympLCW4p3d6195v69TxW',
      Path => 'electrum',
      Clobber => 0,
      Create => 1 );
  return unless my $mint = new Crypt::HashCash::Mint ( Create => 1, KeyDB => $arg{KeyDB}, DB => $bizbtc->db );
  my @tables = $bizbtc->db->tables('%','%','transactions','TABLE');
  unless ($tables[0]) {
    return undef unless $bizbtc->db->do('CREATE TABLE transactions (
		                                                    txid INTEGER PRIMARY KEY AUTOINCREMENT,
                                                                    type TEXT,
		                                                    amount INTEGER NOT NULL,
                                                                    reqid INTEGER UNIQUE,
		                                                    timestamp INTEGER NOT NULL,
                                                                    fee INT
		                                                   );');
  }
  @tables = $bizbtc->db->tables('%','%','turingtests','TABLE');
  unless ($tables[0]) {
    return undef unless $bizbtc->db->do('CREATE TABLE turingtests (
		                                                   turingid INTEGER UNIQUE,
                                                                   string TEXT
		                                                  );');
  }
  @tables = $bizbtc->db->tables('%','%','exchanges','TABLE');
  unless ($tables[0]) {
    return undef unless $bizbtc->db->do('CREATE TABLE exchanges (
		                                                 init TEXT UNIQUE,
                                                                 params TEXT
		                                                );');
  }
  @tables = $bizbtc->db->tables('%','%','withdrawals','TABLE');
  unless ($tables[0]) {
    return undef unless $bizbtc->db->do('CREATE TABLE withdrawals (
		                                                 id INTEGER UNIQUE,
                                                                 key TEXT,
                                                                 ret TEXT,
                                                                 sendto TEXT,
                                                                 sendamt TEXT
		                                                );');
  }
  bless { MINT           =>   $mint,
	  BIZBTC         =>   $bizbtc,
	  ELECTRUM       =>   $arg{Electrum} || '/usr/local/bin/electrum',
	  DEBUG          =>   $arg{Debug} || 0,
	}, $class;
}

sub keygen {
  my ($self, %arg) = @_;
  my $keydb = $self->mint->keydb;
  my $keydbpath = $keydb->{__Fn}; return unless $keydbpath =~ s/\/[^\/]+$//;
  my $eecdh = new Crypt::EECDH;
  my ($spk,$ssk) = $eecdh->signkeygen();
  my $vaultid = _dec(uc(md5_hex($spk)));
  return unless my $vaultcfg = new Persistence::Object::Simple ('__Fn' => "$keydbpath/$vaultid.cfg");
  $self->mint->keygen; $vaultcfg->{pub} = $keydb->{pub};
  $keydb->{name} = $vaultcfg->{name} = $arg{Name} || 'localhost';
  $keydb->{server} = $vaultcfg->{server} = $arg{Server} || 'localhost';
  $keydb->{port} = $vaultcfg->{port} = $arg{Port} || '20203';
  $keydb->{sigscheme} = $vaultcfg->{sigscheme} = $self->mint->sigscheme;
  my ($pk,$sk) = $eecdh->keygen(PrivateKey => $ssk, PublicKey => $spk);
  $keydb->{vaultsigsec} = unpack('H*',$ssk);
  $keydb->{vaultsigpub} = $vaultcfg->{vaultsigpub} = unpack('H*',$spk);
  $keydb->{vaultsec} = unpack('H*',$sk);
  $keydb->{vaultpub} = $vaultcfg->{vaultpub} = unpack('H*',$pk);
  $keydb->{id} = $vaultcfg->{id} = $vaultid;
  $keydb->{fees} = $vaultcfg->{fees} = $arg{Fees};
  $keydb->commit; $vaultcfg->commit;
}

sub turingimg {
  my $self = shift;
  my $turing = new Authen::TuringImage; my ($img, $string) = $turing->challenge;
  my $turingid = makerandom( Size => 32, Strength => 0 );

  $self->_diag("INSERT INTO turingtests values ('$turingid', '$string');");
  unless ($self->bizbtc->db->do("INSERT INTO turingtests values ($turingid, '$string');")) {
    $self->_diag("INSERT INTO turingtests values ('$turingid', '$string');");
    # TODO: log an error and tx details
  }
  return ($turingid, $img);
}

sub predeposit {
  my ($self, %arg) = @_;
  my $query = "SELECT string from turingtests WHERE turingid='$arg{TuringID}';";
  return '-ENOTURING' unless my ($string) = $self->bizbtc->db->selectrow_array($query);
  $self->bizbtc->db->do("DELETE FROM turingtests WHERE turingid='$arg{TuringID}';");
  return '-ETURINGMISMATCH' unless $string eq $arg{TuringString};
  my $btcreq = $self->bizbtc->request(Amount => $arg{Amount});
  return $btcreq->address;
}

sub initdeposit {
  my ($self, %arg) = @_;
  return '-ENOADDRESS' unless $arg{Address};
  return '-EADDRESS' unless my $btcreq = $self->bizbtc->findreq(Address => $arg{Address});
  return '-EVERIFY' unless ($arg{Offline} ? $btcreq->verify_serial : $btcreq->verify);
  my @inits;
  for (1..$arg{NumCoins}) {
    push (@inits, $self->mint->init);
  }
  return \@inits;
}

sub deposit {
  my ($self, %arg) = @_;
  return '-ENOADDRESS' unless $arg{Address};
  my $reqs = $arg{Requests};
  my ($total, $btcreq, $fee, @coins);
  for (@$reqs) {
    $total += $_->d;
  }
  unless ($arg{Change}) {
    return '-EADDRESS' unless $btcreq = $self->bizbtc->findreq(Address => $arg{Address});
    return '-EPROCESSED' if $btcreq->status and $btcreq->status eq 'processed';         # This payment has already been processed
    $btcreq->status('unverified'), $btcreq->processed(time), $btcreq->commit,
      return '-EVERIFY' unless ($arg{Offline} ? $btcreq->verify_serial : $btcreq->verify);
    $fee = $self->fee_mf * scalar @$reqs + int($total * $self->fee_mp);
    $btcreq->status('mismatched'), $btcreq->processed(time), $btcreq->commit, return '-EMISMATCH'
      unless $total + $fee == $btcreq->amount;
  }
  for (@$reqs) {
    push @coins, $self->mint->mint_coin($_);
  }
  unless ($arg{Change}) {
    $btcreq->status('processed'); $btcreq->processed(time); $btcreq->commit;
    unless ($self->bizbtc->db->do("INSERT INTO transactions values (NULL, 'd', '" . $btcreq->amount . "', " .
				  $btcreq->id . ', ' . time . ", $fee);")) {
      $self->_diag("INSERT INTO transactions values (NULL, 'd', '" . $btcreq->amount . "', " .
		  $btcreq->id . ', ' . time . ", $fee);");
      # TODO: log an error and tx details
    }
  }
  return \@coins;
}

sub initexchange {
  my ($self, %arg) = @_;

  my ($numcoins, $amt, $numreqs, $reqamt, $numreplaced, $replacedamt, $numchange, $changeamt, $feecointotal);
  for (keys %{$arg{ExchangeDenoms}}) { $amt += $_ * $arg{ExchangeDenoms}->{$_}; $numcoins += $arg{ExchangeDenoms}->{$_} }
  for (keys %{$arg{ReqDenoms}}) { $reqamt += $_ * $arg{ReqDenoms}->{$_}; $numreqs += $arg{ReqDenoms}->{$_} }
  for (keys %{$arg{ReplacedDenoms}}) { $replacedamt += $_ * $arg{ReplacedDenoms}->{$_}; $numreplaced += $arg{ReplacedDenoms}->{$_} }
  for (keys %{$arg{ChangeDenoms}}) { $numchange += $arg{ChangeDenoms}->{$_}; $changeamt += $_ * $arg{ChangeDenoms}->{$_} }
  for (@{$arg{FeeCoins}}) { $feecointotal += $_->d }

  # Check that sent fee is correct for ExchangeDenoms being changed to ReqDenoms + ReplacedDenoms
  my $fee = $self->fee_vf * $numcoins + ($numreqs + $numreplaced) * $self->fee_mf + int($amt * ($self->fee_mp + $self->fee_vp));
  $fee = $fee + ($self->mint->denoms->[0] - ($fee % $self->mint->denoms->[0]));
  my $sentfee = $feecointotal - $changeamt; $sentfee -= $reqamt if $replacedamt;
  $self->_diag("FEE: $fee, SENTFEE: $sentfee\n");
  return '-EFEE' unless defined $sentfee and $fee == $sentfee;

  # and ReplacedDenoms total - $fee = ChangeDenoms total
  return '-ECHANGEAMT' if $replacedamt and $replacedamt - $fee != $changeamt;

  # and ChangeDenoms conforms to breakamt($changeamt)
  my ($brdenoms, $numbrk) = breakamt($changeamt);
  return '-ECHANGEBRK' unless $numchange == $numbrk;

  # Spend the fee coins
  my $coinsspent;
  my @spentcoins;
  for (@{$arg{FeeCoins}}) {
    if ($self->mint->spend_coin($_)) {
      $coinsspent += $_->d;
      push (@spentcoins, $_);
    }
    else {                                           # Spend error, roll back entire transaction
      for (@spentcoins) {
	$self->mint->unspend_coin($_);
      }
      last;
    }
  }

  return '-EFEECOINS' unless defined $coinsspent and $coinsspent == $feecointotal;

  my @inits;
  for (1..($numreqs+$numchange)) {
    push (@inits, $self->mint->init);
  }
  # Save exchange details to check at exchange time
  unless ($self->bizbtc->db->do("INSERT INTO exchanges values ('" . $inits[0] . "', '$amt:$feecointotal:$numcoins:$numreqs:$changeamt:$numchange:$replacedamt');")) {
    # TODO: Deal with error
  }
  return \@inits;
}

sub exchange {
  my ($self, %arg) = @_;
  my $reqs = $arg{Requests};
  my $changereqs = $arg{ChangeRequests};
  my $coins = $arg{Coins};
  my ($reqtotal, $cointotal, $changetotal, $feetotal, @coins) = (0,0,0,0);
  for (@$reqs) { $reqtotal += $_->d }
  for (@$coins) { $cointotal += $_->d }
  for (@$changereqs) { $changetotal += $_->d }
  for (keys %{$arg{FeeDenoms}}) { $feetotal += $_ * $arg{FeeDenoms}->{$_} }
  my $fee = $cointotal + $feetotal - $reqtotal - $changetotal;
  $self->_diag("reqtotal: $reqtotal, cointotal: $cointotal\n");

  # Check that exchange parameters match params provied at init
  my $query = "SELECT init,params from exchanges WHERE init='$reqs->[0]->{Init}';";
  return '-ELOADPARAMS' unless my ($init, $params) = $self->bizbtc->db->selectrow_array($query);
  my ($pamt, $pfee, $pnumcoins, $pnumreqs, $pchangeamt, $pnumchange, $replaced) = split /:/,$params;
  $self->_diag ("$pamt:$cointotal:$pnumcoins:". scalar @$coins . ":$pnumreqs:" . scalar @$reqs . ":$pnumchange:" .
	       scalar @$changereqs . ":$pchangeamt:$changetotal:$feetotal:$pfee:$replaced\n");
  return '-EPARAMSMISMATCH' unless $pamt == $cointotal and $pnumcoins == @$coins and $pnumreqs == @$reqs
    and $pnumchange == @$changereqs and $pchangeamt == $changetotal and $feetotal == $pfee;
  my $coinsspent = 0;
  if ($replaced) {                                   # Fee was spent from coin being exchanged
    return '-ECOINCOUNT' if exists $coins->[1];                    # Should have only one coin for exchange,
    return '-ECOINDENOM' unless $pfee == $coins->[0]->d;           # of the same denomination as the fee coin
    $coinsspent += $coins->[0]->d;
    shift @$coins;
  }
  my @spentcoins;
  for (@$coins) {
    if ($self->mint->spend_coin($_)) {
      $coinsspent += $_->d;
      push (@spentcoins, $_);
    }
    else {                                           # Spend error, roll back entire transaction
      for (@spentcoins) {
	$self->mint->unspend_coin($_);
      }
      last;
    }
  }
  $self->_diag("coinsspent: $coinsspent, cointotal: $cointotal\n");
  return '-ECOINSPEND' unless $coinsspent == $cointotal;           # Transaction was rolled back
  for (@$reqs,@$changereqs) {
    push @coins, $self->mint->mint_coin($_);         # TODO: Handle error if unable to mint coins
  }
  unless ($self->bizbtc->db->do("DELETE FROM exchanges WHERE init='$reqs->[0]->{Init}';")) {
    # TODO: log the error
  }
  unless ($self->bizbtc->db->do("INSERT INTO transactions values (NULL, 'e', '$cointotal', NULL, " . time . ", $fee);")) {
    $self->_diag("INSERT INTO transactions values (NULL, 'e', '$cointotal', NULL, " . time . ", $fee);");
    # TODO: log an error and tx details
  }
  return \@coins;
}

sub withdraw {
  my ($self, %arg) = @_;
  my $coins = $arg{Coins};
  my $reqs = $arg{Requests} if defined $arg{Requests};
  my ($reqtotal, $cointotal, $coinsspent, $ret) = (0, 0, 0);
  for (@$reqs) {
    $reqtotal += $_->d;
  }
  for (@$coins) {
    $cointotal += $_->d;
  }
  return '-ECHANGEREQS' unless $reqtotal == $arg{Change};
  my $fee = $self->fee_mf * (scalar @$reqs) + $self->fee_vf * (scalar @$coins) +
    int($reqtotal * $self->fee_mp) + int($cointotal * $self->fee_vp);
  return '-ECOINAMT' unless $cointotal == $arg{Amount} + $reqtotal + $fee;
  my @spentcoins;
  for (@$coins) {
    if ($self->mint->spend_coin($_)) {
      $coinsspent += $_->d;
      push (@spentcoins, $_);
    }
    else {                                            # Spend error, roll back entire transaction
      for (@spentcoins) {
	$self->mint->unspend_coin($_);
      }
      last;
    }
  }
  return '-ECOINSPEND' unless $coinsspent == $cointotal;
  $self->_diag("Sending $arg{Amount} Satoshi to BTC address $arg{Address}\n");
  if ($arg{Change}) {                                 # TODO: Handle error if unable to mint coins
    $ret = $self->deposit( Requests => $arg{Requests}, Change => 1 )
  }
  else {
    $ret = 'OK';
  }
  unless ($self->bizbtc->db->do("INSERT INTO transactions values (NULL, 'w', '$cointotal', NULL, " . time . ", $fee);")) {
    $self->_diag("INSERT INTO transactions values (NULL, 'e', '$cointotal', NULL, " . time . ", $fee);");
    # TODO: log an error and tx details
  }
  return $ret;
}

sub process_request {                                 # Hande a request from a client
  my ($self, $ret, $preret, $sendto, $sendamt) = (shift);
  $_ = shift; my $offline = shift;
  if (/^ping$/) {                                     # Ping
    $ret = 'pong';
  }
  elsif (/^hi$/) {                                    # Handshake to begin Deposit ( BTC > [#] ) - Send Turing Image
    my ($turingid, $turingimg) = $self->turingimg;
    $ret = $turingid . ' ' . (unpack 'H*',$turingimg->png);
  }
  elsif (/^dt (\d+)$/) {
    $ret = $self->predeposit(TuringID => $1, TuringString => '');
  }
  elsif (/^id (\d+) (\S+) (\d+) (\d+)$/) {            # Pre-Init Deposit ( BTC > [#] ) - Check Turing string, send BTC address
    $ret = $self->predeposit(TuringID => $1, TuringString => $2, Amount => $3, NumCoins => $4);
  }
  elsif (/^id (\S+) (\d+) (\d+)$/) {                  # Initialise Deposit - Check deposit, send init vectors
    if (my $inits = $self->initdeposit(Address => $1, Amount => $2, NumCoins => $3, Offline => $offline)) {
      $ret = $inits =~ /^-E/ ? $inits : "@$inits";
    }
    else {
      $ret = '';
    }
  }
  elsif (/^ie (\S+) (\S+) (\S+) (\S+) (.+)$/) {       # Initialize Exchange  ( [#] > [#] )
    my $inits = $self->initexchange( ExchangeDenoms  => { split /[,:]/, $1 },
				     ReqDenoms       => { split /[,:]/, $2 },
				     ChangeDenoms    => { split /[,:]/, $3 },
				     ReplacedDenoms  => { split /[,:]/, $4 },
				     FeeCoins        => [ map { Crypt::HashCash::Coin->from_string($_) } split / /,$5 ],
				   );
    $ret = ref $inits eq 'ARRAY' ? "@$inits" : $inits;
  }
  elsif (/^d (\S+) (.+)$/) {                          # Deposit ( BTC > [#] )
    if (my $bcoins = $self->deposit( Address             => $1,
				     Offline             => $offline,
				     Requests            => [ map { Crypt::HashCash::CoinRequest->from_string($_) } split / /,$2 ])) {
      if ($bcoins =~ /^-E/) {
	$ret = $bcoins;
      }
      else {
	my @bcoins = map { $_->as_string } @$bcoins;
	$ret = "@bcoins";
      }
    }
    else {
      $ret = '';
    }
  }
  elsif (/^w (\S+) (\d+) (\d+) (\S+) (.+) d (.+)$/) { # Withdraw ( [#] > BTC ), with change request(s)
    my $bcoins = $self->withdraw(Address => $1, Amount => $2, BTCFee => $3, Change => -$4,
				 Coins => [ map { Crypt::HashCash::Coin->from_string($_) } split / /,$5 ],
				 Requests => [ map { Crypt::HashCash::CoinRequest->from_string($_) } split / /,$6 ]);
    my @bcoins = map { $_->as_string } @$bcoins;
    $preret = "ep $1 $2 $3"; $sendto = $1; $sendamt = $2;
    $ret = "@bcoins";
  }
  elsif (/^w (\S+) (\d+) (\d+) (\S+) (.+)$/) {        # Withdraw ( [#] > BTC ), no change request(s)
    my $r = $self->withdraw(Address => $1, Amount => $2, BTCFee => $3, Change => $4,
			    Coins => [ map { Crypt::HashCash::Coin->from_string($_) } split / /,$5 ]);
    if ($r eq 'OK') {
      if ($offline) {                                 # Save payment details for processing by online machine
	$preret = "ep $1 $2 $3"; $sendto = $1; $sendamt = $2; $ret ='OK';
      }
      else {
	$sendto = $1;
	$sendamt = sprintf("%f",$2 / 100000000); my $feeamt = sprintf("%f",$3 / 100000000);
	my $electrum = $self->electrum;
	my $balance = `$electrum getbalance`;
	$balance =~ /"confirmed": "(\S+)"/s; $balance = $1 * 100000000;
	# TODO: Return error if wallet balance lower than send amount
	my $tx = `$electrum payto $sendto $sendamt -f $feeamt -u`;
	my $txdetails = `$electrum deserialize '$tx'`;    # Check transaction details
	my $addresses = `$electrum listaddresses --change`;
	my @addresses = map { /\"(\S+)\"/; $1; } split /,\s*/, $addresses;
	$txdetails =~ /\"outputs\": (.*)/s; my $outputs = $1;
	my @outputs = map { /\"address\": \"(\S+?)\".*\"value\": (\d+)/s; ($1 => $2) } split /\}\,/s, $outputs;
	if ($outputs[0] eq $sendto and $outputs[1] == $sendamt) {
	  my $err;
	  for (2..$#outputs) {                            # Check that all other outputs are our change addresses
	    next if $_ % 2; my $o = $outputs[$_];
	    $ret ='-ECHANGEOUTPUT', $err = 1, last unless grep { /^$o$/ } @addresses;
	  }
	  unless ($err) {
	    my $signedtx = `$electrum signtransaction '$tx'`;
	    _diag("$electrum broadcast '$signedtx'");
	    my $id = `$electrum broadcast '$signedtx'`;
#	    my $id = '1234';
	    $ret = "OK $id";
	  }
	}
	else {
	  $ret = '-ETXOUTPUT';
	}
      }
    }
    else {
      $ret = $r;
    }
  }
  elsif (/^e (\S+) (.+) r (.+) c (.+)$/) {            # Exchange ( [#] > [#] ), with change request(s)
    my $bcoins = $self->exchange( FeeDenoms          => { split /[,:]/, $1 },
				  Coins              => [ map { Crypt::HashCash::Coin->from_string($_) } split / /,$2 ],
				  Requests           => [ map { Crypt::HashCash::CoinRequest->from_string($_) } split / /,$3 ],
				  ChangeRequests     => [ map { Crypt::HashCash::CoinRequest->from_string($_) } split / /,$4 ]);
    if ($bcoins =~ /^-E/) {
      $ret = $bcoins;
    }
    else {
      my @bcoins = map { $_->as_string } @$bcoins;
      $ret = "@bcoins";
    }
  }
  elsif (/^e (\S+) (.+) r (.+)$/) {                   # Exchange ( [#] > [#] ), no change request(s)
    my $bcoins = $self->exchange( FeeDenoms          => { split /[,:]/, $1 },
				  Coins              => [ map { Crypt::HashCash::Coin->from_string($_) } split / /,$2 ],
				  Requests           => [ map { Crypt::HashCash::CoinRequest->from_string($_) } split / /,$3 ]);
    if ($bcoins =~ /^-E/) {
      $ret = $bcoins;
    }
    else {
      my @bcoins = map { $_->as_string } @$bcoins;
      $ret = "@bcoins";
    }
  }
  return ($ret, $preret, $sendto, $sendamt);
}

sub _diag {
  my $self = shift;
  print STDERR @_ if $self->debug;
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(debug|electrum)$/x) {
    $self->{"\U$auto"} = shift if (defined $_[0]);
  }
  if ($auto =~ /^(debug|mint|bizbtc|electrum)$/x) {
    return $self->{"\U$auto"};
  }
  if ($auto =~ /^fee_(mf|mp|vf|vp)$/) {
    return $self->mint->keydb->{fees}->{$1};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

1; # End of Crypt::HashCash::Vault::Bitcoin

__END__

=head1 NAME

Crypt::HashCash::Vault::Bitcoin - Bitcoin Vault for HashCash Digital Cash

=head1 VERSION

 $Revision: 1.129 $
 $Date: Tue Oct 16 16:56:38 PDT 2018 $

=head1 SYNOPSIS

  use Crypt::HashCash::Vault::Bitcoin;;

  my $vault = new Crypt::HashCash::Vault::Bitcoin ( Create => 1 );

  my ($id, $turing) = $vault->turingimg;       # Get a Turing image

  my $address = $vault->predeposit             # Get an address for a deposit
    ( TuringID       => $id,
      TuringString   => $string,
      Amount         => $amount );

  my @inits = $vault->initdeposit              # Get init vectors for a deposit
    ( Address        => $address,
      NumCoins       => $numcoins );

  my @coins = $vault->deposit                  # Deposit Bitcoin and receive coins
    ( Requests       => \@requests,
      Address        => $address );

  my @inits = $vault->initexchange             # Get init vectors for an exchange
    ( FeeCoins       => \@coins,
      ExchangeDenoms => $xchgdenoms,
      ReqDenoms      => $reqdenoms,
      ReplacedDenoms => $replaceddenoms,
      ChangeDenoms   => $changedenoms );

  my @coins = $vault->exchange                 # Exchange / verify coins
    ( Coins          => \@coins,
      Requests       => \@requests,
      ChangeRequests => \@changerequests,
      FeeDenoms      => $feedenoms );

  $vault->withdraw (                           # Withdraw Bitcoin
    ( Coins          => \@coins,
      Requests       => \@requests,
      Amount         => $amount,
      Change         => $change );

=head1 DESCRIPTION

This module implements a Bitcoin vault for the HashCash digital cash
system. It provides methods to deposit Bitcoin and receive HashCash
coins, to exchange and verify HashCash coins, and to redeem HashCash
for Bitcoin.

=head1 METHODS

=head2 new

Creates and returns a new Crypt::HashCash::Vault::Bitcoin object.

=head2 keygen

=head2 turingimg

=head2 predeposit

=head2 initdeposit

=head2 deposit

=head2 initexchange

=head2 exchange

=head2 withdraw

=head2 process_request

=head1 SEE ALSO

=head2 L<http://www.hashcash.com>

=head2 L<Crypt::HashCash>

=head2 L<Crypt::HashCash::Mint>

=head2 L<Crypt::HashCash::Client>

=head2 L<Crypt::HashCash::Coin>

=head2 L<Business::HashCash>

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

    perldoc Crypt::HashCash::Vault::Bitcoin

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

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftwr.org/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
