package Bigtop::ScriptHelp;
use strict; use warnings;

use base 'Exporter';

our @EXPORT = qw( valid_ident );

use File::HomeDir;
use File::Spec;
use Cwd;

my %non_entry   = (
    id       => 1,
    created  => 1,
    modified => 1,
);

sub _get_config_block {
    my $app_name  = shift;
    my $build_dir = shift;

    $app_name =~ s/::/_/g;
    $app_name = lc( $app_name );

    my $conf_file = File::Spec->catfile(
            $build_dir, 'docs', 'app.gantry.conf'
    );

    return << "EO_Config_Default";
config {
    engine          MP20;
    template_engine TT;
    Init            Std             {}
    Conf Gantry      { conffile `$conf_file`; instance $app_name; }
    HttpdConf Gantry { gantry_conf 1; }
    SQL             SQLite          {}
    SQL             Postgres        {}
    SQL             MySQL           {}
    CGI             Gantry          { with_server 1; flex_db 1; gantry_conf 1; }
    Control         Gantry          { dbix 1; }
    Model           GantryDBIxClass {}
    SiteLook        GantryDefault   {}
}
EO_Config_Default
}

sub get_minimal_default {
    my $class  = shift;
    my $name   = shift || 'Sample';

    my $cwd       = getcwd();
    my $dir_name  = $name;
    $dir_name     =~ s/::/-/g;

    my $cgi       = lc( $dir_name ) . '.cgi';

    my $build_dir = File::Spec->catfile( $cwd, $dir_name );
    my $app_db    = File::Spec->catfile( $build_dir, 'app.db' );

    # See if they have a bigtopdef or ~/.bigtopdef
    # If no .bigtopdef, whip something up from scratch
    my $def_file;
    my $home_dir = File::HomeDir->my_home();
    my $home_def = File::Spec->catfile( $home_dir, '.bigtopdef' );
    if ( -f 'bigtopdef' ) {
        $def_file = 'bigtopdef';
    }
    elsif ( -f $home_def ) {
        $def_file = $home_def;
    }

    if ( $def_file and not $ENV{ BIGTOP_REAL_DEF } ) {
        return _minimal_from_file( $def_file, $name );
    }

    my $config = _get_config_block( $name, $build_dir );

    return << "EO_Little_Default";
$config
app $name {
    config {
        dbconn `dbi:SQLite:dbname=app.db` => no_accessor;
        template_wrapper `genwrapper.tt` => no_accessor;
        doc_rootp `/static` => no_accessor;
        show_dev_navigation 1 => no_accessor;
    }
    config CGI {
        dbconn `dbi:SQLite:dbname=$app_db` => no_accessor;
        app_rootp `/cgi-bin/$cgi` => no_accessor;
    }
    controller is base_controller {
        method do_main is base_links {
        }
        method site_links is links {
        }
    }
}
EO_Little_Default
}

sub _minimal_from_file {
    my $file     = shift;
    my $app_name = shift;

    # form substitution names
    my $short_name = $app_name;
    $short_name    =~ s/.*:://;

    my $no_colon_name = $app_name;
    $no_colon_name    =~ s/::/_/g;
    $no_colon_name    = lc( $no_colon_name );

    my %subs = (
        app_name      => $app_name,
        no_colon_name => $no_colon_name,
        short_name    => $short_name,
    );

    # apply substitution names
    require Template;

    my $retval;
    my $tt = Template->new( { ABSOLUTE => 1 } );
    $tt->process( $file, \%subs, \$retval );

    # give it to 'em
    return $retval;
}

sub get_big_default {
    my $class    = shift;
    my $style    = shift;
    my $app_name = shift;
    my $extras   = join ' ', @_;

    my $starter_kit = $class->get_minimal_default( $app_name );
    my $tree        = Bigtop::Parser->parse_string( $starter_kit );

    $class->augment_tree( $style, $tree, $extras );

    return Bigtop::Deparser->deparse( $tree );
}

sub _transpose {
    my $foreign_key_for = shift;

    my %retval;

    foreach my $foreign_key ( keys %{ $foreign_key_for } ) {
        foreach my $table_info ( @{ $foreign_key_for->{ $foreign_key } } ) {
            push @{ $retval{ $table_info->{ table } } }, $foreign_key;
        }
    }

    return \%retval;
}

