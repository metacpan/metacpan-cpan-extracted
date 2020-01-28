use v5.14;
use warnings;

=head1 NAME

AtteanX::Parser::JSONLD - JSONLD Parser

=head1 VERSION

This document describes AtteanX::Parser::JSONLD version 0.001

=head1 SYNOPSIS

 use Attean;
 my $parser = Attean->get_parser('JSONLD')->new();
 $parser->parse_cb_from_io( $fh );

=head1 DESCRIPTION

This module implements a JSON-LD 1.11 RDF parser for L<Attean>.

=head1 ROLES

This class consumes the following roles:

=over 4

=item * L<Attean::API::MixedStatementParser>

=item * L<Attean::API::AbbreviatingParser>

=item * L<Attean::API::PullParser>

=back

=head1 METHODS

=over 4

=cut

package AtteanX::Parser::JSONLD::Handler {
	use v5.18;
	use autodie;
	use Moo;
	use Attean::RDF;
	use Encode qw(decode_utf8 encode_utf8);
	extends 'JSONLD';
	use namespace::clean;
	
	sub default_graph {
		return iri('tag:gwilliams@cpan.org,2010-01-01:Attean:DEFAULT');
	}

	sub add_quad {
		my $self	= shift;
		my $quad	= shift;
		my $ds		= shift;
		$ds->add_quad($quad);
	}

	sub new_dataset {
		my $self	= shift;
		my $store	= Attean->get_store('Memory')->new();
		return $store;
	}
	
	sub new_triple {
		my $self	= shift;
		foreach my $v (@_) {
			Carp::confess "not a term object" unless (ref($v));
		}
		return triple(@_);
	}
	
	sub new_quad {
		my $self	= shift;
		foreach my $v (@_) {
			unless (ref($v) and $v->does('Attean::API::Term')) {
# 				warn "not a term object: $v";
				return;
			}
		}
		return quad(@_);
	}
	
	sub skolem_prefix {
		my $self	= shift;
		return 'tag:gwilliams@cpan.org,2019-12:JSONLD:skolem:';
	}
	sub new_graphname {
		my $self	= shift;
		my $value	= shift;
		if ($value =~ /^_:(.+)$/) {
			$value	= $self->skolem_prefix() . $1;
		}
		return $self->new_iri($value);
	}

	sub new_iri {
		my $self	= shift;
		return iri(shift);
	}
	
	sub new_blank {
		my $self	= shift;
		return blank(@_);
	}
	
	sub new_lang_literal {
		my $self	= shift;
		my $value	= shift;
		my $lang	= shift;
		return langliteral($value, $lang);
	}
	
	sub canonical_json {
		my $class	= shift;
		my $value	= shift;
		my $j		= JSON->new->utf8->allow_nonref->canonical(1);
		my $v		= $j->decode($value);
		return $j->encode($v);
	}

	sub new_dt_literal {
		my $self	= shift;
		my $value	= shift;
		my $dt		= shift;
		if ($dt eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#JSON') {
			$value	= decode_utf8($self->canonical_json(encode_utf8($value)));
		}
		return dtliteral($value, $dt);
	}
}

package AtteanX::Parser::JSONLD {
	use utf8;
	
	our $VERSION	=  '0.001';

	use Attean;
	use JSON;
	use JSONLD;
	use Moo;
	
=item C<< canonical_media_type >>

Returns the canonical media type for JSON-LD: application/ld+json.

=cut

	sub canonical_media_type { return "application/ld+json" }

=item C<< media_types >>

Returns a list of media types that may be parsed with the JSON-LD parser:
application/ld+json.

=cut

	sub media_types {
		return [qw(application/ld+json)];
	}
	
=item C<< file_extensions >>

Returns a list of file extensions that may be parsed with the parser.

=cut

	sub file_extensions { return [qw(jsonld json)] }
	
	with 'Attean::API::MixedStatementParser';
	with 'Attean::API::AbbreviatingParser';
	with 'Attean::API::PullParser';


=item C<< parse_iter_from_io( $fh ) >>

Returns an iterator of L<Attean::API::Binding> objects that result from parsing
the data read from the L<IO::Handle> object C<< $fh >>.

=cut

	sub parse_iter_from_io {
		my $self	= shift;
		my $fh		= shift;
		my $bytes	= do { local($/); <$fh> };
		return $self->parse_iter_from_bytes($bytes);
	}

=item C<< parse_cb_from_bytes( $data ) >>

Calls the C<< $parser->handler >> function once for each
L<Attean::API::Binding> object that result from parsing
the data read from the UTF-8 encoded byte string C<< $data >>.

=cut

	sub parse_iter_from_bytes {
		my $self	= shift;
		my $bytes	= shift;
		my $j		= JSON->new();
		my $data	= $j->decode($bytes);
		
		my %args;
		if ($self->has_base) {
			$args{base_iri}	= $self->base;
		}
		my $jld		= AtteanX::Parser::JSONLD::Handler->new(%args);
		my $qiter	= $jld->to_rdf($data)->get_quads();

		my $default_graph	= $jld->default_graph();
		my $iter	= Attean::CodeIterator->new(generator => sub {
			my $q	= $qiter->next;
			return unless ($q);
			my $g		= $q->graph;
			my $prefix	= $jld->skolem_prefix();
			if ($g->equals($default_graph)) {
				return $q->as_triple;
			} elsif (substr($g->value, 0, length($prefix)) eq $prefix) {
				my $gb		= $jld->new_blank(substr($g->value, length($prefix)));
				my @terms	= $q->values;
				$terms[3]	= $gb;
				return $jld->new_quad(@terms);
			} else {
				return $q;
			}
		}, item_type => 'Attean::API::TripleOrQuad')->materialize;
		return $iter;
	}
}

1;

__END__

=back

=head1 BUGS

Please report any bugs or feature requests to through the GitHub web interface
at L<https://github.com/kasei/atteanx-parser-jsonld/issues>.

=head1 AUTHOR

Gregory Todd Williams  C<< <gwilliams@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2020--2020 Gregory Todd Williams. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
