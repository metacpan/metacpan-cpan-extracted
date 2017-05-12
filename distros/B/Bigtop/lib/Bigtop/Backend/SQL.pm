package Bigtop::Backend::SQL;
use strict; use warnings;

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
                'field', 'is', 'refers_to', 'on_delete', 'on_update'
        )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
                'table', 'sequence', 'data', 'refered_to_by'
        )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for( 'app_literal', 'SQL' )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
                'join_table', 'joins', 'names', 'data'
        )
    );
}

package # table_block
    table_block;
use strict; use warnings;

sub get_create_keyword {
    my $self = shift;

    return 'TABLE';
}

sub _skip_this_block {
    my $self = shift;

    my $skip = $self->walk_postorder( 'skip_this' );

    return pop @{ $skip };
}

package # seq_block
    seq_block;
use strict; use warnings;

sub get_create_keyword {
    my $self = shift;

    return 'SEQUENCE';
}

sub _skip_this_block {
    my $self = shift;

    my $skip = $self->walk_postorder( 'skip_this' );

    return pop @{ $skip };
}

package # schema_block
    schema_block;
use strict; use warnings;

sub get_create_keyword {
    my $self = shift;

    return 'SCHEMA';
}

sub _skip_this_block {
    my $self = shift;

    return;
}

package # table_element_block
    table_element_block;
use strict; use warnings;

sub skip_this {
    my $self         = shift;

    if ( $self->{__BODY__} eq 'not_for' ) {
        foreach my $skipped_backend ( @{ $self->{__ARGS__} } ) {
            if ( $skipped_backend eq 'SQL' ) {
                return [ 1 ];
            }
        }
    }
}

1;

=head1 NAME

Bigtop::Backend::SQL - defines legal keywords in table and field blocks

=head1 SYNOPSIS

If you are making an SQL generating backend:

    use Bigtop::Backend::SQL;

This specifies the valid keywords for the SQL generating backend.

If you need additional keywords which are generally useful, add them
here (and send in a patch).  If you need backend specific keywords, register
them within your backend module.  Note that only keywords affecting
the SQL should be put here.  But, fields have other keywords which
affect things like how they look in html forms and whether they are fetched
by default.  Register those keywords in Bigtop::Control:: or
Bigtop::Model:: modules.

=head1 DESCRIPTION

If you are using a Bigtop backend which generates SQL, you should
read this document to find out what the valid keywords inside table
and field blocks are.

If you are writing a Bigtop backend to generate SQL, you should use
this module.  That will register the standard table and field keywords
with the Bigtop parser.

=head1 BASIC STRUCTURE

A bigtop app block could look like this:

    app name {
        table name {
            field name {
            }
        }
    }

=head1 KEYWORDS

Inside the table, you can include the following keywords:

=over 4

=item sequence

This must be the name of a valid sequence defined with an app level
sequence block.  Any field whose 'is' list includes auto (which is an
alias for assign_by_sequence) will use this sequence.

=item data

Allows you to include data for table population.  Include
as many column name => value pairs as you need.  Repeat for each
row you want to insert.  They will become INSERT INTO statements.

Example:

    table payeepayor {
        field id    { is int, primary_key, assign_by_sequence; }
        field name  { is varchar; }
        sequence payeepayor_seq;
        data
            name => `Gas Company`;
        data
            id   => 2,
            name => `Electric Company`;
    }

Note that it is not wise to manually assign ids for tables with sequence
defaults.  I show it here as a simple syntactic example.

Be somewhat careful with quoting.  Numbers won't be quoted, but
strings will be.  If you need internal quotes, escape them as in:

    data name => `Phil\'s Business Center`;

Double quotes don't need escaping, since the value will be single quoted.

=back

Inside the field you may include

=over 4

=item is (required)

This defines the basic SQL declaration for the column.  Provide a
comma separated list of SQL column definition phrases or put them
all in a back quoted string or use some combination of those.
There are some keywords you can use, these are translated by the
backend to their proper equivalents:

=over 4

=item int

Short for int4.

=item primary_key

Not very short for PRIMARY KEY.

=item assign_by_sequence

Short for defaults to the next value from the sequence for this table.
To use this, you must have a defined sequence for the table and that
sequence must be defined at the app level.  (Defining it twice seems odd
to me, but some tables must share an index.  The app level definition
creates the sequence, as in it generates 'CREATE SEQUENCE...'.  The table
level definition ties this table to a sequence, as in it generates
a default clause with the sequence in it.)

=item auto

A pure synonymn for assign_by_sequence, for those who refuse to type
so long a keyword.

=back

=item update_with

Not currently supported.

=item refers_to

This marks the column as a foreign key (whether a genuine SQL foreign
key is used is up to the backend).  Currently, you can only specify the
table this column points to.  The assumption about which column varies
depending on who's doing the assuming.  For example, Class::DBI assumes
the column refers to the primary key of the other table.  Gantry makes
the tacit assumption that the primary key is the single column called id.

=back

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
