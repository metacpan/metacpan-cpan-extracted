package DBIx::TextIndex::DBD::Pg;

use strict;
use warnings;

our $VERSION = '0.26';

use DBD::Pg;
use base qw(DBIx::TextIndex::DBD);

sub add_mask {
    my $self = shift;
    my ($mask, $vector_enum) = @_;
    my $sql = <<END;
DELETE FROM $self->{MASK_TABLE} where mask = ?;
INSERT into $self->{MASK_TABLE} (mask, docs_vector) values (?, ?)
END

    $self->{INDEX_DBH}->do($sql, undef, $mask, $mask, $vector_enum);
}

sub create_collection_table {
    my $self = shift;
    my $collection_length = DBIx::TextIndex::COLLECTION_NAME_MAX_LENGTH;
    return <<END;
CREATE TABLE collection (
  collection varchar($collection_length) PRIMARY KEY default '',
  version numeric(10,2) NOT NULL default 0.00,
  max_indexed_id int NOT NULL default 0,
  doc_table varchar(30),
  doc_id_field varchar(30),
  doc_fields varchar(250) NOT NULL default '',
  charset varchar(50) NOT NULL default '',
  stoplist varchar(255) NOT NULL default '',
  proximity_index varchar(1) NOT NULL default '0',
  error_empty_query varchar(255) NOT NULL default '',
  error_quote_count varchar(255) NOT NULL default '',
  error_no_results varchar(255) NOT NULL default '',
  error_no_results_stop varchar(255) NOT NULL default '',
  error_wildcard_length varchar(255) NOT NULL default '',
  error_wildcard_expansion varchar(255) NOT NULL default '',
  max_word_length int NOT NULL default 0,
  result_threshold int NOT NULL default 0,
  phrase_threshold int NOT NULL default 0,
  min_wildcard_length int NOT NULL default 0,
  max_wildcard_term_expansion int NOT NULL default 0,
  decode_html_entities varchar(1) NOT NULL default '0',
  scoring_method varchar(20) NOT NULL default '',
  update_commit_interval int NOT NULL default 0
)
END

}

sub update_all_docs_vector {
    my $self = shift;
    return <<END;
DELETE FROM $self->{ALL_DOCS_VECTOR_TABLE} WHERE id = 1;
INSERT INTO $self->{ALL_DOCS_VECTOR_TABLE}
(id, all_docs_vector)
VALUES (1, ?)
END
}

sub update_docweights {
    my $self = shift;

    return <<END;
DELETE FROM $self->{DOCWEIGHTS_TABLE} WHERE field_no = ?;
INSERT into $self->{DOCWEIGHTS_TABLE} (field_no, avg_docweight, docweights) values (?, ?, ?)
END

}

sub update_docweights_execute {
    my $self = shift;
    my ($sth, $fno, $avg_w_d, $packed_w_d) = @_;
    $sth->bind_param( 1, $fno );
    $sth->bind_param( 2, $fno );
    $sth->bind_param( 3, $avg_w_d );
    $sth->bind_param( 4, $packed_w_d, { pg_type => DBD::Pg::PG_BYTEA } );
    $sth->execute();
}

sub update_delete_queue {
    my $self = shift;
    my $delete_queue = shift;
    $self->{INDEX_DBH}->do(<<END, undef, 1, $delete_queue, 1);
DELETE FROM $self->{DELETE_QUEUE_TABLE} WHERE id = ?;
INSERT INTO $self->{DELETE_QUEUE_TABLE} (delete_queue, id)
VALUES (?, ?)
END

}

sub inverted_replace {
    my $self = shift;
    my $table = shift;

    return <<END;
DELETE FROM $table WHERE term = ?;
INSERT into $table
(term, docfreq_t, term_docs, term_pos)
values (?, ?, ?, ?)
END

}

sub inverted_replace_execute {
    my $self = shift;
    my ($sth, $term, $docfreq_t, $term_docs, $term_pos) = @_;

    $sth->bind_param( 1, $term );
    $sth->bind_param( 2, $term );
    $sth->bind_param( 3, $docfreq_t );
    $sth->bind_param( 4, $term_docs, { pg_type => DBD::Pg::PG_BYTEA } );
    $sth->bind_param( 5, $term_pos, { pg_type => DBD::Pg::PG_BYTEA } );
    $sth->execute() or warn $self->{INDEX_DBH}->err;
}

