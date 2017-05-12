package Bigtop::Backend::SQL::SQLite;
use strict; use warnings;

use Bigtop::Backend::SQL;
use Inline;

sub what_do_you_make {
    return [
        [ 'docs/schema.sqlite' => 'SQLite database schema' ],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },

        { keyword => 'template',
          label   => 'Alternate Template',
          descr   => 'A custom TT template.',
          type    => 'text' },
    ];
}

sub gen_SQL {
    shift;
    my $base_dir = shift;
    my $tree     = shift;

    # walk tree generating sql
    my $lookup       = $tree->{application}{lookup};
    my $sql          = $tree->walk_postorder( 'output_sql_lite', $lookup );
    my $sql_output   = join '', @{ $sql };

    # write the schema.sqlite
    my $docs_dir     = File::Spec->catdir( $base_dir, 'docs' );
    mkdir $docs_dir;

    my $sql_file     = File::Spec->catfile( $docs_dir, 'schema.sqlite' );

    open my $SQL, '>', $sql_file or die "Couldn't write $sql_file: $!\n";

    print $SQL $sql_output;

    close $SQL or die "Couldn't close $sql_file: $!\n";
}

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_blocks';
[% BLOCK sql_block %]
CREATE [% keyword %] [% name %][% child_output %]

[% END %]

[% BLOCK table_body %]
 (
[% FOREACH child_element IN child_output %]
[% child_element +%][% UNLESS loop.last %],[% END %]

[% END %]
);
[% FOREACH uq_cons_name IN unique_name.keys.sort %]
CREATE UNIQUE INDEX [% uq_cons_name %] ON [% name %]( [% unique_name.${uq_cons_name}.join(', ') %] );
[% END %]
[% END %]

[% BLOCK pk_text %]
    PRIMARY KEY( [% FOREACH pk IN pks %][% pk %][% UNLESS loop.last %], [% END %][% END %] )
[%- END -%]

[% BLOCK table_element_block %]    [% name %] [% child_output %][% END %]

[% BLOCK field_statement %]
[% keywords.join( ' ' ) %]
[% END %]

[% BLOCK insert_statement %]
INSERT INTO [% table %] ( [% columns.join( ', ' ) %] )
    VALUES ( [% values.join( ', ' ) %] );
[% END %]

[% BLOCK three_way %]
CREATE TABLE [% table_name %] (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
[% FOREACH foreign_key IN foreign_keys %]
    [% foreign_key %] INTEGER[% IF ! loop.last || other_fields.0 %],[% END +%]
[% END %]
[%- FOREACH other_field IN other_fields %]
[% other_field %][% IF ! loop.last %],[% END +%]
[% END -%]
);
[% END %]
EO_TT_blocks

sub setup_template {
    my $class         = shift;
    my $template_text = shift || $default_template_text;

    return if ( $template_is_setup );

    Inline->bind(
        TT                  => $template_text,
        POST_CHOMP          => 1,
        TRIM_LEADING_SPACE  => 0,
        TRIM_TRAILING_SPACE => 0,
    );

    $template_is_setup = 1;
}

package # table_block
    table_block;
use strict; use warnings;

sub output_sql_lite {
    my $self         = shift;
    my $child_output = shift;
    my $lookup       = shift;

    return if ( $self->_skip_this_block );

    my %output;
    foreach my $statement ( @{ $child_output } ) {
        my ( $type, $output ) = @{ $statement };
        push @{ $output{ $type } }, $output;
    }

    my $pks = $self->find_primary_key( $self->{__NAME__}, $lookup );

    if ( ref( $pks ) eq 'ARRAY' ) { # multi-column primary key
        my $pk_text = Bigtop::Backend::SQL::SQLite::pk_text(
                { pks => $pks, }
        );
        push @{ $output{ table_body } }, $pk_text;
    }

    my $unique_name = $self->find_unique_name(
            $self->{__NAME__},
            $lookup,
    );

    my $child_out_str = Bigtop::Backend::SQL::SQLite::table_body(
        {
            child_output => $output{table_body},
            unique_name  => $unique_name,
            name         => $self->get_name()
        }
    );

    if ( defined $output{insert_statements} ) {
        $child_out_str .= "\n" . join "\n", @{ $output{insert_statements} };
    }

    my $output = Bigtop::Backend::SQL::SQLite::sql_block(
        {
            keyword      => $self->get_create_keyword(),
            child_output => $child_out_str,
            name         => $self->get_name(),
        }
    );

    return [ $output ];
}

