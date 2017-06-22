# -*-cperl-*-
#
# Crypt::HashCash::Coin - HashCash Digital Cash Coin
# Copyright (c) 2001-2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: lib/Crypt/HashCash/Coin.pm v1.124 Mon Jun 19 15:51:59 PDT 2017 $

package Crypt::HashCash::Coin;

use warnings;
use strict;

use Crypt::HashCash qw (_squish _unsquish _hex _dec);
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.124 $' =~ /\s+([\d\.]+)/;

sub as_string {
  my $self = shift;
  my $serialized = join ':', ref $self->z eq 'Crypt::ECDSA::Blind::Signature' ?
    ($self->d,$self->x,$self->z->{'s'},$self->z->{R}) : ($self->d,$self->x,$self->z);
#  my $serialized = ref $self->z eq 'Crypt::ECDSA::Blind::Signature' ?
#    pack('H*',$self->as_hex) : join ':', ($self->d,$self->x,$self->z);
  _squish($serialized);
}

sub from_string {
  my ($class, $str) = @_; $str =~ s/\s*$//;
  return unless my $dump = _unsquish($str);
  my ($D, $X, $s, $R) = split /:/, $dump;
  bless $R ?
    { D => $D, X => $X, Z => bless { s => $s, R => $R }, 'Crypt::ECDSA::Blind::Signature' } :
    { D => $D, X => $X, Z => $s }, 'Crypt::HashCash::Coin';
}

sub as_hex {
  my $self = shift;
  my $hex;
  if (ref $self->z eq 'Crypt::ECDSA::Blind::Signature') {
    my $d = _hex($self->d); $d = '0' x (8 - length($d)) . $d;
    my $x = _hex($self->x); $x = '0' x (32 - length($x)) . $x;
    my $s = $self->z->{'s'}; $s = '0' x (64 - length($s)) . $s;
    my $R = $self->z->{R}; $R = '0' x (66 - length($R)) . $R;
    $hex = "$d$x$s$R";
  }
  else {    # TODO: Make compatble with non-1024-bit RSA
    my $d = _hex($self->d); $d = '0' x (8 - length($d)) . $d;
    my $x = _hex($self->x); $x = '0' x (32 - length($x)) . $x;
    my $z = _hex($self->z); $z = '0' x (256 - length($z)) . $z;
    $hex = "$d$x$z";
  }
  $hex;
}

sub from_hex {
  my ($class, $hex) = @_; $hex =~ s/\s*$//;
  my $coin;
  if (length($hex) == 170) {       # ECDSA Coin
    return unless $hex =~ /^([0-9a-f]{8})([0-9a-f]{32})([0-9a-f]{64})([0-9a-f]{66})$/;
    local $SIG{'__WARN__'} = sub { };
    $coin = bless { D => Math::BaseCnv::dec($1), X => Math::BaseCnv::dec($2),
		    Z => bless { s => $3, R => $4 }, 'Crypt::ECDSA::Blind::Signature' },
		      'Crypt::HashCash::Coin';
  }
  elsif (length($hex) == 296) {    # 1024-bit RSA Coin
    return unless $hex =~ /^([0-9a-f]{8})([0-9a-f]{32})([0-9a-f]{256})$/;
    local $SIG{'__WARN__'} = sub { };
    $coin = bless { D => Math::BaseCnv::dec($1), X => Math::BaseCnv::dec($2), Z => Math::BaseCnv::dec($3) },
      'Crypt::HashCash::Coin';
  }
  $coin;
}

sub is_valid {
  my $self = shift;
  return if $self->d =~ /\D/ or $self->x =~ /\D/;
  return ref $self->z eq 'Crypt::ECDSA::Blind::Signature' ?
    $self->z->is_valid : $self->z !~ /\D/;
}

sub _diag {
  my $self = shift;
  print STDERR @_ if $self->debug;
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(debug)$/x) {
    $self->{"\U$auto"} = shift if (defined $_[0]);
  }
  if ($auto =~ /^(d|x|z|debug)$/x) {
    return $self->{"\U$auto"};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

1;

__END__

=head1 NAME

Crypt::HashCash::Coin - HashCash Digital Cash Coin

=head1 VERSION

 $Revision: 1.124 $
 $Date: Mon Jun 19 15:51:59 PDT 2017 $

=head1 SYNOPSIS

  use Crypt::HashCash::Coin;

  my $coinstr = $coin->as_string;

  my $coin = Crypt::HashCash::Coin->from_string($coinstr);

  my $coinhex = $coin->as_hex;

  my $coin2 = Crypt::HashCash::Coin->from_hex($coinhex);

  print "OK\n" if $coin-is_valid;

=head1 DESCRIPTION

This class provides methods to serialize, deserialize and check the
validity of HashCash coins.

=head1 METHODS

=head2 as_string

Serializes the coin and returns a string representation of it.

=head2 from_string

Creates and returns a Crypt::HashCash::Coin object from the string
provided as the only argument.

=head2 from_hex

=head2 as_hex

=head2 is_valid

Returns true if the coin's instance variable pass basic sanity checks
for a valid coin. This method does not verify the coin's signature.

=head1 SEE ALSO

=head2 L<www.hashcash.com>

=head2 L<Crypt::HashCash>

=head2 L<Crypt::HashCash::Mint>

=head2 L<Crypt::HashCash::Client>

=head2 L<Crypt::HashCash::Vault::Bitcoin>

=head2 L<Business::HashCash>

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-hashcash at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-hashcash at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-HashCash>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::HashCash::Coin

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

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