sub _correlate_columns {
    my $columns = shift;
    my $ast     = shift;

    my %correlation;

    # first walk existing tables in the tree
    if ( defined $ast ) {
        my $tables = $ast->walk_postorder( 'all_table_names' );

        foreach my $table ( @{ $tables } ) {

            my $columns = $ast->walk_postorder( 'all_field_names', $table );

            $correlation{ $table } = $columns;
        }
    }

    # then walk new columns
    foreach my $table ( keys %{ $columns } ) {
        my @table_columns;
        foreach my $col ( @{ $columns->{ $table } } ) {
            push @table_columns, $col->{ name };
        }
        $correlation{ $table } = \@table_columns;
    }

    return \%correlation;
}

sub _safely_order {
    my $requested_tables = shift;
    my $foreign_key_for  = shift;

    my @ordered_tables;
    my %requests = map { $_ => 1 } @{ $requested_tables };

    my %fk_tree;
    foreach my $fk ( keys %{ $foreign_key_for } ) {
        foreach my $f_table ( @{ $foreign_key_for->{ $fk } } ) {
            push @{ $fk_tree{ $fk } }, $f_table->{ table };
        }
    }

    my @chains;
    foreach my $chain_leaf ( keys %fk_tree ) {
        push @chains, [ _build_chain( $chain_leaf, \%fk_tree ) ];
    }

    my %handled;

    foreach my $chain ( @chains ) {
        LINK:
        foreach my $link ( @{ $chain } ) {
            next LINK unless $requests{ $link };
            next LINK if $handled{ $link }++;

            push @ordered_tables, $link;
        }
    }

    STRAY:
    foreach my $table ( @{ $requested_tables } ) {
        next STRAY unless $requests{ $table };
        next STRAY if $handled{ $table }++;
        push @ordered_tables, $table;
    }

    return \@ordered_tables;
}

sub _build_chain {
    my $chain_leaf = shift;
    my $fk_tree    = shift;

    my @retval = ( $chain_leaf );

    return @retval unless ( defined $fk_tree->{ $chain_leaf } );

    foreach my $parent ( @{ $fk_tree->{ $chain_leaf } } ) {
        unshift @retval, _build_chain( $parent, $fk_tree );
    }

    return @retval;
}

sub _make_native_fields {
    my $columns_for = shift;
    my $table       = shift;
    my $foreign_targets = shift;

    my $columns     = $columns_for->{ $table };
    my $foreign_display;
    my $second_main_col;
    my @exclude_from_form;

    # first handle the columns
    my $retval = '';
    my $space  = ' ';
    my $outer_indent = $space x 8;
    my $is_spacing   = $space x 12;

    foreach my $column ( @{ $columns } ) {

        if ( $column->{ default } ) {
            push @{ $column->{ types } }, "`DEFAULT '$column->{ default }'`";
        }

        my $type_string = join ', ', @{ $column->{ types } };

        my $decorations = '';
        if ( $non_entry{ $column->{ name } } ) {
            push @exclude_from_form, $column->{ name };
        }
        else {
            $second_main_col = $column->{ name }
                        if $foreign_display and not $second_main_col;

            $foreign_display = $column->{ name } unless $foreign_display;

            $type_string = "${is_spacing}$type_string";

            die "invalid column name $column->{ name }\n"
                    unless valid_ident( $column->{ name } );

            my $label = Bigtop::ScriptHelp->default_label( $column->{ name } );

            $label = "`$label`" if ( $label =~ /\s+/ );

            $decorations = << "EO_DEC";
            label          $label;
            html_form_type text;
EO_DEC
            if ( $column->{ optional } ) {
                $decorations .= << "EO_OPTIONAL";
            html_form_optional 1;
EO_OPTIONAL
            }
            if ( $column->{ default } ) {
                $decorations .= << "EO_DEFAULT";
            html_form_default_value `$column->{ default }`;
EO_DEFAULT
            }
        }

        $retval .= "${outer_indent}field $column->{ name } {\n";
        $retval .= "${outer_indent}    is $type_string;\n";
        $retval .= $decorations if $decorations;
        $retval .= "${outer_indent}}\n";
    }

    # finish by adding foreign_display
    $retval .= "${outer_indent}foreign_display `%$foreign_display`;";

    foreach my $foreign_target ( @{ $foreign_targets->{ $table } } ) {
        $retval .=
            "\n${outer_indent}refered_to_by `$foreign_target`;";
    }

    my $main_cols = $foreign_display;
    $main_cols   .= ", $second_main_col" if $second_main_col;

    return ( $retval, $main_cols, join( ', ', @exclude_from_form ) );
}