package # table_element_block
    table_element_block;
use strict; use warnings;

sub output_sql_lite {
    my $self         = shift;
    my $child_output = shift;

    if ( defined $child_output) {

        my %output_pieces;
        foreach my $child_item ( @{ $child_output } ) {
            my ( $type, $output )   = %{ $child_item };
            $output_pieces{ $type } = $output;
        }

        return if $output_pieces{ skip_column };

        my $child_out_str = $output_pieces{ base_col_def };
        if ( $output_pieces{ foreign_key_col } ) {
            unless ( $output_pieces{ foreign_table } ) {
                die "field '" . $self->get_name . "' in table '"
                    .   $self->get_table_name
                    .   "' has a foreign_key_col, but no refers_to\n"
            }
            $child_out_str  .= ' REFERENCES '
                            .   $output_pieces{ foreign_table }
                            . "($output_pieces{ foreign_key_col })";
        }

        my $output = Bigtop::Backend::SQL::SQLite::table_element_block(
            { name => $self->get_name(), child_output => $child_out_str }
        );

        return [ [ table_body => $output ] ];
    }
    else {
        return unless ( $self->{__TYPE__} eq 'data' );

        my @columns;
        my @values;
        foreach my $insertion ( @{ $self->{__ARGS__} } ) {
            my ( $column, $value ) = %{ $insertion };

            $value = "'$value'" unless $value =~ /^\d+$/;

            push @columns, $column;
            push @values,  $value;
        }

        my $output = Bigtop::Backend::SQL::SQLite::insert_statement(
            {
                table   => $self->get_table_name,
                columns => \@columns,
                values  => \@values,
            }
        );
        return [ [ insert_statements => $output ] ];
    }
}

package # field_statement
    field_statement;
use strict; use warnings;

my %expansion_for = (
    int4               => 'INTEGER',
    assign_by_sequence => 'AUTOINCREMENT',
    auto               => 'AUTOINCREMENT',
);

sub sqlite_pk_text {
    my $self   = shift;
    my $lookup = shift;
    my $table  = $self->get_table_name();

    my $pks    = table_block->find_primary_key( $table, $lookup );

    return ( ref( $pks ) eq 'ARRAY' ) ? '' : 'PRIMARY KEY';
}

sub output_sql_lite {
    my $self   = shift;
    shift;  # there is no child output
    my $lookup = shift;

    my $keyword = $self->get_name();

    if ($keyword eq 'pseudo_value') {
        if ($self->{__DEF__}{__ARGS__}[0]) {
            return [ { skip_column => 1 } ];
        }
    }

    elsif ( $keyword eq 'is' ) {
        my @keywords;
        foreach my $arg ( @{ $self->{__DEF__}{__ARGS__} } ) {
            my $expanded_form = $expansion_for{$arg};

            if ( $arg eq 'primary_key' ) {
                my $pk_text = $self->sqlite_pk_text( $lookup );
                push @keywords, $pk_text if $pk_text;
            }
            elsif ( defined $expanded_form ) {
                push @keywords, $expanded_form;
            }
            else {
                push @keywords, $arg;
            }
        }
        my $output = Bigtop::Backend::SQL::SQLite::field_statement(
            { keywords => \@keywords }
        );

        return [ { base_col_def => $output } ];
    }
    elsif ( $keyword eq 'refers_to' ) {
        my $foreign_info = $self->{__DEF__}{__ARGS__}[0];

        return unless ( ref( $foreign_info ) eq 'HASH' );

        my ( $table, $col ) = %{ $foreign_info };

        return [
            { foreign_table   => $table },
            { foreign_key_col => $col   },
        ];
    }
}

