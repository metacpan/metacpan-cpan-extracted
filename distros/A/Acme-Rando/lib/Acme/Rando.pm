package Acme::Rando;
$Acme::Rando::VERSION = '0.1';
use strict;
use warnings;

use HTTP::Tiny;
use JSON;

use parent 'Exporter';
our @EXPORT = qw(rando);


  
=head1 NAME

Acme::Rando - Get a Random Star Wars quote

=head1 VERSION

version 0.1

=head1 SYNOPSIS

	use Acme::Rando;

	say rando();

=head1 DESCRIPTION

Exports a function rando() which returns a random star wars quote.  This joke
probably only makes sense to my coworkers.

=cut

sub rando {
	my $res = HTTP::Tiny->new->get('http://www.iheartquotes.com/api/v1/random?source=starwars&format=json');
	
	unless ($res->{success}) {
		return "These aren't the droids you're looking for: $res->{reason}"
	}
	
	my $dat  = JSON::decode_json($res->{content});
	
	return $dat->{quote};
}

=head1 AUTHORS

    Chris Reinhardt
    crein@cpan.org
    
=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
__END__
