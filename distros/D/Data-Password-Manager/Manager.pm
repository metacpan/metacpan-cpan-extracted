package Data::Password::Manager;

use strict;
#use diagnostics;
#use warnings;
use vars qw($VERSION @ISA @EXPORT_OK @to64);
require Exporter;
@ISA = qw(Exporter);
$VERSION = do { my @r = (q$Revision: 0.05 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	pw_gen
	pw_valid
	pw_clean
	pw_obscure
	pw_get
);

#
# crypto lib to decode and encode passwords
#

=head1 NAME

Data::Password::Manager - generate, check, manage B<crypt - des> passwords

=head1 SYNOPSIS

  use Data::Password::Manager qw(
        pw_gen
        pw_valid
        pw_obscure
        pw_clean
	pw_get
  );

  $password = pw_gen($cleartext);
  $ok = pw_valid($cleartxt,$password);
  $clean_text = pw_clean($dirty_text);
  ($code,$text) = $pw_obscure($newpass,$oldpass,$min_len);
  $passwd = pw_get($user,$passwd_file,\$error);

=head1 DESCRIPTION

=over 2

=item * $password = pw_gen($cleartext);

Generate a 13 character DES password string from clear text

  input:	string <= 128 characters
  output:	password

=cut

###############################################
# Subroutine to encrypt a string
# uses 'crypt'

sub pw_gen {
  my($clrtxt) = @_;
  my $seed = time + unpack("%16C*", $clrtxt);
  srand;				# init rand generator
  my $salt = &salt_char($clrtxt);	# first salt char
  srand $seed;				# alter rand generator
  $salt .= &salt_char($clrtxt);		# 2nd salt char
  $clrtxt = substr($clrtxt,0,128) if length $clrtxt > 128;
  return crypt($clrtxt,$salt);		# password
}   

=item * $ok = pw_valid($cleartxt,$password);

Return true if clear text is password match

  input:	string <= 128 characters,
		password
  output:	true on match, else false

=cut

###############################################
# Subroutine to check a password
# uses 'crypt'
#

sub pw_valid {
  my($plaintxt, $passwd) = @_;
  return crypt($plaintxt, $passwd) eq $passwd
	if $passwd;
# for blank encrypted passwords
  return $plaintxt eq $passwd;
}

=item * $clean_text = pw_clean($dirty_text);

  Clean a text string to only include
  / . 0..9 a..z A..Z

  Useful for restricted password sets 
  i.e. http applications

  Returns a string of 128 characters or less

=cut

###############################################
# Subroutine to clean string for crypt use
#
# Input:  [string]
# Output: [clean string <128 characters]

sub pw_clean {
  my $string = $_[0];
  $string =~ tr/[a-zA-Z0-9\/\.]//cd;
  $string = (length $string > 128)
	? substr($string,0,128)
	: $string;
}

=item * ($code,$text) = $pw_obscure($newpass,$oldpass);

Check for a usable password. Returns ok if there is 
no old password. i.e. any new password will do.

  input:	string <= 128 characters

  return (0, 'OK') if no old password or new is good
  return ( 1, 'too short' ) if length < $MIN_LEN (default 5)
  return ( 2, 'no change' ) if old eq new
  return ( 3, 'a palindrome' ) if new is a palindrome
  return ( 4, 'case change only' ) if old =~ /$new$/i
  return ( 5, 'to similar' ) see code
  return ( 6, 'to simple' ) if not a good character mix
  return ( 7, 'rotated' ) if new is rotated version of old
  return ( 8, 'flipped' ) if new is old flipped around

=cut

### sub-subroutine to pick a character not in the input string
# Input:  [string]
# Output: [character]
#

@to64 = ('.', '/', 0..9,'A'..'Z', 'a'..'z');

sub salt_char {
  my($clrtxt) = @_;
  my $salt = $to64[rand 64];
# try once again if the character is in the clear text string
  $salt = ($clrtxt =~ /$salt/)
	? $to64[rand 64]
	: $salt;
}

=item * $passwd=pw_get($user,$passwd_file,\$error);

Check a password file for the presence of $user:$password.

  input:	$user
  return:	$password

Returns undef on error and places a descriptive error message in the scalar
$error. Since a valid password can be empty, the caller must check that the
return value is defined, not just false.

FILE is of the form:

	user1:DESpassword1
	user2:DESpassword2
	etc...
	# in-line comments are OK

=back

=cut

# return encrypted password or undef
# since the password can be empty,
# caller must check if "defined"

sub pw_get {
  my($user,$passwd_file,$ep) = @_;
  $$ep = 'could not access password file';
  open(P,$passwd_file) 
	or return undef;
  $$ep = "no such user, $user";
  my $passwd;
  foreach(<P>) {
    if ($_ =~ /^${user}:(.*)/) {
      $$ep = '';
      $passwd = $1;
      last;
    }
  }
  close P;
  return undef 
	if $$ep;
  return $passwd || '';
}


#######################################################
# subroutine to check for obscure password
# This is a port to perl of the functions found 
# in the shadow suite.
#######################################################
#
# Copyright 1989 - 1994, Julianne Frances Haugh
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of Julianne F. Haugh nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY JULIE HAUGH AND CONTRIBUTORS `AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL JULIE HAUGH OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# RCSID("$Id: obscure.c,v 1.7 1998/04/16 19:57:44 marekm Exp $")
#
# This version of obscure.c contains modifications to support "cracklib"
# by Alec Muffet (alec.muffett@uk.sun.com).  You must obtain the Cracklib
# library source code for this function to operate.
#
#######################################################
# subroutine to do the password checking
#
# Input:	$newpass,[$oldpass],[$minpasslen]
# Return:	( code, message )
#
#		    0	OK
#		   !0	something wrong
#
#sub CryptLibObscure {
#  my($old,$new) = @_;
# @_ = ($new,$old);
# goto &pw_obscure;
#}

sub pw_obscure {
  my ( $oldmono, $newmono );

#  my ( $old, $new )	= @_;
  my ($new,$old,$min_pass_len) = @_;
  $min_pass_len = 5 unless $min_pass_len;

  return (9,'missing new password') unless $new;
  return (0,'OK') unless $old;

  
  ( $oldmono = $old ) =~ tr/A-Z/a-z/;
  ( $newmono = $new ) =~ tr/A-Z/a-z/;

#  @_ = split ( '', $oldmono );			# turn $old end for end
#  while ( $i = pop ) {
#    $flipped .= $i;
#  }
#  $flipped .= $flipped;

  my $flipped = reverse $oldmono;

  return ( 1, 'too short' ) if ( length ($new) < $min_pass_len );
  return ( 2, 'no change' ) if ( $old eq $new );
  return ( 3, 'a palindrome' ) if ( &CL_Palindrome ($oldmono, $newmono));
  return ( 4, 'case change only' ) if ( $oldmono eq $newmono );
  return ( 5, 'to similar' ) if ( &CL_Similar ($oldmono, $newmono));
  return ( 6, 'to simple' ) if ( &CL_Simple ( $old, $new ));
  $oldmono .= $oldmono;
  return ( 7, 'rotated' ) if ( $oldmono =~ /$newmono/ );
  return ( 8, 'flipped' ) if ( $flipped =~ /$newmono/ );
  return (0,'OK');
}

#######################################################
# subroutine to check for palindrome
#
# Input:	[old], [new]    passwords
# Return:	0, OK
#		1, no good
#
sub CL_Palindrome {
  my ( $i, $j );
  my ( $old, $new ) = @_;
  my @new = split ( '', $new );

# can't be a palindrome - like `R A D A R' or `M A D A M'

  $i = @new;
  for ( $j=0; $j < $i; $j++ ) {
    if ( $new[$i-$j-1] ne $new[$j] ) {
      return (0);
    }
  }
  1;
}

