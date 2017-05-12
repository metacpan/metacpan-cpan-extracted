package Crypt::Discordian;

use Data::Dumper;

use 5.006001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Crypt::Discordian ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub normalize {
  my $string = uc(shift);

  # remove spaces from string
  $string =~ s/\s+//g;

  $string;
}

sub vowel_shift {
  my $string = normalize(shift);

  my $vowel  = qr/[AEIOUY]/;
  

  # collect all occurences of vowels in order
  my @vowel = ($string =~ m/$vowel/g) ;

  # remove all vowels from string
  $string =~ s/$vowel//g;

  # append all vowels to end of string
  $string = "$string$_" for @vowel;

  $string;
}

sub encrypt {
  my $string = normalize(shift);
  my @string;

  $string = vowel_shift $string;
  $string = reverse $string;
  @string = unpack 'C*', $string;
  @string = sort { $a <=> $b } @string;
  pack 'C*', @string;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Crypt::Discordian - encryption as described in Principia Discorida

=head1 SYNOPSIS

  use Crypt::Discordian;

  # per http://www.principiadiscordia.com/book/78.php
  my $string = 'hail eris';
  $string = Crypt::Discordian::encrypt($string); # yields 'AEHIILRS'

=head1 DESCRIPTION

Page 78 of the Principia Discordia lists an algorithm for encrypting text.
I decided not to code it up. Then I looked away. And I decided not to code
it again. And then I decided to do something else. And then I looked away
again. So here's the result of my decision not to code up the algorithm.

=head2 EXPORT

None by default.

=head1 AUTHOR

Terrence Brannon, E<lt>metaperl@urth.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by U-MOKSHA\metaperl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
