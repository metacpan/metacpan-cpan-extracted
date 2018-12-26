#!/usr/bin/perl
# -*-cperl-*-
#
# hashcash.pl - Wallet for HashCash Digital Cash
# Copyright (c) 2001-2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: bin/hashcash.pl v1.130 Sat Dec 22 18:42:26 PST 2018 $

use warnings;

use Wx qw (:everything);
use Wx::Grid;
use Wx::Event qw (EVT_BUTTON EVT_CHOICE EVT_PAINT);
use Crypt::HashCash qw (breakamt changecoin _squish _unsquish _hex _dec);
use Compress::Zlib;
use Crypt::HashCash::Client;
use Crypt::HashCash::Coin;
use Crypt::HashCash::Coin::Blinded;
use Crypt::HashCash::Stash;
use Crypt::Diceware;
use GD::Barcode::QRcode;
use File::HomeDir;

my $HASHCASH = $ENV{HASHCASHDIR} || File::HomeDir->my_home . '/.hashcash';

unless (-d $HASHCASH) {
  die "Directory $HASHCASH doesn't exist and couldn't be created.\n" unless mkdir($HASHCASH, 0700);
}

unless (-d "$HASHCASH/stash") {
  die "Directory $HASHCASH/.stash doesn't exist and couldn't be created.\n" unless mkdir("$HASHCASH/stash", 0700);
}

# Get vault configs, default to first vault
my @vaults = map { new Persistence::Object::Simple ('__Fn' => $_) } glob("$HASHCASH/vaults/*.cfg");
my $vaultid = $vaults[0]->{id};

# Initialize client
my $client = new Crypt::HashCash::Client (VaultConfig => "$HASHCASH/vaults/$vaultid\.cfg");
$client->loadkeys;
my %fee = %{$client->keydb->{fees}};

$client->offline(1) if (defined $main::ARGV[0] and $main::ARGV[0] eq '--offline');

# Initialize stash
my $stash = new Crypt::HashCash::Stash (_DB => "$HASHCASH/stash/$vaultid\.db", Create => 1);
$stash->denoms($client->denoms);
$stash->load;

# Initialize l8n
my ($lang, %lang) = initl8n();

# Initialize UI
my ($app, $frame, $vaultsel, $label, $label2, $grid, $topSizer, $statusBar, %button) = initui();

# Actions for all the buttons
my %action;

$action{Buy} = sub {   # Buy HashCash
  my ($denoms, $numcoins, $amt, $address, $payamt, $savedbuys, $retry);
  my $choice = 0;
  if ($savedbuys = $stash->savedbuys) {
    $dialog = Wx::SingleChoiceDialog->new( $frame, "Would you like to start a new purchase, or retry one initiated previously?",
					   "Buy HashCash", ["New purchase", map { $_->[0] } @$savedbuys ]);
    return if $dialog->ShowModal == wxID_CANCEL;
    $choice = $dialog->GetSelection();
  }
  if ($choice == 0) {
    my $dialog = Wx::TextEntryDialog->new( $frame, ('Amount to buy (in Satoshi)'), _('Buy coins'));
    return if $dialog->ShowModal == wxID_CANCEL;
    $amt = $dialog->GetValue();
    return unless $amt and $amt !~ /\D/;
    if ($amt % $client->denoms->[0]) {
      $dialog = Wx::MessageDialog->new( $frame, "The amount to buy should be a multiple of " . $client->denoms->[0],
					"Unsupported denomination", wxOK);
      return if $dialog->ShowModal == wxID_OK;
    }
    $statusBar->SetStatusText("Buy $amt", 0);

    ($denoms, $numcoins) = breakamt($amt);
    $payamt = $amt + $numcoins * $fee{mf} + int($amt * $fee{mp});
    $statusBar->SetStatusText("Initializing request with vault...", 0);

    connecterror(), return unless my $turingimage = $client->turingimg;

    my $turingfh; eval { open $turingfh, '<', \$turingimage or die "cannot open: $!"; };
    my $turingpng = Wx::Bitmap->new(Wx::Image->new($turingfh, wxBITMAP_TYPE_PNG));
    $dialog = Wx::TextEntryDialog->new( $frame, "\n\n\nEnter the text from the image into the box below:", "Buy coins");
    my $st = Wx::StaticBitmap->new( $dialog, -1, $turingpng, [60,15] );
    $statusBar->SetStatusText("Awaiting Turing test completion.", 0);
    if($dialog->ShowModal == wxID_CANCEL) {
      $client->cancelturing;
      return;
    }
    my $turingstring = $dialog->GetValue();
    unless ($turingstring and $turingstring =~ /[\d\w]+/) {
      $client->cancelturing;
      return;
    }

    connecterror(), return unless $address = $client->getaddress( Turing => $turingstring, Amt => $payamt, Numcoins => $numcoins );

    if ($address =~ /^-E/) {
      $dialog = Wx::MessageDialog->new( $frame, "The code you entered did not match the image shown. Please try again.",
					"Turing test error", wxOK);
      return if $dialog->ShowModal == wxID_OK;
    }

    $statusBar->SetStatusText("Awaiting Bitcoin payment confirmation.", 0);
    $dialog = Wx::MessageDialog->new( $frame, "Please send $payamt Satoshi to address $address and ".
				      'click OK when the transaction has at least 6 confirmations.',
				      'Send Bitcoin Confirmation', wxOK|wxCANCEL);
    return if $dialog->ShowModal == wxID_CANCEL;
  }
  else {                # Retry saved purchase
    ($address, $payamt, $denoms) = @{$savedbuys->[$choice-1]};
    $denoms = { split /:/, $denoms };
    for (values %$denoms) { $numcoins += $_ }
    $retry = 1;
    $statusBar->SetStatusText("Awaiting Bitcoin payment confirmation.", 0);

    $dialog = Wx::MessageDialog->new( $frame, "Please send $payamt Satoshi to address $address and ".
				      'click OK when the transaction has at least 6 confirmations.',
				      'Send Bitcoin Confirmation', wxOK|wxCANCEL);
    return if $dialog->ShowModal == wxID_CANCEL;
  }

  my $inits = $client->initbuy( Address => $address, Amt => $payamt, Numcoins => $numcoins );
  unless ($inits) {
    $stash->savebuy( Address => $address, Amt => $payamt, Numcoins => $numcoins, Denoms => $denoms ) unless $retry;
    connecterror(1); return;
  }
  if ($inits =~ /^-E/) {
    $stash->savebuy( Address => $address, Amt => $payamt, Numcoins => $numcoins, Denoms => $denoms ) unless $retry;
    $dialog = Wx::MessageDialog->new( $frame, "Please ensure your payment of $payamt Satoshi has at least 6 " .
				      "confirmations, and then try again. Your payment details are saved.",
				      "Payment not verified", wxOK);
    return if $dialog->ShowModal == wxID_OK;
  }

  my $max; map { $max += $denoms->{$_} } keys %$denoms;
  my $ProgressDialog = Wx::ProgressDialog->new("Creating Requests", "Creating HashCash coin requests", 2*$max + 3, $frame,
					       wxPD_AUTO_HIDE | wxPD_APP_MODAL | wxPD_ELAPSED_TIME |
					       wxPD_ESTIMATED_TIME | wxPD_REMAINING_TIME);
  $ProgressDialog->Update(0,"Initializing requests with vault");
  $statusBar->SetStatusText("Initializing request with vault...", 0);

  my $i = 0; my @requests;
  for my $d (keys %{$denoms}) {
    for (1..$denoms->{$d}) {
      $statusBar->SetStatusText('Creating coin request ' .  ($i+1), 0);
      $ProgressDialog->Update($i+2,'Creating coin request ' . ($i+1));
      push @requests, $client->request_coin( Denomination => $d, Init => $inits->[$i++] );
    }
  }

  $ProgressDialog->Update($max+2,"Sending requests to vault");
  $statusBar->SetStatusText("Sending requests to vault", 0);

  $ProgressDialog->Update(2*$max+3), show(), connecterror(), return unless my $coins = $client->buy( Requests => \@requests, Address => $address );

  if ($coins eq '-EVERIFY') {
    $stash->savebuy( Address => $address, Amt => $payamt, Numcoins => $numcoins, Denoms => $denoms ) unless $retry;
    $dialog = Wx::MessageDialog->new( $frame, "Please ensure your payment of $payamt Satoshi has at least 6 confirmations, and then try again. " .
				      "Your payment details are saved.", "Payment not verified", wxOK );
  }
  elsif ($coins eq '-EPROCESSED') {
    $dialog = Wx::MessageDialog->new( $frame, "This transaction has already been completed.", "Duplicate transaction", wxOK );
  }
  elsif ($coins =~ /^-E/) {
    $dialog = Wx::MessageDialog->new( $frame, "There was an error in the payment parameters.", "Error", wxOK);
  }
  if ($coins =~ /^-E/) {
    $ProgressDialog->Update(2*$max+3); show();
    return if $dialog->ShowModal == wxID_OK;
  }

  $i = 1;
  for (@$coins) {
    $ProgressDialog->Update($max+2+$i,"Unblinding and adding coin $i"); $i++;
    $statusBar->SetStatusText("Unblinding and adding coins to wallet", 0);
    my $coin = $client->unblind_coin($_);
    $client->verify_coin($coin) && $stash->addcoins('V',$coin);
  }
  $ProgressDialog->Update($max+$i+2);
  $stash->finishbuy($address) if $retry;
  show();
};

