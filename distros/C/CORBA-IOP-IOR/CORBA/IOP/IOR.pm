package CORBA::IOP::IOR;

require 5.001;

use CORBA::IOP::TaggedProfile;
use CORBA::IOP::Util;

use strict;

$IOR::VERSION='0.1';


sub new {
  my $class = shift;
  my $self = {};

  return bless $self, $class;
}


sub parseIOR {
  my $self = shift;

  my ($ior) = @_;

  my ($prefix, $byte, $profiles_len);

  $prefix = unpack("a4", $ior);

  if ($prefix ne $IOR_MAGIC) {
    die "Invalid IOR.";
  }

  $ior = substr($ior, 4);
  $byte = 0;

  ($self->{little_endian}, $byte) = decode_number($ior, $byte, 1, 0); 

  ($self->{type_id}, $byte) = decode_string($ior, $byte, $self->{little_endian});

  ($profiles_len, $byte) = decode_number($ior, $byte, 4, $self->{little_endian}); 

  # search for IIOP profile (skip other profiles)
  while($profiles_len--) {
    my ($profile_id, $profile_data_len);

    ($profile_id, $byte) = decode_number($ior, $byte, 4, $self->{little_endian}); 
    
    # next is the length of the 'profile_data' encapsulation
    ($profile_data_len, $byte) = decode_number($ior, $byte, 4, $self->{little_endian}); 

    if ($profile_id == $TAG_INTERNET_IOP) {
      # Found an IIOP profile. 
      $self->{IIOP_profile} = new CORBA::IOP::TaggedProfile;
      $self->{IIOP_profile}->parseIOR($ior, $byte, $self->{little_endian});
    }
    else  {
      print "Unknown profile ID: $profile_id\n";
    }

    $byte += $profile_data_len;
  }
}


sub printHash {
  my $self = shift;

  my ($key, $value);

  while (($key, $value) = each %$self) {
    print "$key = $value\n" unless $key eq "IIOP_profile";
  }

  if ($self->{IIOP_profile}) {
    $self->{IIOP_profile}->printHash();
  }
}


sub stringifyIOR {
  my $self = shift;

  my ($ior, $string, $stringifiedProfile);

  $ior = "";

  $ior .= encode_number(length($ior), 1,  0, $self->{little_endian});

  $ior .= encode_string(length($ior), $self->{little_endian}, $self->{type_id});

  if (!$self->{IIOP_profile}) {
    die "No IIOP profile set."
  }

  # Hard code, only one profile.
  $ior .= encode_number(length($ior), 4, $self->{little_endian}, 1); 

  # And its IIOP.
  $ior .= encode_number(length($ior), 4, $self->{little_endian}, $TAG_INTERNET_IOP); 

  # Make it.
  $stringifiedProfile = $self->{IIOP_profile}->stringifyIOR(length($ior), $self->{little_endian});

  # Encode profile length.
  $ior .= encode_number(length($ior), 4, $self->{little_endian}, length($stringifiedProfile)/2);

  # Add profile on.
  $ior .= $stringifiedProfile;

  return $IOR_MAGIC . $ior;
}


1;
