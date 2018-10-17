#!/usr/bin/perl
# -*-cperl-*-
#
# unsnoopable.pl - Completely unsnoopable messaging
# Copyright (c) Ashish Gulhati <crypt-unsnoopable at hash.neo.tc>
#
# $Id: bin/unsnoopable.pl v1.010 Tue Oct 16 21:04:28 PDT 2018 $

use warnings;

use Wx qw (:everything);
use Wx::Event qw (EVT_BUTTON);
use Crypt::Unsnoopable qw(dec heX);
use GD::Barcode::QRcode;
use File::HomeDir;

my $NOODLEPI;
if ($ARGV[0] and $ARGV[0] eq '--noodlepi') {
  my $uname = `uname -a`; my $cpu;
  if ($uname =~ /armv6l GNU\/Linux/) {
    $cpu = `grep Hardware /proc/cpuinfo`;
  }
  $NOODLEPI = 1 if $cpu =~ /BCM2708/;
}
my $UNSNOOPABLE = $ENV{UNSNOOPABLEDIR} || File::HomeDir->my_home . '/.unsnoopable';

unless (-d $UNSNOOPABLE) {
  die "Directory $UNSNOOPABLE doesn't exist and couldn't be created.\n" unless mkdir($UNSNOOPABLE, 0700);
}

my $u = new Crypt::Unsnoopable (DB => $UNSNOOPABLE);
my $pads = $u->otps;

# Initialize l8n
my ($lang, %lang) = initl8n();

# Initialize UI
my ($app, $frame, $padsel, $topSizer, $boxSizer, $statusBar, %button) = initui();

# Actions for all the buttons
my %action;

$action{Generate} = sub {   # Generate new OTP
  my $dialog = Wx::TextEntryDialog->new( $frame, "Enter a name for this pad:", "Generate One-Time Pad");
  return if $dialog->ShowModal == wxID_CANCEL;
  my $name = $dialog->GetValue(); return unless $name =~ /^[\w\d\s]+$/; return if exists $pads->{$name};
  my $pad = $u->otpgen(2935, $name);
  $pads = $u->otps;
  $padsel->Insert("$name (2935)", 0);
  show();
};

$action{Import} = sub {     # Import OTP
  my ($dialog, $pad);
  if ($NOODLEPI) {
    system ('v4l2-ctl --overlay=1');
    open (ZBAR, "zbarcam --nodisplay --prescale=640x480 /dev/video0 |");
    $pad = <ZBAR>; chomp $pad; $pad =~ s/^QR-Code://;
    system ('killall -9 zbarcam');
    close ZBAR;
    system ('v4l2-ctl --overlay=0');
    print "$pad\n";
  }
  else {
    $dialog = Wx::TextEntryDialog->new( $frame, "Paste pad below", "Import One-Time Pad");
    return if($dialog->ShowModal == wxID_CANCEL);
    $pad = $dialog->GetValue();
  }
  return if $pad =~ /\D/;
  $dialog = Wx::TextEntryDialog->new( $frame, "Enter a name for this pad:", "Import One-Time Pad");
  return if $dialog->ShowModal == wxID_CANCEL;
  my $name = $dialog->GetValue(); return unless $name =~ /^[\w\d\s]+$/; return if exists $pads->{$name};
  return unless $pad = $u->add($pad, $name);
  $pads = $u->otps; my $len = length($pads->{$name}->{pad})/2;
  $padsel->Insert("$name ($len)", 0);
  show();
};

$action{Export} = sub {     # Export OTP
  my $pad_name = $padsel->GetString($padsel->GetSelection); $pad_name =~ s/\s*\(\d+\)//;
  local $SIG{'__WARN__'} = sub { };
  my $pad = dec(heX($pads->{$pad_name}->{id}) . $pads->{$pad_name}->{pad});
  my $dialog = qrdialog($pad, 'Scan the QR code or copy pad from below', 'Export One-Time Pad');
  $dialog->ShowModal;
};

$action{Send} = sub {       # Send a message
  my $dialog = Wx::TextEntryDialog->new( $frame, "Enter message:", "Send message");
  return if $dialog->ShowModal == wxID_CANCEL;
  my $msg = $dialog->GetValue(); return unless $msg;
  my $selnum = $padsel->GetSelection;
  my $pad_name = $padsel->GetString($selnum); $pad_name =~ s/\s*\(\d+\)//;
  return unless my $encrypted = $u->encrypt($pad_name, $msg);
  my $len = length($u->otps->{$pad_name}->{pad})/2;
  $padsel->SetString($selnum, "$pad_name ($len)");
  $dialog = qrdialog($encrypted, 'Scan the QR code or copy message from below', 'Send message');
  $dialog->ShowModal;
};

