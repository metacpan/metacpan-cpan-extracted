#!/usr/bin/perl

use LiveGeez::Request;
use Convert::Ethiopic::Cstocs;

main:
{
local ( $r ) = LiveGeez::Request->new ( ( 'sysOut' => 'UTF8' ) );

	my ( $c ) = Convert::Ethiopic::Cstocs->new ( $r->{sysIn}, $r->{sysOut} );

	while ( <> ) {
		chop;
		$r->{string} = $_;
		print &$c ($r->{string}), "\n";
		# print $c->conv( $r->{string} );  # this works too...
	}

}


__END__


=head1 NAME

estring -- print date and time in Amharic or Tigrigna with locale options

=head1 SYNOPSIS

  estring.pl
  selam^D


=head1 DESCRIPTION

estring.pl is the Perl analogue of "g2" which comes with the LibEth library.
estring.pl also requires LibEth and the Ethiopic:: module which is itself an
interface to LibEth.  estring.pl does not yet fully emulate the capabilities of
LibEth g2 but that is an eventual goal.  Intended for demonstrative purposes.

=head1 SEE ALSO

perl(1).  Et(3).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=cut
