package Bigtop::Deparser;
use strict; use warnings;

sub deparse {
    my $class = shift;
    my $ast   = shift;

    my @source;

    # Do the config section.
    push @source, 'config {';

    my $config = $ast->get_config;

    foreach my $statement ( @{ $config->{__STATEMENTS__} } ) {
        my ( $keyword, $value ) = @{ $statement };

        if ( ref( $value ) eq 'HASH' ) {
            my $type    = $keyword;
            my $backend = $value->{__NAME__};

            my $content = _get_backend_block_content( $value );

            push @source, "    $type $backend { $content }";
        }
        else {
            my $quoted_value = ( $value =~ /^[\w\d_]+$/ )
                             ? $value
                             : "`$value`";
            push @source, "    $keyword $quoted_value;";
        }
    }

    push @source, '}';

    # Use walk_postorder to do the app section.
    my $app_elements = $ast->walk_postorder( 'output_app_body' );

    push @source, 'app ' . $ast->get_appname() . ' {';
    push @source, @{ $app_elements };
    push @source, '}';

    # Now restore comments as best we can.
    my $last_line = @source - 1;
    my $comments = $ast->get_comments;

    foreach my $comment_line_no ( sort { $a <=> $b } keys %{ $comments } ) {
        if ( $comment_line_no <= $last_line ) {
            splice @source,
                   $comment_line_no,
                   0,
                   $comments->{ $comment_line_no };
        }
        else {
            push @source, $comments->{ $comment_line_no };
        }
    }

    return join( "\n", @source ) . "\n";
}

sub _get_backend_block_content {
    my $backend_hash = shift;

    my @statements;

    STATEMENT:
    foreach my $statement ( keys %{ $backend_hash } ) {
        next STATEMENT if $statement eq '__NAME__';

        my $value = $backend_hash->{ $statement };

        unless ( $value =~ /^\w[\w\d_:]*$/ ) {
            $value = "`$value`";
        }

        push @statements, "$statement $value;";
    }

    return join ' ', @statements;
}

package # app_statement
    app_statement;
use strict; use warnings;

sub output_app_body {
    my $self = shift;

    my $indent = ' ' x 4;

    my $retval = "$indent$self->{__KEYWORD__} ";

    $retval   .= $self->{__ARGS__}->get_quoted_args . ';';

    return [ $retval ];

}

package # app_config_block;
    app_config_block;
use strict; use warnings;

sub output_app_body {
    my $self          = shift;
    my $child_output  = shift;

    my $indent        = ' ' x 4;

    my @retval;
    
    if ( $self->{__TYPE__} ) {
        @retval = ( "${indent}config $self->{__TYPE__} {",
                    @{ $child_output },
                    "${indent}}"
                  );
    }
    else {
        @retval = ( "${indent}config {", @{ $child_output }, "${indent}}" );
    }

    return \@retval;
}

package # app_config_statement;
    app_config_statement;
use strict; use warnings;

sub output_app_body {
    my $self    = shift;

    my $indent  = ' ' x 8;

    my $retval  = "$indent$self->{__KEYWORD__} ";
    $retval    .= $self->{__ARGS__}->get_quoted_args . ';';

    return [ $retval ];
}

package # table_block
    table_block;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;
    my $child_output = shift;

    my $indent       = ' ' x 4;
    my @retval;

    push @retval, "${indent}table $self->{__NAME__} {";
    push @retval, @{ $child_output };
    push @retval, "${indent}}";

    return \@retval;
}

package # seq_block
    seq_block;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;

    my $indent       = ' ' x 4;

    return [ "${indent}sequence $self->{__NAME__} {}" ];
}

package # schema_block
    schema_block;
use strict; use warnings;

sub output_app_body {
    my $self   = shift;
    my $indent = ' ' x 4;

    return [ "${indent}schema $self->{__NAME__} {}" ];
}

package # table_element_block
    table_element_block;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;
    my $child_output = shift;

    my @retval;

    my $indent       = ' ' x 8;
    my $arg_indent   = ' ' x 12;

    if ( $self->{__TYPE__} eq 'field' ) {
        push @retval, "${indent}field $self->{__NAME__} {";
        push @retval, @{ $child_output };
        push @retval, "${indent}}";
    }
    else {
        if ( $self->{__TYPE__} eq 'data' ) {
            push @retval, "${indent}data";

            my @args = $self->{__ARGS__}->get_quoted_args;
            my $args = join ",\n$arg_indent", @args;

            push @retval, "$arg_indent$args;";
        }
        else {
            my $args = $self->{__ARGS__}->get_quoted_args;
            push @retval, "${indent}$self->{__TYPE__} $args;";
        }
    }

    return \@retval;
}

package # field_statement
    field_statement;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;
    my $child_output = shift;

    my $indent       = ' ' x 12;
    my $arg_indent   = ' ' x 16;

    my $retval;
    if ( $self->{__KEYWORD__} eq 'html_form_options' ) {
        my @retval;

        push @retval, "${indent}html_form_options";

        $child_output->[0] =~ s/, /,\n${indent}    /g;

        push @retval, "$arg_indent$child_output->[0];";

        $retval = join "\n", @retval;
    }
    else {
        $retval = "${indent}$self->{__KEYWORD__} ";
        $retval   .= join( '', @{ $child_output } ) . ';';
    }

    return [ $retval ];
}

