package Bigtop::Backend::Model;
use strict; use warnings;

use Bigtop::Keywords;

#-----------------------------------------------------------------
#   Register keywords in the grammar
#-----------------------------------------------------------------

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'table',
            'foreign_display',
            'model_base_class',
        )
    );
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'field',
            'non_essential',
        )
    );
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'join_table',
            'joins',
            'names',
        )
    );
}

package # table_block
    table_block;
use strict; use warnings;

sub _build_foreign_display_body {
    my $foreign_display = shift;
    my @field_names     = @_;

    my $retval;

    foreach my $field ( @field_names ) {
        $retval .= ' ' x 4 . "my \$$field = \$self->$field() || '';\n";
    }

    $retval .= "\n";
    $foreign_display =~ s{%([\d\w_]+)}{\$$1}g;
    $retval .= "    return \"$foreign_display\";\n";

    return $retval;
}

# table_element_block
package # table_element_block
    table_element_block;
use strict; use warnings;

sub _not_for_model {
    my $field = shift;

    if ( $field->{not_for} ) {
        my $skipped_backends = $field->{not_for}{args};

        foreach my $skipped_backend ( @{ $skipped_backends } ) {
            return 1 if ( $skipped_backend eq 'Model' );
        }
    }

    return 0;
}

1;

=head1 NAME

Bigtop::Backend::Model - defines legal keywords in table and field blocks

=head1 SYNOPSIS

If you are making a Model generating backend:

    use Bigtop::Backend::Model;

This specifies the valid keywords for the Model generating backend.

If you need additional keywords which are generally useful, add them
here (and send in a patch).  If you need backend specific keywords, register
them within your backend module.  Note that only keywords affecting
the model should be put here.  But, fields have other keywords which
affect things like what SQL represents them and how they look in html
forms.  Register those keywords in Bigtop::SQL:: or Bigtop::Control:: modules.

=head1 DESCRIPTION

If you are using a Bigtop backend which generates models, you should
read this document to find out what the valid keywords inside table
and field blocks are.

If you are writing a Bigtop backend to generate models, you should use
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

=head1 TABLE KEYWORDS

Tables can be field blocks.  They can also have these simple statements:

=over 4

=item foreign_display

Inside the table, you can include a foreign_display statement.  The
value must be a quoted string like this:

    foreign_display `%last_name, %first_name`;

Any percent and the Perl identifier after it will be replaced with the
current row's values for those columns.  This is useful when a model
needs to deliver a user meaningful value for the current row.

=item model_base_class

This becomes the base class of the model module for this table.
Each backend has a default base model, but setting this overrides it.

=back

=head1 FIELD KEYWORDS

=over 4

=item non_essential

Inside the field you may include non_essential.  If it has a true value,
the column will not be considered essential.  This usually means that it
will not be fetched when a row is retrieved from the database, unless
its accessor is directly called.  By default, all fields are considered
essential.

=back

=head1 OTHER KEYWORDS

The main Bigtop::Parser registers not_for simple statements for tables
and fields.  You can use them like this:

    table something_that_needs_no_model {
        not_for      Model;
        ...
    }

This will generate the SQL for the table (if you are using an SQL
backend), but not the Model.  The same goes for this:

    table normal_but_with_strange_field {
        field confusing_to_CDBI {
            is      int4;
            not_for Model;
        }
    }

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
