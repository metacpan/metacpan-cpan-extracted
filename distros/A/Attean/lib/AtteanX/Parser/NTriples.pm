=head1 NAME

AtteanX::Parser::NTriples - N-Triples Parser

=head1 VERSION

This document describes AtteanX::Parser::NTriples version 0.035

=head1 SYNOPSIS

 use Attean;
 my $parser = Attean->get_parser('NTriples')->new();

 # Parse data from a file-handle and handle triples in the 'handler' callback
 $parser->parse_cb_from_io( $fh );
 
 # Parse the given byte-string, and return an iterator of triples
 my $iter = $parser->parse_iter_from_bytes('<http://example.org/subject> <tag:example.org:predicate> "object" .');
 while (my $triple = $iter->next) {
   print $triple->as_string;
 }

=head1 DESCRIPTION

This module implements a parser for the N-Triples format.

=head1 ROLES

This class consumes L<Attean::API::Parser>, L<Attean::API::PullParser>
and <Attean::API::TripleParser>.

=head1 METHODS

=over 4

=item C<< parse_iter_from_io( $fh ) >>

Returns an L<Attean::API::Iterator> that result from parsing the data read from
the L<IO::Handle> object C<< $fh >>.

=item C<< parse_iter_from_bytes( $data ) >>

Returns an L<Attean::API::Iterator> that result from parsing the data read from
the UTF-8 encoded byte string C<< $data >>.

=cut

use v5.14;
use warnings;

package AtteanX::Parser::NTriples 0.035 {
	use utf8;
	
	use Attean;
	use Moo;
	extends 'AtteanX::Parser::NTuples';
	
=item C<< canonical_media_type >>

Returns the canonical media type for N-Triples: application/n-triples.

=cut

	sub canonical_media_type { return "application/n-triples" }

=item C<< media_types >>

Returns a list of media types that may be parsed with the N-Triples parser:
application/n-triples.

=cut

	sub media_types {
		return [qw(application/n-triples)];
	}
	
=item C<< file_extensions >>

Returns a list of file extensions that may be parsed with the parser.

=cut

	sub file_extensions { return [qw(nt)] }

	with 'Attean::API::TripleParser';
	with 'Attean::API::PullParser';
	with 'Attean::API::Parser';
	with 'Attean::API::CDTBlankNodeMappingParser';

	sub _binding {
		my $self	= shift;
		my $nodes	= shift;
		my $lineno	= shift;
		if (scalar(@$nodes) == 3) {
			return Attean::Triple->new(@$nodes);
		} else {
			die qq[Not valid N-Triples data at line $lineno];
		}
	}
}


1;

__END__

=back

=head1 BUGS

Please report any bugs or feature requests to through the GitHub web interface
at L<https://github.com/kasei/perlrdf/issues>.

=head1 AUTHOR

Gregory Todd Williams  C<< <gwilliams@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2014--2022 Gregory Todd Williams. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
