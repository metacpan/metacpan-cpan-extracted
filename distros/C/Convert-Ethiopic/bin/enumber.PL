#!/usr/bin/perl

use LiveGeez::Request;
use Convert::Ethiopic::Cstocs;

main:
{
local ( %input ) = ( '0' => 'nothing', 'sysOut' => 'UTF8' );
local ( $r )     = LiveGeez::Request->new ( \%input );

	undef ( %input );

	while ( <> ) {
		chop;
		$r->{number} = $_;
		print "$r->{number} = ", EthiopicNumber ( $r ), "\n";
	}

}


__END__


=head1 NAME

enumber -- convert numbers from English to Ethiopic

=head1 SYNOPSIS

  edate.pl
  1991^D


=head1 DESCRIPTION

enumber.pl is a simple tool to read numbers from standard input and convert
them into their representation in the Ethiopic numeral system.  enumber.pl
also requires LibEth and the Ethiopic:: module which is itself an interface to
LibEth.  Intended for demonstrative purposes.

=head1 SEE ALSO

perl(1).  Et(3).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=cut
