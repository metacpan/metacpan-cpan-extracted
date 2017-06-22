#!/usr/bin/perl
# -*-cperl-*-
#
# unsnoopable.pl - Completely unsnoopable messaging
# Copyright (c) 2017 Ashish Gulhati <crypt-unsnoopable at hash.neo.tc>
#
# $Id: bin/unsnoopable.pl v1.006 Tue Jun 20 15:40:10 PDT 2017 $

use warnings;

use Wx qw (:everything);
use Wx::Event qw (EVT_BUTTON);
use Crypt::Unsnoopable;
use GD::Barcode::QRcode;
use File::HomeDir;
use Math::BaseCnv qw(dec heX);

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
  my $dialog = Wx::TextEntryDialog->new( $frame, "Paste pad below", "Import One-Time Pad");
  return if($dialog->ShowModal == wxID_CANCEL);
  my $pad = $dialog->GetValue();
  return if $pad =~ /\D/;
  $dialog = Wx::TextEntryDialog->new( $frame, "Enter a name for this pad:", "Import One-Time Pad");
  return if $dialog->ShowModal == wxID_CANCEL;
  my $name = $dialog->GetValue(); return unless $name =~ /^[\w\d\s]+$/; return if exists $pads->{$name};
  return unless my $pad = $u->add($pad, $name);
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
  my $dialog = Wx::TextEntryDialog->new( $frame, "Enter message:", "Receive message");
  return if $dialog->ShowModal == wxID_CANCEL;
  my $msg = $dialog->GetValue(); return unless $msg;
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
    my $qrxpm = GD::Barcode::QRcode->new($text, { Version => $version, Ecc => L, ModuleSize => 2 })->barcode;
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

unsnoopable.pl - Completely unsnoopable messaging

=head1 VERSION

 $Revision: 1.006 $
 $Date: Tue Jun 20 15:40:10 PDT 2017 $

=head1 SYNOPSIS

  unsnoopable.pl

=head1 DESCRIPTION

unsnoopable.pl (Unsnoopable) is a simple application for end-to-end
completely unsnoopable messaging. It is intended to be run on
air-gapped devices that are never connected to any networks and have
no wireless networking hardware. Unsnoopable uses one-time pads (OTPs)
for completely unbreakable encryption.

Unsnoopability goes further than unbreakability of encryption however,
as a compromised device can leak plaintext even when the encryption
used to transmit the message is unbreakable. This is the reason
Unsnoopable is designed for use on an air-gapped devices, with a
screen, text input capability, and a camera.

A new one-time pad can be generated by clicking the Generate button,
and providing a name for the pad. The OTP can then be Exported by
displaying it on the device's screen as a QR code. It can be Imported
into the corresponding device of the person one wishes to communicate
unsnoopably with, by scanning it using a camera and a QR code
recognition software such as Zbar. Unsnoopable doesn't currently
feature QR code scanning within the application.

To send a message, one selects an OTP from the list at the top of the
application window, and clicks Send. A message can then be typed in,
and it will be encrypted using the selected OTP, and displayed as a QR
code for scanning. The QR code can be scanned from the screen of the
air-gapped device using a regular connected smartphone and any mobile
QR code scanning app. The scanned string can then be sent to the
recipient using any communications medium.

The receipient can display the received message as a QR code on their
own smartphone screen, scan it into their own air-gapped device (which
already has the OTP shared previously) and click Receive to input the
ciphertext string and view the decrypted message.

This provides not only theoretically unbreakable encryption for the
message using OTP encryption, but also complete air-gapped security
for the devices where the plaintext and OTPs are stored. In effect
this is complete and total unsnoopability for the message over the
network both while in transit, and from any network-based attacks
against the recipient devices.

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
secure. A small single board computer such as a Raspberry Pi would be
an excellent option to deploy Unsnoopable on, as it features a MicroSD
card reader and boots off the MicroSD card itself. Keeping the boot OS
secure is also important - an attacker with access to the air-gapped
machine's OS could put in trojans to surreptitiously save OTPs or
plaintexts for later retrieval.

There's also a suitable camera module available for use with the Pi,
as well as a variety of suitable small LCD screens. Indeed Unsnoopable
was designed with Pi-based deployment in mind, specifically on models
that don't have wireless networking hardware, such as the (non-W) Pi
Zero.

The current implementation uses the L<Bytes::Random::Secure> module to
source random numbers for the one-time pads. This module uses a CSPRNG
to generate random numbers, and isn't a truly random source. For
really unbreakable encryption, a source of true random numbers should
be used. A few devices that generate true random numbers are available
commercially.

The pad length is currently set to a fixed size that is communicable
in a single QR code. This limitation will be removed in future
versions of the app.

=head1 SEE ALSO

=head2 L<http://www.unsnoopable.org>

=head2 L<Crypt::Unsnoopable>

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-unsnoopable at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-hashcash at
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

Copyright (c) 2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