$action{Receive} = sub {    # Receive a message
  my ($dialog, $msg);
  if ($NOODLEPI) {
    system ('v4l2-ctl --overlay=1');
    open (ZBAR, "zbarcam --nodisplay --prescale=640x480 /dev/video0 |");
    $msg = <ZBAR>; chomp $msg; $msg =~ s/^QR-Code://;
    system ('killall -9 zbarcam');
    close ZBAR;
    system ('v4l2-ctl --overlay=0');
    print "$msg\n";
  }
  else {
    $dialog = Wx::TextEntryDialog->new( $frame, "Enter message:", "Receive message");
    return if $dialog->ShowModal == wxID_CANCEL;
    $msg = $dialog->GetValue();
  }
  return unless $msg;
  return unless my ($decrypted, $pad, $oldlen) = $u->decrypt($msg);
  my $padlen = length($pad->{pad})/2;
  my $pad_name = pack('H*',$pad->{name});
  my $selnum = $padsel->FindString("$pad_name ($oldlen)");
  $padsel->SetString($selnum, "$pad_name ($padlen)");
  $dialog = Wx::MessageDialog->new( $frame, "Received message:\n\n$decrypted", "Receive message");
  $dialog->ShowModal;
};

$action{Exit} = sub {       # Exit
  $statusBar->SetStatusText("Exit", 0);
  my $dialog = Wx::MessageDialog->new( $frame, "Do you really want to exit?", "Confirm", wxOK|wxCANCEL);
  return if $dialog->ShowModal == wxID_CANCEL;
  $app->ExitMainLoop;
};

EVT_BUTTON($frame, $button{$_}, $action{$_}) for (qw(Generate Import Export Send Receive Exit));

# Start the UI

show();
$statusBar->SetStatusText(_('Unsnoopable Ready'), 0);
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
  my $frame = Wx::Frame->new( undef, -1, _('Unsnoopable') , wxDefaultPosition, [500, 700] );

  my $padsel = Wx::Choice->new($frame, -1, wxDefaultPosition, [-1,-1],
			       [ map { "$_ (" . length($pads->{$_}->{pad})/2 . ')' } keys %$pads ], wxCB_SORT);
#  $padsel->SetStringSelection($pads->[0]->{name});
#  my $selbox = Wx::BoxSizer->new(wxHORIZONTAL);
#  $selbox->Add($padsel, 2, wxALL, 5);

  my $topSizer = Wx::BoxSizer->new(wxVERTICAL);
  $frame->SetSizer($topSizer);
  my $boxSizer = Wx::BoxSizer->new(wxVERTICAL);
  $topSizer->Add($boxSizer, 0, wxALIGN_CENTER_HORIZONTAL | wxALL | wxEXPAND, 5);

  $boxSizer->Add($padsel, 0, wxGROW | wxALL, 5);

  # Buttons

  my %button;

  $button{Generate} = Wx::Button->new($frame, -1, _('Generate'), [-1,-1] );
  $button{Import} = Wx::Button->new($frame, -1, _('Import'), [-1, -1]);
  $button{Send} = Wx::Button->new($frame, -1, _('Send'), [-1, -1]);
  $button{Receive} = Wx::Button->new($frame, -1, _('Receive'), [-1, -1]);
  $button{Export} = Wx::Button->new($frame, -1, _('Export'), [-1,-1]);
  $button{Exit} = Wx::Button->new($frame, -1, _('Exit'), [-1,-1]);

  my $buttonbox1 = Wx::BoxSizer->new(wxHORIZONTAL);
  $boxSizer->Add($buttonbox1, 0, wxGROW | wxALL, 5);

  $buttonbox1->Add($button{Generate}, 1, wxALL, 5);
  $buttonbox1->Add($button{Import}, 1, wxALL, 5);
  $buttonbox1->Add($button{Export}, 1, wxALL, 5);

  my $buttonbox2 = Wx::BoxSizer->new(wxHORIZONTAL);
  $boxSizer->Add($buttonbox2, 0, wxGROW | wxALL, 5);

  $buttonbox2->Add($button{Send}, 1, wxALL, 5);
  $buttonbox2->Add($button{Receive}, 1, wxALL, 5);
  $buttonbox2->Add($button{Exit}, 1, wxALL, 5);

  # Status bar

  my $statusBar = Wx::StatusBar->new($frame, wxID_ANY);
  $frame->SetStatusBar($statusBar);
  return ($app, $frame, $padsel, $topSizer, $boxSizer, $statusBar, %button)
}

