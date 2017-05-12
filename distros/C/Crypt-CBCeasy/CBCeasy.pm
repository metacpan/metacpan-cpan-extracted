# easy en/decryption with DES/IDEA/Blowfish and some other ciphers
# Mike Blazer <blazer@mail.nevalink.ru>

package Crypt::CBCeasy;

use 5.003;
use Crypt::CBC;
use Carp;
use Symbol;

use strict;
no strict 'refs';
use vars qw($VERSION @DEFAULT_CIPHERS $LastCipher);

$VERSION = '0.24';
@DEFAULT_CIPHERS = qw/DES IDEA Blowfish/;


#--------------
sub useCBC {
#--------------
# $from - handler (r), filename or just plain or encrypted text
# $to   - handler (r), or filename. If '' or undef sub returns $to-string
  my ($key, $from, $to) = @_;
  my $sub               = (caller(1))[3]; # caller subroutine
  my ($algorithm, $op)  = $sub =~ /^(.*)::(.*)$/;
#print "$algorithm, $op\n";
  $LastCipher = $algorithm;

  my ($fhi, $fho, $fromFile, $INopened, $OUTopened,
      $buffer, $fromStr, $toStr, $cipher);

  croak "CBCeasy: source not defined\n"      unless defined $from;
  croak "CBCeasy: key not defined\n"         unless defined $key;
  croak "CBCeasy: I can do only `encipher' or `decipher'\n"
     unless $op && $op =~ /^(encipher|decipher)$/i;

  if ((UNIVERSAL::isa($from, 'GLOB') ||     # \*HANDLE
       UNIVERSAL::isa(\$from,'GLOB')        # *HANDLE
       ) &&  defined fileno $from
     ) {

     $fhi = $from;
     $fromFile = 1;

  } elsif (-e $from && -r _) {      # filename
     $fhi = gensym;
     $fromFile = 1;
     $INopened = 1;
     open ($fhi, $from) || croak "CBCeasy: file `$from' not found/readable\n";

  } elsif (-e $from && !-r _) {     # filename
     croak "CBCeasy: file `$from' not readable\n";

  } else { # stream itself in $from
  }

  $cipher = new Crypt::CBC($key, $algorithm);
  $cipher->start(lc $op);

  if ($fromFile) {

     binmode $fhi;
     # fails with too long chains
     while (read($fhi,$buffer,4096)) {
	$toStr .= $cipher->crypt($buffer);
     }
     $toStr .= $cipher->finish;

     close $fhi if $INopened;

  } else {
     # fails with too long chains
     while ($from) {
       $fromStr = substr($from, 0, 4096);
       substr($from, 0, 4096) = '';
       $toStr .= $cipher->crypt($fromStr);
     }
     $toStr .= $cipher->finish;
  }

  return $toStr unless $to;

  if ((UNIVERSAL::isa($to, 'GLOB') ||     # \*HANDLE
       UNIVERSAL::isa(\$to,'GLOB')        # *HANDLE
      ) &&  defined fileno $to
     ) {

     $fho = $to;

  } else {      # filename
     $fho = gensym;
     $OUTopened = 1;
     open ($fho, ">$to") || croak "CBCeasy: can't write file `$to'\n";

  }

  binmode $fho;
  print $fho $toStr;

  close $fho if $OUTopened;

}

#--------------
sub import {
  my $pkg = shift;

  for (@_ ? @_ : @DEFAULT_CIPHERS) {
     eval <<"E_O_P" unless defined *{"$_\::encipher"}{CODE};

	 sub $_\::encipher { useCBC(\@_) }
	 sub $_\::decipher { useCBC(\@_) }
E_O_P

  }
}

1;
__END__

=head1 NAME

Crypt::CBCeasy - Easy things make really easy with Crypt::CBC

=head1 SYNOPSIS

 use Crypt::CBCeasy; # !!! YOU can not 'require' this module !!!

 IDEA::encipher($my_key, "plain-file", "crypted-file");

 $plain_text = DES::decipher($my_key, \*CRYPTO_FILE);

 $crypted = Blowfish::encipher($my_key, \*PLAIN_SOCKET);

=head1 ABSTRACT

This module is just a helper for Crypt::CBC to make simple and
usual jobs just one-liners.

The current version of the module is available at CPAN.

=head1 DESCRIPTION

After you call this module as

  use Crypt::CBCeasy IMPORT-LIST;

it creates the C<encipher()> and C<decipher()> functions in all
namespaces (packages) listed in the C<IMPORT-LIST>.

Without the C<IMPORT-LIST> it creates these 2 functions
in the B<DES::>, B<IDEA::> and
B<Blowfish::> namespaces by default
to stay compatible with the previous versions
that were capable to handle only these 3 ciphers.

You have to install C<Crypt::CBC> v. 1.22 or later to work with C<Blowfish>.

Sure IDEA:: functions will work only if you have Crypt::IDEA installed,
DES:: - if you have Crypt::DES, Blowfish:: - if you have Crypt::Blowfish
and Crypt::CBC is version 1.22 or above etc.

