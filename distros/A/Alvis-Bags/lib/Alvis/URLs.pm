package Alvis::URLs;

$Alvis::URLs::VERSION = '0.3';

###################### CONFIGURATION #####################


############ END CONFIGURATION ######################

use Digest::MD5 qw(md5_hex);
use strict;
use POSIX;
use Encode;
use URI;

# encoding pragmas follow any includes like "use"
use encoding 'utf8';
use open ':utf8';

#  return 32-bit unsigned
sub easyhash32
{
  my $string = shift;
  Encode::_utf8_off($string);
  my $dig = md5_hex($string);
  # print $dig . " \n";
  return POSIX::strtol(substr($dig,0,8),16);
}

#  return 64-bit unsigned
sub easyhash64char
{
  my $string = shift;
  Encode::_utf8_off($string);
  my $dig = md5_hex($string);
  # print $dig . " \n";
  return substr($dig,0,16);
}

#  URL switches
$Alvis::URLs::nocase = 0;
$Alvis::URLs::noclean = 0;
$Alvis::URLs::keepfrag = 0;

sub CleanURL() {
  if ( !$_[0] ) {
	return undef;
  }
  my $uri = new URI($_[0]);
  if ( ! $Alvis::URLs::keepfrag ) {
    $uri->fragment(undef);
  }
  return $uri->canonical;
}

sub StandardURL() {
  my $inu = shift();
  if ( $Alvis::URLs::nocase ) {
    $inu = lc($inu);
  }
  if ( $Alvis::URLs::noclean == 0 ) {
    $inu = &Alvis::URLs::CleanURL($inu);
  }
  return $inu;
}


1;

__END__

=head1 NAME

Alvis::URLs - URL and hash standardisation utilities.

=head1 SYNOPSIS

 $Alvis::URLs::keepfrag = 0; # set to keep fragment, default removes
 $cleanurl = &Alvis::URLs::CleanURL($url);
 $Alvis::URLs::nocase = 0;   # set to convert everything to lowercase
 $Alvis::URLs::noclean = 0;  # set to disable use of URI cleaning
 $standardurl = &Alvis::URLs::StandardURL($url);

=head1 DESCRIPTION

Provides an MD5 hashing interface, as well as simple standards for URL cleaning
based on the URI library.

=head1 METHODS

=head2 easyhash32()

   $myhash = &easyhash32($text);

Return 32-bit unsigned part of the MD5 hash as an integer.

=head2 easyhash64char()

   $myhash = &easyhash32($text);

Return 64-bit unsigned part of an MD5 hash as a 16 character string in hexadecimal.

=head2 CleanURL()

 $cleanurl = &Alvis::URLs::CleanURL($url);

Use the URI library to cleanup the format of the URL.

=head2 StandardURL()

 $standardurl = &Alvis::URLs::StandardURL($url);

Standardise the format of the URL, including cleaning above if switches dictate.

=head1 SEE ALSO

URI(3).

=head1 AUTHOR

Wray Buntine, E<lt>wray.buntine@hiit.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Wray Buntine

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