sub _make_foreign_key_fields {
    my $foreign_key_for = shift;
    my $model           = shift;
    my $col_num_2_name  = shift;

    my @foreign_fields;
    my $foreign_text = "\n";
    if ( defined $foreign_key_for->{ $model } ) {
        foreach my $foreign_key ( @{ $foreign_key_for->{ $model } } ) {

            my $label = Bigtop::ScriptHelp->default_label(
                    _strip_schema( $foreign_key->{ table } )
            );

            my $name  = $foreign_key->{ table };
            $name     =~ s/\./_/;

            my $reference_str = "`$foreign_key->{ table }`";
            if ( defined $foreign_key->{ col } ) {
                my $col_name = $col_num_2_name->{ $foreign_key->{ table } }
                                                [ $foreign_key->{ col } - 1 ];

                $reference_str .= " => $col_name" if $col_name;
            }

            my $new_foreigner = <<"EO_Foreign_Field";
        field $name {
            is             int4;
            label          `$label`;
            refers_to      $reference_str;
            html_form_type select;
        }
EO_Foreign_Field
            push @foreign_fields, $new_foreigner;
        }
        $foreign_text = join '', @foreign_fields;
    }

    chomp $foreign_text;

    return $foreign_text;
}

sub _strip_schema {
    my $input = shift;
    $input    =~ s/^[^\.]*\.//;

    return $input;
}

