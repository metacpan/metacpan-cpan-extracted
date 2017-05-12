#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN 
  {
  $| = 1;
  unshift @INC,'../lib';
  chdir 't' if -d 't';
  plan tests => 40;
  use_ok qw/Convert::Morse/;
  }

#############################################################################
# test wether some partial inputs are morsable/morse

my (@parts,$try,$rc);

is (Convert::Morse::is_morsable('Helo World.'), 1, 'Helo World.');

is (Convert::Morse::is_morse('- . ----- .-.-.-'), 1, 'is_morse');

is (Convert::Morse::is_morsable('!@$%='), undef, 'is_morsable');

is (Convert::Morse::is_morse('- . 3'), undef, 'no is_morse');

while (<DATA>)
  {
  chomp;
  @parts = split /:/;
  $parts[0] = '' if !defined $parts[0];
  $parts[1] = '' if !defined $parts[1];
  # test wether convert between 0 and 1 works

  $try = "Convert::Morse::as_ascii('$parts[0]');";
  
  $rc = eval "$try";
  is ($rc,"$parts[1]", "to ascii $parts[1]");
 
  next if $parts[0] =~ /[^-.\s]/; # no reverse

  $try = "Convert::Morse::as_morse('$parts[1]');";
  
  $rc = eval "$try";
  is ($rc,"$parts[0]", "reverse $parts[1] to $parts[0]");

  }

# test with newlines

my $a = Convert::Morse::as_ascii("-----\n\n -----");
is ($a, "0\n 0", "as_ascii() with newlines");

my $m = Convert::Morse::as_morse("0\n 0");
is ($m, "----- \n -----", "as_morse() with newlines");

1;

__END__
.:E
-:T
-----:0
.----:1
..---:2
...--:3
....-:4
.....:5
-....:6
--...:7
---..:8
----.:9
:
----- ----- ----- -----:0000
By - . .-.. ... .-.-.-  in:By TELS. in
-.--. -.--.- -...- .-.-.:()=+
.--.-. -.-.--:@!
