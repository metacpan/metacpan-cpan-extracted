package Bigtop::Backend::Diagram::GraphvizSql;
use strict; use warnings;

use Inline;

BEGIN {
    Bigtop::Parser->add_valid_keywords (
        Bigtop::Keywords->get_docs_for(
            'app', 'label'
        )
    );
    Bigtop::Parser->add_valid_keywords (
        Bigtop::Keywords->get_docs_for(
            'table', 'label'
        )
    );
    Bigtop::Parser->add_valid_keywords (
        Bigtop::Keywords->get_docs_for(
            'field', 'quasi_refers_to'
        )
    );
}

sub what_do_you_make {
    return [
        [ 'docs/schema.diagram' => 'Graphviz dot file for SQL data model' ],
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

        { keyword => 'skip_layout',
            label   => 'Skip Layout',
            descr   => 'Do NOT run a Graphviz layout program like dot.',
            type    => 'boolean' },

        { keyword => 'layout_program',
            label   => 'Layout Program',
            descr   => 'Some Graphviz layout program like neato. '
                        .   '[Default is dot]',
            type    => 'text' },

        { keyword => 'layout_flags',
            label   => 'Layout Flags',
            descr   => 'Command line flags for Graphviz layout program. '
                        .   '[Default is -Tpdf]',
            type    => 'text' },
    ];
}

sub gen_Diagram {
    shift;
    my $base_dir = shift;
    my $tree     = shift;

    my $diagram_lines = $tree->walk_postorder(
        'output_diagram_gvsql', $tree->{application}{lookup} );
    my $diagram       = join '', @{ $diagram_lines };

    my $docs_dir      = File::Spec->catdir( $base_dir, 'docs' );
    my $out_file      = File::Spec->catfile( $docs_dir, 'schema.graphviz' );

    open my $OUT, '>', $out_file or die "Couldn't write $out_file: $!\n";

    print $OUT $diagram;

    close $OUT;

    # Decide whether and how to run a graphviz tool.
    my $config_block = $tree->get_config()->{ Diagram };
    $config_block = {} unless $config_block->{__NAME__} eq 'GraphvizSql';

    return if defined $config_block->{ skip_layout }
                  and $config_block->{ skip_layout };

    my $prog      =  $config_block->{ layout_program } || 'dot';
    my $flags     =  $config_block->{ layout_flags   } || '-Tpdf';
    $flags        =~ /-T(\S+)/;
    my $extension =  $1;
    if ( not defined $extension ) {
        $flags    .= ' -Tpdf';
        $extension = 'pdf';
    }

    my $image_file = File::Spec->catfile( $docs_dir, "schema.$extension" );

    `$prog $flags $out_file > $image_file`;
}

