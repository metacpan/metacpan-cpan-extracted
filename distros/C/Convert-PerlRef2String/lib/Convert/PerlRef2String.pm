package Convert::PerlRef2String;

use 5.008003;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

use vars qw(@ISA @EXPORT @EXPORT_OK);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Convert::PerlRef2String ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

@EXPORT = qw(perlref2string string2perlref string2perlcode);
@EXPORT_OK = qw(perlref2string string2perlref string2perlcode);

our $VERSION = '0.03';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.
use MIME::Base64;
use Compress::Zlib;
use Data::Dumper;

sub perlref2string {
        my $perlref = shift;
        die "Argument undefined" unless(defined $perlref);
        my ($string,$zipped,$encoded);
        if(ref $perlref){
        	eval{$string  = Dumper($perlref);};
        	die $! if($@);
        }else{
        	$string = $perlref;
        }
        eval{$zipped  = Compress::Zlib::memGzip($string);};
        die $! if($@);
        eval{$encoded = encode_base64($zipped);};
        die $! if($@);
        return $encoded;
}

sub string2perlref {
        my $string = shift;
        return unless(defined $string);
        my($decoded,$perlref,$VAR1);
        eval{$decoded = decode_base64($string);};
        die $! if($@);
        $perlref = eval($VAR1 = Compress::Zlib::memGunzip($decoded));
        die $! if($@);
        return $perlref;
}

sub string2perlcode {
        my $string = shift;
        return unless(defined $string);
        my($decoded,$perlcode);
        eval{$decoded = decode_base64($string);};
        die $! if($@);
        eval {$perlcode = Compress::Zlib::memGunzip($decoded);};
        die $! if($@);
        return $perlcode;
}

1;
__END__


=head1 NAME

Convert::PerlRef2String - Converting PERL references to compressed string and vice versa

=head1 SYNOPSIS

The following script

  use Convert::PerlRef2String;

  #Sender's action:
  use Data::Dumper;
  my $perl = {
          'Order' => {
                       'BookName' => 'Programming Web Serivices with Perl',
                       'Id'       => '0-596-00206-8',
                       'Quantity' => '500'
                     },
          'Payment' => {
                         'CardType'  => 'VISA',
                         'ValidDate' => '12-10-2006',
                         'CardNo'    => '1234-5678-9012-3456',
                         'Bearer'    => 'Kai Li'
                       }
        };
  my $string = perlref2string($perl);
  print $string,"\n";
  #sending the string over the Internet...
  
  #Receiver's action:
  my $perlref = string2perlref($string);
  print Dumper($perlref);

produces this output:

  H4sIAAAAAAAAA32RzarCQAxG9z5FFheycSCttiqi4M9GFK1XqetoBx20rYyjUqTvbtVeuYJtlplz
  vknIj9/7taADtwq8C2c6kBqh0/1ofxT243g/5VA+MfR0vNUchirawkquYSG1uqiNPMFVmR14Uh+w
  Wpg1Cl4pJJyWK4hsckWzhJ+fOTLKJC/LIcLvaPo/Aj1OQhmZ8r0ybsA6WCbHfDN/tOgVj5LhPh9U
  MGST85YtLBI2kVtqPT6Zxn9KrS4ct9EULcr0Wt0pd/uSdX4fHLOCicIiOn0/pO3KHXfoF8XsAQAA

  $VAR1 = {
          'Order' => {
                       'BookName' => 'Programming Web Serivices with Perl',
                       'Id' => '0-596-00206-8',
                       'Quantity' => '500'
                     },
          'Payment' => {
                         'CardType' => 'VISA',
                         'ValidDate' => '12-10-2006',
                         'CardNo' => '1234-5678-9012-3456',
                         'Bearer' => 'Kai Li'
                       }
        };

While a slightly different version (passing PERL code to sunroutine perlref2string instead of reference)

  use Convert::PerlRef2String;

  #Sender's action:
  use Data::Dumper;
  my $perl = q|{
          'Order' => {
                       'BookName' => 'Programming Web Serivices with Perl',
                       'Id'       => '0-596-00206-8',
                       'Quantity' => '500'
                     },
          'Payment' => {
                         'CardType'  => 'VISA',
                         'ValidDate' => '12-10-2006',
                         'CardNo'    => '1234-5678-9012-3456',
                         'Bearer'    => 'Kai Li'
                       }
        };|;
  my $string = perlref2string($perl);
  print $string,"\n";
  #sending the string over the Internet...
  
  #Receiver's action:
  my $perlref = string2perlref($string);
  print Dumper($perlref);


