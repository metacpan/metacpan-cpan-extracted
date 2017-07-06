# -*-cperl-*-
#
# Crypt::HashCash::Coin::Blinded - Blinded HashCash Digital Cash Coin
# Copyright (c) 2001-2017 Ashish Gulhati <crypt-hashcash at hash.neo.tc>
#
# $Id: lib/Crypt/HashCash/Coin/Blinded.pm v1.126 Sat Jun 24 02:15:18 PDT 2017 $

package Crypt::HashCash::Coin::Blinded;

use warnings;
use strict;

use Crypt::HashCash qw (_dec _hex);
use Compress::Zlib;
use vars qw( $VERSION $AUTOLOAD );

our ( $VERSION ) = '$Revision: 1.126 $' =~ /\s+([\d\.]+)/;

sub from_string {
  my ($class, $str) = @_;
  return if $str =~ /\D/;
  return unless my $hex = _hex($str);
  return unless my $dump = uncompress(pack 'H*',$hex);
  my ($D, $C, $init) = split /:/, $dump;
  bless { D => $D, C => $C, Init => $init },
    'Crypt::HashCash::Coin::Blinded';
}

sub as_string {
  my $self = shift;
  my $dump = "$self->{D}:$self->{C}:$self->{Init}";
  $self->_diag("$dump\n");
  my $bcoinstr = _dec(unpack 'H*', compress($dump));
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

Crypt::HashCash::Coin::Blinded - Blinded HashCash Digital Cash Coin

=head1 VERSION

 $Revision: 1.126 $
 $Date: Sat Jun 24 02:15:18 PDT 2017 $

=head1 SYNOPSIS

  my $bcoinstr = $bcoin->as_string;

  my $bcoin = Crypt::HashCash::Coin::Blinded->from_string($bcoinstr);

=head1 DESCRIPTION

This class provides methods to serialize and deserialize a blinded
HashCash coin.

=head1 METHODS

=head2 as_string

Serializes the blinded coin and returns a string representation of it.

=head2 from_string

Creates and returns a Crypt::HashCash::Coin::Blinded object from the
string provided as the only argument.

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

    perldoc Crypt::HashCash::Coin::Blinded

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

Copyright (c) 2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