$action{Sell} = sub {   # Sell HashCash
  my $dialog = Wx::TextEntryDialog->new( $frame, "Amount to sell (in Satoshi)", "Sell coins");
  if($dialog->ShowModal == wxID_CANCEL) {
    return;
  };
  my $amt = $dialog->GetValue();
  return unless $amt and $amt !~ /\D/;
  if ($amt % $client->denoms->[0]) {
    $dialog = Wx::MessageDialog->new( $frame, "The amount to sell should be a multiple of " . $client->denoms->[0],
				      "Unsupported denomination", wxOK);
    if($dialog->ShowModal == wxID_OK) {
      return;
    }
  }
  if ($amt > $stash->balance) {
    $dialog = Wx::MessageDialog->new( $frame, "Your verified balance " . $stash->balance . " is lower than $amt", "Not enough cash", wxOK);
    if($dialog->ShowModal == wxID_OK) {
      return;
    }
  }
  my ($coins, $change) = $stash->getcoins($amt); my $j = 0;
  if ($change) { # TODO: Provide change if necessary. This is a temporay workaround.
    $stash->addcoins('V',@$coins);
    $dialog = Wx::MessageDialog->new( $frame, "You don't have exact change to sell $amt", "Need change", wxOK);
    return if $dialog->ShowModal;
  }
  my ($numcoins, $denoms) = (0); ($denoms, $numcoins) = breakamt(-$change) if $change;
  my $fee = (scalar @$coins) * $fee{vf} + int(($amt-$change) * $fee{vp}) + $numcoins * $fee{mf} + int($change * $fee{mp});
  # We won't round up fee to multipe of lowest denomination coin as we can deduct precise amount before determining Bitcoin amount to send
  my $sendamt = $amt - $fee;
  $dialog = Wx::TextEntryDialog->new( $frame, "HashCash fees for this sale will be $fee Satoshi.\n\nEnter amount to pay in Bitcoin fees:", "Sell coins");
  if($dialog->ShowModal == wxID_CANCEL) {
    $stash->addcoins('V',@$coins);
    return;
  };
  my $btcfee = $dialog->GetValue();
  $stash->addcoins('V',@$coins), return unless $btcfee and $btcfee !~ /\D/;
  unless ($btcfee < $sendamt) {
    $dialog = Wx::MessageDialog->new( $frame, "Bitcoin fee should be lower than $sendamt", "Fee exeeds sale amount", wxOK);
    if($dialog->ShowModal == wxID_OK) {
      $stash->addcoins('V',@$coins);
      return;
    }
  }
  my $continue = 1; my $max = $change ? ($numcoins*2 + 3) : 1;
  $dialog = Wx::TextEntryDialog->new( $frame, "Address to send Bitcoin to", "Send funds to Bitcoin");
  if($dialog->ShowModal == wxID_CANCEL) {
    $stash->addcoins('V',@$coins);
    return;
  };
  my $sendaddress = $dialog->GetValue();
  $statusBar->SetStatusText("Sending $sendamt Satoshi to $sendaddress", 0);
  my $ProgressDialog = Wx::ProgressDialog->new("Selling Coins", "Sending coins to vault", $max, $frame,
					       wxPD_AUTO_HIDE | wxPD_APP_MODAL | wxPD_ELAPSED_TIME |
					       wxPD_ESTIMATED_TIME | wxPD_REMAINING_TIME);
  $continue = $ProgressDialog->Update($j++);
  if (!$change) {
    $stash->addcoins('V',@$coins), $ProgressDialog->Update($max), show(), connecterror(), return unless
      my $res = $client->sell( Address => $sendaddress, Amount => $sendamt, BTCFee => $btcfee, Coins => $coins, Change => $change );
    unless ($res =~ /^OK (\S+)/) {
      $stash->addcoins('V',@$coins); $ProgressDialog->Update($max); show();
      $dialog = Wx::MessageDialog->new( $frame, "Error processing sale: $res", "Error", wxOK);
      return if $dialog->ShowModal == wxID_OK;
    }
    $ProgressDialog->Update($max);
    $dialog = Wx::MessageDialog->new( $frame, "Bitcoin payment of $sendamt sent to $sendaddress.\nBitcoin Tx ID: $1", "Bitcoin payment sent", wxOK);
    $dialog->ShowModal;
  }
  else { # TODO: When change is to be returned. This code isn't currently used
    $continue = $ProgressDialog->Update($j++, "Initiating request for change");
    $statusBar->SetStatusText("Initiating request for change", 0);;
    #  my ($inits, $address) = $vault->initdeposit(Amount => -$change, NumCoins => $numcoins);
    #! TODO: Got to take fee at this step:
    my ($address, @inits) = split / /, $client->msgvault('id ' . -$change . " $numcoins"); my $inits = \@inits;
    my $i = 0; my @requests;
    for my $d (keys %{$denoms}) {
      for (1..$denoms->{$d}) {
	$continue = $ProgressDialog->Update($j++, "Creating coin request " . ($i + 1) );
	push @requests, $client->request_coin( Denomination => $d, Init => $inits->[$i++] );
      }
    }
    $continue = $ProgressDialog->Update($j++, "Receiving change");
    $statusBar->SetStatusText("Receiving change", 0);;

    #  my $coins = $vault->deposit( Requests => \@requests, Change => 1 );
    my @reqstrs = map { $_->as_string } @requests;

    my $res = $client->msgvault("w $sendaddress $sendamt $btcfee $change " . (join ' ', map { $_->as_string } @$coins) . " d @reqstrs");

    $ProgressDialog->Update($max), show(), return unless $res; # TODO: Handle errors, as in the no change version
    my $coins = [ map { Crypt::HashCash::Coin::Blinded->from_string($_) } split / /, $res ];
    for (@$coins) {
      $continue = $ProgressDialog->Update($j++, "Unblinding and adding coin " . ($j - $numcoins - 3));
      my $coin = $client->unblind_coin($_);
      $client->verify_coin($coin) && $stash->addcoins('V',$coin);
    }
  }
  $continue = $ProgressDialog->Update($j);
  show();
};

$action{Export} = sub {   # Export Coins
  my $dialog = Wx::TextEntryDialog->new( $frame, "Amount to export (in Satoshi)", "Export coins from wallet");
  my $dialog_height = $dialog->GetSize->GetHeight;
  my $fontheight = $frame->GetCharHeight;
  if($dialog->ShowModal == wxID_CANCEL) {
    return;
  };
  my $amt = $dialog->GetValue();
  return unless $amt and $amt !~ /\D/;
  if ($amt % $client->denoms->[0]) {
    $dialog = Wx::MessageDialog->new( $frame, "The amount to export should be a multiple of " . $client->denoms->[0],
				      "Unsupported denomination", wxOK);
    if($dialog->ShowModal == wxID_OK) {
      return;
    }
  }
  if ($amt > $stash->balance) {
    $dialog = Wx::MessageDialog->new( $frame, "Your balance " . $stash->balance  . " is lower than $amt", "Not enough cash", wxOK);
    if($dialog->ShowModal == wxID_OK) {
      return;
    }
  }
  $statusBar->SetStatusText("Export $amt", 0);;

  my ($coins, $change) = $stash->getcoins($amt);

  if ($change) {
    $stash->addcoins('V',@$coins);
    $dialog = Wx::MessageDialog->new( $frame, "You don't have exact change to export $amt", "Need change", wxOK);
    return if $dialog->ShowModal;
  }
  return unless $coins;
  my $wordlist = 'Common'; $wordlist = uc($lang) if $lang =~ /(es|it|hi|de|gr|zh|ja|ru)/;
  my @words = eval 'use Crypt::Diceware words => { wordlist => $wordlist }; words(4);';
  $dialog = Wx::TextEntryDialog->new( $frame, "Passphrase (blank for no encryption - NOT RECOMMENDED!)",
				      "Coin encryption passphrase", join (' ', @words));
  $stash->addcoins('V',@$coins), return if $dialog->ShowModal == wxID_CANCEL;
  my $passphrase = $dialog->GetValue();
  if ($passphrase) {
    $dialog = Wx::TextEntryDialog->new( $frame, "Passphrase Confirm", "Coin encryption passphrase");
    $stash->addcoins('V',@$coins), return if $dialog->ShowModal == wxID_CANCEL or $dialog->GetValue() ne $passphrase;
  }
  my $coinexp = _hex($client->keydb->{id}); $coinexp = '0' x (32 - length($coinexp)) . $coinexp;
  $coinexp = unpack('H*','[#]' . substr($client->sigscheme, 0, 1)) . $coinexp;
#  print STDERR "COINEXP: $coinexp\n";
  for (@$coins) {
#    $coinexp .= ' ' . $_->as_string;
    $coinexp .= $_->as_hex;
  }
  $coinexp = pack('H*', $coinexp);
  if ($passphrase) {
    my $cipher = Crypt::CBC->new (-key => $passphrase, -cipher => 'Rijndael', -header => 'salt');
    $coinexp = $cipher->encrypt($coinexp);
  }
  $coinexp = _squish($coinexp);
  my ($msg, $qr, $st) = ('Copy coins from below');
  my $len = length($coinexp);
  if ($len < 7090 ) {
    my $qrfh; my $level;
    my @version = qw( 0 41 77 127 187 255 322 370 461 552 652 772 883 1022 1101 1250 1408 1548 1725 1903 2061 2232 
		      2409 2620 2812 3057 3283 3517 3669 3909 4158 4417 4686 4965 5253 5529 5836 6153 6479 6743 7089 );
    for (1..40) { next if $len > $version[$_]; $version = $_; last; }
    my $qrxpm = GD::Barcode::QRcode->new($coinexp, { Version => $version, Ecc => L, ModuleSize => 2 })->barcode;
    $qrxpm =~ /^(.*)$/m; my $qrsize = length($1);
    $qr = Wx::Bitmap->newFromXPM([ split /\n/, "$qrsize $qrsize 2 1\n0 c #FFFFFF\n1 c #000000\n$qrxpm" ]);
    $msg = "\n" x ($qr->GetHeight / $fontheight) . "\n\nScan the QR code or copy coins from below";
  }
  $dialog = Wx::TextEntryDialog->new( $frame, $msg , 'Export coins', $coinexp);
  if (defined $qr) {
    my $dialogwidth = $dialog->GetSize->GetWidth;
    my $qrheight = $qr->GetHeight; my $width = $qrheight + 20 > $dialogwidth ? $qrheight + 20 : $dialogwidth;
    my $adjust = 10 unless $^O eq 'MSWin32' or $^O eq 'darwin';
    my $qrpos = ($width-$qrheight)/2 + ($width == 300 ? $adjust : 0);
    $dialog->SetSize([$width,$dialog_height+$qrheight+$fontheight+10]);
    $dialog->SetMinSize([$width,$dialog_height+$qrheight+$fontheight+10]);
    $dialog->SetMaxSize([$width,$dialog_height+$qrheight+$fontheight+10]);
    $st = Wx::StaticBitmap->new( $dialog, -1, $qr, [$qrpos,10] );
  }
  if($dialog->ShowModal == wxID_CANCEL) {
    $stash->addcoins('V',@$coins);
  }
  show();
};

