package Cisco::IPPhone;

# Author: Mark Palmer markpalmer@us.ibm.com 
# Date: 7/2002

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Cisco::IPPhone ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.05';


# Preloaded methods go here.
############# Code Here

use POSIX;

$|=1;  # Turn off buffered output

# Hash Table containing URI options
# 7940 phones use Line1 and Line2
# 7960 phones use Line1 through Line6
# 7914 sidecar on 7960 phones use Line7 through Line20
# second 7914 sidecar phones use Line21 through Line34

# URI Dial:1234 cuases the phone to dial 1234
# URI EditDial:1234 enables the user to edit the dial string 1234

my %uriKeys = ( 0 => 'Key:KeyPad0', 1 => 'Key:KeyPad1', 2 => 'Key:KeyPad2',
 3 => 'Key:KeyPad3', 4 => 'Key:KeyPad4', 5 => 'Key:KeyPad5', 6 => 'Key:KeyPad6', 
 7 => 'Key:KeyPad7', 8 => 'Key:KeyPad8', 9 => 'Key:KeyPad9', 10 => 'KeyPadStar', 
 11 => 'Key:KeyPadPound', 12 => 'Key:Soft1', 13 => 'Key:Soft2', 
 14 => 'Key:Soft3', 15 => 'Key:Soft4', 16 => 'Key:VolDwn', 17 => 'Key:VolUp',
 18 => 'Key:Headset', 19 => 'Key:Speaker', 20 => 'Key:Mute', 21 => 'Key:Info',
 22 => 'Key:Messages', 23 => 'Key:Services', 24 => 'Key:Directory', 
 25 => 'Key:Settings', 26 => 'Key:NavUp', 27 => 'Key:NavDwn', 
 28 => 'SoftKey:Update', 29 => 'SoftKey:Select', 30 => 'Key:SoftKey:Exit', 
 31 => 'Key:Line1', 32 => 'Key:Line2',
 33 => 'Key:Line3', 34 => 'Key:Line4', 35 => 'Key:Line5', 36 => 'Key:Line6',
 37 => 'Key:Line7', 38 => 'Key:Line8', 39 => 'Key:Line9', 40 => 'Key:Line10',
 41 => 'Key:Line11', 42 => 'Key:Line12', 43 => 'Key:Line13', 44 => 'Key:Line14',
 45 => 'Key:Line15', 46 => 'Key:Line16', 47 => 'Key:Line17', 48 => 'Key:Line18',
 49 => 'Key:Line19', 50 => 'Key:Line20', 51 => 'Key:Line21', 52 => 'Key:Line22',
 53 => 'Key:Line23', 54 => 'Key:Line24', 55 => 'Key:Line25', 56 => 'Key:Line26',
 57 => 'Key:Line27', 58 => 'Key:Line28', 59 => 'Key:Line29', 60 => 'Key:Line30',
 61 => 'Key:Line31', 62 => 'Key:Line32', 63 => 'Key:Line33', 64 => 'Key:Line34',
 65 => 'Init:CallHistory', 66 => 'SoftKey:<<', 67 => 'SoftKey:Cancel' );

# For use with InputItems
my %inputFlags = ( ASCII => 'A', Telephone => 'T', Numeric => 'N', 
  Equation => 'E', Uppercase => 'U', Lowercase => 'L', Password => 'P' );

# Declaration of new object with data types defined and blessed for use
sub new {
  my $package = shift;
  my $this = { xmlobject => [] };
  return bless($this, $package);
}

sub Print {
  # Takes no input.  Prints the xmlobject array datastructure to the phone
  my $self = shift;
  ${$self->{xmlobject}}[0] = "Content-Type: text/xml\n\n${$self->{xmlobject}}[0]";
  print @{$self->{xmlobject}};
}

sub Content {
  my $self = shift;
  my $options = shift if (@_);
  # Assume Content-Type is text/xml unless otherwise specified
  my $header = '';

  if ($options->{Refresh}) {
     $header .= "refresh: $options->{Refresh};";
     if ($options->{URL}) {
        $header .= " url=$options->{URL}\n";
     } else {
        $header .= "\n";
     }
  }
  if ($options->{Location}) {
     $header .= "location: $options->{Location}\n";
  }
  if ($options->{Date}) {
     $header .= "date: $options->{Date}\n";
  }
  if ($options->{Expires}) {
     $header .= "expires: $options->{Expires}\n";
  }
  if ($options->{Cookie}) {
     $header .= "Set-Cookie: $options->{Cookie}\n";
  }
  if ($options->{Type}) {
     $header .= "Content-Type: $options->{Type}\n\n";
  } else {
     $header .= "Content-Type: text/xml\n\n";
  }

  ${$self->{xmlobject}}[0] = "${header}${$self->{xmlobject}}[0]";
  return @{$self->{xmlobject}};
}

sub Content_Noheader {
  my $self = shift;
  my $result = '';
  my $line = '';
  if (wantarray) { return @{$self->{xmlobject}} };
  foreach $line (@{$self->{xmlobject}}) {
    $result .= $line;
  }
  return $result;
}

sub Text {
  # Input: Title, Prompt, Text and optional softkeyitems or menuitems
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<CiscoIPPhoneText>\n";
  push @{$self->{xmlobject}}, "<Title>$options->{Title}</Title>\n";
  push @{$self->{xmlobject}}, "<Prompt>$options->{Prompt}</Prompt>\n";
  push @{$self->{xmlobject}}, "<Text>$options->{Text}</Text>\n";
  push @{$self->{xmlobject}}, "</CiscoIPPhoneText>\n";
  return @{$self->{xmlobject}};
}