package # literal_block
    literal_block;
use strict; use warnings;

sub output_sql_lite {
    my $self = shift;

    return $self->make_output( 'SQL' );
}

package # join_table
    join_table;
use strict; use warnings;

sub output_sql_lite {
    my $self         = shift;
    my $child_output = shift;

    my @foreign_keys;
    my @other_fields;
    my @inserts;

    foreach my $child_bit ( @{ $child_output } ) {
        if ( ref $child_bit eq 'ARRAY' ) {
            my ( $type, $new_item ) = @{ $child_bit };

            if ( $type eq 'table_body' ) {
                push @other_fields, $new_item;
            }
            elsif ( $type eq 'insert_statements' ) {
                push @inserts, $new_item;
            }
        }
        else {
            push @foreign_keys, $child_bit;
        }
    }

    my $three_way    = Bigtop::Backend::SQL::SQLite::three_way(
        {
            table_name   => $self->{__NAME__},
            foreign_keys => \@foreign_keys,
            other_fields => \@other_fields,
        }
    );

    $three_way .= "\n" . join( "\n", @inserts ) . "\n" if @inserts;

    return [ $three_way ];
}

package # join_table_statement
    join_table_statement;
use strict; use warnings;

sub output_sql_lite {
    my $self         = shift;
    my $child_output = shift;

    if ( $self->{__KEYWORD__} eq 'joins' ) {
        my @tables = %{ $self->{__DEF__}->get_first_arg() };

        return \@tables;
    }
    elsif ( $self->{__KEYWORD__} eq 'data' ) {
        my @columns;
        my @values;
        foreach my $insertion ( @{ $self->{__DEF__} } ) {
            my ( $column, $value ) = %{ $insertion };

            $value = "'$value'" unless $value =~ /^\d+$/;

            push @columns, $column;
            push @values,  $value;
        }

        my $output = Bigtop::Backend::SQL::SQLite::insert_statement(
            {
                table   => $self->get_join_table_name,
                columns => \@columns,
                values  => \@values,
            }
        );
        return [ [ insert_statements => $output ] ];
    }
    else {
        return;
    }

}

1;

__END__

=head1 NAME

Bigtop::Backend::SQL::SQLite - backend to generate sql for SQLite database creation

=head1 SYNOPSIS

If your bigtop file looks like this:

    config {
        SQL  SQLite {}
    }
    app App::Name {
    }

and there are table and/or sequence blocks in the app block, this
module will make docs/schema.sqlite (relative to the build_dir) when
you type:

    bigtop app.bigtop SQL

or

    bigtop app.bigtop all

You can feed that file directly to psql, once you have created
a database.  That is type:

    sqlite dbname < docs/schema.sqlite

=head1 DESCRIPTION

This is a Bigtop backend which generates SQL SQLite can understand.

=head1 KEYWORDS

This module defines no keywords.  Look in Bigtop::SQL for a list
of the keywords you can use in table and sequence blocks.

Note that SQLite does not support sequences.  Trying to use them with
this backend will be fatal.

=head1 SHORTHAND for is arguments

This module does provide a couple of bits of shorthand (some aren't so short)
for the arguments of the is field statement.

    field id {
        is int4, primary_key, auto;
    }

This translates into:

    id INTEGER PRIMARY KEY AUTOINCREMENT

You can also type 'assign_by_sequence' instead of 'auto'.  That might
aid understanding, if you can type it correctly.

Note that using 'primary_key' instead of the literal 'PRIMARY KEY' is
important.  It tells the SQL and the Model back ends that this is the
primary key.

=head1 METHODS

To keep podcoverage tests happy.

=over 4

=item backend_block_keywords

Tells tentmaker that I understand these config section backend block keywords:

    no_gen
    template

=item what_do_you_make

Tells tentmaker what this module makes.  Summary: docs/schema.sqlite.

=item gen_SQL

Called by Bigtop::Parser to get me to do my thing.

=item setup_template

Called by Bigtop::Parser so the user can substitute an alternate template
for the hard coded one here.

=back

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