sub initl8n {               # Initialize l8n
  $lang{en}->{__NAME} = 'English';
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

unsnoopable.pl - Completely unsnoopable messaging

=head1 VERSION

 $Revision: 1.010 $
 $Date: Tue Oct 16 21:04:28 PDT 2018 $

=head1 SYNOPSIS

  unsnoopable.pl [--noodlepi]

=head1 DESCRIPTION

unsnoopable.pl (Unsnoopable) is a simple application for end-to-end
completely unsnoopable messaging. It is intended to be run on
air-gapped devices that are never connected to any networks and have
no wireless networking hardware. Unsnoopable uses one-time pads (OTPs)
for completely unbreakable encryption.

Unsnoopability goes further than unbreakability of encryption, as a
compromised device can leak plaintext even when the encryption used to
transmit the message is unbreakable. This is the reason Unsnoopable is
designed for use on an air-gapped devices, with a screen, text input
capability, and a camera, such as the Noodle Air
L<http://www.noodlepi.com/>.

A new one-time pad can be generated by clicking the 'Generate' button,
and providing a name for the pad. The OTP can then be exported by
clicking the 'Export' button, which will cause it to be displayed on
the device's screen as a QR code. It can then be imported into the
corresponding device of the person one wishes to communicate
unsnoopably with, by clicking 'Import' on that device and then
scanning it with its camera.

Unsnoopable currently implements QR code scanning only on the Noodle
Air, using the 'zbar' program. When running unsnoopable on a Noodle
Air, use the '--noodlepi' command line switch.

To send a message to Bob, Alice selects a pre-shared OTP from the list
at the top of the application window, clicks 'Send', and types in a
message. The message will be encrypted using the selected OTP, and the
ciphertext displayed as a QR code. Alice then scans QR code from the
screen of the air-gapped Noodle Air using a regular connected
smartphone and any mobile QR code scanning app, and sends the scanned
string to Bob using any communications medium.

Bob displays the received ciphertext as a QR code on his own
smartphone screen, and clicks 'Receive' to scan it into his own Noodle
Air (which already has the pre-shared OTP on it). The ciphertext is
then automatically decrypted and the plaintext message displayed.

This provides not only theoretically unbreakable encryption for the
message using OTP encryption, but also air-gapped security for the
devices where the plaintext and OTPs are stored. In effect this
provides complete unsnoopability for the message over the network both
while in transit and from any network-based attacks against the
devices where plaintext is processed.

As with all security systems, though, there are still some caveats:

Obviously Unsnoopable can't and doesn't protect against physical
attacks where the attacker has access to any of the devices on which
the OTPs are stored, or visual access that would enable them to view
the messages or pads on the device screens, or proximity access that
would enable attacks based on leakage via electromagnetic radiation,
or audio access via bugs / smartphone microphones (if the message is
spoken out aloud), etc.

Physical access to the OTPs can be protected by storing them on
MicroSD cards, which are small and relatively easy to keep physically
secure. Noodle Air features a MicroSD card reader and boots off the
MicroSD card itself, which is also important as it enables keeping the
boot disk physically secure. An attacker with access to the air-gapped
machine's boot disk could put in trojans to surreptitiously save OTPs
or plaintexts for later retrieval.

The current implementation uses the L<Bytes::Random::Secure> module to
source random numbers for the one-time pads. This module uses a CSPRNG
to generate random numbers, and isn't a truly random source. For
really unbreakable encryption, a source of true random numbers should
be used. A few devices that generate true random numbers are available
commercially. It's also easy to generate random numbers in a secure
and low-tech way by rolling dice.

The pad length is currently set to a fixed size that is communicable
in a single QR code. This limitation will be removed in future
versions of the app.

=head1 SEE ALSO

=head2 L<http://www.unsnoopable.org>

=head2 L<http://www.noodlepi.com>

=head2 L<Crypt::Unsnoopable>

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-unsnoopable at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-unsnoopable at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-Unsnoopable>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this command with the perldoc command.

    perldoc unsnoopable.pl

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-Unsnoopable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-Unsnoopable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-Unsnoopable>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-Unsnoopable/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftwr.org/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
