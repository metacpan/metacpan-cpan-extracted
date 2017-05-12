package Acme::PGPSign;

use strict;
use warnings;

use Crypt::OpenPGP;
use Crypt::OpenPGP::Armour;

my $pgp = Crypt::OpenPGP->new();

our $VERSION = '0.01';
sub valid_signed {
  my $data = shift;
  my $return = $pgp->handle( Data => $data );
  return (defined $return->{Validity})?1:0;
}

sub decrypt {
  my $data = shift;
  my $return = Crypt::OpenPGP::Message->new( Data => $data );
  return ($return->pieces)[1]->data; # return the code part of the Message
}

sub sign {
  my $data = shift;
  my $param = shift;
  %param =();
  if ($param) {
     %param = eval ($param);
     {use Data::Dumper; print Dumper(\%param);}
  }

  $param{Data} = $data;
  $param{Armour} = 1;
  $param{Clearsign} = 1 unless $param{Clearsign};
  $param{PassphraseCallback} = sub {
    if (my $cert = $_[0]) {
        printf "Enter passphrase for secret key %s: ",
            $cert->key_id_hex;
    } else {
        print "Enter passphrase: ";
    }
    my $return =  readline(*STDIN);
    chomp $return;
    return $return
    }
     unless (defined $param{Passphrase});
  my $ciphertext = $pgp->sign( %param );
  return $ciphertext;
}

sub signed { $_[0] =~ /-----BEGIN PGP .*MESSAGE-----/ }

open 0 or print "Can't transmit '$0'\n" and exit;
(my $program = join "", <0>) =~ s/.*^\s*use\s+Acme::PGPSign\s*(.*?);\n//sm;
my $param=$1;
do {eval decrypt $program; exit} unless (not signed $program or not valid_signed $program);
do {warn "Not valid : ".$pgp->errstr."\n"; exit} if (not valid_signed $program and signed $program) ;

my $ciphertext = sign $program, $param;
print "Cannot Sign '$0'\n" unless ($ciphertext);

open 0, ">$0" or print "Cannot Sign '$0'\n" and exit;
print {0} "use Acme::PGPSign;\n", $ciphertext and exit;
     
1;
__END__

=head1 NAME

Acme::PGPSign - Perl extension for signed scripts

=head1 SYNOPSIS

  use Acme::PGPSign (KeyID => 'abcdef');

  print "Hello World\n";
  

=head1 ABSTRACT

The first time you run a program under C<use Acme::PGPSign>, the module converts
your program to a PGP signed code segment. The code continues to work exactly as 
it did before, but now it looks like this:

use Acme::PGPSign;
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

print "Hello World\n";
-----BEGIN PGP SIGNATURE-----
Version: Crypt::OpenPGP 1.03

iQBGBAERAgAGBQI/HCQpAAoJEKWJ3MaRjamws9UAoKSTyel1JNOj9erCMjmMlI9s
wc5oAJ9UuzLk2J1WBnzZR4+AwgBiIvi6xw==
=PdE4
-----END PGP SIGNATURE-----

=head1 DESCRIPTION

In order for C<use Acme::PGPSign> to work you need to be able to sign the code 
with your keyring.

=head2 EXPORT

None

=head1 DEPENDENCIES

This module requires:

  Crypt::OpenPGP

=head1 KNOWN BUGS

Currently only supports signing of scripts and not modules.

=head1 SEE ALSO

    Crypt::OpenPGP

=head1 AUTHOR

Patrick Mulvany, E<lt>paddy@firedrake.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 Patrick Mulvany All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=cut
