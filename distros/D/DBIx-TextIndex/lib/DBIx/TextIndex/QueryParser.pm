package DBIx::TextIndex::QueryParser;

use strict;
use warnings;

our $VERSION = '0.26';

use base qw(DBIx::TextIndex);

use DBIx::TextIndex::Exception;
use Text::Balanced qw(extract_bracketed extract_delimited);

my $QRY = 'DBIx::TextIndex::Exception::Query';

sub new {
    my $pkg = shift;
    my $class = ref($pkg) || $pkg;
    my $self = bless {}, $class;
    my $args = shift || {};
    foreach my $field (keys %$args) {
	$self->{uc($field)} = $args->{$field};
    }
    return $self;
}

sub term_fields {
    my $self = shift;
    return sort { $a cmp $b } keys %{$self->{TERM_FIELDS}};
}

sub parse {
    my $self = shift;
    delete($self->{TERM_FIELDS});
    delete($self->{STOPLISTED_QUERY});
    $self->_parse(@_);
}

sub _parse {
    my $self = shift;
    my $q = shift;
    my @clauses;
    my $term;

    $q =~ s/\s+$//;

    while ($q) {
	my $clause;

	if ($q =~ s/^\s+//) {
	    next;
	}

	if ($q =~ s/^(AND|OR|\&\&|\|\|)\s+//) {
	    $clause->{CONJ} = $1;
	    $clause->{CONJ} = 'AND' if $clause->{CONJ} eq '&&';
	    $clause->{CONJ} = 'OR' if $clause->{CONJ} eq '||';
	}

	if ($q =~ s/^\+//) {
	    $clause->{MODIFIER} = 'AND';
	} elsif ($q =~ s/^(-|NOT|!)\s*//) {
	    $clause->{MODIFIER} = 'NOT';
	} else {
	    $clause->{MODIFIER} = 'OR';
	}

	if ($q =~ s/^(\w+)://) {
	    $clause->{FIELD} = $1;
	    $self->{TERM_FIELDS}->{$clause->{FIELD}}++;
	} else {
	    $self->{TERM_FIELDS}->{__DEFAULT}++;
	}

	if ($q =~ m/^\(/) {
	    my ($extract, $remain) = extract_bracketed($q, "(");
	    unless ($extract) {
		# FIXME: hard coded error message
		throw $QRY( error => 'Open and close parentheses are uneven.');
	    }
	    $q = $remain;
	    $extract =~ s/^\(//;
	    $extract =~ s/\)$//;
	    $clause->{TYPE} = 'QUERY';
	    $clause->{QUERY} = $self->_parse($extract);
	} elsif ($q =~ m/^\"/) {
	    my ($extract, $remain) = extract_delimited($q, '"');
	    unless ($extract) {
		# FIXME: hard coded error message
		throw $QRY( error => 'Quotes must be used in matching pairs.')
	    }
	    $q = $remain;
	    $extract =~ s/^\"//;
	    $extract =~ s/\"$//;
	    $clause->{TYPE} = 'PHRASE';
	    $term = $extract;
	    $clause->{PHRASETERMS} = $self->_parse($extract);
	    if ($q =~ s/^~(\d+)//) {
		$clause->{PROXIMITY} = $1;
	    } else {
		$clause->{PROXIMITY} = 1;
	    }
	} elsif ($q =~ s/^(\S+(?:[\+\-\&\.\@\']|\\\*)\S+)//) {
	    $clause->{TYPE} = 'IMPLICITPHRASE';
	    $term = $1;
	    $term =~ s:\\\*:\*:g;
	    $clause->{PHRASETERMS} =
	     $self->_parse(join(' ', split('[\+\-\&\.\@\'\*]',$term))); # FIXME: check for double characters, which would cause empty phrase terms
	} elsif ($q =~ s/^(\S+)\+//) {
	    $clause->{TYPE} = 'PLURAL';
	    $term = $1;
	} else {
	    $q =~ s/(\S+)//;
	    my $t = $1;
	    if ($t =~ m/[\?\*]/) {
		$clause->{TYPE} = 'WILD';
	    } else {
		$clause->{TYPE} = 'TERM';
	    }
	    $term = $t;
	}
	$clause->{TERM} = $self->_lc_and_unac($term) if $term;
	if ($clause->{TERM}) {
	    next unless $clause->{TERM} =~ m/[a-z0-9]/;
            next if $self->_stoplisted($clause->{TERM});
	}
	push @clauses, $clause;
    }
    my $folded = fold_nested_phrases(\@clauses);
    return $folded;
}

sub fold_nested_phrases {
    my $clauses = shift;
    my @folded;
    foreach my $clause (@$clauses) {
	if ($clause->{TYPE} eq 'PHRASE' ||
	    $clause->{TYPE} eq 'IMPLICITPHRASE') {
	    my @folded_terms;
	    foreach my $phraseterm (@{$clause->{PHRASETERMS}}) {
		if ($phraseterm->{TYPE} eq 'IMPLICITPHRASE') {
		    push @folded_terms,
		        fold_nested_phrases($phraseterm->{PHRASETERMS});
		} else {
		    push @folded_terms, $phraseterm;
		}
	    }
	    $clause->{PHRASETERMS} = \@folded_terms;
	}
	push @folded, $clause;
    }
    return wantarray ? @folded : \@folded;
}

sub stoplisted_query {
    my $self = shift;
    return ref $self->{STOPLISTED_QUERY} eq 'ARRAY' ?
        $self->{STOPLISTED_QUERY} : [];
}

1;
__END__

=head1 NAME

DBIx::TextIndex::QueryParser - Parser for user-supplied query strings


=head1 SYNOPSIS

 use DBIx::TextIndex::QueryParser;

 my $parser = DBIx::TextIndex::QueryParser->new();

 $parser->parse($query_string);


=head1 DESCRIPTION

Used internally by L<DBIx::TextIndex>, see that module's documentation
for the query syntax.

This class should not be used directly by client code.

=head2 Restricted Methods

=over

=item C<fold_nested_phrases>

=item C<new>

=item C<parse>

=item C<term_fields>

=item C<stoplisted_query>

=back

=head1 AUTHOR

Daniel Koch, dkoch@cpan.org.


=head1 COPYRIGHT

Copyright 1997-2007 by Daniel Koch.
All rights reserved.


=head1 LICENSE

This package is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, i.e., under the terms of the "Artistic
License" or the "GNU General Public License".


=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut
