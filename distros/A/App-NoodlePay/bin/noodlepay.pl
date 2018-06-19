#!/usr/bin/perl
# -*-cperl-*-
#
# noodlepay.pl - Convenient way to securely send Bitcoin from cold storage
# Copyright (c) Ashish Gulhati <noodlepay at hash.neo.tc>
#
# $Id: bin/noodlepay.pl v1.006 Tue Jun 19 01:28:58 PDT 2018 $

use warnings;

use Wx qw (:everything);
use Wx::Event qw (EVT_BUTTON);
use LWP::UserAgent;
use HTTP::Request;
use GD::Barcode::QRcode;
use Math::Prime::Util qw(fromdigits todigitstring);
use vars qw( $VERSION $AUTOLOAD );

my $electrum = 'electrum';
#my $electrum = 'python ~/src/Electrum-2.8.2/electrum';

# Initialize l8n
my ($lang, %lang) = initl8n();

# Initialize UI
my ($app, $frame, $topSizer, $boxSizer, $statusBar, %button) = initui();

# Actions for all the buttons
my %action;

$action{SendSign} = sub {   # Send bitcoin / Sign transaction
  if ($ARGV[0] and $ARGV[0] eq '--offline') {
    system ('v4l2-ctl --set-fmt-overlay=width=400,top=0,left=0 --overlay=1');
    open (ZBAR, "zbarcam --nodisplay --prescale=640x480 /dev/video0 |");
    my $x = <ZBAR>; chomp $x; $x =~ s/^QR-Code://;
    system ('killall -9 zbarcam');
    close ZBAR;
    system ('v4l2-ctl --overlay=0');
    my $tx = "{\n\"complete\": false,\n\"final\": true,\n\"hex\": \"$x\"\n}";
    my $txdetails = `$electrum deserialize '$tx'`;    # Check transaction details
    my $chgaddresses = `$electrum listaddresses --change`;
    my @chgaddresses = map { /\"(\S+)\"/; $1; } split /,\s*/, $chgaddresses;
    $txdetails =~ /\"inputs\": (.*)\"outputs:\"/s; my $inputs = $1;
    $txdetails =~ /\"outputs\": (.*)/s; my $outputs = $1;
    my @outputs = map { /\"address\": \"(\S+?)\".*\"value\": (\d+)/s; ($1 => $2) } split /\}\,/s, $outputs;
    my @inputs = map { /\"address\": \"(\S+?)\".*\"value\": (\d+)/s; ($1 => $2) } split /\}\,/s, $inputs;
    my $chgtotal = 0;
    for (2..$#outputs) {
      $chgtotal += $outputs[$_], next if $_ % 2; my $o = $outputs[$_];
      $err = 1, last unless grep { /^$o$/ } @chgaddresses;
    }
#    my $feeamt = $total - $chgtotal;
    unless ($err) {
      my $dialog = Wx::MessageDialog->new( $frame, "Sign transaction of $outputs[1] Satoshi to $outputs[0]?", "Confirm", wxOK|wxCANCEL);
      return if $dialog->ShowModal == wxID_CANCEL;
      my $signedtx = `$electrum signtransaction '$tx'`;
      $signedtx =~ /"hex": "(\S+)"/s;
      $dialog = qrdialog(fromdigits($1,16), 'Scan the QR code on Noodle Pi', 'Broadcast Transaction');
      $dialog->ShowModal;
    }
  }
  else {
    my $dialog = Wx::TextEntryDialog->new( $frame, "Enter amount (in Satoshi)", "Send Bitcoin", "", wxOK|wxCANCEL, [70,280] );
    system ('xvkbd -geometry 480x250+0+520 -keypad&');
    my $ret = $dialog->ShowModal;
    system ('killall -9 xvkbd');
    return if $ret == wxID_CANCEL;
    my $amount = $dialog->GetValue(); return unless $amount =~ /^\d+$/; $amount = sprintf("%f",$amount / 100000000);
    system ('v4l2-ctl --set-fmt-overlay=width=400,top=0,left=0 --overlay=1');
    open (ZBAR, "zbarcam --nodisplay --prescale=640x480 /dev/video0 |");
    my $sendto = <ZBAR>;
    system ('killall -9 zbarcam');
    close ZBAR;
    system ('v4l2-ctl --overlay=0');
    chomp $sendto; $sendto =~ s/^QR-Code://; $sendto =~ s/^bitcoin://;
    my $ProgressDialog = Wx::ProgressDialog->new("Send Money", "Creating transaction", 3, $frame,
						 wxPD_AUTO_HIDE | wxPD_APP_MODAL );
    $ProgressDialog->Update(0,"Checking balance...");
    my $balance = `$electrum getbalance`;
    if (defined $balance and $balance) {
      $balance =~ /"confirmed": "(\S+)"/s; $balance = $1 * 100000000;
      # TODO: Return error if wallet balance lower than send amount
      $ProgressDialog->Update(1,"Creating transaction...");
      my $tx = `$electrum payto $sendto $amount -f 0 -u`;
      $ProgressDialog->Update(2,"Looking up fees...");
      $tx =~ /"hex": "(\S+)"/s; my $txsize = length($1)/2 + 65;
      my $ua = new LWP::UserAgent; $ua->agent('Mozilla/5.0');
      my $req = HTTP::Request->new(GET => 'https://bitcoinfees.earn.com/api/v1/fees/recommended');
      my $res = $ua->request($req);
      my $fees = $res->content; $fees =~ s/\{\s*(.*)\s*\}/$1/; $fees =~ s/\"//g;
      my %fees = split /[:,]\s*/, $fees;
      my $fastest_fee = $fees{fastestFee} * $txsize;
      my $halfhour_fee = $fees{halfHourFee} * $txsize;
      my $hour_fee = $fees{hourFee} * $txsize;
      $ProgressDialog->Update(3);
      $dialog = Wx::TextEntryDialog->new( $frame, "Enter fee amount (in Satoshi). Recommended fees:\n\n" .
					  "- Fastest (10-20 mins): $fastest_fee\n- Within half an hour: $halfhour_fee\n" .
					  "- Within an hour: $hour_fee\n", "Send Bitcoin", $fastest_fee, wxOK|wxCANCEL, [50, 180]);
      system ('xvkbd -geometry 480x250+0+520 -keypad&');
      $ret = $dialog->ShowModal;
      system ('killall -9 xvkbd');
      return if $ret == wxID_CANCEL;
      my $feeamt = $dialog->GetValue(); return unless $feeamt =~ /^\d+$/; $feeamt = sprintf("%f",$feeamt / 100000000);
      my $signedtx;
      if ($ARGV[0] and $ARGV[0] eq '--online') {
	$ProgressDialog = Wx::ProgressDialog->new("Send Money", "Signing transaction", 1, $frame,
						  wxPD_AUTO_HIDE | wxPD_APP_MODAL );
	$ProgressDialog->Update(0,"Signing transaction...");
	$signedtx = `$electrum payto $sendto $amount -f $feeamt`;
        $signedtx =~ s/\"final\": false/\"final\": true/;
	$ProgressDialog->Update(1);
      }
      else {
	$tx = `$electrum payto $sendto $amount -f $feeamt -u`;
	$tx =~ /"hex": "(\S+)"/s;
	my $dialog = qrdialog(fromdigits($1,16), 'Scan the QR code on Noodle Air', 'Sign Transaction');
	$dialog->ShowModal;
	system ('v4l2-ctl --set-fmt-overlay=width=400,top=0,left=0 --overlay=1');
	open (ZBAR, "zbarcam --nodisplay --prescale=640x480 /dev/video0 |");
	my $signed = <ZBAR>; chomp $signed; $signed =~ s/^QR-Code://; $signed = todigitstring($signed,16);
	system ('killall -9 zbarcam');
	close ZBAR;
	system ('v4l2-ctl --overlay=0');
	$signedtx = "{\n\"complete\": true,\n\"final\": true,\n\"hex\": \"$signed\"\n}";
      }
      $dialog = Wx::MessageDialog->new( $frame, "Broadcast transaction?", "Confirm", wxOK|wxCANCEL);
      return if $dialog->ShowModal == wxID_CANCEL;
      my $id = `$electrum broadcast '$signedtx'`;
      $dialog = Wx::MessageDialog->new( $frame, "Transaction ID is $id", "Payment Sent", wxOK);
      $dialog->ShowModal;
    }
  }
  show();
};

$action{Exit} = sub {       # Exit
  $statusBar->SetStatusText("Exit", 0);
  my $dialog = Wx::MessageDialog->new( $frame, "Do you really want to exit?", "Confirm", wxOK|wxCANCEL);
  return if $dialog->ShowModal == wxID_CANCEL;
  $app->ExitMainLoop;
};

EVT_BUTTON($frame, $button{$_}, $action{$_}) for (qw(SendSign Exit));

# Start the UI

show();
$statusBar->SetStatusText(_('Noodle Pay Ready'), 0);
$frame->Show; $frame->Centre(wxBOTH); $frame->Refresh;
$app->MainLoop;

# Helper functions

sub qrdialog {
  my ($text, $msgtxt, $title) = @_;
  my $len = length($text); my ($msg, $qr, $dialog, $version);
  if ($len < 7090 ) {
    my $qrfh; my $level;
    my @version = qw( 0 41 77 127 187 255 322 370 461 552 652 772 883 1022 1101 1250 1408 1548 1725 1903 2061 2232 
		      2409 2620 2812 3057 3283 3517 3669 3909 4158 4417 4686 4965 5253 5529 5836 6153 6479 6743 7089 );
    for (1..40) { next if $len > $version[$_]; $version = $_; last; }
    my $qrxpm = GD::Barcode::QRcode->new($text, { Version => $version, Ecc => L, ModuleSize => 4 })->barcode;
    $qrxpm =~ /^(.*)$/m; my $qrsize = length($1);
    $qr = Wx::Bitmap->newFromXPM([ split /\n/, "$qrsize $qrsize 2 1\n0 c #FFFFFF\n1 c #000000\n$qrxpm" ]);
  }
  if (defined $qr) {
    my $fontheight = $frame->GetCharHeight;
    $msg = "\n" x ($qr->GetHeight / $fontheight) . "\n\n$msgtxt";
    $dialog = Wx::TextEntryDialog->new($frame, $msg , $title, $text);
    my $dialog_height = $dialog->GetSize->GetHeight;
    my $dialogwidth = $dialog->GetSize->GetWidth;
    my $qrheight = $qr->GetHeight; my $width = $qrheight + 20 > $dialogwidth ? $qrheight + 20 : $dialogwidth;
    my $adjust = 10 unless $^O eq 'MSWin32' or $^O eq 'darwin';
    my $qrpos = ($width-$qrheight)/2 + ($width == 300 ? $adjust : 0);
    $dialog->SetSize([$width,$dialog_height]);
    $dialog->SetMinSize([$width,$dialog_height]);
    $dialog->SetMaxSize([$width,$dialog_height]);
      Wx::StaticBitmap->new( $dialog, -1, $qr, [$qrpos,10] );
  }
  return $dialog;
}

sub show {                  # Update the main frame
  my $bottom = $topSizer->GetMinSize->GetHeight;
  my $right = $topSizer->GetMinSize->GetWidth;
  my $clientsize = [$right, $bottom];
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
  my $frame = Wx::Frame->new( undef, -1, _('Noodle Pay'), wxDefaultPosition, wxDefaultSize );

  my $topSizer = Wx::BoxSizer->new(wxVERTICAL);
  $frame->SetSizer($topSizer);
  my $boxSizer = Wx::BoxSizer->new(wxVERTICAL);
  $topSizer->Add($boxSizer, 0, wxALL | wxEXPAND, 5);

  # Buttons

  my %button;

  if ($ARGV[0] and $ARGV[0] eq '--offline') {
      $button{SendSign} = Wx::Button->new($frame, -1, _('Sign'), [-1,-1]);
  }
  else {
      $button{SendSign} = Wx::Button->new($frame, -1, _('Send'), [-1,-1]);
  }
  $button{Exit} = Wx::Button->new($frame, -1, _('Exit'), [-1,-1]);

  my $buttonbox1 = Wx::BoxSizer->new(wxHORIZONTAL);
  $boxSizer->Add($buttonbox1, 0, wxGROW | wxALL, 5);

  $buttonbox1->Add($button{SendSign}, 1, wxALL, 5);
  $buttonbox1->Add($button{Exit}, 1, wxALL, 5);

  # Status bar

  my $statusBar = Wx::StatusBar->new($frame, wxID_ANY);
  $frame->SetStatusBar($statusBar);
  return ($app, $frame, $topSizer, $boxSizer, $statusBar, %button)
}

sub initl8n {               # Initialize l8n
  $lang{zh} = { };
  $lang{es} = { };
  $lang{fr} = { };
  $lang{de} = { };
  $lang{gr} = { };
  $lang{hi} = { };
  $lang{it} = { };
  $lang{ja} = { };
  $lang{kr} = { };
  $lang{ru} = { };
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

noodlepay.pl - Convenient way to securely send Bitcoin from cold storage

=head1 VERSION

 $Revision: 1.006 $
 $Date: Tue Jun 19 01:28:58 PDT 2018 $

=head1 SYNOPSIS

  noodlepay.pl [--offline] [--online]

=head1 DESCRIPTION

noodlepay.pl (Noodle Pay) enables the use of an air-gapped wallet
running on a device such as a Noodle Air (L<http://www.noodlepi.com>)
to easily and securely send Bitcoin payments.

Noodle Pay is much more convenient to use than hardware wallets, and
doesn't require single-purpose hardware. The Noodle Air device is a
general purpose Linux computer, which can be used for many other
applications as well.

Noodle Pay uses the Electrum wallet's command line mode to create,
sign and publish Bitcoin transactions.

To use Noodle Pay to send Bitcoin from cold storage, you would first
create a cold storage wallet using Electrum on a Noodle Air. Then you
copy the master public key from the Noodle Air to a Noodle Pi, and
create a "watching-only wallet" on the Noodle Pi.

Now you can receive funds to your cold storage wallet and keep track
of them using your watching-only wallet on the Noodle Pi (or any other
computer).

To spend funds from your cold storage wallet, you run noodlepay.pl on
the Noodle Pi, and "noodlepay.pl --offline" on the Noodle Air. Click
"Send" on the Noodle Pi, and enter the amount, scan the destination
address QR code, and enter the transaction fee amount.

A QR code then pops up on the screen, which you scan on the Noodle Air
by clicking "Sign". You're then asked to confirm the transaction, and
if you do a QR code pops up, which you now scan on the Noodle
Pi. You're then asked for confirmation to broadcast the transaction,
and when you click OK it is broadcast.

Your private keys always stay secure on the offline Noodle Air.

Noodle Air provides a truly mobile, wire-free and convenient cold
storage payment solution. Most hardware wallets require the use of a
desktop or laptop computer, and a USB cable to connect it to the
hardware wallet device.

Compared to other hardware wallet solutions, Noodle Pay also greatly
simplifies physically securing your private keys, and keeping
backups. You can simply pop the MicroSD card out of the Noodle Air,
and keep it physically secure. For backups, you can just duplicate the
MicroSD card, and keep multiple copies in safe locations.

=head1 CONFIGURATION

The $electrum variable at the top of noodlepay.pl should be set to the
path or command required to run electrum on your system.

=head1 OPTION SWITCHES

=head2 --offline

Use this switch when running the app offline on a Noodle Air.

=head2 --online

Use this switch to have the app sign transactions directly on Noodle
Pi rather than delegating signing to an air-gapped Noodle Air.

=head1 PREREQUISITES

Currently this app is designed to work on Noodle Pi / Noodle
Air devices, and requires the following programs to be
available:

* electrum

* zbarcam

* v4l2-ctl

* xvkbd

=head1 SEE ALSO

L<http://www.noodlepi.com>

L<http://www.noodlepay.com>

=head1 AUTHOR

Ashish Gulhati, C<< <noodlepay at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-noodlepay at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-NoodlePay>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::NoodlePay

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-NoodlePay>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-NoodlePay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-NoodlePay>

=item * Search CPAN

L<http://search.cpan.org/dist/App-NoodlePay/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