sub insert_doc_key {
    my $self = shift;
    my $doc_key = shift;

    my $sql = <<END;
INSERT INTO $self->{DOC_KEY_TABLE} (doc_key) VALUES (?)
END

    $self->{INDEX_DBH}->do($sql, undef, $doc_key);

    my ($doc_id) = $self->{INDEX_DBH}->selectrow_array(<<END);
SELECT CURRVAL('$self->{DOC_KEY_TABLE}_doc_id_seq')
END

    return $doc_id;
}

sub create_mask_table {
    my $self = shift;

    return <<END;
CREATE TABLE $self->{MASK_TABLE} (
  mask             varchar(100)    PRIMARY KEY,
  docs_vector text 	           NOT NULL
);
END

}

sub create_docweights_table {
    my $self = shift;
    return <<END;
CREATE TABLE $self->{DOCWEIGHTS_TABLE} (
  field_no 	   integer 	           PRIMARY KEY,
  avg_docweight    float                   NOT NULL,
  docweights 	   bytea 		   NOT NULL
)
END
}

sub create_all_docs_vector_table {
    my $self = shift;

    return <<END;
CREATE TABLE $self->{ALL_DOCS_VECTOR_TABLE} (
  id               integer               PRIMARY KEY,
  all_docs_vector  text              NOT NULL
)
END
}

sub create_delete_queue_table {
    my $self = shift;

    return <<END;
CREATE TABLE $self->{DELETE_QUEUE_TABLE} (
  id                   integer            PRIMARY KEY,
  delete_queue         text              NOT NULL
)
END
}

sub create_inverted_table {
    my $self = shift;
    my $table = shift;
    my $max_word = $self->{MAX_WORD_LENGTH};

    return <<END;
CREATE TABLE $table (
  term             varchar($max_word)      PRIMARY KEY,
  docfreq_t 	   int                     NOT NULL,
  term_docs	   bytea 		   NOT NULL,
  term_pos         bytea                   NOT NULL
)
END

}

sub create_doc_key_table {
    my $self = shift;
    my $doc_key_sql_type = $self->{DOC_KEY_SQL_TYPE};
    $doc_key_sql_type .= "($self->{DOC_KEY_LENGTH})"
	if $self->{DOC_KEY_LENGTH}; 
    my $sequence = "$self->{DOC_KEY_TABLE}_doc_id_seq";

    return <<END;
CREATE SEQUENCE $sequence;
CREATE TABLE $self->{DOC_KEY_TABLE} (
  doc_id           bigint DEFAULT nextval('$sequence'),
  doc_key          $doc_key_sql_type  NOT NULL,
  CONSTRAINT pk_$self->{DOC_KEY_TABLE}_doc_id PRIMARY KEY (doc_id),
  CONSTRAINT uniq_$self->{DOC_KEY_TABLE}_doc_key UNIQUE (doc_key)
)
END

}

sub drop_doc_key_table {
    my $self = shift;
    if ($self->drop_table($self->{DOC_KEY_TABLE})) {
	$self->{INDEX_DBH}->do(
	    qq(DROP SEQUENCE $self->{DOC_KEY_TABLE}_doc_id_seq) );
    }
}

1;
__END__

=head1 NAME

DBIx::TextIndex::DBD::Pg - Driver for PostgreSQL

=head1 SYNOPSIS

 require DBIx::TextIndex::DBD::Pg;

=head1 DESCRIPTION

Contains PostgreSQL-specific overrides for methods of
L<DBIx::TextIndex::DBD>.

Used internally by L<DBIx::TextIndex>.


=head1 INTERFACE

=head2 Restricted Methods

=over

=item C<add_mask>

=item C<create_collection_table>

=item C<update_all_docs_vector>

=item C<update_docweights>

=item C<update_docweights_execute>

=item C<update_delete_queue>

=item C<inverted_replace>

=item C<inverted_replace_execute>

=item C<insert_doc_key>

=item C<create_mask_table>

=item C<create_docweights_table>

=item C<create_all_docs_vector_table>

=item C<create_delete_queue_table>

=item C<create_inverted_table>

=item C<create_doc_key_table>

=item C<drop_doc_key_table>

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