Here's the list of the ciphers that could be called via the
C<Crypt::CBCeasy> interface today (in fact the same modules
that are C<Crypt::CBC> compatible):

  Cipher          CPAN module

  DES             Crypt::DES
  IDEA            Crypt::IDEA
  Blowfish        Crypt::Blowfish
  Twofish2        Crypt::Twofish2
  DES_PP          Crypt::DES_PP
  Blowfish_PP     Crypt::Blowfish_PP
  Rijndael        Crypt::Rijndael
  TEA             Crypt::TEA

Note that cipher names are case sensitive in the C<IMPORT-LIST>,
so "blowfish" will give an error.
Type them exactly as they are written in the correspondent
underlying modules.

Both C<encipher()> and C<decipher()> functions take 3 parameters:

  1 - en/decryption key
  2 - source
  3 - destination

The sources could be: an existing file, a scalar (just a string that would be
encrypted), an opened filehandle, any other object that inherits from the
filehandle, for example IO::File or FileHandle object, and socket.

Destinations could be any of the above except scalar, because we can not
distinguish between scalar and output file name here.

Well, it's easier to look at the examples:

(C<$fh> vars here are IO::Handle, IO::File or FileHandle objects,
variables of type "GLOB", "GLOB" refs or sockets)

B<IDEA::encipher(> $my_key, "in-file", "out-file" B<);>

B<IDEA::encipher(> $my_key, *IN, "out-file" B<);>

B<IDEA::encipher(> $my_key, \*IN, "out-file" B<);>

B<IDEA::encipher(> $my_key, $fh_in, "out-file" B<);>

B<IDEA::encipher(> $my_key, "in-file", *OUT B<);>

B<IDEA::encipher(> $my_key, "in-file", \*OUT B<);>

B<IDEA::encipher(> $my_key, "in-file", $fh_out B<);>

B<IDEA::encipher(> $my_key, *IN, *OUT B<);>

B<IDEA::encipher(> $my_key, \*IN, \*OUT B<);>

B<IDEA::encipher(> $my_key, $fh_in, $fh_out B<);>

B<IDEA::encipher(> $my_key, $plain_text, "out-file" B<);>

B<IDEA::encipher(> $my_key, $plain_text, *OUT B<);>

B<IDEA::encipher(> $my_key, $plain_text, \*OUT B<);>

B<IDEA::encipher(> $my_key, $plain_text, $fh_out B<);>

any of the above will work and do what was expected.

In addition there is a 2-argument version that returns it's result
as scalar:

$crypted_text = B<IDEA::encipher(> $my_key, $plain_text B<);>

$crypted_text = B<IDEA::encipher(> $my_key, "in-file" B<);>

$crypted_text = B<IDEA::encipher(> $my_key, *IN B<);>

$crypted_text = B<IDEA::encipher(> $my_key, \*IN B<);>

$crypted_text = B<IDEA::encipher(> $my_key, $fh B<);>

All the same is possible for any of the ciphers in the C<IMPORT-LIST>.

All functions croak on errors (such as "input file not found"), so
if you want to trap errors use them inside the C<eval{}> block
and check the C<$@>.


Note that all filehandles are used in C<binmode> whether you claimed them
C<binmode> or not. On Win32 for example this will result in CRLF's in
$plain_text after

 $plain_text = DES::decipher($my_key, "crypted_file");

if "crypted_file" was created by

 DES::encipher($my_key, "text_file", "crypted_file");

If the filehandle was used before - it's your job to rewind it
to the beginning and/or close.

=head1 INSTALLATION

As this is just a plain module no special installation is needed. Put it
into the /Crypt subdirectory somewhere in your @INC. The standard

 Makefile.PL
 make
 make test
 make install

procedure is provided. In addition

 make html

will produce the HTML-docs.

This module requires

Crypt::CBC by Lincoln Stein, lstein@cshl.org
v.1.20 or later.

one or more of

Crypt::IDEA, Crypt::DES, Crypt::Blowfish, Crypt::Blowfish_PP,
Crypt::Twofish2, Crypt::DES_PP or other Crypt::CBC compatible modules.

=head1 CAVEATS

This module has been created and tested in a Win95/98/2000Pro environment
with Perl 5.004_02 and ActiveState ActivePerl build 618.
I expect it to function correctly on other systems too.

=head1 CHANGES

 0.21   Mon Mar  6 07:28:41 2000  -  first public release

 0.22   Sun Feb 18 13:11:59 2001
	A horrible BUG was found by Michael Drumheller <drumheller@alum.mit.edu>
	In fact 0.21 was ALWAYS using DES despite of the desired cipher.
	DAMN!
	Fixed.
	And the test is modified so that this will never happen again.

	Now you can define the list of ciphers that are compatible
	with Crypt::CBC in the import list.
	You can not call this module with the "require" statement. This
	is incompatible with the older versions.

  0.23  Crypt::Rijndael 0.02 compatibility was approved.
        Tests are some more complex now.

  0.24  Crypt::TEA 1.01 by Abhijit Menon-Sen <ams@wiw.org> is checked
	and approved.

=head1 TODO

Any suggestions are much appreciated.

=head1 BUGS

Please report.

=head1 VERSION

This man page documents "Crypt::CBCeasy" version 0.24

February 18, 2001

=head1 AUTHOR

Mike Blazer, blazer@mail.nevalink.ru

http://base.dux.ru/guest/fno/perl/

=head1 SEE ALSO

Crypt::CBC

=head1 COPYRIGHT

Copyright (C) 2000-2001 Mike Blazer.

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

