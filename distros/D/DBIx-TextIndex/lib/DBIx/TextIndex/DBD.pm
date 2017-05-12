package DBIx::TextIndex::DBD;

use strict;
use warnings;

our $VERSION = '0.26';

use base qw(DBIx::TextIndex);

my @FIELDS = qw(
		all_docs_vector_table
		collection_fields
		collection_table
		doc_fields
		doc_id_field
		doc_table
		docweights_table
		mask_table
		max_word_length
		doc_key_sql_type
		doc_key_length
		);

BEGIN { DBIx::TextIndex::create_accessors(\@FIELDS); }

sub new {
    my $pkg = shift;
    my $class = ref($pkg) || $pkg;
    my $self = bless {}, $class;
    my $args = shift;
    $self->set($args) if $args;
    return $self;
}

sub drop_table {
    my $self = shift;
    my $table = shift;
    if ($self->table_exists($table)) {
	$self->{INDEX_DBH}->do("DROP TABLE $table");
	return 1;
    } else {
	return 0;
    }
}

sub table_exists {
    my $self = shift;
    my $table = shift;
    my @tables = $self->{INDEX_DBH}->tables(undef, undef, $table, 'table');
    for (@tables) {
	return 1 if m/^.*\.?[\"\`]?$table[\"\`]?$/;
    }
    return 0;
}

sub delete_mask {
    my $self = shift;
    return <<END;
DELETE FROM $self->{MASK_TABLE}
WHERE mask = ?
END

}

sub add_mask {
    my $self = shift;
    my ($mask, $vector_enum) = @_;
    my $sql = <<END;
REPLACE INTO $self->{MASK_TABLE} (mask, docs_vector)
VALUES (?, ?)
END
    $self->{INDEX_DBH}->do($sql, undef, $mask, $vector_enum);
}

sub create_collection_table {
    my $self = shift;
    my $collection_length = DBIx::TextIndex::COLLECTION_NAME_MAX_LENGTH;
    return <<END;
CREATE TABLE collection (
  collection varchar($collection_length) NOT NULL default '',
  version decimal(10,2) NOT NULL default '0.00',
  max_indexed_id int(10) unsigned NOT NULL default '0',
  doc_table varchar(30),
  doc_id_field varchar(30),
  doc_fields varchar(250) NOT NULL default '',
  charset varchar(50) NOT NULL default '',
  stoplist varchar(255) NOT NULL default '',
  proximity_index enum('0', '1') NOT NULL default '0',
  error_empty_query varchar(255) NOT NULL default '',
  error_quote_count varchar(255) NOT NULL default '',
  error_no_results varchar(255) NOT NULL default '',
  error_no_results_stop varchar(255) NOT NULL default '',
  error_wildcard_length varchar(255) NOT NULL default '',
  error_wildcard_expansion varchar(255) NOT NULL default '',
  max_word_length int(10) unsigned NOT NULL default '0',
  result_threshold int(10) unsigned NOT NULL default '0',
  phrase_threshold int(10) unsigned NOT NULL default '0',
  min_wildcard_length int(10) unsigned NOT NULL default '0',
  max_wildcard_term_expansion int(10) unsigned NOT NULL default '0',
  decode_html_entities enum('0', '1') NOT NULL default '0',
  scoring_method varchar(20) NOT NULL default '',
  update_commit_interval int(10) unsigned NOT NULL default '0',
  PRIMARY KEY collection_key (collection)
)
END

}

sub insert_collection_table_row {
    my $self = shift;
    my $row = shift;
    my @fields;
    my @values;
    while (my ($field, $value) = each %$row) {
	push @fields, $field;
	push @values, $value;
    }
    my $collection_fields = join ', ', @fields;
    my $place_holders = join ', ', (('?') x ($#fields + 1)); 
    my $sql = <<END;
INSERT INTO $self->{COLLECTION_TABLE}
($collection_fields)
VALUES ($place_holders)
END
    $self->{INDEX_DBH}->do($sql, undef, @values);

}

sub fetch_doc_id {
    my $self = shift;
    my $doc_key = shift;

    my $sql = <<END;
SELECT doc_id
FROM $self->{DOC_KEY_TABLE}
WHERE doc_key = ?
END

    my ($doc_id) = $self->{INDEX_DBH}->selectrow_array($sql, undef, $doc_key);
    return $doc_id ? $doc_id : undef;
}

sub fetch_doc_ids {
    my $self = shift;
    my $doc_keys = shift;

    my $placeholders = join(',', (('?') x ($#$doc_keys +1)));
    my $sql = <<END;
SELECT doc_id
FROM $self->{DOC_KEY_TABLE}
WHERE doc_key in ($placeholders) order by doc_id
END

    my $doc_ids = $self->{INDEX_DBH}->selectcol_arrayref($sql, undef,
							 @$doc_keys);

    return $doc_ids;
}

sub fetch_doc_keys {
    my $self = shift;
    my $doc_ids = shift;

    my $placeholders = join(',', (('?') x ($#$doc_ids +1)));
    my $sql = <<END;
SELECT doc_key
FROM $self->{DOC_KEY_TABLE}
WHERE doc_id in ($placeholders) order by doc_id
END

    my $doc_keys = $self->{INDEX_DBH}->selectcol_arrayref($sql, undef,
							  @$doc_ids);

    return $doc_keys;
}

sub delete_doc_key_doc_ids {
    my $self = shift;
    my $doc_ids = shift;

    my $placeholders = join(',', (('?') x ($#$doc_ids +1)));
    my $sql = <<END;
DELETE FROM $self->{DOC_KEY_TABLE}
WHERE doc_id in ($placeholders)
END

    $self->{INDEX_DBH}->do($sql, undef, @$doc_ids);

}

sub insert_doc_key {
    my $self = shift;
    my $doc_key = shift;

    my $sql = <<END;
INSERT INTO $self->{DOC_KEY_TABLE} (doc_key) VALUES (?)
END

    $self->{INDEX_DBH}->do($sql, undef, $doc_key);
    my $doc_id = $self->{INDEX_DBH}->last_insert_id(undef, undef,
				       $self->{DOC_KEY_TABLE}, undef);
    return $doc_id;
}

sub fetch_max_indexed_id {
    my $self = shift;

    return <<END;
SELECT max_indexed_id
FROM $self->{COLLECTION_TABLE}
WHERE collection = ?
END

}

sub fetch_collection_version {
    my $self = shift;

    return <<END;
SELECT MAX(version) FROM $self->{COLLECTION_TABLE}
END

}

sub collection_count {
    my $self = shift;

    return <<END;
SELECT COUNT(*) FROM $self->{COLLECTION_TABLE}
END

}

sub update_collection_info {
    my $self = shift;
    my $field = shift;

    return <<END;
UPDATE $self->{COLLECTION_TABLE}
SET $field = ?
WHERE collection = ?
END

}

sub delete_collection_info {
    my $self = shift;

    return <<END;
DELETE FROM $self->{COLLECTION_TABLE}
WHERE collection = ?
END

}

sub store_collection_info {
    my $self = shift;

    my @collection_fields = @{$self->{COLLECTION_FIELDS}};
    my $collection_fields = join ', ', @collection_fields;
    my $place_holders = join ', ', (('?') x ($#collection_fields + 1)); 
    return <<END;
INSERT INTO $self->{COLLECTION_TABLE}
($collection_fields)
VALUES
($place_holders)
END

}

sub fetch_collection_info {
    my $self = shift;

    my $collection_fields = join ', ', @{$self->{COLLECTION_FIELDS}};

    return <<END;
SELECT
$collection_fields
FROM $self->{COLLECTION_TABLE}
WHERE collection = ?
END

}

sub fetch_all_collection_rows {
    my $self = shift;

    return <<END;
SELECT * FROM $self->{COLLECTION_TABLE}
END

}

sub phrase_scan_cz {
    my $self = shift;
    my $result_docs = shift;
    my $fno = shift;

    return <<END;
SELECT $self->{DOC_ID_FIELD}, $self->{DOC_FIELDS}->[$fno]
FROM   $self->{DOC_TABLE}
WHERE  $self->{DOC_ID_FIELD} IN ($result_docs)
END

}

sub phrase_scan {
    my $self = shift;
    my $result_docs = shift;
    my $fno = shift;

    return <<END;
SELECT $self->{DOC_ID_FIELD}
FROM   $self->{DOC_TABLE}
WHERE  $self->{DOC_ID_FIELD} IN ($result_docs)
       AND $self->{DOC_FIELDS}->[$fno] LIKE ?
END

}

sub fetch_docweights {
    my $self = shift;
    my $fields = shift;

    return <<END;
SELECT field_no, avg_docweight, docweights
FROM $self->{DOCWEIGHTS_TABLE}
WHERE field_no in ($fields)
END

}

sub fetch_all_docs_vector {
    my $self = shift;
    return <<END;
SELECT all_docs_vector
FROM $self->{ALL_DOCS_VECTOR_TABLE}
END

}

sub update_all_docs_vector {
    my $self = shift;
    return <<END;
REPLACE INTO $self->{ALL_DOCS_VECTOR_TABLE}
(id, all_docs_vector)
VALUES (1, ?)
END
}

sub fetch_mask {
    my $self = shift;

    return <<END;
SELECT docs_vector
FROM $self->{MASK_TABLE}
WHERE mask = ?
END

}

sub fetch_term_pos {
    my $self = shift;
    my $table = shift;

    return <<END;
SELECT term_pos
FROM $table
WHERE term = ?
END

}

sub fetch_term_docs {
    my $self = shift;
    my $table = shift;

    return <<END;
SELECT term_docs
FROM $table
WHERE term = ?
END

}

sub fetch_term_freq_and_docs {
    my $self = shift;
    my $table = shift;
    return <<END;
select docfreq_t, term_docs
from $table
where term = ?
END

}

sub fetch_terms {
    my $self = shift;
    my $table = shift;

    return <<END;
SELECT term
FROM $table
WHERE term LIKE ?
END

}

sub ping_doc {
    my $self = shift;

    return <<END;
SELECT 1
FROM $self->{DOC_TABLE}
WHERE $self->{DOC_ID_FIELD} = ?
END

}

sub fetch_doc {
    my $self = shift;
    my $field = shift;

    return <<END;
SELECT $field
FROM $self->{DOC_TABLE}
WHERE $self->{DOC_ID_FIELD} = ?
END

}

sub fetch_doc_all_fields {
    my $self = shift;
    my $fields = join(', ', @{$self->{DOC_FIELDS}});

    return <<END;
SELECT $fields
FROM $self->{DOC_TABLE}
WHERE $self->{DOC_ID_FIELD} = ?
END

}

sub update_docweights {
    my $self = shift;

    return <<END;
REPLACE INTO $self->{DOCWEIGHTS_TABLE} (field_no, avg_docweight, docweights)
VALUES (?, ?, ?)
END

}

sub update_docweights_execute {
    my $self = shift;
    my ($sth, $fno, $avg_w_d, $packed_w_d) = @_;
    $sth->execute($fno, $avg_w_d, $packed_w_d);
}

sub inverted_replace {
    my $self = shift;
    my $table = shift;

    return <<END;
REPLACE INTO $table
(term, docfreq_t, term_docs, term_pos)
VALUES (?, ?, ?, ?)
END

}

sub fetch_delete_queue {
    my $self = shift;

    my ($delete_queue) = $self->{INDEX_DBH}->selectrow_array(<<END, undef, 1);
SELECT delete_queue
FROM $self->{DELETE_QUEUE_TABLE}
WHERE ID = ?
END

    return $delete_queue ? $delete_queue : undef;
}

sub update_delete_queue {
    my $self = shift;
    my $delete_queue = shift;
    $self->{INDEX_DBH}->do(<<END, undef, $delete_queue, 1);
REPLACE INTO $self->{DELETE_QUEUE_TABLE} (delete_queue, id)
VALUES (?, ?)
END

}

sub inverted_replace_execute {
    my $self = shift;
    my ($sth, $term, $docfreq_t, $term_docs, $term_pos) = @_;

    $sth->execute(
		  $term,
		  $docfreq_t,
		  $term_docs,
		  $term_pos,
		  ) or warn $self->{INDEX_DBH}->err;

}

sub inverted_select {
    my $self = shift;
    my $table = shift;

    return <<END;
SELECT docfreq_t, term_docs, term_pos
FROM $table
WHERE term = ?
END

}

sub total_terms {
    my $self = shift;
    my $table = shift;

    return <<END;
SELECT SUM(docfreq_t)
FROM $table
END

}

sub create_mask_table {
    my $self = shift;

    return <<END;
CREATE TABLE $self->{MASK_TABLE} (
  mask             varchar(100)            NOT NULL,
  docs_vector mediumblob 	           NOT NULL,
  primary key 	   mask_key (mask)
)
END

}

sub create_docweights_table {
    my $self = shift;
    return <<END;
CREATE TABLE $self->{DOCWEIGHTS_TABLE} (
  field_no 	   smallint unsigned 	   NOT NULL,
  avg_docweight    float                   NOT NULL,
  docweights 	   mediumblob 		   NOT NULL,
  primary key 	   field_no_key (field_no)
)
END
}


sub create_all_docs_vector_table {
    my $self = shift;

    return <<END;
CREATE TABLE $self->{ALL_DOCS_VECTOR_TABLE} (
  id               INT UNSIGNED            NOT NULL,
  all_docs_vector  MEDIUMBLOB              NOT NULL,
  UNIQUE KEY       id_key (id)
)
END
}

sub create_delete_queue_table {
    my $self = shift;

    return <<END;
CREATE TABLE $self->{DELETE_QUEUE_TABLE} (
  id                   INT UNSIGNED            NOT NULL,
  delete_queue         MEDIUMBLOB              NOT NULL,
  UNIQUE KEY           id_key (id)
)
END
}


sub create_inverted_table {
    my $self = shift;
    my $table = shift;
    my $max_word = $self->{MAX_WORD_LENGTH};

    return <<END;
CREATE TABLE $table (
  term             varchar($max_word)      NOT NULL,
  docfreq_t 	   int unsigned 	   NOT NULL,
  term_docs	   mediumblob 		   NOT NULL,
  term_pos         longblob                NOT NULL,
  PRIMARY KEY 	   term_key (term)
)
END

}

sub create_doc_key_table {
    my $self = shift;
    my $doc_key_sql_type = $self->{DOC_KEY_SQL_TYPE};

    if (lc($doc_key_sql_type) eq 'int') {
	$doc_key_sql_type .= ' unsigned';
    } else {
	$doc_key_sql_type .= "($self->{DOC_KEY_LENGTH})"
	    if $self->{DOC_KEY_LENGTH}; 
    }

    return <<END;
CREATE TABLE $self->{DOC_KEY_TABLE} (
  doc_id           bigint unsigned    NOT NULL AUTO_INCREMENT PRIMARY KEY,
  doc_key          $doc_key_sql_type  NOT NULL,
  UNIQUE doc_key_key (doc_key)
)
END

}

sub drop_doc_key_table {
    my $self = shift;
    $self->drop_table($self->{DOC_KEY_TABLE});
}

1;
__END__

=head1 NAME

DBIx::TextIndex::DBD - Base class for database-specific SQL drivers

=head1 SYNOPSIS

Not for direct use, clients use L<DBIx::TextIndex>.

=head1 DESCRIPTION

This module is a base class for creating database drivers that
encapsulate SQL calls specific to a given database.

=head2 Restricted Methods

=over

=item C<add_mask>

=item C<collection_count>

=item C<create_all_docs_vector_table>

=item C<create_collection_table>

=item C<create_delete_queue_table>

=item C<create_doc_key_table>

=item C<create_docweights_table>

=item C<create_inverted_table>

=item C<create_mask_table>

=item C<delete_collection_info>

=item C<delete_doc_key_doc_ids>

=item C<delete_mask>

=item C<drop_doc_key_table>

=item C<drop_table>

=item C<fetch_all_collection_rows>

=item C<fetch_all_docs_vector>

=item C<fetch_collection_info>

=item C<fetch_collection_version>

=item C<fetch_delete_queue>

=item C<fetch_doc>

=item C<fetch_doc_all_fields>

=item C<fetch_doc_id>

=item C<fetch_doc_ids>

=item C<fetch_doc_keys>

=item C<fetch_docweights>

=item C<fetch_mask>

=item C<fetch_max_indexed_id>

=item C<fetch_term_docs>

=item C<fetch_term_freq_and_docs>

=item C<fetch_term_pos>

=item C<fetch_terms>

=item C<insert_collection_table_row>

=item C<insert_doc_key>

=item C<inverted_replace>

=item C<inverted_replace_execute>

=item C<inverted_select>

=item C<new>

=item C<phrase_scan>

=item C<phrase_scan_cz>

=item C<ping_doc>

=item C<store_collection_info>

=item C<table_exists>

=item C<total_terms>

=item C<update_all_docs_vector>

=item C<update_collection_info>

=item C<update_delete_queue>

=item C<update_docweights>

=item C<update_docweights_execute>

=back

=head1 SEE ALSO

L<DBIx::TextIndex>

=head1 AUTHOR

Daniel Koch <dkoch@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Daniel Koch.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