sub Menu {
# Takes Title, Prompt and optional softkeyitems or menuitems
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<CiscoIPPhoneMenu>\n";
  push @{$self->{xmlobject}},"<Title>$options->{Title}</Title>\n";
  push @{$self->{xmlobject}},"<Prompt>$options->{Prompt}</Prompt>\n";
# Insert Menu Options using AddMenuItem
  push @{$self->{xmlobject}},"</CiscoIPPhoneMenu>\n";
  return @{$self->{xmlobject}};
}

sub MenuItem {
# Input: Name and URL (or URI)
# A maximum of 99 MenuItem tags are allowed
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<MenuItem>\n";
  push @{$self->{xmlobject}}, "<IconIndex>$options->{IconIndex}</IconIndex>\n" if $options->{IconIndex};
  push @{$self->{xmlobject}}, "<Name>$options->{Name}</Name>\n";
  push @{$self->{xmlobject}}, "<URL>$options->{URL}</URL>\n";
  push @{$self->{xmlobject}},"</MenuItem>\n";
  return @{$self->{xmlobject}};
}

sub AddMenuItem {
# Input: Name and URL (or URI)
# Adds the MenuItem to the Object that called this method
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Menu Tag
  my $lastline = pop @{$self->{xmlobject}};

  push @{$self->{xmlobject}},"<MenuItem>\n";
  push @{$self->{xmlobject}}, "<IconIndex>$options->{IconIndex}</IconIndex>\n" if $options->{IconIndex};
  push @{$self->{xmlobject}},"<Name>$options->{Name}</Name>\n";
  push @{$self->{xmlobject}},"<URL>$options->{URL}</URL>\n";
  push @{$self->{xmlobject}},"</MenuItem>\n";

# Push the Close Menu Tag Back onto the Menu Object
  push @{$self->{xmlobject}}, $lastline;
# Returns array if called in list context, or returns scalar
  if (wantarray) { return @{$self->{xmlobject}} };
  return 1;
}

sub AddMenuItemObject {
# Input: MenuItem Object
# Adds the MenuItem Object to the Object that called this method
  my $line;
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Menu Tag
  my $lastline = pop @{$self->{xmlobject}};

# Push the MenuItems onto the menu
  foreach $line (@{$options->{MenuItem}->{xmlobject}}) {
	push @{$self->{xmlobject}},$line;
  }
# Push the Close Menu Tag Back onto the Menu Object
  push @{$self->{xmlobject}}, $lastline;
  return @{$self->{xmlobject}};
}

sub Input {
# Input: Title, Prompt, URL
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<CiscoIPPhoneInput>\n";
  push @{$self->{xmlobject}}, "<Title>$options->{Title}</Title>\n";
  push @{$self->{xmlobject}}, "<Prompt>$options->{Prompt}</Prompt>\n";
  push @{$self->{xmlobject}}, "<URL>$options->{URL}</URL>\n";
  push @{$self->{xmlobject}}, "</CiscoIPPhoneInput>\n";
  return @{$self->{xmlobject}};
}

sub InputItem {
# Input: DisplayName, QueryStringParam, DefaultValue, InputFlags
# Valid Input Tags: see inputFlags hash defined above

  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<InputItem>\n";
  push @{$self->{xmlobject}}, "<DisplayName>$options->{DisplayName}</DisplayName>\n";
  push @{$self->{xmlobject}}, "<QueryStringParam>$options->{QueryStringParam}</QueryStringParam>\n";
  push @{$self->{xmlobject}}, "<DefaultValue>$options->{DefaultValue}</DefaultValue>\n";
  push @{$self->{xmlobject}}, "<InputFlags>$options->{InputFlags}</InputFlags>\n";
  push @{$self->{xmlobject}},"</InputItem>\n";
  return @{$self->{xmlobject}};
}

sub AddInputItem {
# Input: DisplayName, QueryStringParam, DefaultValue, InputFlags
# Valid Input Tags: see inputFlags hash defined above
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Menu Tag
  my $lastline = pop @{$self->{xmlobject}};

  push @{$self->{xmlobject}},"<InputItem>\n";
  push @{$self->{xmlobject}}, "<DisplayName>$options->{DisplayName}</DisplayName>\n";
  push @{$self->{xmlobject}}, "<QueryStringParam>$options->{QueryStringParam}</QueryStringParam>\n";
  push @{$self->{xmlobject}}, "<DefaultValue>$options->{DefaultValue}</DefaultValue>\n";
  push @{$self->{xmlobject}}, "<InputFlags>$options->{InputFlags}</InputFlags>\n";
  push @{$self->{xmlobject}},"</InputItem>\n";

# Push the Close Tag Back onto the Calling Object
  push @{$self->{xmlobject}}, $lastline;
# Returns array if called in list context or returns scalar in scaler context
  if (wantarray) { return @{$self->{xmlobject}} };
  return 1;
}

sub AddInputItemObject {
# Input: InputItem Object
# Adds the InputItem Object to the Object that called this method
  my $line;
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Tag
  my $lastline = pop @{$self->{xmlobject}};

# Push the MenuItems onto the menu
  foreach $line (@{$options->{InputItem}->{xmlobject}}) {
	push @{$self->{xmlobject}},$line;
  }
# Push the Close Tag Back onto the Calling Object
  push @{$self->{xmlobject}}, $lastline;
  return @{$self->{xmlobject}};
}