sub augment_tree {
    my $class = shift;
    my $style = shift;
    my $ast   = shift;
    my $art   = shift;

    # parse existing tree, get a list of all the extant tables
    my %initial_tables  = map { $_ => 1 }
                  keys %{ $ast->{application}{lookup}{tables} };
    my $joins   = $ast->{application}{lookup}{join_tables};

    foreach my $join_member ( keys %{ $joins } ) {

        foreach my $membership ( @{ $joins->{ $join_member } } ) {

            my ( $join_table ) = values %{ $membership->{ joins } };

            $initial_tables{ $join_table } = 1;
        }
    }

    my $parsed_art = $style->get_db_layout( $art, \%initial_tables );
    my ( $tables, $new_tables, $joiners, $foreign_key_for, $columns ) = (
        $parsed_art->{ all_tables },
        $parsed_art->{ new_tables },
        $parsed_art->{ joiners    },
        $parsed_art->{ foreigners },
        $parsed_art->{ columns    },
    );

    my $foreign_targets = _transpose( $foreign_key_for );

    my $col_num_2_name = _correlate_columns( $columns, $ast );

    $new_tables = _safely_order( $new_tables, $foreign_key_for );

    # make new tables with tentmaker hooks
    my %new_table;
    my %new_controller_for;
    foreach my $table ( @{ $new_tables } ) {
        my $controller  = Bigtop::ScriptHelp->default_controller( $table );

        my $schema_free = _strip_schema( $table );

        my $descr       = $schema_free;
        $descr          =~ s/_/ /g;

        my $model_label = Bigtop::ScriptHelp->default_label( $schema_free );

        my $rel_loc     = $table;
        $rel_loc        =~ s/\./_/;

        $new_table{ $table } = $ast->create_block(
                'table', $table, { columns => $columns->{ $table } }
        );

        my ( $foreign_display, $on_main_listing, $all_fields_but ) = 
                _get_controller_fields( $columns->{ $table } );

        # set a foreign display
        if ( defined $foreign_display ) {
            $ast->change_statement(
                {
                    type      => 'table',
                    ident     => $new_table{ $table }->get_ident,
                    keyword   => 'foreign_display',
                    new_value => "%$foreign_display",
                }
            );
        }

        # make a controller for the new table
        $new_controller_for{ $table } = $ast->create_block(
                'controller',
                $controller,
                { subtype          => 'AutoCRUD',
                  table            => $table,
                  text_description => $descr,
                  page_link_label  => $model_label,
                  rel_loc          => $rel_loc,
                  on_main_listing  => $on_main_listing,
                  all_fields_but   => $all_fields_but,
                }
        );
    }

    foreach my $point_from ( keys %{ $foreign_key_for } ) {
        my $ident = $ast->{application}
                          {lookup}
                          {tables}
                          {$point_from}
                          {__IDENT__};

        if ( not defined $ident ) {  # must be new
            $ident = $new_table{ $point_from }->get_ident();
        }

        foreach my $foreign_key ( @{ $foreign_key_for->{ $point_from } } ) {

            my $name  = $foreign_key->{ table };
            $name     =~ s/\./_/;

            my $label =
                    Bigtop::ScriptHelp->default_label(
                            _strip_schema( $foreign_key->{ table } )
                    );

            my $foreign_key_ref_str = $foreign_key->{ table };
            if ( defined $foreign_key->{ col } ) {
                my $col_name = $col_num_2_name->{ $foreign_key->{ table } }
                                                [ $foreign_key->{ col } - 1 ];

                $foreign_key_ref_str = {
                        keys   => $foreign_key->{ table },
                        values => $col_name
                } if $col_name;
            }

            my $refers_to_field = $ast->create_subblock(
                {
                    parent => {
                        type => 'table', ident => $ident
                    },
                    new_child => {
                        type => 'field',
                        name => $name,
                    },
                }
            );

            $ast->change_statement(
                {
                    type => 'field',
                    ident => $refers_to_field->{__IDENT__},
                    keyword => 'is',
                    new_value => 'int4',
                }
            );
            $ast->change_statement(
                {
                    type => 'field',
                    ident => $refers_to_field->{__IDENT__},
                    keyword => 'label',
                    new_value => $label,
                }
            );
            $ast->change_statement(
                {
                    type => 'field',
                    ident => $refers_to_field->{__IDENT__},
                    keyword => 'refers_to',
                    new_value => $foreign_key_ref_str,
                }
            );
            $ast->change_statement(
                {
                    type      => 'field',
                    ident     => $refers_to_field->{__IDENT__},
                    keyword   => 'html_form_type',
                    new_value => 'select',
                }
            );
        }
    }

    foreach my $point_to ( keys %{ $foreign_targets } ) {
        my $ident = $ast->{application}
                          {lookup} 
                          {tables}
                          {$point_to}
                          {__IDENT__};

        if ( not defined $ident ) {
            $ident = $new_table{ $point_to }->get_ident();
        }

        my @all_referrers;
        my @referrer_values;

        # find existing referrals
        my $original_referrers = $ast->get_statement(
            {
                type    => 'table',
                ident   => $ident,
                keyword => 'refered_to_by',
            }
        );

        foreach my $original_referrer ( @{ $original_referrers } ) {
            my ( $table, $has_many_name ) =
                    split /\s*=>\s*/, $original_referrer;

            $has_many_name ||= '';

            push @all_referrers, $table;
            push @referrer_values, $has_many_name;
        }

        # add new ones and set as new value
        push @all_referrers, @{ $foreign_targets->{ $point_to } };

        $ast->change_statement(
            {
                type => 'table',
                ident => $ident,
                keyword => 'refered_to_by',
                new_value => {
                    keys   => join( '][', @all_referrers ),
                    values => join( '][', @referrer_values ),
                }
            }
        );
    }

    # Make three ways.
    foreach my $joiner ( @{ $joiners } ) {
        my ( $table1, $table2 ) = @{ $joiner };
        my $second = $table2;
        $second    =~ s/.*\.//;
        my $join_name = "${table1}_${second}";
        my $join_table = $ast->create_block( 'join_table', $join_name, {} );

        $ast->change_statement(
            {
                type      => 'join_table',
                ident     => $join_table->{ join_table }{ __IDENT__ },
                keyword   => 'joins',
                new_value => {
                    keys => $table1,
                    values => $table2,
                }
            }
        );
    }

    return; # This is an in place tree modifier.
}

sub _get_controller_fields {
    my $columns = shift;

    my $foreign_display;
    my $second_main_col;
    my @exclude_from_form;

    foreach my $column ( @{ $columns } ) {
        if ( $non_entry{ $column->{ name } } ) {
            push @exclude_from_form, $column->{ name };
        }
        else {
            $second_main_col = $column->{ name }
                        if $foreign_display and not $second_main_col;

            $foreign_display = $column->{ name } unless $foreign_display;
        }
    }

    my $main_cols = $foreign_display;
    $main_cols   .= ", $second_main_col" if $second_main_col;

    return ( $foreign_display, $main_cols, join( ', ', @exclude_from_form ) );
}

