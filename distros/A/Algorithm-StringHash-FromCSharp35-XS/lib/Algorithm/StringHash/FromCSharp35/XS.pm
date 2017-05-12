package Algorithm::StringHash::FromCSharp35::XS;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(	) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(GetHashCode);
our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Algorithm::StringHash::FromCSharp35::XS', $VERSION);

1;
__END__

=head1 NAME

Algorithm::StringHash::FromCSharp35::XS - C#'s string Hashing Algorithm in V3.5 

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Algorithm::StringHash::FromCSharp35::XS qw(GetHashCode);

  my $str = "hello world";
  my $hashcode = GetHashCode($str);
  print $hashcode;

=head1 DESCRIPTION

This module implement the C#'s getHashCode function in V3.5.
The algorithm always produce a unsigned int for any string and always return the same unsigned int for the same string.
Comparison with other string hash algorithm, it is characterized by fast.


=head1 METHODS

=head2 GetHashCode($string)
 
The only method, export by default.
Input is some string, output is a number between 0 and 2^32.


=head1 IMPLEMENTATION OF PERL

You can take the implementation if perl if not able to build XS module.

  sub getHashCode
  {
      use bigint;
      no warnings 'uninitialized';
      my $str = shift;
      my @str = split //, $str;
      my $num = 0x15051505;
      my $num2 = $num;
      my $len=length($str);
      my $i = 0;
      my $pos = 0;
      my $field_max = 1<<32;
      for($i=$len;$i>0;$i-=4)
      {
          my $numptr;
          $numptr = (ord($str[$pos*4+3])<<24) + (ord($str[$pos*4+2])<<16) + (ord($str[$pos*4+1])<<8) + ord($str[$pos*4]);
          $num = ((($num << 5) + $num) + ($num >> 0x1b)) ^ $numptr;
          $num %= $field_max;
          if($i<=2) {last;}
          $pos++;
          $numptr = (ord($str[$pos*4+3])<<24) + (ord($str[$pos*4+2])<<16) + (ord($str[$pos*4+1])<<8) + ord($str[$pos*4]);
          $num2=((($num2 << 5) + $num2) + ($num2 >> 0x1b)) ^ $numptr;
          $num2 %= $field_max;
          $pos++;
      }
      return ($num + ($num2 * 0x5d588b65)) % $field_max;
  }


=head1 AUTHOR
 
Written by ChenGang, yikuyiku.com@gmail.com
 
L<http://blog.yikuyiku.com/>
 
 
=head1 COPYRIGHT
 
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
 
=cut