sub SoftKeyItem {
# Input: Name, URL (or URI), and Position
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<SoftKeyItem>\n";
  push @{$self->{xmlobject}}, "<Name>$options->{Name}</Name>\n";
  push @{$self->{xmlobject}}, "<URL>$options->{URL}</URL>\n";
  push @{$self->{xmlobject}}, "<Position>$options->{Position}</Position>\n";
  push @{$self->{xmlobject}},"</SoftKeyItem>\n";
  return @{$self->{xmlobject}};
}

sub AddSoftKeyItem {
# Input: Name and URL (or URI), and Position
# Adds the SoftKeyItem Object to the Object that called this method
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Menu Tag
  my $lastline = pop @{$self->{xmlobject}};

  push @{$self->{xmlobject}},"<SoftKeyItem>\n";
  push @{$self->{xmlobject}},"<Name>$options->{Name}</Name>\n";
  push @{$self->{xmlobject}},"<URL>$options->{URL}</URL>\n";
  push @{$self->{xmlobject}},"<Position>$options->{Position}</Position>\n";
  push @{$self->{xmlobject}},"</SoftKeyItem>\n";

# Push the Close Menu Tag Back onto the Menu Object
  push @{$self->{xmlobject}}, $lastline;
  return @{$self->{xmlobject}};
}

sub AddSoftKeyItemObject {
# Input: SoftKeyItem Object
# Adds the SoftKeyItem Object to the Object that called this method
  my $line;
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Tag
  my $lastline = pop @{$self->{xmlobject}};

# Push the SoftKeyItems onto the Calling Object
  foreach $line (@{$options->{SoftKeyItem}->{xmlobject}}) {
	push @{$self->{xmlobject}},$line;
  }
# Push the Close Tag Back onto the Calling Object
  push @{$self->{xmlobject}}, $lastline;
  return @{$self->{xmlobject}};
}

sub Directory {
# Input: Title and Prompt
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<CiscoIPPhoneDirectory>\n";
  push @{$self->{xmlobject}},"<Title>$options->{Title}</Title>\n";
  push @{$self->{xmlobject}},"<Prompt>$options->{Prompt}</Prompt>\n";
# Insert Directory Entries using AddDirectoryEntry
  push @{$self->{xmlobject}},"</CiscoIPPhoneDirectory>\n";
}

sub DirectoryEntry {
# Input: Name and Telephone
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<DirectoryEntry>\n";
  push @{$self->{xmlobject}}, "<Name>$options->{Name}</Name>\n";
  push @{$self->{xmlobject}}, "<Telephone>$options->{Telephone}</Telephone>\n";
  push @{$self->{xmlobject}},"</DirectoryEntry>\n";
  return @{$self->{xmlobject}};
}

sub AddDirectoryEntry {
# Input: Name and URL (or URI)
# Adds the DirectoryEntry to the Object that called this method
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Tag
  my $lastline = pop @{$self->{xmlobject}};

  push @{$self->{xmlobject}},"<DirectoryEntry>\n";
  push @{$self->{xmlobject}},"<Name>$options->{Name}</Name>\n";
  push @{$self->{xmlobject}},"<Telephone>$options->{Telephone}</Telephone>\n";
  push @{$self->{xmlobject}},"</DirectoryEntry>\n";

# Push the Close Tag Back onto the Calling Object
  push @{$self->{xmlobject}}, $lastline;

# Returns array if called in list context, or returns scalar
  if (wantarray) { return @{$self->{xmlobject}} };
  return 1;
}

sub AddDirectoryEntryObject {
# Input: DirectoryEntry Object
# Adds the Directory Entry Object to the Object that called this method
  my $line;
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Tag
  my $lastline = pop @{$self->{xmlobject}};

# Push the Directory Entries onto the Calling Object
  foreach $line (@{$options->{DirectoryEntry}->{xmlobject}}) {
	push @{$self->{xmlobject}},$line;
  }
# Push the Close Tag Back onto the Calling Object
  push @{$self->{xmlobject}}, $lastline;
  return @{$self->{xmlobject}};
}

sub Image {
# Input: Title,Prompt,LocationX,LocationY,Width,Height,Depth,Data
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<CiscoIPPhoneImage>\n";
  push @{$self->{xmlobject}},"<Title>$options->{Title}</Title>\n";
  push @{$self->{xmlobject}},"<Prompt>$options->{Prompt}</Prompt>\n";
  push @{$self->{xmlobject}},"<LocationX>$options->{LocationX}</LocationX>\n";
  push @{$self->{xmlobject}},"<LocationY>$options->{LocationY}</LocationY>\n";
  push @{$self->{xmlobject}},"<Width>$options->{Width}</Width>\n";
  push @{$self->{xmlobject}},"<Height>$options->{Height}</Height>\n";
  push @{$self->{xmlobject}},"<Depth>$options->{Depth}</Depth>\n";
  push @{$self->{xmlobject}},"<Data>$options->{Data}</Data>\n";
  push @{$self->{xmlobject}},"</CiscoIPPhoneImage>\n";
  return @{$self->{xmlobject}};
}

sub GraphicMenu {
# Input: Title,Prompt,LocationX,LocationY,Width,Height,Depth,Data
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<CiscoIPPhoneGraphicMenu>\n";
  push @{$self->{xmlobject}},"<Title>$options->{Title}</Title>\n";
  push @{$self->{xmlobject}},"<Prompt>$options->{Prompt}</Prompt>\n";
  push @{$self->{xmlobject}},"<LocationX>$options->{LocationX}</LocationX>\n";
  push @{$self->{xmlobject}},"<LocationY>$options->{LocationY}</LocationY>\n";
  push @{$self->{xmlobject}},"<Width>$options->{Width}</Width>\n";
  push @{$self->{xmlobject}},"<Height>$options->{Height}</Height>\n";
  push @{$self->{xmlobject}},"<Depth>$options->{Depth}</Depth>\n";
  push @{$self->{xmlobject}},"<Data>$options->{Data}</Data>\n";
  push @{$self->{xmlobject}},"</CiscoIPPhoneGraphicMenu>\n";
  return @{$self->{xmlobject}};
}