sub valid_ident {
    my $candidate = shift;

    # XXX this regex is allowing leading digits
    return $candidate =~ /^\w[\w\d_:\.]*$/;
}

sub default_label {
    my $class  = shift;
    my $name   = shift;

    my @output_pieces = _name_breaker( $name, qr/_/ );

    return join ' ', @output_pieces;  # one space separator
}

sub default_controller {
    my $class = shift;
    my $table = shift;

    my $name = $class->default_label( $table );
    $name    =~ s/ //g;

    my @output_pieces = _name_breaker( $name, qr/\./ );

    return join '', @output_pieces;  # no space separator
}

sub _name_breaker {
    my $name     = shift;
    my $split_on = shift;

    my @output_pieces;

    foreach my $piece ( split $split_on, $name ) {
        $piece = ucfirst $piece;
        push @output_pieces, $piece;
    }

    return @output_pieces;
}

1;

=head1 NAME

Bigtop::ScriptHelp - A helper modules for command line utilities

=head1 SYNOPSIS

    #!/usr/bin/perl
    use Bigtop::ScriptHelp;

    my $default = Bigtop::ScriptHelp->get_minimal_default();
    my $tree    = Bigtop::Parser->parse_string( $default );
    # ...

    my $style   = 'SomeStyle';  # must live in Bigtop::ScriptHelp::Style::

    my $better_default = Bigtop::ScriptHelp->get_big_default(
            $style, $name, $art
    );
    my $better_tree    = Bigtop::Parser->parse_string( $better_default );

    Bigtop::ScriptHelp->augment_tree( $style, $bigtop_tree, $art );

    my $new_field_label = Bigtop::ScriptHelp->default_label( $name );

=head1 DESCRIPTION

This module is used by the bigtop and tentmaker scripts.  It provides
convenience functions for them.

=head1 Styles

Whenever a user is building or augmenting a bigtop file, they can
specify new tables and their relationships via a script help style of their
choice.  All the styles are modules in the Bigtop::ScriptHelp::Style::
namespace.  See C<Bigtop::ScriptHelp::Style> for general information about
styles and individual modules under its namespace for how each style
works.  That said, here is a list of the styles available when this was
written.

=head2 Kickstart

This is the default style.

It allows short text descriptions of database relationships.
For example:

    bigtop -n App 'contact<-birth_day'

But recent versions allow you to specify column names, their types, whether
they are optional, and to give them literal default values.  See
C<Bigtop::ScriptHelp::Style::Kickstart> for details.  This is my favorite
style (so it's no surprise that it is the default).

=head2 Pg8Live

This style must be requested:

    bigtop -n App -s Pg8Live dsninfo username password

It will connect to the database described by the dsninfo with the supplied
username and password and create a bigtop file from it.  This will create
a full AutoCRUD app for the database.  The bigtop file will have all the
tables, their columns including types and defaults.  It will also know about
all primary and foreign keys in the original database.  Depending on how
exotic the input database is, it will also know to autoincrement the primary
key.

Writing your own style is easy.  See C<Bigtop::ScriptHelp::Style> for
the requirements and the two existing styles for examples.

=head1 METHODS

All methods are class methods.

=over 4

=item get_minimal_default

Params: app_name (optional, defaults to Sample)

Returns: a little default bigtop string suitable for initial building.
It has everything you need for your app except tables and controllers.

=item get_big_default

Params:

    script help style
    app name
    a list of data for the style

Returns: a bigtop file suitable for immediately creating an app and
starting it.

=item augment_tree

Params:

    script help style
    a Bigtop::Parser syntax tree (what you got from a parse_* method)
    a string of data for the style (join all elements with spaces)

Returns: nothing, but the tree you passed will be updated.

=item default_label

Params: a new name

Returns: a default label for that name

Example of conversion: if name is birth_date, the label becomes 'Birth Date'.

=item default_controller

Params: a new table name

Returns: a default label for that table's controller

Example of conversion: if table name is birth_date, the controller
becomes 'BirthDate'.

=back

=head1 FUNCTIONS

The following functions are meant for internal use, but you might like
them too.  Don't call them through the class, call them as functions.

=over 4

=item valid_ident

Exported by default.

Params: a proposed ident

Returns: true if the ident looks good, false otherwise.  Note that the
regex is not perfect.  For instance, it will allow leading numbers.
Further it absolutely will not notice if a table or controller name is
reserved.

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-7, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
