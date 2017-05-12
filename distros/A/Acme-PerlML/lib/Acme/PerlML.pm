package Acme::PerlML;

use 5.005;
use strict;
use PPI;
use Perl::SAX;
use XML::Parser::PerlSAX;
use base qw(XML::SAX::Base);

use vars qw{$VERSION $CODE};
BEGIN {
	$VERSION = '1.00';
	$CODE    = '';
}

sub new {
	return bless {@_[1 .. $#_]}, $_[0];
}

sub characters {
	$CODE .= $_[1]->{Data};
}

sub xml2code {
	XML::Parser::PerlSAX->new(
		Handler => Acme::PerlML->new
		)->parse($_[0]);
	return $CODE;
}

sub code2xml {
	my $Document = PPI::Document->new(\$_[0]);
	my $SAX      = Perl::SAX->new;
	$SAX->parse( $Document );
  	return ${ $SAX->{Output} };
}

# Allow people to use Acme::PerlML () sanely
sub import {
	## This code isn't Acme::Bleach evil yet as that would be teh hard to debug
	open 0 or die "Couldn't open $0: $!";
	(my $code = join "", <0>) =~ s/(.*)^\s*use\s+Acme::PerlML\s*;\n//sm;

	# Already converted
	if ( $code =~ /^<document>/m ) {
		eval xml2code($code);
		exit();
	}

	my $xml = code2xml($code) or die "Failed to convert Perl to XML";
	no strict 'refs';
	open 0, ">$0" or die "Cannot make the switch for '$0' : $!\n";
	print {0} "$1\nuse Acme::PerlML;\n" . $xml;
}

1;

__END__

=pod

=head1 NAME

Acme::PerlML - Replaces your ugly Perl code with powerful XML

=head1 SYNOPSIS

  use Acme::PerlML;
  
  print "Hello World!\n";

=head1 DESCRIPTION

C<Acme::PerlML> is a member of the L<Acme::Bleach> family of modules.

The first time you run your program, it takes your ugly Perl code and
replaces it with powerful and sophisticated XML, the choice of...
well... 1998 to... erm... 2002... ish. :/

The code continues to work exactly as it did before, but now it looks
like this:

=head1 SEE ALSO

L<Acme::Bleach>, L<Acme::Pony>, L<PPI>, L<Perl::SAX>, L<http://ali.as/>

=head1 AUTHOR

Original code by Dan Brooks

Refactored, documented and released by Adam Kennedy

=head1 COPYRIGHT

Copyright 2005 - 2006 Dan Brooks and Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
