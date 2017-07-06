# -*-cperl-*-
#
# Crypt::HashCash - HashCash Digital Cash
# Copyright (c) 2001-2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: lib/Crypt/HashCash.pm v1.126 Sat Jun 24 02:15:17 PDT 2017 $

package Crypt::HashCash;

use warnings;
use strict;
use Exporter;
use Compress::Zlib;
use Math::BaseCnv qw (cnv dig diginit);
use vars qw($VERSION @ISA @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT_OK = qw(breakamt changecoin _hex _dec _squish _unsquish _dectob85 _b85todec);

our ( $VERSION ) = '$Revision: 1.126 $' =~ /\s+([\d\.]+)/;

sub breakamt {          # Return denominations of lowest number of coins to make an amount
  my $amt = shift; my %d;
  my %break = ( 1 => [ qw( 1 ) ],
		2 => [ qw( 2 ) ],
		3 => [ qw( 2 1 ) ],
		4 => [ qw( 2 2 ) ],
		5 => [ qw( 5 ) ],
		6 => [ qw( 5 1 ) ],
		7 => [ qw( 5 2 ) ],
		8 => [ qw( 5 2 1 ) ],
		9 => [ qw( 5 2 2 ) ]
	      );
  my @digits = split //, $amt; my $i=-1; my $count = 0;
  for (reverse @digits) {
    $i++;
    next unless $_;
    my @denoms = @{$break{$_}};
    for my $denom (@denoms) {
      $d{$denom*(10**$i)}++;
      $count++;
    }
  }
  return (\%d, $count);
}

sub changecoin {        # Return denominations of change for a specific coin
  my $amt = shift; my %d; my @denoms;
  my %change = ( 2  => [ qw( 1 1 ) ],
		 5  => [ qw( 2 1 1 1 ) ],
		 10 => [ qw( 5 2 1 1 1 ) ],
		 20 => [ qw( 5 5 2 2 1 1 1 1 1 1 ) ],
		 50 => [ qw( 20 10 5 5 2 2 2 1 1 1 1 ) ],
	       );
  if ($amt < 10) {
    @denoms = @{$change{$amt}};
  }
  else {
    $amt =~ /^(..)(0*)$/;
    my $digits = $1; my $zeros = $2;
    @denoms = map { $_ . $zeros } @{$change{$digits}};
  }
  my $count;
  for my $denom (@denoms) {
    $d{$denom}++;
    $count++;
  }
  return (\%d, $count);
}

sub _hex {
  my $dec = shift;
  local $SIG{'__WARN__'} = sub { };
  my $hex = Math::BaseCnv::heX($dec);
  $hex =~ tr/A-F/a-f/; $hex =~ s/^ff//;
  $hex;
}

sub _dec {
  my $hex = shift;
  $hex = 'ff' . $hex;     # So we don't lose leading 0s
  local $SIG{'__WARN__'} = sub { };
  Math::BaseCnv::dec($hex);
}

sub _squish {
  my $str = shift; #print "U: $str\n";
  my $dec = _dec(unpack 'H*', compress($str));
  $dec;
}

sub _unsquish {
  my $str = shift;
  return if $str =~ /\D/;
  return unless my $hex = _hex($str);
  uncompress(pack 'H*',$hex);
}

sub _dectob85 {
  my $dec = shift;
  dig('b85');
  $dec = '9' . $dec;     # So we don't lose leading 0s
  local $SIG{'__WARN__'} = sub { };
  cnv ($dec, 10, 85);
}

sub _b85todec {
  my $base85 = shift;
  dig('b85');
  local $SIG{'__WARN__'} = sub { };
  my $dec = cnv ($base85, 85, 10);
  $dec =~ s/^9//;
  $dec;
}

sub _hextob32 {
  my $hex = shift;
  dig( [ qw( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 2 3 4 6 7 9 0 1 5 8 ) ] );
  $hex =~ tr/0-9a-f/A-P/;
  $hex = 'ff' . $hex;     # So we don't lose leading 0s
  $hex =~ tr/0-9a-f/A-P/;
  local $SIG{'__WARN__'} = sub { };
  cnv ($hex, 16, 32);
}

sub _b32tohex {
  my $base32 = shift;
  dig( [ qw( A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 2 3 4 6 7 9 0 1 5 8 ) ] );
  local $SIG{'__WARN__'} = sub { };
  my $hex = cnv ($base32, 32, 16);
  $hex =~ tr/A-P/0-9a-f/; $hex =~ s/^ff//;
  return $hex;
}

1; # End of Crypt::HashCash

=head1 NAME

Crypt::HashCash - HashCash Digital Cash

=head1 VERSION

 $Revision: 1.126 $
 $Date: Sat Jun 24 02:15:17 PDT 2017 $

=head1 SYNOPSIS

HashCash is a digital cash system based on blind signatures, as
introduced by David Chaum in [1].

HashCash features a number of optimizations for usability and
accessibility, including blind ECDSA signatures which make for more
compact coins than blind RSA, and a simple protocol that enables the
system to work in a permissionless manner, requiring no user accounts
or registration.

The main components of HashCash are: one or more vaults, which issue
and verify HashCash coins; the coins themselves; and wallets, which
hold and manage coins owned by users.

HashCash coins are blind-signed by a vault and represent specific
denominations of some value stored by the vault. They are bearer
tokens which can be passed directly from one user to another, and
cannot be tracked by the vault.

HashCash coins could be backed by any store of value, some
possibilities being precious metals, fiat currencies, gift cards,
etc. The distribution includes an implementation of a vault for
Bitcoin, which issues HashCash coins backed by Bitcoin.

All messages between wallets and vaults are encrypted, so there's no
need for a secure communications channel between them.

=head1 HOW TO USE

To begin with, the keys and configuration details of one or more
vaults (in the form of vault configuration files) need to be placed in
the "~/.hashcash/vaults" directory (or "$HASHCASHDIR/.hashcash/vaults"
if the HASHCASHDIR environment variable is set).

As there are no live public vaults at this time, and the software is
in early beta testing, to try the system you can run a local vault
yourself. After installing the HashCash distribution, run the command:

    vault.pl

This will generate vault keys on its first run. Wait for key
generation to complete before starting the wallet, so the vault
configuration file is in place for the wallet.

Once the vault has completed key generation, start the wallet with:

    hashcash.pl

Then you can buy or sell HashCash, export coins from your wallet to
give to others, or import coins received from others into your
wallet. You can also exchange coins for lower denominations, and
verify coins you've imported into the wallet.

For more details on testing with a local vault, see the Download page
on the website: L<http://www.hashcash.com/download.html>. Pre-built
executables for popular OSes are also available from that page.

HashCash coins can be sent to others over any communications channel -
email, web, instant messaging, SMS, directly by scanning a QR
code. They could even be printed on paper and used just like normal
paper currency, though with a higher level of security and privacy.

It's easy to automate the acceptance of HashCash payments on a website
(or via email or any other communications channel) using the
L<Business::HashCash> module.

It's also quite straightforward, from a technical standpoint, to start
a HashCash vault, which could be quite a profitable automated business
requiring minimal ongoing time investment. For more details on this
visit the website: L<http://www.hashcash.com>.

=head1 FUNCTIONS

The Crypt::HashCash module contains a few helper functions. Most of
the actual implementation of the system is in other modules, listed in
the SEE ALSO section below.

=head2 breakamt

Accepts a single parameter which is an amount to break into coins, and
returns the denominations of the minimum number of coins that total up
to this amount, as well as the total number of coins. The coin
denominations are returned as a hash whose keys are the coin
denominations and values are the number of coins of the corresponding
denomination.

=head2 changecoin

Accepts a single parameter which is the denomination of a coin to get
change for, and returns the denominations of the change coins, as well
as the total number of coins. The denominations are returned in a
hash, as described above, followed by the total number of coins.

=head1 SEE ALSO

=head2 L<http://www.hashcash.com>

=head2 L<Crypt::HashCash::Mint>

=head2 L<Crypt::HashCash::Client>

=head2 L<Crypt::HashCash::Coin>

=head2 L<Crypt::HashCash::Vault::Bitcoin>

=head2 L<Business::HashCash>

=head1 REFERENCES

1. Blind Signatures For Untraceable Payments, David Chaum.
L<http://www.hit.bme.hu/~buttyan/courses/BMEVIHIM219/2009/Chaum.BlindSigForPayment.1982.PDF>

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-hashcash at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-hashcash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-HashCash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::HashCash

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-HashCash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-HashCash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-HashCash>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-HashCash/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2001-2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See L<http://www.perlfoundation.org/artistic_license_2_0> for the full
license terms.