#######################################################
# subroutine to check for similarity between new, old password
#
# Input:	[old], [new]	passwords
# Return:       0, OK                                  
#               1, no good                             
#
sub CL_Similar {
  my ( $i, $j );
  my ( $old, $new ) = @_;
  my @old = split ( '', $old );

# @new is only used to get cheap length and
# a $#new count so the equation below is consistent
  my @new = split ( '', $new );

# XXX - sometimes this fails when changing from a simple password
# to a really long one (MD5).  For now, I just return success if
# the new password is long enough.  Please feel free to suggest
# something better...  --marekm

  if ( @new >= 8 ) { return (0); }
  $j=0;
  for ( $i=0; ($i<=$#new && $i<=$#old); $i++ ) {
# next line really is $new
    if ( $new =~ /$old[$i]/ ) { ++$j; }
  }
  if ( $i >= $j*2 ) { return (0); }
  1;
}

#######################################################
# subroutine to check for a nice mix of characters
#
# Input:        [old], [new]    passwords
# Return:       0, OK
#               1, no good
#
sub CL_Simple {
  my $i;
  my $digits	= 0;
  my $uppers	= 0;
  my $lowers	= 0;
  my $others	= 0;
  
  my ( $old, $new ) = @_;
  my @new = split ( '', $new );

  for ( $i=0; $i <= $#new; $i++ ) {
    if ( $new[$i] =~ /[0-9]/ ) { ++$digits;
    } elsif ( $new[$i] =~ /[a-z]/ ) { ++$lowers;
    } elsif ( $new[$i] =~ /[A-Z]/ ) { ++$uppers;
    } else { ++$others; }
  }

# The scam is this - a password of only one character type
# must be 8 letters long.  Two types, 7, and so on.

  my $size = 9;
  if ( $digits ) { --$size; }
  if ( $uppers ) { --$size; }
  if ( $lowers ) { --$size; }
  if ( $others ) { --$size; }

  if ( $size <= $i ) { return (0); }
  1;
}
1;
__END__

=head1 EXPORTS_OK 

        pw_gen
        pw_valid
        pw_clean
        pw_obscure
	pw_get

=head1 ACKNOWLEDGEMENTS

Code for the subroutine to check for obscure passwords is based on and taken
in part from a port to perl of the functions found  in the shadow suite by
Julianne Frances Haugh. Thank you for your contribution to public domain
software Julianne.

Copyright 1989 - 1994, Julianne Frances Haugh
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

=over 2

=item * 1

Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

=item * 2.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

=item * 3.

Neither the name of Julianne F. Haugh nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

=back

THIS SOFTWARE IS PROVIDED BY JULIE HAUGH AND CONTRIBUTORS `AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.IN NO EVENT SHALL JULIE HAUGH OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

RCSID("$Id: obscure.c,v 1.7 1998/04/16 19:57:44 marekm Exp $")

This version of obscure.c contains modifications to support "cracklib"
by Alec Muffet (alec.muffett@uk.sun.com).You must obtain the Cracklib
library source code for this function to operate.

=head1 COPYRIGHT

Copyright 2003 - 2014, Michael Robinton <michael@bizsystems.com>

The non-(Julianne Haugh) portion of the program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton, BizSystems <michael@bizsystems.com>

=cut

1;