$action{Import} = sub {     # Add coins to wallet
  my $dialog = Wx::TextEntryDialog->new( $frame, "Paste coins below", "Add coins to wallet");
  if($dialog->ShowModal == wxID_CANCEL) {
    return;
  };
  my $coins = $dialog->GetValue();
  $coins = _unsquish($coins);
  my (@coins, @coinstrs, $sigscheme, $vaultid);
  $coins = unpack('H*', $coins);
  if ($coins =~ /^5b235d(52|45)/) {
    $coins =~ /^5b235d(52|45)([0-9a-f]{32})(.*)$/; ($sigscheme, $vaultid, $coins) = ($1, _dec($2), $3);
    my $coinsize = $sigscheme == 52 ? 296 : 170;
    while (my $coinstr = substr($coins, 0, $coinsize, '')) { push @coinstrs, $coinstr }
  }
  else {
    $dialog = Wx::TextEntryDialog->new( $frame, "Enter passphrase to decrypt coins", "Add coins to wallet");
    if($dialog->ShowModal == wxID_CANCEL) {
      return;
    }
    my $passphrase = $dialog->GetValue();
    my $cipher = Crypt::CBC->new (-key => $passphrase, -cipher => 'Rijndael');
    my $decrypted = $cipher->decrypt(pack 'H*', $coins); $decrypted =~ s/\s*$//;
    return unless $decrypted =~ /^\[\#\](R|E)/;
    $decrypted = unpack('H*',$decrypted);
    $decrypted =~ /^5b235d(52|45)([0-9a-f]{32})(.*)$/; ($sigscheme, $vaultid, $coins) = ($1, _dec($2), $3);
    my $coinsize = ($sigscheme == 52) ? 296 : 170;
    while (my $coinstr = substr($coins, 0, $coinsize, '')) { push @coinstrs, $coinstr }
  }
  unless ($vaultid eq $client->keydb->{id}) {
    $dialog = Wx::MessageDialog->new( $frame, "Please switch to the vault with ID\n$vaultid\nto import these coins.", "Add coins to wallet", wxOK);
    if($dialog->ShowModal == wxID_OK) {
      return;
    }
  }
  for (@coinstrs) {
    my $coin = Crypt::HashCash::Coin->from_hex($_);
    push @coins, $coin if $coin;
  }
  if (scalar @coins) {
    my $continue = 1; my $max = scalar @coins; my $i = 0;
    my $ProgressDialog = Wx::ProgressDialog->new("Adding Coins", "Adding coins to wallet", $max, $frame,
						 wxPD_AUTO_HIDE | wxPD_APP_MODAL | wxPD_ELAPSED_TIME |
						 wxPD_ESTIMATED_TIME | wxPD_REMAINING_TIME);
    for my $coin (@coins) {
      $ProgressDialog->Update($i++, "Adding coin $i");
      $ProgressDialog->Update($i++), next unless $client->verify_coin($coin);
      if ($stash->addcoins('U',$coin)) {
	$ProgressDialog->Update($i . '.5', "Added coin $i");
      }
      else {
	$ProgressDialog->Update($i, "Coin $i is a duplicate, skipped");
      }
    }
  }
  show();
};

$action{Exchange} = sub {   # Exchange / verify coins
  my $unverified = scalar grep { defined $stash->{$_}->{U} } grep { !/^_/ } keys %$stash;
  my ($choice, $i, $j, $continue, $dialog) = (1, 0, 1);
  my (@coins, $amt, $numcoins, $denoms, $d);
  my ($feecoins, $change, $numchgcoins, $chgdenoms);
  if ($unverified) {
    $dialog = Wx::SingleChoiceDialog->new( $frame, "Select type of exchange", "Exchange or verify coins",
					   ["Verify all unverified coins", "Make change for a specific amount"]);
    return if $dialog->ShowModal == wxID_CANCEL;
    $choice = $dialog->GetSelection();
  }
  my $feefromxchgcoin;
  if ($choice == 1) {
    $dialog = Wx::TextEntryDialog->new( $frame, "Denomination of coin to get change for", "Exchange coin");
    return if $dialog->ShowModal == wxID_CANCEL;
    $amt = $dialog->GetValue();
    return unless $amt and $amt !~ /\D/ and $amt > 1;
    unless ($stash->havedenom($amt)) {
      return if Wx::MessageDialog->new( $frame, "Don't have a verified coin of denomination $amt", "Exchange coin", wxOK)->ShowModal;
    }
    $statusBar->SetStatusText("Exchange $amt", 0);
    ($denoms, $numcoins) = changecoin($amt);
    my $fee = $fee{vf} + $numcoins * $fee{mf} + int($amt * ($fee{mp} + $fee{vp}));
    $fee = $fee + ($client->denoms->[0] - ($fee % $client->denoms->[0]));
    if ($fee > $stash->balance) {
      $dialog = Wx::MessageDialog->new( $frame, "Your balance " . $stash->balance . " is lower than fee amount $fee", "Not enough cash", wxOK);
      if($dialog->ShowModal == wxID_OK) {
	return;
      }
    }
    if ($fee >= $amt) {
      $dialog = Wx::MessageDialog->new( $frame, "Transaction cancelled because the fee $fee is more than $amt, the amount of the transaction",
					"Loss-making transaction", wxOK);
      if($dialog->ShowModal == wxID_OK) {
	return;
      }
    }
    $dialog = Wx::MessageDialog->new( $frame, "The fee for this exchange is $fee Satoshi. Click OK to continue with the exchange.",
				      "Confirm exchange fee", wxOK|wxCANCEL);
    if($dialog->ShowModal == wxID_CANCEL) {
      return;
    }
    ($feecoins, $change) = $stash->getcoins($fee);
    ($numchgcoins, $chgdenoms) = (0); ($chgdenoms, $numchgcoins) = breakamt(-$change) if $change;

    ($feefromxchgcoin) = grep { $_->d == $amt } @$feecoins;
    if ($feefromxchgcoin) {                                             # Paying fee from same coin we're exchanging
      ($d) = changecoin($amt); $denoms = {}; $numcoins = 0;
      for (keys %$chgdenoms) {                                          # Figure out which denoms from exchange request being
	next unless $d->{$_};                                           # replaced with denoms from change request
	if ($d->{$_} <= $chgdenoms->{$_}) {
	  $denoms->{$_} = $d->{$_};
	  $numcoins += $denoms->{$_};
	  $chgdenoms->{$_} -= $d->{$_}; delete $chgdenoms->{$_} unless $chgdenoms->{$_};
	  $numchgcoins -= $d->{$_};
	  delete $d->{$_};
	}
	else {
	  $denoms->{$_} = $chgdenoms->{$_};
	  $numcoins += $denoms->{$_};
	  $d->{$_} -= $chgdenoms->{$_};
	  $numchgcoins -= $chgdenoms->{$_};
	  delete $chgdenoms->{$_};
	}
      }
      push (@coins, $feefromxchgcoin);
      # We'll generate @changereqs from $chgdenoms, @reqsreplacedbychangereqs from $d, @reqs from $denom
    }
    else {                                                              # Not using the coin we're exchanging to pay the fee
      if (my $xchgcoin = $stash->getdenom($amt)) {                      # so get the coin we're exchanging
	push @coins, $xchgcoin;
      }
      else {
	$stash->addcoins('V',@$feecoins);
	return;
      }
    }
    # We'll send to vault:
    # First -> ie @$feecoins $change $denoms $reqdenoms $changereqdenoms $reqsreplacedbychangereqsdenoms
    # Vault checks that fee is correct for @coins being changed to @reqs + @reqsreplacedbychangereqs
    # and that @reqsreplacedbychangereqs - $fee = @changereqs and @changereqs conforms to breakamt()
    # Then -> e @coins r @reqs c @changereqs
    # Vault checks that @coins, @reqs and @changereqs are as stated in the ie step before
  }
  else {
    $statusBar->SetStatusText("Verify", 0);
    ($amt, $denoms, @coins) = $stash->unverified; $numcoins = scalar @coins;
    my $fee = $numcoins * ($fee{vf} + $fee{mf}) + int($amt * ($fee{mp} + $fee{vp}));
    $fee = $fee + ($client->denoms->[0] - ($fee % $client->denoms->[0]));
    if ($fee > $stash->balance) {
      $dialog = Wx::MessageDialog->new( $frame, "Your balance " . $stash->balance . " is lower than fee amount $fee", "Not enough cash", wxOK);
      if($dialog->ShowModal == wxID_OK) {
	$stash->addcoins('U',@coins);
	return;
      }
    }
    if ($fee >= $amt) {
      $dialog = Wx::MessageDialog->new( $frame, "Transaction cancelled because the fee $fee is more than $amt, the amount of the transaction",
					"Loss-making transaction", wxOK);
      if($dialog->ShowModal == wxID_OK) {
	$stash->addcoins('U',@coins);
	return;
      }
    }
    $dialog = Wx::MessageDialog->new( $frame, "The fee for this exchange is $fee Satoshi. Click OK to continue with the exchange.",
				      "Confirm exchange fee", wxOK|wxCANCEL);
    if($dialog->ShowModal == wxID_CANCEL) {
      $stash->addcoins('U',@coins);
      return;
    }
    ($feecoins, $change) = $stash->getcoins($fee);
    ($numchgcoins, $chgdenoms) = (0); ($chgdenoms, $numchgcoins) = breakamt(-$change) if $change;
  }
  my %coins; for (@coins) { $coins{$_->d}++ }
  my $ProgressDialog = Wx::ProgressDialog->new("Exchanging Coins", "Initializing requests with vault", 2+($numcoins+$numchgcoins)*2, $frame,
					       wxPD_AUTO_HIDE | wxPD_APP_MODAL | wxPD_ELAPSED_TIME |
					       wxPD_ESTIMATED_TIME | wxPD_REMAINING_TIME);
  $continue = $ProgressDialog->Update(0);
  my $res = $client->initexchange( Coins => \%coins,                           # Denominations of coins being exchanged
				   ReqDenoms => $denoms,                       # Denominations of coins being requested
				   ChangeDenoms => $chgdenoms,                 # Denominations of change coins from fee payment
				   ReplaceDenoms => $d,                        # Denominations of exchange coins replaced by change coins
				   FeeCoins => $feecoins );                    # The fee coins
  unless ($res) {
    $stash->addcoins('V', @$feecoins); # TODO: Check if actually used a U coin
    $stash->addcoins($choice==1?'V':'U', @coins) unless $feefromxchgcoin;
    $ProgressDialog->Update(2+($numcoins+$numchgcoins)*2); show();
    connecterror();
    return;
  }
  if ($res =~ /^-E/) {
    $stash->addcoins('V', @$feecoins); # TODO: Check if actually used a U coin
    $stash->addcoins($choice==1?'V':'U', @coins) unless $feefromxchgcoin;
    $ProgressDialog->Update(2+($numcoins+$numchgcoins)*2); show();
    $dialog = Wx::MessageDialog->new( $frame, "Error processing exchange: $res", "Error", wxOK);
    return if $dialog->ShowModal == wxID_OK;
  }
  my @inits = split / /, $res;
  my @requests;
  for my $denom (keys %{$denoms}) {
    for (1..$denoms->{$denom}) {
      $continue = $ProgressDialog->Update($j++, "Creating coin request " . ($i+1));
      push @requests, $client->request_coin( Denomination => $denom, Init => $inits[$i++] );
    }
  }
  my @changereqs;
  for my $denom (keys %{$chgdenoms}) {
    for (1..$chgdenoms->{$denom}) {
      $continue = $ProgressDialog->Update($j++, "Creating coin request " . ($i+1));
      push @changereqs, $client->request_coin( Denomination => $denom, Init => $inits[$i++] );
    }
  }
  $continue = $ProgressDialog->Update($j++, "Requesting coins");
  $statusBar->SetStatusText("Requesting coins", 0);
  my %feecoins; for (@$feecoins) { $feecoins{$_->d}++ }
  $res = $client->exchange( FeeCoins => \%feecoins, Coins => \@coins, Requests => \@requests, ChangeRequests => \@changereqs );
  unless ($res) {
    # TODO: On vault side, timeout exchanges and unspend fee coins. Add fee coins back to stash here.
    $stash->addcoins($choice==1?'V':'U', @coins) unless $feefromxchgcoin;
    $ProgressDialog->Update(2+($numcoins+$numchgcoins)*2); show();
    connecterror(); return;
  }
  if ($res =~ /^-E/) {
    # TODO: More fine-grained error handling. As it stands, fee coins will be spent
    $stash->addcoins($choice==1?'V':'U', @coins) unless $feefromxchgcoin;
    $ProgressDialog->Update(2+($numcoins+$numchgcoins)*2); show();
    $dialog = Wx::MessageDialog->new( $frame, "Error processing exchange: $res", "Error", wxOK);
    return if $dialog->ShowModal == wxID_OK;
  }
  $res =~ s/\s*$//;
  my $coins = [ map { Crypt::HashCash::Coin::Blinded->from_string($_) } split / /, $res ];
  for (@$coins) {
    $continue = $ProgressDialog->Update($j++, "Unblinding and adding coin " . ($j - ($numcoins+$numchgcoins) - 2));
    my $coin = $client->unblind_coin($_);
    if ($client->verify_coin($coin)) {
      $stash->addcoins('V',$coin);
    }
  }
  $continue = $ProgressDialog->Update(2+($numcoins+$numchgcoins)*2);
  show();
};

$action{Exit} = sub {       # Exit
  $statusBar->SetStatusText("Exit", 0);
  my $dialog = Wx::MessageDialog->new( $frame, "Do you really want to exit the wallet?", "Confirm", wxOK|wxCANCEL);
  return if $dialog->ShowModal == wxID_CANCEL;
  $app->ExitMainLoop;
};

$action{LangSel} = sub {    # Set language
  my $newlang = (sort keys %lang)[$langsel->GetCurrentSelection];
  if ($newlang ne $lang) {
    $lang = $newlang;
    $grid->SetColLabelValue(0, _('Denomination'));
    $grid->SetColLabelValue(1, _('Coins'));
    $grid->SetColLabelValue(2, _('Subtotal'));
    $frame->SetTitle('[#] ' . _('HashCash'));
    for (qw(Buy Sell Import Export Exchange Exit)) {
      $button{$_}->SetLabel(_($_));
    }
    show();
  }
};

$action{VaultSel} = sub {   # Set vault
  $vaultid = $vaultsel->GetCurrentSelection;
#  print STDERR "Vault changed to $vaultid\n";
  $vaultid = $vaults[$vaultid]->{id};
  $stash = new Crypt::HashCash::Stash (_DB => "$HASHCASH/stash/$vaultid\.db", Create => 1);
  $client = new Crypt::HashCash::Client (VaultConfig => "$HASHCASH/vaults/$vaultid\.cfg");
  $client->loadkeys;
  %fee = %{$client->keydb->{fees}};
  $stash->denoms($client->denoms);
  $stash->load;
  show();
};

for (qw(Buy Sell Import Export Exchange Exit)) {
  EVT_BUTTON($frame, $button{$_}, $action{$_});
}
EVT_CHOICE($frame, $vaultsel, $action{VaultSel});
EVT_CHOICE($frame, $langsel, $action{LangSel});

# Start the UI

show();
$statusBar->SetStatusText(_('HashCash Wallet Ready'), 0);
$frame->Show; $frame->Centre(wxBOTH); $frame->Refresh;
$app->MainLoop;

# Helper functions

sub show {                  # Update the wallet view
  my $total = my $total_u = my $i = 0;
  my $rows = $grid->GetNumberRows;
  my $needrows = (scalar grep { !/^_/ } keys %$stash) +
    (scalar grep { !/^_/ && defined $stash->{$_} && defined $stash->{$_}->{U} && defined $stash->{$_}->{V} } keys %$stash);
  if ($rows > $needrows) {
    $grid->DeleteRows(0, $rows - $needrows);
  }
  elsif ($rows < $needrows) {
    $grid->InsertRows(0, $needrows - $rows);
  }
  for $denom (sort {$b <=> $a} grep {!/^_/} keys %$stash) {
    my $numcoins = defined $stash->{$denom}->{V} ? scalar @{$stash->{$denom}->{V}} : 0;
    my $numcoins_u = $stash->{$denom}->{U} ? scalar @{$stash->{$denom}->{U}} : 0;
    if ($numcoins) {
      $grid->SetCellValue($i, 0, _($denom)); $grid->SetReadOnly($i, 0);
      $grid->SetCellValue($i, 1, _($numcoins)); $grid->SetReadOnly($i, 1);
      $grid->SetCellValue($i, 2, _($denom * $numcoins)); $grid->SetReadOnly($i, 2);
      $grid->SetCellTextColour($i, 0, wxBLACK); $grid->SetCellTextColour($i, 1, wxBLACK);
      $grid->SetCellTextColour($i++, 2, wxBLACK);
    }
    if ($numcoins_u) {
      $grid->SetCellValue($i, 0, _($denom)); $grid->SetReadOnly($i, 0);
      $grid->SetCellValue($i, 1, _($numcoins_u)); $grid->SetReadOnly($i, 1);
      $grid->SetCellValue($i, 2, _($denom * $numcoins_u)); $grid->SetReadOnly($i, 2);
      $grid->SetCellTextColour($i, 0, wxRED); $grid->SetCellTextColour($i, 1, wxRED);
      $grid->SetCellTextColour($i++, 2, wxRED);
    }
    $total += $denom * $numcoins; $total_u += $denom * $numcoins_u;
  }
  $stash->balance($total); $stash->balance_u($total_u);

  $label->SetLabel(_('Balance:') . ' ' . _($total)); $label2->SetLabel("Unverified: $total_u");
  $label->CentreOnParent(wxHORIZONTAL); $label2->CentreOnParent(wxHORIZONTAL); $label2->SetForegroundColour(wxRED);
  $label2->Show($total_u);

  my $bottom = $topSizer->GetMinSize->GetHeight;
  my $right = $topSizer->GetMinSize->GetWidth;

  $grid->SetSize([$right-20, 250]);
  $grid->SetColSize(0,int($right*2/5)-10);
  $grid->SetColSize(1,int($right*1/5));
  $grid->SetColSize(2,int($right*2/5)-10);

  $bottom = $topSizer->GetMinSize->GetHeight;
  $right = $topSizer->GetMinSize->GetWidth;

  my $clientsize = [$right, $bottom]; # $topSizer->ComputeFittingClientSize;
  $frame->SetClientSize($clientsize);
  my $windowsize = $frame->GetSize;
  $frame->SetMaxSize($windowsize);
  $frame->SetMinSize($windowsize);
  $frame->SetSize($windowsize);
  $frame->Refresh;
}

sub initui {                # Initialize the UI
  Wx::InitAllImageHandlers();
  my $app = Wx::SimpleApp->new;
  my $frame = Wx::Frame->new( undef, -1, '[#] ' . _('HashCash') , wxDefaultPosition, [500, 700] );

  $client->frame($frame);   # Enables client to access UI for offline wallet mode

  # Vault selection menu

  my $vaultsel = Wx::Choice->new($frame, -1, wxDefaultPosition, [-1,-1], [ map { $_->{name} . ' ' . $_->{sigscheme} } @vaults ]);
  $vaultsel->SetStringSelection($vaults[0]->{name});
  my @langs = map { $lang{$_}->{__NAME} } sort keys %lang;
  #my $langsel = Wx::Choice->new($frame, -1, wxDefaultPosition, [-1,-1], \@langs);
  #$langsel->SetStringSelection('English');
  my $selbox = Wx::BoxSizer->new(wxHORIZONTAL);
  $selbox->Add($vaultsel, 2, wxALL, 5);
  #$selbox->Add($langsel, 1, wxALL, 5);

  # Balance labels

  my $label = Wx::StaticText->new( $frame, -1, _('Balance:') . ' ' . _($stash->balance), [0,10], wxDefaultSize, wxALIGN_LEFT );
  my $font = Wx::Font->new(14, wxMODERN, wxNORMAL, wxBOLD, 0, 'Helvetica', wxFONTENCODING_SYSTEM);
  my $label2 = Wx::StaticText->new( $frame, -1, "Unverified: " . $stash->balance_u, [0,35], wxDefaultSize, wxALIGN_LEFT );
  my $font2 = Wx::Font->new(12, wxMODERN, wxNORMAL, wxNORMAL, 0, 'Helvetica', wxFONTENCODING_SYSTEM);
  $label->SetFont($font); $label2->SetFont($font2); $label2->SetForegroundColour(wxRED);

  my $grid = Wx::Grid->new( $frame, -1, [-1,-1], [100, 250] ); $grid->CreateGrid( 10, 3 );
  $grid->SetSelectionMode(wxGridSelectRows);
  $grid->SetRowLabelSize(0); $grid->SetDefaultCellAlignment(wxALIGN_RIGHT,wxALIGN_CENTRE);
  $grid->SetColLabelAlignment(wxALIGN_CENTRE,wxALIGN_CENTRE);
  $grid->DisableDragColSize(); $grid->DisableDragRowSize();
  $grid->SetColLabelValue(0, _('Denomination'));
  $grid->SetColLabelValue(1, _('Coins'));
  $grid->SetColLabelValue(2, _('Subtotal'));
  my $rect = $grid->CellToRect($grid->GetNumberRows - 1,2);
  my $top = $rect->GetTop; my $bottom = $rect->GetBottom;
  $grid->SetColLabelSize($bottom - $top);

  my $topSizer = Wx::BoxSizer->new(wxVERTICAL);
  $frame->SetSizer($topSizer);
  my $boxSizer = Wx::BoxSizer->new(wxVERTICAL);
  $topSizer->Add($boxSizer, 0, wxALIGN_CENTER_HORIZONTAL | wxALL | wxEXPAND, 5);

  $boxSizer->Add($selbox, 0, wxGROW | wxALL, 5);
  $boxSizer->Add($label, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);
  $boxSizer->Add($label2, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);
  $boxSizer->Add($grid, 1, wxALIGN_LEFT | wxEXPAND | wxALL, 5);

  # Buttons

  my %button;

  $button{Buy} = Wx::Button->new($frame, -1, _('Buy'), [-1,-1] );
  $button{Import} = Wx::Button->new($frame, -1, _('Import'), [-1, -1]);
  $button{Exchange} = Wx::Button->new($frame, -1, _('Exchange'), [-1, -1]);
  $button{Sell} = Wx::Button->new($frame, -1, _('Sell'), [-1, -1]);
  $button{Export} = Wx::Button->new($frame, -1, _('Export'), [-1,-1]);
  $button{Exit} = Wx::Button->new($frame, -1, _('Exit'), [-1,-1]);

  my $buttonbox1 = Wx::BoxSizer->new(wxHORIZONTAL);
  $boxSizer->Add($buttonbox1, 0, wxGROW | wxALL, 5);

  $buttonbox1->Add($button{Buy}, 1, wxALL, 5);
  $buttonbox1->Add($button{Export}, 1, wxALL, 5);
  $buttonbox1->Add($button{Exchange}, 1, wxALL, 5);

  my $buttonbox2 = Wx::BoxSizer->new(wxHORIZONTAL);
  $boxSizer->Add($buttonbox2, 0, wxGROW | wxALL, 5);

  $buttonbox2->Add($button{Sell}, 1, wxALL, 5);
  $buttonbox2->Add($button{Import}, 1, wxALL, 5);
  $buttonbox2->Add($button{Exit}, 1, wxALL, 5);

  # Status bar

  my $statusBar = Wx::StatusBar->new($frame, wxID_ANY);
  $frame->SetStatusBar($statusBar);
  return ($app, $frame, $vaultsel, $label, $label2, $grid, $topSizer, $statusBar, %button)
}

sub connecterror {
  my $saved = shift() ? ' Your payment details are saved.' : '';
  Wx::MessageDialog->new( $frame, "Unable to connect to the vault. This may be due to a network error. " .
			  "Check your network connection and try again.$saved", "Connection error", wxOK)->ShowModal;
}

sub initl8n {               # Initialize l8n
  $lang{en} = { map { $_ => $_ } qw(Balance: Import Export Exchange Buy Sell Exit HashCash Wallet Denomination Subtotal) };
  $lang{en}->{Denomination} = '  Denomination  ';
  $lang{en}->{Coins} = '  Coins  ';
  $lang{en}->{Subtotal} = '    Subtotal    ';
  $lang{en}->{'HashCash Wallet Ready'} = 'HashCash Wallet Ready';
  $lang{en}->{__NAME} = 'English';
  $lang{zh} = { 'Import'       => "\x{5bfc}\x{5165}",
		'Export'       => "\x{5bfc}\x{51fa}",
		'Buy'          => "\x{91c7}\x{8d2d}",
		'Sell'         => "\x{51fa}\x{552e}",
		'Exchange'     => "\x{66ff}\x{6362}",
		'Exit'         => "\x{9000}\x{51fa}",
		'Balance:'     => "\x{5e73}\x{8861}\x{ff1a}",
		'HashCash'     => "HashCash",
		'Wallet'       => "\x{94b1}\x{5305}",
		'Ready'        => "Listo",
		'Coins'        => "  \x{786c}\x{5e01}  ",
		'Denomination' => "  \x{8861}\x{91cf}\x{5355}\x{4f4d}  ",
		'Subtotal'     => "    \x{5c0f}\x{8ba1}    ",
		'__NAME'       => "\x{6c49}\x{8bed}"
	      };
  $lang{es} = { 'Import'       => "Importaci\x{f3}n",
		'Export'       => "Exportaci\x{f3}n",
		'Buy'          => "Compra",
		'Sell'         => "Venta",
		'Exchange'     => "Intercambio",
		'Exit'         => "Salida",
		'Balance:'     => "Balance:",
		'HashCash'     => "HashCash",
		'Wallet'       => "Carpeta",
		'Ready'        => "Listo",
		'Coins'        => "  Monedas  ",
		'Denomination' => "  Denominaci\x{f3}n  ",
		'Subtotal'     => "    Subtotal    ",
		'Buy coins'    => 'Compre monedas',
		'Amount to buy (in Satoshi)' => 'Cantidad a comprar (en Satoshi)',
                '__NAME'       => "Espa\x{f1}ol"
	      };
  $lang{fr} = { 'Import'       => "Importation",
		'Export'       => "Exportation",
		'Buy'          => "Achat",
		'Sell'         => "Vente",
		'Exchange'     => "\x{c9}change",
		'Exit'         => "Sortie",
		'Balance:'     => "\x{c9}quilibre:",
		'HashCash'     => "HashCash",
		'Wallet'       => "Pochette",
		'Ready'        => "Listo",
		'Coins'        => "  Nombre  ",
		'Denomination' => "  D\x{e9}nomination  ",
		'Subtotal'     => "    Total partiel    ",
                '__NAME'       => "Fran\x{e7}ais"
	      };
  $lang{de} = { 'Import'       => "Import",
		'Export'       => "Export",
		'Buy'          => "Kauf",
		'Sell'         => "Verkauf",
		'Exchange'     => "Austausch",
		'Exit'         => "Ausgang",
		'Balance:'     => "Balance:",
		'HashCash'     => "HashCash",
		'Wallet'       => "Mappe",
		'Ready'        => "Listo",
		'Coins'        => "  M\x{fc}nzen  ",
		'Denomination' => "  Bezeichnung  ",
		'Subtotal'     => "   Teilsumme   ",
                '__NAME'       => "Deutsch"
	      };
  $lang{gr} = { 'Import'       => "\x{395}\x{3b9}\x{3c3}\x{3b1}\x{3b3}\x{3c9}\x{3ae}",
		'Export'       => "\x{395}\x{3be}\x{3b1}\x{3b3}\x{3c9}\x{3ae}",
		'Buy'          => "\x{391}\x{3b3}\x{3bf}\x{3c1}\x{3ac}\x{3c3}\x{3c4}\x{3b5}",
		'Sell'         => "\x{3a0}\x{3c9}\x{3bb}\x{3ae}\x{3c3}\x{3c4}\x{3b5}",
		'Exchange'     => "\x{391}\x{3bd}\x{3c4}\x{3b1}\x{3bb}\x{3b3}\x{3ae}",
		'Exit'         => "\x{388}\x{3be}\x{3bf}\x{3b4}\x{3c2}",
		'Balance:'     => "\x{399}\x{3c3}\x{3bf}\x{3c1}\x{3c0}\x{3af}\x{3b1}:",
		'HashCash'     => "HashCash",
		'Wallet'       => "\x{3a0}\x{3bf}\x{3c1}\x{3c4}\x{3c6}\x{3cc}\x{3bb}\x{3b9}",
		'Ready'        => "Listo",
		'Coins'        => "  \x{3bd}\x{3bf}\x{3bc}\x{3af}\x{3c3}\x{3b1}\x{3c4}  ",
		'Denomination' => "  \x{3bc}\x{3b5}\x{3c4}\x{3bf}\x{3bd}\x{3b1}\x{3c3}\x{3af}  ",
		'Subtotal'     => "    \x{3c5}\x{3c0}\x{3bf}\x{3c3}\x{3cd}\x{3bd}\x{3bb}    ",
                '__NAME'       => "\x{395}\x{3bb}\x{3b7}\x{3bd}\x{3b9}\x{3ba}\x{3ac}"
	      };
  $lang{hi} = { 'Import'       => "\x{921}\x{93e}\x{932}\x{94b}",
		'Export'       => "\x{928}\x{93f}\x{915}\x{93e}\x{932}\x{94b}",
		'Buy'          => "\x{916}\x{930}\x{940}\x{926}\x{94b}",
		'Sell'         => "\x{92c}\x{947}\x{91a}\x{94b}",
		'Exchange'     => "\x{905}\x{926}\x{932}\x{93e} \x{92c}\x{926}\x{932}\x{940}",
#		'Exit'         => "\x{92c}\x{902}\x{926} \x{915}\x{930}\x{94b}",
		'Exit'         => "\x{928}\x{93f}\x{915}\x{93e}\x{938}",
		'Balance:'     => "\x{936}\x{947}\x{937} \x{930}\x{93e}\x{936}\x{940}:",
		'HashCash'     => "\x{939}\x{948}\x{936}\x{915}\x{948}\x{936}",
		'Wallet'       => "\x{92c}\x{91f}\x{941}\x{906}",
		'Ready'        => "\x{924}\x{948}\x{92f}\x{93e}\x{930}",
		'Coins'        => "      \x{938}\x{93f}\x{915}\x{94d}\x{915}\x{947}      ",
		'Denomination' => "             \x{92e}\x{942}\x{932}\x{94d}\x{92f}             ",
		'Subtotal'     => "              \x{915}\x{941}\x{932}              ",
		'__NUMERALS'   => "\x{966}\x{967}\x{968}\x{969}\x{96a}\x{96b}\x{96c}\x{96d}\x{96e}\x{96f}",
		'__NAME'       => "\x{939}\x{93f}\x{902}\x{926}\x{940}"
	      };
  $lang{hi}->
    {__X11} = { 'Import'       => "\x{921}\x{93e}\x{932}\x{94b}",
		'Export'       => "\x{928}\x{93f}\x{915}\x{93e}\x{932}\x{94b}",
		'Buy'          => "\x{916}\x{930}\x{940}\x{926}\x{94b}",
		'Sell'         => "\x{947}\x{92c}\x{91a}\x{94b}",
		'Exchange'     => "\x{905}\x{926}\x{932}\x{93e} \x{92c}\x{926}\x{932}\x{94b}",
#		'Exit'         => "\x{959}\x{924}\x{92e} \x{915}\x{930}\x{94b}",
		'Exit'         => "\x{928}\x{93f}\x{915}\x{93e}\x{938}",
		'Balance:'     => "\x{947}\x{936}\x{937} \x{930}\x{93e}\x{936}\x{940}:",
		'HashCash'     => "\x{948}\x{939}\x{936}\x{948}\x{915}\x{936}",
		'Wallet'       => "\x{92c}\x{941}\x{91f}\x{906}",
		'Ready'        => "\x{948}\x{924}\x{92f}\x{93e}\x{930}",
		'Coins'        => "\x{938}\x{93f}\x{947}\x{915}\x{94d}\x{915}",
		'Denomination' => "\x{92e}\x{942}\x{932}\x{94d}\x{92f}",
		'Subtotal'     => "              \x{915}\x{941}\x{932}              ",
		'__NAME'       => "\x{939}\x{93f}\x{902}\x{926}\x{940} (X11)"
	      };
  $lang{it} = { 'Import'       => "Inclusione",
		'Export'       => "Esportazione",
		'Buy'          => "Affare",
		'Sell'         => "Vendita",
		'Exchange'     => "Scambio",
		'Exit'         => "Uscita",
		'Balance:'     => "Equilibrio:",
		'HashCash'     => "HashCash",
		'Wallet'       => "Raccoglitore",
		'Ready'        => "Listo",
		'Coins'        => " Monete ",
		'Denomination' => " Denominazione ",
		'Subtotal'     => " Totale parziale ",
                '__NAME'       => "Italiano"
	      };
  $lang{ja} = { 'Import'       => "\x{30a4}\x{30f3}\x{30dd}\x{30fc}\x{30c8}",
		'Export'       => "\x{30a8}\x{30af}\x{30b9}\x{30dd}\x{30fc}\x{30c8}",
		'Buy'          => "\x{8cb7}\x{7269}",
		'Sell'         => "\x{8ca9}\x{58f2}\x{6cd5}",
		'Exchange'     => "\x{4ea4}\x{63db}",
		'Exit'         => "\x{51fa}\x{53e3}",
		'Balance:'     => "\x{30d0}\x{30e9}\x{30f3}\x{30b9}:",
		'HashCash'     => "HashCash",
		'Wallet'       => "\x{672d}\x{5165}\x{308c}",
		'Ready'        => "Listo",
		'Coins'        => "  \x{786c}\x{8ca8}  ",
		'Denomination' => "  \x{7a2e}\x{985e}  ",
		'Subtotal'     => "   \x{30b5}\x{30d6}\x{30c8}\x{30fc}\x{30bf}\x{30eb}   ",
		'__NAME'       => "\x{65e5}\x{672c}\x{8a9e}"
	      };
  $lang{kr} = { 'Import'       => "\x{ac00}\x{c838}\x{c624}\x{ae30}",
		'Export'       => "\x{c218}\x{cd9c}",
		'Buy'          => "\x{ad6c}\x{b9e4}",
		'Sell'         => "\x{c778}\x{ae30} \x{c0c1}\x{d488}",
		'Exchange'     => "\x{ad50}\x{d658}",
		'Exit'         => "\x{cd9c}\x{ad6c}",
		'Balance:'     => "\x{ade0}\x{d6a5}:",
		'HashCash'     => "HashCash",
		'Wallet'       => "\x{c9c0}\x{ac11}",
		'Ready'        => "Listo",
		'Coins'        => "  \x{b3d9}\x{c804}  ",
		'Denomination' => "  \x{ba85}\x{ce6d}  ",
		'Subtotal'     => "   \x{c18c}\x{acc4}   ",
                '__NAME'       => "\x{d55c}\x{ad6d}\x{c5b4}"
	      };
  $lang{ru} = { 'Import'       => "\x{412}\x{432}\x{43e}\x{437}",
		'Export'       => "\x{42d}\x{43a}\x{441}\x{43f}\x{43e}\x{440}\x{442}",
		'Buy'          => "\x{41f}\x{43e}\x{43a}\x{443}\x{43f}\x{430}",
		'Sell'         => "\x{41d}\x{430}\x{434}\x{443}\x{432}\x{442}\x{435}\x{43b}\x{44c}",
		'Exchange'     => "\x{41e}\x{431}\x{43c}\x{435}\x{43d}",
		'Exit'         => "\x{412}\x{44b}\x{445}\x{43e}\x{434}",
		'Balance:'     => "\x{411}\x{430}\x{43b}\x{43d}\x{441}:",
		'HashCash'     => "HashCash",
		'Wallet'       => "\x{411}\x{443}\x{43c}\x{430}\x{436}\x{43d}\x{438}\x{43a}",
		'Ready'        => "Listo",
		'Coins'        => "  \x{43c}\x{43e}\x{43d}\x{435}\x{442}\x{43a}\x{438}  ",
		'Denomination' => "  \x{434}\x{435}\x{43d}\x{43e}\x{43c}\x{438}\x{430}\x{446}  ",
		'Subtotal'     => "    \x{43f}\x{43e}\x{434} \x{438}\x{442}\x{433}    ",
		'__NAME'       => "\x{420}\x{443}\x{441}\x{43a}\x{43e}"
	      };
  $lang = 'zh';
  $lang{zh}->{'HashCash Wallet Ready'} = join ' ', _('HashCash'), _('Wallet'), _('Ready');
  $lang = 'es';
  $lang{es}->{'HashCash Wallet Ready'} = join ' ', _('HashCash'), _('Wallet'), _('Ready');
  $lang = 'ja';
  $lang{ja}->{'HashCash Wallet Ready'} = join ' ', _('HashCash'), _('Wallet'), _('Ready');
  $lang = 'hi';
  $lang{hi}->{'HashCash Wallet Ready'} = join ' ', _('HashCash'), _('Wallet'), _('Ready');
  $lang = 'en';
  if ($^O eq 'MSWin32') {
    my %winlang = ( de => [qw(0007 0c07 0407 1407 1007 0807)],
		    es => [qw(000a 2c0a 200a 400a 340a 240a 140a 5c0a 1c0a 300a 440a 100a 480a 580a 080a 4c0a 180a 3c0a 280a 500a 040a 0c0a 540a 380a)],
		    fr => [qw(000c 080c 2c0c 240c 300c 040c 3c0c 140c 340c 380c 180c 200c 280c 100c)],
		    gr => [qw(0008 0408)],
		    hi => [qw(0039 0439)],
		    it => [qw(0010 0410 0810)],
		    ja => [qw(0011 0411)],
		    kr => [qw(0012 0412)],
		    ru => [qw(0019 0819 0419)],
		    zh => [qw(0004 7804 0804 1004 7c04 0c04 1404 0404)]
		  );
    require Win32::API;
    Win32::API->Import('kernel32', 'int GetUserDefaultLCID()');
    my $langid = GetUserDefaultLCID();
    for my $l (keys %winlang) {
      $lang = $l, last if grep { sprintf("%04x",$langid) eq $_ } @{$winlang{$l}};
    }
#    print STDERR "$lang\n";
  }
  else {
    $lang = $ENV{LC_ALL} || $ENV{LANG};
  }
  $lang = 'en' unless defined $lang;
  $lang = 'en' if $lang =~ /^C|POSIX/;
  $lang = substr($lang, 0, 2) || 'en';
  return ($lang, %lang);
}

sub _ {
  $_ = shift;
  if (/^\d+$/) {
    if ($lang eq 'h1') {
      $numerals = $lang{$lang}->{__NUMERALS};
      eval "tr/0-9/$numerals/";
    }
    return $_;
  }
  else {
    if ($lang eq 'hi' and $ENV{DISPLAY} and $ENV{DISPLAY} !~ /apple/) {
      return $lang{$lang}->{__X11}->{$_} || $_;
    }
    else {
      return $lang{$lang}->{$_} || $_;
    }
  }
}

1;

__END__

=head1 NAME

hashcash.pl - Wallet for HashCash digital cash

=head1 VERSION

 $Revision: 1.130 $
 $Date: Sat Dec 22 18:42:26 PST 2018 $

=head1 SYNOPSIS

  hashcash.pl [--offline]

=head1 DESCRIPTION

hashcash.pl is a cross-platform GUI wallet for the HashCash digital
cash system. It provides the ability to buy, sell and exchange
HashCash coins, as well as to export coins from the wallet to send to
others, and to import and verify received coins.

=head1 COMMAND LINE OPTIONS

=over

--offline - Run the wallet in offline mode. In this mode the user is
  responsible for relaying messages between the wallet and the vault.

=back

=head1 SEE ALSO

=head2 L<http://www.hashcash.com>

=head2

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-hashcash at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-hashcash at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-HashCash>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this command with the perldoc command.

    perldoc hashcash.pl

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
