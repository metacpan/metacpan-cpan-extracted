package Crypt::Lucifer;
use 5.014002;
use strict;
use warnings;
use Carp;
require Exporter;
use AutoLoader;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.1';
require XSLoader;
XSLoader::load('Crypt::Lucifer', $VERSION);

sub new{
	my $self = bless {}, shift;
	setkey(shift);
	$self;
}
sub set_key{
	setkey($_[1]);
}
sub encrypt(){
	return luc_encrypt($_[1]);
}
sub decrypt(){
	return luc_decrypt($_[1]);
}
1;
__END__
=head1 NAME

Crypt::Lucifer - Perl implementation of the Lucifer encryption algorithm

=head1 SYNOPSIS

  use Crypt::Lucifer;
  $e = new Crypt::Lucifer("the16bytekeyword");     #if key length is less than 16 (bytes) it will be extended by some EOS characters.
  print $e->decrypt($e->encrypt("string of any length"));

=head1 DESCRIPTION

A simple implementation of the Lucifer algorithm, developed by IBM. Here is the description from Wikipedia:

"In cryptography, Lucifer was the name given to several of the earliest civilian block ciphers, developed by Horst Feistel and his colleagues at IBM. Lucifer was a direct precursor to the Data Encryption Standard. One version, alternatively named DTD-1, saw commercial use in the 1970s for electronic banking."


=head2 EXPORT

None by default.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Lucifer_(cipher)>,L<http://www.staff.uni-mainz.de/pommeren/Kryptologie02/Bitblock/2_Feistel/lucifer.c>

=head1 AUTHOR

Sadegh Ahmadzadegan (sadegh <at> cpan.org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Sadegh Ahmadzadegan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