sub IconMenu {
# Takes Title, Prompt and optional softkeyitems or menuitems
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<CiscoIPPhoneIconMenu>\n";
  push @{$self->{xmlobject}},"<Title>$options->{Title}</Title>\n";
  push @{$self->{xmlobject}},"<Prompt>$options->{Prompt}</Prompt>\n";
# Insert Menu Options using AddMenuItem
# Insert SoftKey Options using AddSoftKeyItem
# Insert Icon Options using AddIconItem
  push @{$self->{xmlobject}},"</CiscoIPPhoneIconMenu>\n";
  return @{$self->{xmlobject}};
}

sub IconItem {
# Input: Index, Height, Width, Depth, Data
# Build IconItem Object
  my $self = shift;
  my $options = shift if (@_);

  push @{$self->{xmlobject}},"<IconItem>\n";
  push @{$self->{xmlobject}},"<Index>$options->{Index}</Index>\n";
  push @{$self->{xmlobject}},"<Height>$options->{Height}</Height>\n";
  push @{$self->{xmlobject}},"<Width>$options->{Width}</Width>\n";
  push @{$self->{xmlobject}},"<Depth>$options->{Depth}</Depth>\n";
  push @{$self->{xmlobject}},"<Data>$options->{Data}</Data>\n";
  push @{$self->{xmlobject}},"</IconItem>\n";

  return @{$self->{xmlobject}};
}

sub AddIconItem {
# Input: Index, Height, Width, Depth, Data
# Adds the IconItem Object to the IconMenu Object that called this method
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close IconMenu Tag
  my $lastline = pop @{$self->{xmlobject}};

  push @{$self->{xmlobject}},"<IconItem>\n";
  push @{$self->{xmlobject}},"<Index>$options->{Index}</Index>\n";
  push @{$self->{xmlobject}},"<Height>$options->{Height}</Height>\n";
  push @{$self->{xmlobject}},"<Width>$options->{Width}</Width>\n";
  push @{$self->{xmlobject}},"<Depth>$options->{Depth}</Depth>\n";
  push @{$self->{xmlobject}},"<Data>$options->{Data}</Data>\n";
  push @{$self->{xmlobject}},"</IconItem>\n";

# Push the Close IconMenu Tag Back onto the Menu Object
  push @{$self->{xmlobject}}, $lastline;
  return @{$self->{xmlobject}};
}

sub AddIconItemObject {
# Input: IconItem Object
# Adds the IconItem Object to the Object that called this method
  my $line;
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Tag
  my $lastline = pop @{$self->{xmlobject}};

# Push the Icon Items onto the Calling Object
  foreach $line (@{$options->{IconItem}->{xmlobject}}) {
	push @{$self->{xmlobject}},$line;
  }
# Push the Close Tag Back onto the Calling Object
  push @{$self->{xmlobject}}, $lastline;
  return @{$self->{xmlobject}};
}

sub Execute {
# Input: None
  my $self = shift;
  push @{$self->{xmlobject}},"<CiscoIPPhoneExecute>\n";
# Insert Execute Items using AddExecuteItem
  push @{$self->{xmlobject}},"</CiscoIPPhoneExecute>\n";
  return @{$self->{xmlobject}};
}

sub AddExecuteItem {
# Input: URL to be executed (can have up to 3 items in one execute object)
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Tag
  my $lastline = pop @{$self->{xmlobject}};

  push @{$self->{xmlobject}},"<ExecuteItem URL=\"$options->{ExecuteItem}\"/>\n";

# Push the Close Tag Back onto the Calling Object
  push @{$self->{xmlobject}}, $lastline;

# Returns array if called in list context, or returns scalar
  if (wantarray) { return @{$self->{xmlobject}} };
  return 1;
}

sub AddExecuteItemObject {
# Input: ExecuteItem Object
# Adds the Execute Item Object to the Object that called this method
  my $line;
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Tag
  my $lastline = pop @{$self->{xmlobject}};

# Push the Directory Entries onto the Calling Object
  foreach $line (@{$options->{ExecuteItem}->{xmlobject}}) {
	push @{$self->{xmlobject}},$line;
  }
# Push the Close Tag Back onto the Calling Object
  push @{$self->{xmlobject}}, $lastline;
  return @{$self->{xmlobject}};
}

sub Response {
# Input: None
  my $self = shift;
  push @{$self->{xmlobject}},"<CiscoIPPhoneResponse>\n";
# Insert Response Items using AddResponseItem
  push @{$self->{xmlobject}},"</CiscoIPPhoneResponse>\n";
  return @{$self->{xmlobject}};
}

sub ResponseItem {
# Input: URL to be executed (can have up to 3 items in one execute object)
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<ResponseItem Status=\"$options->{Status}\" Data=\"$options->{Data}\" URL=\"$options->{URL}\"/>\n";
# Returns array if called in list context, or returns scalar
  if (wantarray) { return @{$self->{xmlobject}} };
  return 1;
}

