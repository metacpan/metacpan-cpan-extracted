# -*-cperl-*-
#
# Crypt::FDH - Full Domain Hash
# Copyright (c) 2016-2017 Ashish Gulhati <crypt-fdh at hash.neo.tc>
#
# $Id: lib/Crypt/FDH.pm v1.009 Sat Jun 10 00:08:07 PDT 2017 $

use strict;

package Crypt::FDH;

use warnings;
use strict;
use Digest::SHA;

use vars qw( @ISA $VERSION $AUTOLOAD );

BEGIN {
  require Exporter;
  our ( $VERSION ) = '$Revision: 1.009 $' =~ /\s+([\d\.]+)/;
  our @ISA         = qw(Exporter);
  our @EXPORT_OK   = qw(hash hexhash hexdigest fdh);
}

my $VALGOS = 'sha1|sha256';
my %hashsz = ('sha256' => 256, 'sha1' => 160);

sub hash {
  my %args = @_;
  my ($size, $m, $algo) = ($args{Size},$args{Message},$args{Algorithm}||'sha256');
  die "Invalid hash algorithm: $algo" unless $algo =~ /$VALGOS/;
  my $ctx = Digest::SHA->new($algo);
  my $hash; my $n = int($size / $hashsz{$algo});
  die "Hash size does not fit into target size\n"
    unless $n * $hashsz{$algo} == $size; my $hexlen = $size / 4;
  for (0..$n-1) {
    $ctx->add($m.$_);
    $hash .= $ctx->hexdigest;
  }
  return $hash;
}

sub fdh {
  hash @_
}

sub hexhash {
  hash @_
}

sub hexdigest {
  hash @_
}

1; # End of Crypt::FDH

=head1 NAME

Crypt::FDH - Full Domain Hash

=head1 VERSION

 $Revision: 1.009 $
 $Date: Sat Jun 10 00:08:07 PDT 2017 $

=head1 SYNOPSIS

Provides a Full Domain Hash of the input for cryptograhic uses.

    use Crypt::FDH qw (hash);

    my $fdh = hash(Size => 2048, Message => "Hello world!\n", Algorithm => 'SHA256');

=head1 SUBROUTINES

=head2 hash / hexhash / hexdigest / fdh

All of these names are aliases for one subroutine which returns a Full
Domain Hash of the input message, as a hex number.

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-fdh at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-fdh at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-FDH>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::FDH

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-FDH>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-FDH>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-FDH>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-FDH/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016-2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