produces essentially the same result.

When the reference contains more sophiscated data elements (for example subroutines) we prefer to send the original code over the Internet so we must use subroutine string2perlcode instead of string2perlref. The follwing script

  use Convert::PerlRef2String;
  
  #Sender's action:
  my $perlref = q|{
          "Skipper" => sub{
                  my $person = shift;
                  print "Kipper: Hey there, $person!\n";
          },
          "Gilligan" => sub{
                  my $person = shift;
                  if($person eq "Skipper"){
                          print "Gilligan: Sir, yes, sir, $person!\n";
                  }else{
                          print "Gilligan: Hi, $person!\n";
                  }
          },
          "Professor" => sub{
                  my $person = shift;
                  print "Professor: By my calculations, you must be $person!\n";
          },
          "Ginger" => sub{
                  my $person = shift;
                  print "Ginger: (in a sulty voice) Well hello, $person!\n";
          }, 
  };|;
  
  my $string = perlref2string($perlref);
  print $string,"\n";
  #sending the string over the Internet...
  
  #Receiver's action:
  my $perlcode = string2perlcode($string);
  print $perlcode;
  
  my $greets = eval($perlcode);
  
  my @room;
  for my $person(qw(Gilligan Skipper Professor Ginger)){
          print "\n\n";
          print "$person walks into the room.\n";
          for my $room_person(@room){
                  $greets->{$person}->($room_person);
                  $greets->{$room_person}->($person);
          }
          push @room, $person;
  }

produces:

  H4sIAAAAAAAAA62SywrCMBBF937FtbhQ6BdUdOFGwY3gwo2bWqZ2MCY1kwpB/Hfroy34QEVnEQK5
  c+ZOZg4t3CKYbzjPyQYYDCHF6lC/VLH16JQCMRoDSMap6z9ocsvaIZheUBEm5OEyshRWqe2lDpq0
  Y9jUH7NSvI71bwY47VYa2jVN9R5pd5ar8hHmbEN4khByvj01XjdASugL9oTfAZ/+zcyalETMf6ZT
  0yKM/DkxiVVSqNix0WXX3hTYFuKwok+mptd/WporKkKXNeKSppzH3nBCPSxIKWTlYV4vUuvYPwHy
  z8yqzgIAAA==
  
  {
          "Skipper" => sub{
                  my $person = shift;
                  print "Kipper: Hey there, $person!\n";
          },
          "Gilligan" => sub{
                  my $person = shift;
                  if($person eq "Skipper"){
                          print "Gilligan: Sir, yes, sir, $person!\n";
                  }else{
                          print "Gilligan: Hi, $person!\n";
                  }
          },
          "Professor" => sub{
                  my $person = shift;
                  print "Professor: By my calculations, you must be $person!\n";
          },
          "Ginger" => sub{
                  my $person = shift;
                  print "Ginger: (in a sulty voice) Well hello, $person!\n";
          },
  
  };
  
  Gilligan walks into the room.
  
  
  Skipper walks into the room.
  Kipper: Hey there, Gilligan!
  Gilligan: Sir, yes, sir, Skipper!
  
  
  Professor walks into the room.
  Professor: By my calculations, you must be Gilligan!
  Gilligan: Hi, Professor!
  Professor: By my calculations, you must be Skipper!
  Kipper: Hey there, Professor!
  
  
  Ginger walks into the room.
  Ginger: (in a sulty voice) Well hello, Gilligan!
  Gilligan: Hi, Ginger!
  Ginger: (in a sulty voice) Well hello, Skipper!
  Kipper: Hey there, Ginger!
  Ginger: (in a sulty voice) Well hello, Professor!
  Professor: By my calculations, you must be Ginger!

Obviously there are some risks for using the latest. Strong encryption is recommended (for example SSL) and client/server certificates should be installed at the two parts to ensure a protected and exclusive channel.

=head1 DESCRIPTION

This is a handy tool for who wants to exchange PERL references over the Internet as compressed strings. When both the sender and receiver are PERL programs you can use this tool as an alternative to exchanging XML files (sometimes this methods is more powerful than SOAP).

=head2 EXPORT

  perlref2string(<reference_or_ref_string>)  
  string2perlref(<base64_encoded_string>)
  string2perlcode(<base64_encoded_string>)



=head1 AUTHOR

Kai Li, E<lt>kaili@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kai Li

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