sub AddResponseItem {
# Input: URL to be executed (can have up to 3 items in one execute object)
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Tag
  my $lastline = pop @{$self->{xmlobject}};

  push @{$self->{xmlobject}},"<ResponseItem Status=\"$options->{Status}\" Data=\"$options->{Data}\" URL=\"$options->{URL}\"/>\n";

# Push the Close Tag Back onto the Calling Object
  push @{$self->{xmlobject}}, $lastline;

# Returns array if called in list context, or returns scalar
  if (wantarray) { return @{$self->{xmlobject}} };
  return 1;
}

sub AddResponseItemObject {
# Input: ResponseItem Object
# Adds the Response Item Object to the Object that called this method
  my $line;
  my $self = shift;
  my $options = shift if (@_);

# Pop off the Close Tag
  my $lastline = pop @{$self->{xmlobject}};

# Push the Directory Entries onto the Calling Object
  foreach $line (@{$options->{ResponseItem}->{xmlobject}}) {
	push @{$self->{xmlobject}},$line;
  }
# Push the Close Tag Back onto the Calling Object
  push @{$self->{xmlobject}}, $lastline;
  return @{$self->{xmlobject}};
}

# Possible error codes:
# Error 1 = Error parsing CiscoIPPhoneExecute object
# Error 2 = Error framing CiscoIPPhoneResponse object
# Error 3 = Internal file error
# Error 4 = Authentication error

sub Error {
# USE &quot; for double quotes on phone
# Input: Number representing error number
  my $self = shift;
  my $options = shift if (@_);
  push @{$self->{xmlobject}},"<CiscoIPPhoneError Number=\"$options->{Number}\"/>\n";
  return @{$self->{xmlobject}};
}

sub Date {
  my ($sec, $min, $hour, $mday, $mon, $year);
  ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
  my $date = POSIX::strftime("%Y%m%e",$sec, $min, $hour, $mday, $mon, $year);
  $date =~ s/\s/0/;
  return $date;
}

############# End Code

1;
__END__


=head1 NAME

Cisco::IPPhone - Package for creating Cisco IPPhone XML objects

=head1 SYNOPSIS

 use Cisco::IPPhone;

 $mytext = new Cisco::IPPhone;

 $mytext->Text({ Title => "My Title", Prompt => "My Prompt", 
                           Text => "My Text" });
 $mytext->AddSoftKeyItem( { Name => "Update", URL => "SoftKey:Update", 
                           Position => "1" });
 $mytext->AddSoftKeyItem( { Name => "Exit", URL => "SoftKey:Exit", 
                           Position => "2" });

 print $mytext->Content;

=head1 DESCRIPTION

Cisco::IPPhone - Package for creating Cisco IPPhone XML applications

This Cisco IPPhone module was created to provide a simple convenient
method to display Cisco IP Phone objects and gather input from a Cisco
7940 or 7960 IP Phone.  This module supports all known Cisco XML objects
for 7940 and 7960 phones.  Knowledge of Cisco XML syntax is not a requirement.

This Perl module gives the ability to use simple PERL objects to display XML on the IP Phone unlike to Cisco Software Development Kit (SDK) which uses Microsoft IIS Server, ASP's, JSP's, Javascript, COM Objects, and requires knowledge of XML syntax.

The following list gives typical services that might be supplied to a phone:

 - Weather
 - Stock information
 - Contact information
 - Company news
 - To-do lists
 - Real-time NFL scores
 - Daily schedule

=head2 Requirements

Developing Cisco IPPhone XML applications using the Cisco::IPPhone module requires the following:
 - Cisco CallManager Software or the CallManager Emulator Software
 - Any web server capable of running Perl CGI (Apache, etc)
 - A Cisco 7940 or 7960 IPPhone for testing the applications 

=head2 Add services to Cisco CallManager:

 - Go to Feature -> Cisco IP Phone Services
 - Give the service a name and specify a URL such as:
       http://www.myorg.com/cgi-bin/menu.cgi
   Where menu.cgi is a Perl program that displays the menu
 - use the CCMUser URL to allow the user subscribe their phone to the service
   or have the Administrator assign the service to the phone using the 
   phone device configuration.

=head2 Methods

The following sections provide definitions and descriptions of each Cisco IP phone XML object: CiscoIPPhoneMenu, CiscoIPPhoneText, CiscoIPPhoneInput, CiscoIPPhoneDirectory, CiscoIPPhoneImage, CiscoIPPhoneGraphicMenu, CiscoIPPhoneIconMenu, CiscoIPPhoneExecute, CiscoIPPhoneError and CiscoIPPhoneResponse.

=over 4

=item * $object->Text

B<This method takes a title, prompt, and text as input.>

 $mytext = new IPPhone;
 $mytext->Text( { Title => "My Title", 
                  Prompt => "My Prompt",
                  Text => "My Text" });

=item * $object->Menu

B<This method takes a title, prompt, and text as input.>

 # Create Menu Object
 $mymenu = new IPPhone;
 $mymenu->Menu( { Title => "My Title", 
                  Prompt => "My Prompt", 
                  Text => "My Text" });

=item * $object->MenuItem

 $mymenu = new IPPhone;
 $mymenuitem = new IPPhone;

 # Create a menu object
 $mymenu->Menu( { Title => "My Title", 
                  Prompt => "My Prompt", 
                  Text => "My Text" });

 # Create a menuitem object 
 $mymenuitem->MenuItem({ Name => "Item1", 
                         URL => "http://www.mydomain.com" });

 # Add the menuitem object to the menu object
 $mymenu->AddMenuItemObject( { MenuItem => $mymenuitem });

=item * $object->AddMenuItem

 $mymenu = new IPPhone;

 # Create a menu object
 $mymenu->Menu( { Title => "My Title", 
                  Prompt => "My Prompt", 
                  Text => "My Text" });

 # Add a menuitem to the menu object
 $mymenu->AddMenuItem({ Name => "Item 2", 
                        URL => "http://www.mydomain.com" });