our $template_is_setup = 0;
our $default_template_text = <<'EO_TT_blocks';
[% BLOCK dot_file %]
digraph g {
    graph [
        fontsize=30
        labelloc="t"
        label="[% label %]"
        splines=true
        overlap=false
        rankdir = "LR"
    ];
    node [shape=plaintext]
    ratio = auto;
[% FOREACH table IN tables %]
[% table %]
[% END %]
    date_box [
      label = "Generated [% date_stamp %]"
    ];
[% FOREACH edge IN edges %]
[% edge %]
[% END %]
}
[% END %][%# dot_file %]

[% BLOCK table %]
    [% name %] [
      label = <
        <table border="1" cellborder="0">
          <tr> <td><font point-size="12">[% label %]</font></td> </tr>
[% FOREACH col IN columns %]
          [% col %]
[% END %]
        </table>
      >
    ];
[% END %][%# table %]

[% BLOCK column %]
<tr> <td align="left" PORT="[% port %]">[% label %]</td> </tr>
[% END %][%# column %]
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

package # application
    application;
use strict; use warnings;

sub output_diagram_gvsql {
    my $self         = shift;
    my $child_output = shift;
    my $tables       = shift;

    my $outputs = {
        tables => [],
        edges  => [],
    };
    foreach my $child_item ( @{ $child_output } ) {
        my ( $type, $output ) = %{ $child_item };
        push @{ $outputs->{ $type } }, $output;
    }

    my $label_statement = $self->get_app_statement( 'label' );
    my $label = $label_statement->[0] || $self->get_name();

    my $output = Bigtop::Backend::Diagram::GraphvizSql::dot_file(
        {
            label      => $label,
            tables     => $outputs->{ tables },
            edges      => $outputs->{ edges  },
            date_stamp => scalar localtime,
        }
    );

    return [ $output ];
}

package # table_block
    table_block;
use strict; use warnings;

sub output_diagram_gvsql {
    my $self         = shift;
    my $child_output = shift;
    my $tables       = shift;

    my $skip_this = $self->walk_postorder( 'skip_this_table' );
    return if defined $skip_this and $skip_this->[0];

    # who am I
    my $name = $self->get_name();
    $name =~ s/.*\.//; # remove schema name

    #my $DEBUG = ( $name eq 'session' );
    #warn "table: $name\n" if $DEBUG;

    # deal with child output, including foreign key columns
    #use Data::Dumper; warn Dumper( $child_output ) if $DEBUG;
    #return [];
    my @edges;
    my @columns;
    my $indent = ' ' x 4;
    foreach my $col ( @{ $child_output } ) {
        my $col_output = Bigtop::Backend::Diagram::GraphvizSql::column(
            {
                port  => $col->{ local_col },
                label => $col->{ label } || $col->{ local_col },
            }
        );
        push @columns, $col_output;

        if ( defined $col->{ foreign_col } ) {
            my $port = $col->{ local_col };
            $col->{ local_col } = "$name:$port";

            my $edge = $indent
                        . $col->{ local_col   } . ' -> '
                        . $col->{ foreign_col };
            if ( $col->{ foreign_type } eq 'quasi_refers_to' ) {
                $edge .= ' [style="dotted"]';
            }

            push @edges, $edge;
        }
    }

    # now make the table node, starting with a label statement if present
    my $label;
    CANDIDATE:
    foreach my $block ( @{ $self->{__BODY__} } ) {
        next CANDIDATE unless $block->{__TYPE__} eq 'label';

        $label = ($block->{__ARGS__}->get_unquoted_args)->[0];
        last CANDIDATE;
    }
    $label = join ' ', map { ucfirst $_ } split /_/, $name unless $label;

    my $output = Bigtop::Backend::Diagram::GraphvizSql::table(
        {
            name    => $name,
            label   => $label,
            columns => \@columns,
        }
    );

    if ( @edges ) {
        return [
            { tables => $output },
            { edges  => join( "\n", @edges ) . "\n" }
        ];
    }
    else {
        return [ { tables => $output } ];
    }
}

package # table_element_block
    table_element_block;
use strict; use warnings;

sub output_diagram_gvsql {
    my $self         = shift;
    my $child_output = shift;

    my $name = $self->get_name();

    return unless defined $name;

    my $skip_this = $self->walk_postorder( 'skip_this_field' );
    return if defined $skip_this;

    my $retval = {};
    foreach my $el ( @{ $child_output } ) {
        my ( $key, $val ) = %{ $el };
        $retval->{ $key } = $val;
    }
    $retval->{ local_col } = $name;

    return [ $retval ];
}

sub skip_this_table {
    my $self         = shift;

    if ( $self->{__TYPE__} eq 'not_for' ) {
        my $skipped_backends = $self->{__ARGS__};
        foreach my $spurned ( @{ $skipped_backends } ) {
            return [ 1 ] if $spurned eq 'Diagram';
        }
    }
    return;
}

package # field_statement
    field_statement;
use strict; use warnings;

sub output_diagram_gvsql {
    my $self         = shift;

    my $keyword = $self->get_name();

    if ( $keyword eq 'is' ) {
        # place holder in case we care about special types
        return;
    }
    elsif ( $keyword eq 'refers_to' or $keyword eq 'quasi_refers_to' ) {
        my $foreign_info = $self->{__DEF__}{__ARGS__}[0];

        return unless ( ref( $foreign_info ) eq 'HASH' );

        my ( $table, $col ) = %{ $foreign_info };

        $table =~ s/.*\.//;

        return [
            { foreign_col  => "$table:$col" },
            { foreign_type => $keyword      },
        ];
    }
    elsif ( $keyword eq 'label' ) {
        return [
            { label => $self->{__DEF__}{__ARGS__}[0] }
        ];
    }
}

sub skip_this_field {
    my $self         = shift;

    if ( $self->get_name() eq 'not_for' ) {
        my $skipped_backends = $self->{__DEF__}{__ARGS__};
        foreach my $spurned ( @{ $skipped_backends } ) {
            return [ 1 ] if $spurned eq 'Diagram';
        }
    }
    return;
}

package # join_table
    join_table;
use strict; use warnings;

sub output_diagram_gvsql {
    my $self         = shift;
    my $child_output = shift;

    # who am I
    my $name = $self->{__NAME__};
    $name =~ s/.*\.//;
    # schema might still be there for old versions

    # deal with child output
    my @edges;
    my @columns;
    my $indent = ' ' x 4;
    my $schema = '';
    foreach my $col ( @{ $child_output } ) {
        my $col_output = Bigtop::Backend::Diagram::GraphvizSql::column(
            {
                port  => $col->{ local_col },
                label => $col->{ label } || $col->{ local_col },
            }
        );
        push @columns, $col_output;

        if ( $schema eq '' ) {
            ( $schema, undef ) = split /\./, $col->{ full_name };
            $name =~ s/^$schema//;
        }

        if ( defined $col->{ foreign_col } ) {
            my $port = $col->{ local_col };
            $col->{ local_col } = "$name:$port";

            push @edges, $indent
                        . $col->{ local_col   } . ' -> '
                        . $col->{ foreign_col }
        }
    }

    # now make the table node
    my $label = join ' ', map { ucfirst $_ } split /_/, $name;

    my $output = Bigtop::Backend::Diagram::GraphvizSql::table(
        {
            name    => $name,
            label   => $label,
            columns => \@columns,
        }
    );

    if ( @edges ) {
        return [
            { tables => $output },
            { edges  => join( "\n", @edges ) . "\n" }
        ];
    }
    else {
        return [ { tables => $output } ];
    }
}

package # join_table_statement
    join_table_statement;
use strict; use warnings;

sub output_diagram_gvsql {
    my $self         = shift;
    my $child_output = shift;

    return unless $self->{__KEYWORD__} eq 'joins';
    my @tables = %{ $self->{__DEF__}->get_first_arg() };

    my @retvals;
    foreach my $full_name ( @tables ) {
        my $table     = $full_name;
        $table        =~ s/.*\.//;
        my $col_label = join ' ', map { ucfirst $_ } split /_/, $table;

        push @retvals, {
            foreign_col => "$table:id",
            label       => $col_label,
            local_col   => $table,
            full_name   => $full_name,
        };
    }

    return \@retvals;
}

1;

__END__

=head1 NAME

Bigtop::Backend::Diagram::GraphvizSql - generates dot language file for data model

=head1 SYNOPSIS

If your bigtop file looks like this:

    config {
        SQL      ...      {}
        Diagram  Graphviz {}
    }
    app App::Name {
    }

and there are table blocks in the app block, this module will make
docs/schema.graphviz (relative to the build_dir) when you type:

    bigtop app.bigtop Diagram

or

    bigtop app.bigtop all

This generates C<docs/schema.graphviz>.
By default this backend also runs the following command:

    dot -Tpdf docs/schema.graphviz > docs/schema.pdf

Use backend_block_keywords described below to control the behavior.

=head1 DESCRIPTION

This is a Bigtop backend which generates a file in the dot language
understood by all the Graphviz tools.  For information about Graphviz,
please visit L<http://www.graphviz.org>.  To summarize, the files
generated by this module can be fed through dot or neato to produce
a .png file (many other formats are available) showing the data
model for your project.

=head1 KEYWORDS

This module assumes you are using one of the SQL backends which will
define appropriate keywords for table and field definitions.  But, it
defines three words of its own:

=over 4

=item label

This is valid keyword for both the app and table levels.  The app label
becomes the label for the whole picture.  The table label becomes the
label for the record box of the table.  If these label keywords are
not used the app name and table name are used instead, but split on
underscores and ucfirst applied to all the words which are rejoined with
a single space.

=item quasi_refers_to

This is valid at the field level and indicates that the field's value
refers to a field in another table whenever the value is not null.  In the
picture these links are drawn with dotted lines.

=back

=head1 METHODS

To keep podcoverage tests happy.

=over 4

=item backend_block_keywords

Tells tentmaker that I understand these config section backend block keywords:

    no_gen
    template
    skip_layout
    layout_program
    layout_flags

As mentioned in the L<SYNOPSIS> above, by default this backend runs
the following command:

    dot -Tpdf docs/schema.graphviz > docs/schema.pdf

If skip_layout is present and true, no such command is run.  All you
get is docs/schema.graphviz.  This flag supercedes the other keywords.

layout_program defaults to C<dot>, but this keyword lets you change to
any other interpretter of the dot language.  One of these is neato.  There
are others.  In my humble opinion, only dot looks good for this type of
diagram, so I stick with it.

layout_flags lets you pass things to your layout program.  Feel free to
pass anything.  If you use -T, the generated file will have the -T value
as its file extension.  So this:

    layout_flags `-Tpng`

will actually execute this:

    dot -Tpng docs/schema.graphviz > docs/schema.png

If you omit -T a -Tpdf will be added for you.
No other flags are parsed.

=item what_do_you_make

Tells tentmaker what this module makes.  Summary: docs/schema.graphviz.

=item gen_Diagram

Called by Bigtop::Parser to get me to do my thing.

=item setup_template

Called by Bigtop::Parser so the user can substitute an alternate template
for the hard coded one here.

=back


=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2010 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