package # field_statement_def
    field_statement_def;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;

    my $args = $self->{__ARGS__}->get_quoted_args;
    return [ $args ];
}

package # join_table
    join_table;
use strict; use warnings;

sub output_app_body {
    my $self          = shift;
    my $child_output  = shift;

    my $indent        = ' ' x 4;
    my $type          = '';

    return [
        "${indent}join_table $self->{__NAME__} {",
        @{ $child_output },
        "${indent}}"
    ];
}

package # join_table_statement
    join_table_statement;
use strict; use warnings;

sub output_app_body {
    my $self          = shift;

    my $retval;
    my $indent        = ' ' x 8;
    my $arg_indent    = ' ' x 12;

    if ( $self->{__KEYWORD__} eq 'data' ) {
        my @retval;

        push @retval, "${indent}data";

        my @args = $self->{__DEF__}->get_quoted_args;
        my $args = join ",\n$arg_indent", @args;

        push @retval, "$arg_indent$args;";

        $retval = join "\n", @retval;
    }
    else {
        $retval  = "$indent$self->{__KEYWORD__} ";
        $retval .= $self->{__DEF__}->get_quoted_args . ';';
    }

    return [ $retval ];
}

package # controller_block;
    controller_block;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;
    my $child_output = shift;

    my @retval;
    my $indent       = ' ' x 4;

    my $is_type = $self->get_controller_type;
    $is_type    = ( $is_type eq 'stub' ) ? ' ' : " is $is_type ";

    if ( $self->is_base_controller ) {
        push @retval, "${indent}controller is base_controller \{";
        push @retval, @{ $child_output };
        push @retval, "${indent}}";
    }
    else {
        push @retval, "${indent}controller $self->{__NAME__}$is_type\{";
        push @retval, @{ $child_output };
        push @retval, "${indent}}";
    }

    return \@retval;
}

package # controller_statement;
    controller_statement;
use strict; use warnings;

sub output_app_body {
    my $self    = shift;

    my $indent  = ' ' x 8;

    my $retval  = "$indent$self->{__KEYWORD__} ";
    $retval    .= $self->{__ARGS__}->get_quoted_args . ';';

    return [ $retval ];
}

package # controller_method;
    controller_method;
use strict; use warnings;

sub output_app_body {
    my $self          = shift;
    my $child_output  = shift;

    my $indent        = ' ' x 8;

    return [
        "${indent}method $self->{__NAME__} is $self->{__TYPE__} {",
        @{ $child_output },
        "${indent}}",
    ];
}

package # method_statement;
    method_statement;
use strict; use warnings;

sub output_app_body {
    my $self          = shift;

    my $indent        = ' ' x 12;
    my $arg_indent    = ' ' x 16;

    my $retval;
    if ( $self->{__KEYWORD__} eq 'extra_keys' ) {
        my @retval;

        push @retval, "${indent}extra_keys";

        my $args = $self->{__ARGS__}->get_quoted_args;
        $args    =~ s/, /,\n${arg_indent}/g;

        push @retval, "${arg_indent}$args;";

        $retval  = join "\n", @retval;
    }
    else {
        $retval  = "$indent$self->{__KEYWORD__} ";
        $retval    .= $self->{__ARGS__}->get_quoted_args . ';';
    }

    return [ $retval ];
}

package # literal_block
    literal_block;
use strict; use warnings;

sub output_app_body {
    my $self          = shift;

    my $indent        = ' ' x 4;
    my $string_indent = ' ' x 6;

    my @retval        = ( "${indent}literal $self->{__BACKEND__}" );

    push @retval, "$string_indent`$self->{__BODY__}`;";

    return \@retval;
}

package # controller_literal_block
    controller_literal_block;
use strict; use warnings;

sub output_app_body {
    my $self = shift;

    my $indent        = ' ' x 8;
    my $string_indent = ' ' x 12;

    my @retval        = ( $indent . "literal $self->{__BACKEND__}" );
    push @retval, $string_indent . "`$self->{__BODY__}`;";

    return \@retval;
}

package # controller_config_block
    controller_config_block;
use strict; use warnings;

sub output_app_body {
    my $self         = shift;
    my $child_output = shift;

    my $indent       = ' ' x 8;
    my $type         = $self->{__TYPE__} || '';
    $type           .= ' ' if $type;
    my @retval       = ( $indent . "config ${type}{" );

    push @retval, @{ $child_output };

    push @retval, $indent . '}';

    return \@retval;
}

package # controller_config_statement
    controller_config_statement;
use strict; use warnings;

sub output_app_body {
    my $self   = shift;

    my $indent = ' ' x 12;

    my $retval  = $indent . "$self->{__KEYWORD__} ";
    $retval    .= $self->{__ARGS__}->get_quoted_args . ';';

    return [ $retval ];
}

1;

=head1 NAME

Bigtop::Deparse - given an AST, makes a corresponding bigtop source file

=head1 SYNOPSIS

    use Bigtop::Deparser;

    my $source = Bigtop::Deparser->deparse( $ast );

=head1 DESCRIPTION

This module support TentMaker.  It takes an ast as built by Bigtop::Parser.

=head1 METHODS

=over 4

=item deparse

Params: a bigtop abstract syntax tree

Returns: source code which exactly corresponds to the tree

Note that whitespace is not preserved, but deparse tries hard to use
pleasant indenting.  If you have comments, they may have shifted
due to deletions from the tree or whitespace changes.

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
