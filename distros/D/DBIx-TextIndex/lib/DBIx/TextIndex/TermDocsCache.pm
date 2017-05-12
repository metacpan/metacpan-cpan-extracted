package DBIx::TextIndex::TermDocsCache;

use strict;
use warnings;

our $VERSION = '0.26';

use Bit::Vector;

use base qw(DBIx::TextIndex);

sub new {
    my $pkg = shift;
    my $class = ref($pkg) || $pkg;
    my $self = bless {}, $class;
    my $args = shift;
    $self->set($args) if $args;
    return $self;
}

sub max_indexed_id {
    my $self = shift;
    if (@_) {
	$self->flush_all;
	$self->{MAX_INDEXED_ID} = $_[0];
    }
    return $self->{MAX_INDEXED_ID};
}

sub flush_all {
    my $self = shift;
    $self->flush_bit_vectors;
    $self->flush_term_docs;
}

sub flush_bit_vectors {
    my $self = shift;
    delete($self->{VECTOR});
}

sub flush_term_docs {
    my $self = shift;
    delete($self->{TERM_DOCS});
    delete($self->{DOCFREQ_T});
}

sub term_pos {
    my $self = shift;
    my ($fno, $term) = @_;
    $self->_fetch_term_pos($fno, $term) unless exists $self->{TERM_POS}->[$fno]->{$term};
    return $self->{TERM_POS}->[$fno]->{$term};
}

sub term_docs {
    my $self = shift;
    my ($fno, $term) = @_;
    $self->_fetch_term_docs($fno, $term) unless exists $self->{TERM_DOCS}->[$fno]->{$term};
    return $self->{TERM_DOCS}->[$fno]->{$term};
}

sub term_docs_hashref {
    my $self = shift;
    my ($fno, $term) = @_;
    $self->_fetch_term_docs($fno, $term) unless exists $self->{TERM_DOCS}->[$fno]->{$term};
    return DBIx::TextIndex::term_docs_hashref($self->{TERM_DOCS}->[$fno]->{$term});

}

sub term_docs_arrayref {
    my $self = shift;
    my ($fno, $term) = @_;
    $self->_fetch_term_docs($fno, $term) unless exists $self->{TERM_DOCS}->[$fno]->{$term};
    return DBIx::TextIndex::term_docs_arrayref($self->{TERM_DOCS}->[$fno]->{$term});
}

sub term_doc_ids_arrayref {
    no warnings qw(uninitialized);
    my $self = shift;
    my ($fno, $term) = @_;
    $self->_fetch_term_docs($fno, $term) unless exists $self->{TERM_DOCS}->[$fno]->{$term};
    return DBIx::TextIndex::term_doc_ids_arrayref($self->{TERM_DOCS}->[$fno]->{$term});
}

sub vector {
    my $self = shift;
    my ($fno, $term) = @_;
    if ($self->{VECTOR}->[$fno]->{$term}) {
	return $self->{VECTOR}->[$fno]->{$term};
    }
    my $doc_ids = $self->term_doc_ids_arrayref($fno, $term);
    my $vector = Bit::Vector->new($self->{MAX_INDEXED_ID} + 1);
    $vector->Index_List_Store(@$doc_ids);
    $self->{VECTOR}->[$fno]->{$term} = $vector;
    return $vector;
}

sub f_t {
    my $self = shift;
    my ($fno, $term) = @_;
    $self->_fetch_term_docs($fno, $term)
	unless exists $self->{DOCFREQ_T}->[$fno]->{$term};
    return $self->{DOCFREQ_T}->[$fno]->{$term};
}

sub _fetch_term_pos {
    my $self = shift;
    my ($fno, $term) = @_;
    my $sql =
	$self->{DB}->fetch_term_pos($self->{INVERTED_TABLES}->[$fno]);

    ($self->{TERM_POS}->[$fno]->{$term})
	= $self->{INDEX_DBH}->selectrow_array($sql, undef, $term);
}

sub _fetch_term_docs {
    my $self = shift;
    my ($fno, $term) = @_;
    my $sql = $self->{DB}->fetch_term_freq_and_docs(
                $self->{INVERTED_TABLES}->[$fno]);

    ($self->{DOCFREQ_T}->[$fno]->{$term}, $self->{TERM_DOCS}->[$fno]->{$term})
	= $self->{INDEX_DBH}->selectrow_array($sql, undef, $term);
}

__END__

=head1 NAME

DBIx::TextIndex::TermDocsCache - Cache object for term-documents vectors


=head1 SYNOPSIS

 use DBIx::TextIndex::TermDocsCache;

 my $cache = DBIx::TextIndex::TermDocsCache->new((
     db => $database_name,
     index_dbh => $dbh,
     max_indexed_id => $max_indexed_id,
     inverted_tables => \@table_names,
 });


=head1 DESCRIPTION

Used internally by L<DBIx::TextIndex>. For each term (word) in the
inverted index, a list of documents containing that term is
stored. This class caches reads of these term-documents vectors in
memory.

This class should not be used directly by client code.

=head2 Restricted Methods

=over

=item C<f_t>

=item C<flush_all>

=item C<flush_bit_vectors>

=item C<flush_term_docs>

=item C<max_indexed_id>

=item C<new>

=item C<term_doc_ids_arrayref>

=item C<term_docs>

=item C<term_docs_arrayref>

=item C<term_docs_hashref>

=item C<term_pos>

=item C<vector>

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