=item * $object->AddMenuItemObject

 $mymenu = new IPPhone;
 $mymenuitem = new IPPhone;

 # Create a menu object
 $mymenu->Menu( { Title => "My Title", 
                  Prompt => "My Prompt", 
                  Text => "My Text" });

 # Create a menuitem object 
 $mymenuitem->MenuItem({ Name => "Item1", 
                         URL => "http://www.mydomain.com" });

 # Add the menuitem object to the menu object
 $mymenu->AddMenuItemObject( { MenuItem => $mymenuitem });

 $mymenu->AddMenuItemObject( { MenuItem => $mymenuitem });

=item * $object->Input

 $myinput = new IPPhone;

 # Create Input Object
 $myinput->Input( { Title => "Title Text", 
                   Prompt => "Prompt Text",
                   URL => "The target URL for the completed input" });

=item * $object->InputItem

 # Input Types

 # ASCII => 'A'
 # Telephone => 'T
 # Numeric => 'N' 
 # Equation => 'E'
 # Uppercase => 'U'
 # Lowercase => 'L'
 # Password => 'P'
 
 $myinputitem = new IPPhone;

 # Create an input item
 $myinputitem->InputItem( { DisplayName => "Name of input field to display", 
                     QueryStringParam => "Parameter to be added to target URL",
                     DefaultValue => "Default Display Name",
                     InputFlags => "A"} );

=item * $object->AddInputItem

 $myinput = new IPPhone;

 # Create Input Object
 $myinput->Input( { Title => "Title Text", 
                    Prompt => "Prompt Text",

 # Add an input item to the Menu Object
 $myinput->AddInputItem({ DisplayName => "Name of Input field to display", 
                      QueryStringParam => "Parameter to be added to target URl",
                      DefaultValue => "Default Display Name",
                      InputFlags => "A"} );

=item * $object->AddInputItemObject

 $myinput = new IPPhone;
 $myinputitem = new IPPhone;
 
 # Create Input Object
 $myinput->Input( { Title => "My Title", 
                    Prompt => "My Prompt",
                    URL => "My URL" });

# Create InputItem Object
 $myinputitem->InputItem( { DisplayName => "Display Name1", 
                           QueryStringParam => "QueryString:",
                           DefaultValue => "Default",
                           InputFlags => "A"} );

 # Add the inputitem to the input object
 $myinput->AddInputItemObject( { InputItem => $myinputitem });

=item * $object->SoftKeyItem
 
 $mysoftkeyitem = new IPPhone;
 $mysoftkeyitem->SoftKeyItem ({ Name => "Submit",
                               URL => "SoftKey:Submit",
                               Position => "1" });

=item * $object->AddSoftKeyItem

 $object->AddSoftKeyItem ({ Name => "Submit",
                            URL => "SoftKey:Submit",
                            Position => "1" });
 $object->AddSoftKeyItem ({ Name => "&lt&lt",
                            URL => "SoftKey:&lt&lt",
                            Position => "2" });
 $object->AddSoftKeyItem ({ Name => "Cancel",
                            URL => "SoftKey:Cancel",
                            Position => "3" });

=item * $object->AddSoftKeyItemObject

 # Add the softkeyitem object to the object being built
 $object->AddInputItemObject( { SoftKeyItem => $mysoftkeyitem });

=item * $object->Directory

 $mydirectory = new IPPhone;

 # Create Menu Object
 $mydirectory->Directory( { Title => "My Title", 
                           Prompt => "My Prompt" });

=item * $object->DirectoryEntry

 # Add Directory Entries to Directory Object
 $mydirectoryentry->DirectoryEntry( { Name => "Entry1", 
                                     Telephone => "555-1212" } );

=item * $object->AddDirectoryEntry

 $mydirectory->AddDirectoryEntry({ Name => "Entry 2", 
                                   Telephone => "555-1234" });

=item * $object->AddDirectoryEntryObject

 $mydirectory->AddDirectoryEntryObject( { DirectoryEntry => $mydirectoryentry });

=item * $object->Image

 $myimage = new IPPhone;

 # LocationX & LocationY: Position of the graphic (-1, -1 centers the graphic)
 # Height and Width define the number of pixels high and wide
 # Depth - number of bits per pixel (this number should be 2)

 # Create Menu Object
 $myimage->Image( { Title => "Some Image", Prompt => "View the image",
                  LocationX => "-1", LocationY => "-1", Width => "120",
                  Height => "44", Depth => "2", Data => "$data" });
 
=item * $object->GraphicMenu

 # Data is the data portion of a CIP image.  Use gif2cip or the photoshop
 # plugin to generate the data portion of an image.

 use IPPhone;
 $mygraphicmenu = new IPPhone;

 $data = "FFFFFFFFFFFFFFFFFFFF";

 # Create Menu Object
 $mygraphicmenu->GraphicMenu( { Title => "My Image", 
                 Prompt => "View the image",
                 LocationX => "-1", LocationY => "-1", 
                 Width => "10",
                 Height => "10", 
                 Depth => "2", 
                 Data => "$data" });

 print $mygraphicmenu->Content;

=item * $object->IconMenu

 use Cisco::IPPhone;

 $myiconmenu = new Cisco::IPPhone;

 $data = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

 # Create Icon Menu
 $myiconmenu->IconMenu( { Title => "Icon Menu", 
                   Prompt => "Select an icon" });
 
 $myiconmenu->AddMenuItem({  IconIndex => "1", 
                            Name => "Menu Item 1", 
     URL => "http://192.168.250.31/cgi-bin/metavante/text.cgi" });
 $myiconmenu->AddMenuItem({  IconIndex => "1", 
                            Name => "Menu Item 2", 
     URL => "http://192.168.250.31/cgi-bin/metavante/text.cgi" });
 $myiconmenu->AddMenuItem({  IconIndex => "1", 
                            Name => "Menu Item 3", 
     URL => "http://192.168.250.31/cgi-bin/metavante/text.cgi" });

 # Index is the numeric index of the icon to be displayed
 # Up to 10 instances of iconitem can be displayed
 $myiconmenu->AddIconItem ({ Index => "1", 
                            Width => "10",
                            Height => "10", 
                            Depth => "2", 
                            Data => "$data" });

 print $myiconmenu->Content;

=item * $object->IconItem

 $myiconitem = IconItem ({ Index => "1",
                            Width => "5",
                            Height => "5", 
                            Depth => "2", 
                            Data => "$data" });

=item * $object->AddIconItem
 
 $myiconmenu->AddIconItem ({ Index => "1", 
                            Width => "5",
                            Height => "5", 
                            Depth => "2", 
                            Data => "$data" });

=item * $object->AddIconItemObject

 $myiconmenu->AddIconItemObject( { IconItem => $myiconitem });

=item * $object->Execute

 # Use HTTP POST to push an execute ITEM to an IP Phone
 # One Execute Object can take up to 3 Execute Items
 # A response item will be returned from the phone
 # Phone will require authentiation.  This is the username and password
 # from the call manager database associated with this extension

 # Special characters in a URL pushed to a phone should be properly escaped 
 Character             Escape Sequence  
 & Ampersand           &amp;
 " Quote               &quot;
 ' Apostrophe          &apos;
 < Left angle bracket  &lt;
 > Right angle bracket &gt;
 
 $myexecute->Execute;
 $myexecute->AddExecuteItem( { ExecuteItem => "http://$SERVER/cgi-bin/my.cgi" });
 
=item * $object->AddExecuteItem
 
 $myexecute->Execute;
 $myexecute->AddExecuteItem( { ExecuteItem => "http://$SERVER/cgi-bin/my.cgi" });
 
 Here's the HTML that can push an execute object to an IP Phone
 <HTML>
 <HEAD></HEAD>
 <BODY>
 <FORM action="http://$ipphone/CGI/Execute" Method="POST">
 <TEXTAREA NAME="XML" Rows="5" Cols="60">
   print $myexecute->Content_Noheader;
 </TEXTAREA>
  <BR>
 <input type=submit value=POST>
 </FORM>
 </BODY>
 </HTML>

=item * $object->ExecuteItem

 $myexecuteitem->ExecuteItem ( { ExecuteItem => "http://$SERVER/cgi-bin/my.cgi" });

=item * $object->AddExecuteItemObject

 $myexecute->AddExecuteItemItemObject ( { ExecuteItem => $myexecuteitem });

=item * $object->Response

 $myresponse = new IPPhone;
 $myresponse->Response; #Response Object takes no Input

=item * $object->ResponseItem

 $myresponseitem = IPPhone;
 $myresponseitem->ResponseItem({ Status => "URL1",
                                 Data => "Data1",
                                URL => "URL or URI associated with request" });

=item * $object->AddResponseItem

 # Response Items are sent back from the phone, but you can build one

 use IPPhone;
 $myresponse = new IPPhone;

 $myresponse->Response; #Execute Object takes no Input

 # One Response Object can take up to 3 Execute Items
 $myresponse->AddResponseItem( { Status => "Success or failure of the action",
                                Data => "Data1",
                                URL => "URL or URI associated with request" });
 $myresponse->AddResponseItem( { Status => "Success or failure of the action",
                                Data => "Data2",
                                URL => "Success or failure of the action" });
 print $myresponse->Content;

=item * $object->AddResponseItemObject

=item * $object->Error

 # This object is usually sent back from the phone
 
 $myerror = new IPPhone;
 $myerror->Error( { Number => "1" });
 print $myerror->Content;

=item * $object->Print

 # Print the Object to the Phone
 # Deprecated.  Use "print $object->Content"
 $object->Print


=item * $object->Content

 # Print the Object to the Phone
 print $object->Content;

 # Print the Object to the phone with an automatic refresh every 60 seconds
 print $object->Content(Refresh=>'60');
 
 # Print the Object to the phone with an automatic refresh every 60 seconds
 # Refresh with a different URL
 print $object->Content(Refresh=>'60', URL=>"http://www.my.com/cgi-bin/t.cgi");
 
 # Expires page before current time (expires page immediately)
 print $object->Content(Date=>'Tue, 15 May 2002 23:45:04 GMT');
 print $object->Content(Expires=>'Tue, 15 May 2002 23:44:04 GMT');

 # Expiration is date and time of request minus one minute
 print $object->Content(Date=>'Tue, 15 May 2002 23:45:04 GMT');
 print $object->Content(Expires=>'-1');

 # Set a cookie. The IP Phone will use up to 4 cookies of 255 bytes in length
 print $object->Content(Cookie=>'MyCookieName=Bingo; path=/');

 # Go to a specified location in conjuntion with a status code such as
 # 301 Moved Permanently, 303 See Other, 307 Temporary Redirect, or 
 # 302 Object Moved.  Combined with user-agent logic, this can be effective
 print $object->Content(Location=>'http://services.acme.com');

=item * $object->Content_Noheader

 # Assign object to another object with no Content Type header
 # Can be used to view an object without the header
 # This should not be sent to the phone since the phone needs a content-type

 $myobject = $object->Content_Noheader;

=back

=head2 Examples

B< Example demonstrating Cisco IP Phone Text object>

 #!/usr/bin/perl

 use IPPhone;
 $mytext = new IPPhone;

 $mytext->Text( { Title => "My Title", Prompt => "My Prompt",
                           Text => "My Text" });
 $mytext->AddSoftKeyItem( { Name => "Update", URL => "SoftKey:Update",
                           Position => "1" });
 $mytext->AddSoftKeyItem( { Name => "Exit", URL => "SoftKey:Exit",
                           Position => "2" });
 print $mytext->Content;
 __END__

 Generates the following:

 Content-Type: text/xml

 <CiscoIPPhoneText>
 <Title>My Title</Title>
 <Prompt>My Prompt</Prompt>
 <Text>My Text</Text>
 <SoftKeyItem>
   <Name>Update</Name>
   <URL>SoftKey:Update</URL>
   <Position>1</Position>
 </SoftKeyItem>
 <SoftKeyItem>
   <Name>Exit</Name>
   <URL>SoftKey:Exit</URL>
   <Position>2</Position>
 </SoftKeyItem>
 </CiscoIPPhoneText>

B<Example showing IP Phone Menu>

 #!/usr/bin/perl
 use IPPhone;
 $mymenu = new IPPhone;
 $mymenuitem = new IPPhone;

 # Create Menu Object
 $mymenu->Menu( { Title => "My Title", 
                  Prompt => "My Prompt", 
                  Text => "My Text" });

 # Add Menu Items to Menu Object
 $mymenuitem->MenuItem( { Name => "Item1",  
                          URL => "http://www.mydomain.com" } );

 # Add Menu Item Object to the Menu
 $mymenu->AddMenuItemObject( { MenuItem => $mymenuitem });

 # Instead of creating a separate menu item object using MenuItem and
 # adding the object to the menu using AddMenuItemObject, 
 # you can simply use AddMenuItem to do it in one step

 $mymenu->AddMenuItem({ Name => "Item 2", 
                        URL => "http://www.mydomain.com" });
 
 $mymenu->AddSoftKeyItem({ Name => "Select", URL => "SoftKey:Select", 
                           Position => "1" });
 $mymenu->AddSoftKeyItem({ Name => "Exit", URL => "SoftKey:Exit", 
                           Position => "2" });
 
 # Print the Menu Object to the Phone
 print $mymenu->Content;

 
 Content-Type: text/xml

 <CiscoIPPhoneMenu>
 <Title>My Title</Title>
 <Prompt>My Prompt</Prompt>
 <MenuItem>
   <Name>Item1</Name>
   <URL>http://www.mydomain.com</URL>
 </MenuItem>
 <MenuItem>
   <Name>Item 2</Name>
   <URL>http://www.mydomain.com</URL>
 </MenuItem>
 <SoftKeyItem>
   <Name>Select</Name>
   <URL>SoftKey:Select</URL>
   <Position>1</Position>
 </SoftKeyItem>
 <SoftKeyItem>
   <Name>Exit</Name>
   <URL>SoftKey:Exit</URL>
   <Position>2</Position>
 </SoftKeyItem>
 </CiscoIPPhoneMenu>

B< Example using Execute object to push messages to the phone>

 #!/usr/bin/perl
 # Mark Palmer - markpalmer@us.ibm.com
 # Must use authentication when POSTING an object to a Cisco IPPhone.
 # User should be a user in the global directory associated with the phone
 # Can use this script to send messages to IPPhones
 
 use Cisco::IPPhone;
 use LWP::UserAgent;
 use URI;
 $ua = LWP::UserAgent->new;
 $myexecute = new Cisco::IPPhone;
 
 $SERVER = "192.168.250.17";
 $IPPHONE = "192.168.250.7";
 $USER = 'myname';
 $PASSWORD = 'mypassword';
 $POSTURL = "http://${IPPHONE}/CGI/Execute";
 
 # URL that phone will fetch
 $URL1 = "http://$SERVER/cgi-bin/nfl.cgi";
 
 # Build Execute Object with up to 3 Execute Items
 $myexecute->Execute;
 $myexecute->AddExecuteItem( { ExecuteItem => "$URL1" });
 my $xml = $myexecute->Content_Noheader;
 
 # Translate non-alpha chars into hex
 $xml = URI::Escape::uri_escape("$xml"); 
 
 my $request = new HTTP::Request POST => "$POSTURL";
 $request->authorization_basic($USER, $PASSWORD);
 $request->content("XML=$xml"); # Phone requires parameter named XML
 my $response = $ua->request($request); # Send the POST
 
 if ($response->is_success) {
   $result = $response->content;
   if ($result =~ /CiscoIPPhoneError Number="(\d+)"/) {
      $errno = $1;
      if ($errno == 4) {
          print "Authentication error\n";
      } elsif ($errno == 3) {
          print "Internal file error\n"; 
      } elsif ($errno == 2) {
          print "Error framing CiscoIPPhoneResponse object\n"; 
      } elsif ($errno == 1) {
          print "Error parsing CiscoIPPhoneExecute object\n"; 
      } else {
          print "Unknown Error\n";
          print $result;
      }
   }
 } else {
   print "Failure: Unable to POST XML object to phone $IPPHONE\n";
   print $response->status_line;
 }

=head2 EXPORT

None by default.

=head1 AUTHOR

Mark Palmer, markpalmer@us.ibm.com, 7/13/2002

=head1 SEE ALSO

perl(1).

