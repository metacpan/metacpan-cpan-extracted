package Bigtop::Parser;
use strict; use warnings;

use File::Find;
use File::Spec;
use Data::Dumper;
use Carp;

use Bigtop::Grammar;
use Bigtop::Keywords;
use Bigtop::ScriptHelp;

# These don't work since we moved grammar to bigtop.grammar.
        # $::RD_TRACE = 1;
        # $::RD_HINT = 1;
# Set them in Grammar.pm directly under the use Parse::RecDescent statement.

my $ident_counter = 0;
my $parser;
my %valid_keywords;
my %keyword_for;

#---------------------------------------------------------------------
#   Methods which add and validate keywords in the grammar
#---------------------------------------------------------------------

sub add_valid_keywords {
    my $class    = shift;
    my $type     = shift;
    my $caller   = caller( 0 );

    my %callers;

    KEYWORD:
    foreach my $statement ( @_ ) {
        my $keyword = $statement->{keyword};

        my $seen_it = $valid_keywords{ $type }{ $keyword };

        $valid_keywords{ $type }{ $keyword }++;

        next KEYWORD if ( defined $statement->{type}
                            and   $statement->{type} eq 'deprecated' );

        push @{ $keyword_for{ $type }{ $keyword }{ callers } }, $caller;

        next KEYWORD if $seen_it;

        push @{ $keyword_for{ $type }{ statements } }, $statement;
    }
}

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'config',
            qw( engine template_engine plugins base_dir app_dir )
        )
    );

    # register no_gen as a keyword for (almost) all block types
    # sequence and table are not included since SQL happens all at once
    foreach my $keyword_type qw( app controller method ) {
        Bigtop::Parser->add_valid_keywords(
            Bigtop::Keywords->get_docs_for(
                $keyword_type,
                'no_gen',
            )
        );
    }

    # to allow a table to be described, but to be omitted from either
    # a Model or SQL output

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for( 'table', 'not_for' )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for( 'field', 'not_for' )
    );
}

sub is_valid_keyword {
    my $class   = shift;
    my $type    = shift;
    my $keyword = shift;

    return $valid_keywords{$type}{$keyword};
}

sub get_valid_keywords {
    my $class = shift;
    my $type  = shift;

    my %trailer_for = (
        config     => 'or a valid backend block',
        app        => 'or a valid block (controller, sequence, ' .
                                        'config, table, or join_table)',
        controller => 'or a valid method block',
        table      => 'or a valid field block',
    );

    my %extras_for = (
        app => [ 'literal' ],
    );

    my @extra_expected = @{ $extras_for{ $type } }
            if ( defined $extras_for{ $type } );

    my $trailer  = $trailer_for{ $type };

    my @expected = sort @extra_expected, keys %{ $valid_keywords{ $type } };
    push( @expected, $trailer ) if $trailer;

    return @expected;
}

sub get_keyword_docs {

    foreach my $type ( keys %keyword_for ) {
        my @sorted = sort { $a->{ sort_order } <=> $b->{ sort_order } }
                        @{ $keyword_for{ $type }{ statements } };

        $keyword_for{ $type }{ statements } = \@sorted;
    }

    return \%keyword_for;
}

#---------------------------------------------------------------------
#   The ident factory
#---------------------------------------------------------------------

sub get_ident {
    $ident_counter++;

    return "ident_$ident_counter";
}

#---------------------------------------------------------------------
#   The import method
#---------------------------------------------------------------------

sub import {
    my $class   = shift;
    my @modules = @_;

    foreach my $module ( @modules ) {
        my ( $type, $name, $template ) = split /=/, $module;

        # build full path to module and require it
        my $module_file = File::Spec->catfile(
            'Bigtop', 'Backend', $type, "$name.pm"
        );
        require $module_file;

        my $package = 'Bigtop::Backend::' . $type . '::' . $name;

        # allow caller to fill in a template file
        if ( $class->gen_mode && $package->can( 'setup_template' ) ) {
            $package->setup_template( $template );
        }
    }
}

my $gen_mode = 1;
sub gen_mode {
    my $class = shift;

    return $gen_mode;
}

sub set_gen_mode {
    my $class = shift;
    my $value = shift;

    $gen_mode = $value;

    return $gen_mode;
}

#---------------------------------------------------------------------
#   Methods which handle errors
#---------------------------------------------------------------------

sub fatal_keyword_error {
    my $class = shift;
    my $args  = shift;

    my $bad_keyword          = $args->{ bad_keyword   };
    my $diag_text            = $args->{ diag_text     };
    my $bigtop_input_linenum = $args->{ input_linenum };
    my $keyword_type         = $args->{ type          };
    my @expected             = @{ $args->{ expected } };

    $diag_text               =~ s/\n.*//sg;  # trim to one line

    # see if they forget a block name
    my %block_types = (
        config     => {},
        app        => { controller => 1,
                        sequence   => 1,
                        config     => 1,
                        table      => 1,
                        join_table => 1,
                      },
        controller => { method     => 1, },
        table      => { field      => 1, },
    );

    if ( $block_types{ $keyword_type }{ $bad_keyword } ) {
        die "Error: missing name for $bad_keyword block (line "
            .   "$bigtop_input_linenum) near:\n"
            .   "$diag_text\n";
    }

    my $expected             = join ', ', @expected;

    die "Error: invalid keyword '$bad_keyword' (line $bigtop_input_linenum) "           . "near:\n"
        . "$diag_text\n"
        . "I was expecting one of these: $expected.\n";
}

sub fatal_error_two_lines {
    my $class                = shift;
    my $message              = shift;
    my $diag_text            = shift;
    my $bigtop_input_linenum = shift;

    $diag_text               = substr $diag_text, 0, 65;

    die "Error: $message\n    "
        . "on line $bigtop_input_linenum near:\n$diag_text\n";
}

#---------------------------------------------------------------------
#   The grammar has been moved to the generated Bigtop::Grammar
#---------------------------------------------------------------------

#---------------------------------------------------------------------
#   The preprocessor (comment stripper)
#---------------------------------------------------------------------
#
# The single parameter should be a bigtop string.  It will be modified
# in place, by having all comments removed.  A comment is a line where
# the first non-whitespace char is #
#
# Returns: a hash each key is a line numbers whose value is the comment
# which was on that line of the source.
#
sub preprocess {

    # first capture all the comments
    my %retval;
    my $line_count = 0;
    foreach my $line ( split /\n/, $_[0] ) {
        if ( $line =~ /^\s*#.*/ ) {
            $retval{ $line_count } = $line;
        }
        $line_count++;
    }

    # then expunge all comments
    $_[0] =~ s/^\s*#.*//mg;

    return \%retval;
}

#---------------------------------------------------------------------
#   Methods which parse input
#---------------------------------------------------------------------

sub get_parser {
    $parser = Bigtop::Grammar->new() if ( not defined $parser );

    return $parser;
}

# This is the method that bigtop uses.
sub gen_from_file {
    my $class       = shift;
    my $bigtop_file = shift;
    my $create      = shift;
    my @gen_list    = shift;

    my $BIGTOP_FILE;
    open ( $BIGTOP_FILE, '<', $bigtop_file )
            or die "Couldn't read bigtop file $bigtop_file: $!\n";

    my $bigtop_string = join '', <$BIGTOP_FILE>;

    close $BIGTOP_FILE;

    my $flags;
    if ( $create ) {
        $flags = "-c $bigtop_file @gen_list";
    }

    return $class->gen_from_string(
        {
            bigtop_string => $bigtop_string,
            bigtop_file   => $bigtop_file,
            create        => $create,
            build_list    => \@gen_list,
            flags         => $flags,
        }
    );
}

# This is the method that gen_from_file uses.
sub gen_from_string {
    my $class         = shift;
    my $opts          = shift;

    my $bigtop_string =    $opts->{ bigtop_string };
    my $bigtop_file   =    $opts->{ bigtop_file   };
    my $create        =    $opts->{ create        };
    my $flags         =    $opts->{ flags         };
    my @args          = @{ $opts->{ build_list    } };

    my $config        = $class->parse_config_string( $bigtop_string );

    my $build_types   = $class->load_backends( $bigtop_string, $config );

    # build the whole parse tree
    my $bigtop_tree   = $class->parse_string( $bigtop_string );

    # check to see if an app wide no_gen is in effect
    my $lookup = $bigtop_tree->{application}{lookup};

    if ( defined $lookup->{app_statements}{no_gen}
            and
        $lookup->{app_statements}{no_gen}
    ) {
        warn "Warning: app level is marked no_gen, skipping generation\n";
        return;
    }

    # make the build directory (if needed)
    my $build_dir = _build_app_home_dir( $bigtop_tree, $create );

    # make sure we are in the right place
    # if there are init backends, ask the first one to verify build dir
    if ( $config->{__BACKENDS__}{ Init } ) {
        my $module = join '::', (
            'Bigtop',
            'Backend',
            'Init',
            $config->{__BACKENDS__}{ Init }[0]{__NAME__}
        );
        $module->validate_build_dir( $build_dir, $bigtop_tree, $create );
    }
    else {
        my $init_str = 'Init=Std';
        $class->import( $init_str );
        my $init_pack = 'Bigtop::Backend::Init::Std';
        $init_pack->validate_build_dir( $build_dir, $bigtop_tree, $create );
    }

    # replace all with a list of all available backends
    my @gen_list;
    foreach my $gen_type ( @args ) {
        if ( $gen_type eq 'all' ) { push @gen_list, @{ $build_types}; }
        else                      { push @gen_list, $gen_type;        }
    }

    # generate the files
    my @available_backends = sort keys %{ $config->{ __BACKENDS__ } };
    unshift @available_backends, 'all';
    my $backends_called    = 0;
    foreach my $gen_type ( @gen_list ) {

        BACKEND:
        foreach my $backend ( @{ $config->{__BACKENDS__}{ $gen_type } } ) {

            next BACKEND
                    if ( defined $backend->{no_gen} and $backend->{no_gen} );

            my $module = join '::', (
                'Bigtop', 'Backend', $gen_type, $backend->{__NAME__}
            );
            my $method = "gen_$gen_type";
            $module->$method( $build_dir, $bigtop_tree, $bigtop_file, $flags );

            $backends_called++;
        }
    }

    if ( $backends_called == 0 ) {
        rmdir $build_dir;
        _purge_inline();
        die "I didn't build anything, please check for no_gen in\n"
            .   "$bigtop_file and choose from:\n"
            .   "   @available_backends\n";
    }

    return ( $bigtop_tree->get_appname, $build_dir );
}

sub load_backends {
    my $class         = shift;
    my $bigtop_string = shift;
    my $config        = shift;

    # import the moudles mentioned in the config

    my @modules_to_require;
    my @build_types;
    my %seen_build_type;

    my $saw_init = 0;
    BACKEND:
    foreach my $backend_statement ( @{ $config->{__STATEMENTS__} } ) {
        my $backend_type = $backend_statement->[0];
        next BACKEND unless $config->{__BACKENDS__}{$backend_type};
        $saw_init = 1 if $backend_type eq 'Init';
        foreach my $backend ( @{ $config->{__BACKENDS__}{$backend_type} } ) {
            my $backend_name = $backend->{__NAME__};
            my $template     = $backend->{template} || '';

            my $module_str = join '=', $backend_type, $backend_name, $template;

            push @modules_to_require, $module_str;
            push @build_types, $backend_type
                    unless ( $seen_build_type{ $backend_type }++ );
        }
    }

    $class->import( @modules_to_require );

    push @build_types, 'Init' if $saw_init;

    return \@build_types;
}

sub _build_app_home_dir {
    my $tree     = shift;
    my $create   = shift;
    my $config   = $tree->get_config();

    my $base_dir = '.';
    
    if ( $create ) {
        $base_dir = $config->{base_dir} if defined $config->{base_dir};
    }
    elsif ( defined $config->{base_dir} ) {
        warn "Warning: config's base_dir ignored, "
                . "because we're not in create mode\n";
    }

    # make sure base_dir exists
    die "You must make the base directory $base_dir\n" unless ( -d $base_dir );

    # get app name and make a directory of it
    my $build_dir = _form_build_dir( $base_dir, $tree, $config, $create );

    if ( $create ) {
        if ( -d $build_dir ) {
            die "cowardly refusing to create,\n"
                .   "...build dir $build_dir already exists\n";
        }

        mkdir $build_dir;

        die "couldn't make directory $build_dir\n" unless ( -d $build_dir );
    }
    else {
        die "$build_dir is not a directory, perhaps you need to use --create\n"
                unless ( -d $base_dir );
    }

    $tree->{configuration}{build_dir} = $build_dir;

    return $build_dir;
}

sub _form_build_dir {
    my $base_dir = shift;
    my $tree     = shift;
    my $config   = shift;
    my $create   = shift;

    my $app_dir  = '';
    if ( $create ) {
        if ( defined $config->{app_dir} and $config->{app_dir} ) {
            $app_dir = $config->{app_dir};
        }
        else {
            $app_dir = $tree->get_appname();
            $app_dir    =~ s/::/-/g;
        }
    }
    else {
        if ( defined $config->{app_dir} ) {
            warn "config's app_dir ignored, because we're not in create mode\n";
        }
    }

    return File::Spec->catdir( $base_dir, $app_dir );
}

sub _purge_inline {
    my $doomed_dir = '_Inline';
    return unless -d $doomed_dir;

    my $purger = sub {
        my $name = $_;

        if    ( -f $name ) { unlink $name; }
        elsif ( -d $name ) { rmdir  $name; }
    };

    require File::Find;

    File::Find::finddepth( $purger, $doomed_dir );
    rmdir $doomed_dir;
}

sub parse_config_string {
    my $class  = shift;
    my $string = shift
        or croak "usage: Bigtop::Parser->parse_config_string(bigtop_string)";

    preprocess( $string );

    my $retval = $class->get_parser->config_only( $string );

    unless ( $retval ) {
        die "Couldn't parse config in your bigtop input.\n";
    }

    return $retval;
}

sub parse_string {
    my $class  = shift;
    my $string = shift
        or croak "usage: Bigtop::Parser->parse_string(bigtop_string)";

    # strip comments
    my $comments      = preprocess( $string );

    my $build_types   = $class->load_backends(
            $string,
            $class->parse_config_string( $string )
    );

    my $retval = $class->get_parser->bigtop_file( $string );

    $retval->set_comments( $comments );

    unless ( $retval ) {
        die "Couldn't parse your bigtop input.\n";
    }

    return $retval;
}

sub parse_file {
    my $class       = shift;
    my $bigtop_file = shift
        or croak "usage: BigtoP::Parser->parse_file(bigtop_file)";

    open my $BIGTOP_INPUT, "<", $bigtop_file
        or croak "Couldn't open $bigtop_file: $!\n";

    my $data = join '', <$BIGTOP_INPUT>;

    close $BIGTOP_INPUT;

    return $class->parse_string( $data );
}

#---------------------------------------------------------------------
#   Packages for each node type.  These can walk_postorder.
#   Start with $your_tree->walk_postorder( 'action', $data_object ).
#
#   Most of these have a useful dumpme which trims the Data::Dumper
#   output.  The closer you are to the bottom of the tree, the
#   better it looks relative to a regular dump.
#---------------------------------------------------------------------

package # application_ancestor
    application_ancestor;
use strict; use warnings;

sub set_parent {
    my $self   = shift;
    my $output = shift;
    my $data   = shift;
    my $parent = shift;

    $self->{__PARENT__} = $parent;

    return;
}

sub dumpme {
    my $self = shift;

    my $parent = delete $self->{__PARENT__};

    use Data::Dumper; warn Dumper( $self );

    $self->{__PARENT__} = $parent;
}

sub find_primary_key {
    my $self   = shift;
    my $table  = shift;
    my $lookup = shift;

    my $fields = $lookup->{ tables }{ $table }{ fields };

    my @primaries;

    FIELD:
    foreach my $field_name ( keys %{ $fields } ) {

        my $field = $fields->{$field_name};

        foreach my $statement_keyword ( keys %{ $field } ) {

            next unless $statement_keyword eq 'is';

            my $statement = $field->{ $statement_keyword };

            foreach my $arg ( @{ $statement->{args} } ) {
                if ( $arg eq 'primary_key' ) {
                    push @primaries, $field_name;
                }
            } # end of foreach argument
        } # end of foreach statement
    } # end of foreach field

    if ( @primaries > 1 ) {
        return \@primaries;
    }
    elsif ( @primaries == 1 ) {
        return $primaries[0];
    }
    else {
        return;
    }
}

sub find_unique_name {
    my $self   = shift;
    my $table  = shift;
    my $lookup = shift;

    my $fields = $lookup->{ tables }{ $table }{ fields };

    my $uniques;

    FIELD:
    foreach my $field_name ( keys %{ $fields } ) {

        my $field = $fields->{$field_name};

        foreach my $statement_keyword ( keys %{ $field } ) {

            next unless $statement_keyword eq 'unique_name';

            my $statement = $field->{ $statement_keyword };

            my $constraint_name = $statement->{args}[0];

            push( @{$uniques->{$constraint_name}}, $field_name );
        } # end of foreach statement
    } # end of foreach field

    if ( scalar(keys %{$uniques}) > 0 ) {
        return $uniques;
    }

    else {
        return;
    }
}

package # bigtop_file
    bigtop_file;
use strict; use warnings;

use Config;

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;

    return $self->{application}->walk_postorder( $action, $data );
}

sub get_comments {
    my $self     = shift;

    return $self->{comments};
}

sub set_comments {
    my $self     = shift;
    my $comments = shift;

    $self->{comments} = $comments;
}

sub get_app_configs {
    my $self = shift;

    my $app_configs = $self->walk_postorder( 'get_app_configs' );

    my %retval;

    foreach my $config_type ( @{ $app_configs } ) {
        $retval{ $config_type->{ type } } = $config_type->{ statements };
    }

    return \%retval;
}

sub get_controller_configs {
    my $self = shift;

    my $app_configs = $self->walk_postorder( 'get_controller_configs' );

    my %retval;

    foreach my $config_type ( @{ $app_configs } ) {
        $retval{ $config_type->{ controller } } = $config_type->{ configs };
    }

    return \%retval;
}

sub get_app_config_types {
    my $self = shift;

    return $self->walk_postorder( 'get_app_config_types' );
}

sub get_lookup {
    my $self = shift;

    return $self->{application}{lookup};
}

sub get_authors {
    my $self = shift;

    if ( defined $self->{application}{lookup}{app_statements}{authors} ) {
        my $authors = $self->{application}{lookup}{app_statements}{authors};

        my $retval  = [];

        foreach my $author ( @{ $authors } ) {
            if ( ref( $author ) eq 'HASH' ) {
                push @{ $retval }, [ %{ $author } ];
            }
            else {
                push @{ $retval }, [ $author, '' ];
            }
        }

        $retval;
    }
    else { # fall back on password file or local equivalent
        my $retval = [];
        # this eval was stolen from h2xs, but has been reformatted
        eval {
            my ( $username, $author_gcos ) = ( getpwuid($>) )[0,6];

            if ( defined $username && defined $author_gcos ) {

                $author_gcos =~ s/,.*$//; # in case of sub fields

                my $domain = $Config{ mydomain };
                $domain =~ s/^\.//;

                push @{ $retval }, [ $author_gcos, "$username\@$domain" ];
            }
        };
        return $retval;
    }
}

sub get_contact_us {
    my $self       = shift;
    my $statements = $self->{application}{lookup}{app_statements};

    if ( defined $statements->{contact_us} ) {
        return $statements->{contact_us}[0];
    }
    elsif ( defined $statements->{email} ) {
        return $statements->{email}[0];
    }
    else {
        return '';
    }
}

sub get_copyright_holder {
    my $self       = shift;
    my $statements = $self->{application}{lookup}{app_statements};

    if ( defined $statements->{copyright_holder} ) {
        return $statements->{copyright_holder}[0];
    }
    else {
        my $first_author = $self->get_authors->[0];
        return $first_author->[0] || '';
    }
}

sub get_license_text {
    my $self = shift;

    return $self->{application}{lookup}{app_statements}{license_text}[0];
}

sub get_config {
    my $tree = shift;

    return $tree->{configuration};
}

sub get_app {
    my $tree = shift;

    return $tree->{application};
}

sub get_app_blocks {
    my $tree = shift;

    return $tree->get_app()->get_blocks();
}

sub get_appname {
    my $tree = shift;

    return $tree->get_app()->get_name();
}

sub set_appname {
    my $tree     = shift;
    my $new_name = shift;

    $tree->{application}->set_name( $new_name );
}

sub get_top_level_configs {
    my $tree = shift;

    my %retval;

    STATEMENT:
    foreach my $statement ( @{ $tree->{ configuration }{__STATEMENTS__} } ) {
        my ( $name, $value ) = @{ $statement };
        next STATEMENT if ref( $value );

        $retval{ $name } = $value;
    }

    return \%retval;
}

sub set_top_level_config {
    my $tree      = shift;
    my $keyword   = shift;
    my $new_value = shift;

    $new_value    =~ s/^\s+//;
    $new_value    =~ s/\s+$//;

    if ( $new_value !~ /^\w[\w\d_:\.]*$/ ) {
        $new_value = "`$new_value`";
    }

    my $config    = $tree->{configuration};

    # change it in the quick lookup hash...
    $config->{ $keyword } = $new_value;

    # ... and in the __STATEMENTS__ list
    my $we_changed_it = 0;
    STATEMENT:
    foreach my $statement ( @{ $config->{__STATEMENTS__} } ) {
        my ( $candidate_keyword, $value ) = @{ $statement };
        if ( $candidate_keyword eq $keyword ) {
            $statement->[1] = $new_value;
            $we_changed_it++;
            last STATEMENT;
        }
    }

    # add the statement at the top if it wasn't already there
    unless ( $we_changed_it ) {
        unshift @{ $config->{__STATEMENTS__} }, [ $keyword, $new_value ];
    }
}

sub clear_top_level_config {
    my $tree      = shift;
    my $keyword   = shift;

    my $config    = $tree->{configuration};

    # clear it from the quick lookup hash...
    delete $config->{ $keyword };

    # ... and from the __STATEMENTS__ list
    my $doomed_index = -1;
    my $count        = 0;
    STATEMENT:
    foreach my $statement ( @{ $config->{__STATEMENTS__} } ) {
        my ( $candidate_keyword ) = @{ $statement };
        if ( $candidate_keyword eq $keyword ) {
            $doomed_index = $count;
            last STATEMENT;
        }

        $count++;
    }

    if ( $doomed_index >= 0 ) {
        splice @{ $config->{__STATEMENTS__} }, $doomed_index, 1;
    }
}

sub get_engine {
    my $tree = shift;

    return $tree->{configuration}{engine};
}

sub set_engine {
    my $tree       = shift;
    my $new_engine = shift;

    my $config = $tree->{configuration};

    # change it in the quick lookup hash...
    $config->{engine} = $new_engine;

    # ... and in the __STATEMENTS__ list
    my $we_changed_engines = 0;
    STATEMENT:
    foreach my $statement ( @{ $config->{__STATEMENTS__} } ) {
        my ( $keyword, $value ) = @{ $statement };
        if ( $keyword eq 'engine' ) {
            $statement->[1] = $new_engine;
            $we_changed_engines++;
            last STATEMENT;
        }
    }

    # add the statement at the top if it wasn't already there
    unless ( $we_changed_engines ) {
        unshift @{ $config->{__STATEMENTS__} }, [ 'engine', $new_engine ];
    }
}

sub get_template_engine {
    my $tree = shift;

    return $tree->{configuration}{template_engine};
}

sub set_template_engine {
    my $tree       = shift;
    my $new_engine = shift;

    my $config = $tree->{configuration};

    # change it in the quick lookup hash...
    $config->{template_engine} = $new_engine;

    # ... and in the __STATEMENTS__ list
    my $we_changed_engines = 0;
    STATEMENT:
    foreach my $statement ( @{ $config->{__STATEMENTS__} } ) {
        my ( $keyword, $value ) = @{ $statement };
        if ( $keyword eq 'template_engine' ) {
            $statement->[1] = $new_engine;
            $we_changed_engines++;
            last STATEMENT;
        }
    }

    # add the statement at the top if it wasn't already there
    unless ( $we_changed_engines ) {
        unshift @{ $config->{__STATEMENTS__} },
                [ 'template_engine', $new_engine ];
    }
}

sub change_statement {
    my $self   = shift;
    my $params = shift;

    $params->{ app } = $self->get_app;

    my ( undef, $doc_hash ) = Bigtop::Keywords->get_docs_for(
        $params->{type}, $params->{keyword}
    );

    $params->{ pair_required } = $doc_hash->{ pair_required };

    my $walk_action = "change_$params->{ type }_statement";

    my $result      = $self->walk_postorder( $walk_action, $params );

    if ( @{ $result } == 0 ) {
        die "Couldn't change $params->{type} statement "
            .   "'$params->{keyword}' for '$params->{ident}'\n";
    }

    return $result->[0];
}

sub data_statement_change {
    my $self   = shift;
    my $params = shift;

    return $self->walk_postorder( 'change_data_statement', $params );
}

sub get_statement {
    my $self   = shift;
    my $params = shift;

    my $walk_action = "get_$params->{ type }_statement";

    my $result = $self->walk_postorder( $walk_action, $params );

    return $result->[0];
}

sub remove_statement {
    my $self   = shift;
    my $params = shift;

    my $walk_action = "remove_$params->{ type }_statement";
    my $result      = $self->walk_postorder( $walk_action, $params );

    if ( @{ $result } == 0 ) {
        warn "Couldn't remove statement: couldn't find it with $walk_action\n";
        require Data::Dumper;
        Data::Dumper->import( 'Dumper' );
        warn Dumper( $params );
    }
}

sub change_name {
    my $self   = shift;
    my $params = shift;

    my $method            = "change_name_$params->{type}";

    $params->{__THE_TREE__} = $self;
    my $instructions = $self->walk_postorder( $method, $params );

    if ( $instructions->[1] ) { # Should this be 0?
        return $instructions;
    }
    else {
        return [];
    }
}

sub create_block {
    my $self     = shift;
    my $type     = shift;
    my $name     = shift;
    my $data     = shift;

    my $result   = $self->walk_postorder(
            'add_block', { type => $type, name => $name, %{ $data } }
    );

    return $result->[ 0 ];
}

sub delete_block {
    my $self         = shift;
    my $ident        = shift;

    my $instructions = $self->walk_postorder(
            'remove_block',
            {
                ident        => $ident,
                __THE_TREE__ => $self,
            }
    );

    if ( $instructions->[0] and defined $instructions->[1] ) {
        return $instructions;
    }
    else {
        return [];
    }
}

sub move_block {
    my $self   = shift;
    my $params = shift;

    $self->walk_postorder( 'block_move', $params );
}

sub create_subblock {
    my $self   = shift;
    my $params = shift;

    my $result = $self->walk_postorder( 'add_subblock', $params );

    if ( @{ $result } == 0 ) {
        die "Couldn't add subblock '$params->{new_child}{name}' "
            .   "to $params->{parent}{type} '$params->{parent}{ident}'\n";
    }

    return $result->[0];
}

sub type_change {
    my $self   = shift;
    my $params = shift;

    $self->walk_postorder( 'change_type', $params );
}

sub field_became_date {
    my $self   = shift;
    my $params = shift;

    my @retvals;

    my $table_name = $self->walk_postorder(
        'get_table_name_from_field_ident',
        $params
    )->[0];

    my $result = $self->walk_postorder(
            'use_date_plugin', { table => $table_name, }
    );

    push @retvals, @{ $result };

    # make sure field's type is text
    $self->walk_postorder(
            'change_field_statement',
            {
                type      => 'field',
                ident     => $params->{ ident },
                keyword   => 'html_form_type',
                new_value => 'text',
            },
    );

    push @retvals, $params->{ ident } . '::html_form_type', 'text';

    # based on the triggering event, update the other possible cause
    # ... if is became date, set date select text
    if ( $params->{ trigger } eq 'date' ) {
        $self->walk_postorder(
                'change_field_statement',
                {
                    type      => 'field',
                    ident     => $params->{ ident },
                    keyword   => 'date_select_text',
                    new_value => 'Select Date',
                },
        );
        push @retvals,
             $params->{ ident } . '::date_select_text',
             'Select Date';
    }
    # ... if date select text got a value, make the field type date
    else {
        $self->walk_postorder(
                'change_field_statement',
                {
                    type      => 'field',
                    ident     => $params->{ ident },
                    keyword   => 'is',
                    new_value => 'date',
                },
        );
        push @retvals, $params->{ ident } . '::is', 'date';
    }

    return \@retvals;
}

sub table_reset_bool {
    my $self   = shift;
    my $params = shift;

    return $self->walk_postorder( 'table_reset_bool', $params );
}

sub show_idents {
    my $self = shift;

    $self->walk_postorder( 'show_idents' );
}

package # application
    application;
use strict; use warnings;

sub get_blocks {
    my $self = shift;

    return $self->walk_postorder( 'app_block_hashes' );
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub set_name {
    my $self     = shift;
    my $new_name = shift;

    $self->{__NAME__} = $new_name;
}

sub get_app_statement {
    my $self    = shift;
    my $keyword = shift;

    my $answer = $self->walk_postorder( 'get_statement', $keyword );

    return $answer;
}

sub set_app_statement {
    my $self    = shift;
    my $keyword = shift;
    my $value   = shift;

    my $success = $self->walk_postorder(
        'set_statement', { keyword => $keyword, value => $value }
    );

    unless ( defined $success->[0] ) { # no existing statement, make one
        $self->{__BODY__}->add_last_statement( $keyword, $value );
    }
}

sub set_app_statement_pairs {
    my $self    = shift;
    my $params  = shift;

    my ( undef, $doc_hash ) = Bigtop::Keywords->get_docs_for(
        'app', $params->{keyword}
    );

    $params->{ pair_required } = $doc_hash->{ pair_required };

    my $success = $self->walk_postorder( 'set_statement_pairs', $params );

    unless ( defined $success->[0] ) { # make a new statement
        $self->{__BODY__}->add_last_statement_pair( $params );
    }
}

sub remove_app_statement {
    my $self    = shift;
    my $keyword = shift;

    $self->walk_postorder( 'remove_statement', $keyword );
}

sub set_config_statement {
    my $self     = shift;
    my $ident    = shift;
    my $keyword  = shift;
    my $value    = shift;
    my $accessor = shift;

    my $success  = $self->walk_postorder(
        'update_config_statement',
        {
            ident   => $ident,
            keyword => $keyword,
            value   => $value,
        }
    );

    unless ( defined $success->[0] ) { # no such statement
        $self->{__BODY__}->add_last_config_statement(
                $ident, $keyword, $value, $accessor
        );
    }
}

sub get_config_statement {
    my $self             = shift;
    my $config_type_name = shift;
    my $keyword          = shift;

    return $self->walk_postorder(
        'get_config_value',
        {
            config_type_name => $config_type_name,
            keyword => $keyword,
        }
    );
}

sub get_config_ident {
    my $self              = shift;
    my $config_block_name = shift;

    my $idents = $self->walk_postorder(
            'get_config_idents', $config_block_name
    );

    return $idents->[0];
}

sub set_config_statement_status {
    my $self    = shift;
    my $ident   = shift;
    my $keyword = shift;
    my $value   = shift;

    $self->walk_postorder(
        'config_statement_status',
        {
            ident   => $ident,
            keyword => $keyword,
            value   => $value,
        }
    );
}

sub delete_config_statement {
    my $self    = shift;
    my $ident   = shift;
    my $keyword = shift;

    $self->walk_postorder(
        'remove_config_statement',
        {
            ident => $ident,
            keyword => $keyword,
        }
    );
}

sub get_config {
    my $self = shift;

    my $statements = $self->walk_postorder( 'get_config_statements' );

    return $statements;
}

sub show_idents {
    my $self         = shift;
    my $child_output = shift;

    require Data::Dumper;
    warn Data::Dumper::Dumper( $child_output );

    return;
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;

    my $output = $self->{__BODY__}->walk_postorder( $action, $data, $self );

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, undef );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

package # app_body
    app_body;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $block ( @{ $self->{'block(s?)'} } ) {
        my $child_output = $block->walk_postorder( $action, $data, $self );

        push @{ $output }, @{ $child_output } if $child_output;
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub add_block {
    my $self = shift;
    shift;
    my $data = shift;

    my $new_block = block->new_block( $self, $data );

    push @{ $self->{ 'block(s?)' } }, $new_block;

    return [ $new_block ];
}

sub remove_block {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;
    my $doomed_ident = $data->{ ident };

    my $blocks       = $self->{ 'block(s?)' };
    my $doomed_index = get_block_index( $blocks, $doomed_ident );

    return $child_output if ( $doomed_index == -1 ); # must be for a subblock

    splice @{ $blocks }, $doomed_index, 1;

    return [ 1 ];
}

sub block_move {
    my $self   = shift;
    shift;
    my $data   = shift;
    my $blocks = $self->{ 'block(s?)' };

    my $mover_index  = get_block_index( $blocks, $data->{mover} );
    die "No such block: $data->{mover}\n" if ( $mover_index == -1 );
    my $moving_block = splice @{ $blocks }, $mover_index, 1;

    my $pivot_index  = get_block_index( $blocks, $data->{pivot} );

    if ( $pivot_index == -1 ) {
        splice @{ $blocks }, $mover_index, 0, $moving_block;

        die "No such pivot block: $data->{pivot}\n";
    }

    if ( defined $data->{after} and $data->{after} ) {
        splice @{ $blocks }, $pivot_index + 1, 0, $moving_block;
    }
    else {
        splice @{ $blocks }, $pivot_index, 0, $moving_block;
    }

    return [ 1 ];
}

sub get_block_index {
    my $blocks       = shift;
    my $target_ident = shift;

    my $target_index = -1;
    my $count        = 0;

    BLOCK:
    foreach my $block ( @{ $blocks } ) {
        next BLOCK if defined $block->{app_statement};

        if ( $block->matches( $target_ident ) ) {
            $target_index = $count;
            last BLOCK;
        }
    }
    continue {
        $count++;
    }

    return $target_index;
}

sub remove_statement {
    my $self    = shift;
    shift;
    my $keyword = shift;

    my $doomed_child = -1;
    my $count        = 0;

    BLOCK:
    foreach my $block ( @{ $self->{'block(s?)'} } ) {
        next BLOCK unless defined $block->{app_statement};

        my $child_keyword = $block->{app_statement}->get_keyword();
        if ( $keyword eq $child_keyword ) {
            $doomed_child = $count;
            last BLOCK;
        }
    }
    continue {
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        # This probably leaks memory because children have parent pointers.
        # But the parent is me and I'm the app_body, so maybe not.
        splice @{ $self->{'block(s?)'} }, $doomed_child, 1;
    }
    # else, nothing to see here, move along quietly

    return [ 1 ];
}

sub add_last_config_statement {
    my $self     = shift;
    my $ident    = shift;
    my $keyword  = shift;
    my $value    = shift;
    my $accessor = shift;

    my $success  = $self->walk_postorder(
        'add_config_statement',
        {
            ident    => $ident,
            keyword  => $keyword,
            value    => $value,
            accessor => $accessor,
        }
    );

    # if there is not a config block, make one and try again
    unless ( defined $success->[0] ) {
        my $statement = app_config_statement->new(
            $keyword,
            $value,
            $accessor,
        );

        my $block = app_config_block->new(
            {
                parent     => $self,
                statements => [ $statement ],
            }
        );

        $statement->{__PARENT__} = $block;

        push @{ $self->{ 'block(s?)' } }, $block;
    }
}

sub add_last_statement {
    my $self          = shift;
    my $keyword       = shift;
    my $value         = shift;

    my @values        = split /\]\[/, $value;
    my $new_statement = block->new_statement( $self, $keyword, \@values );

    my $index         = $self->last_statement_index();

    if ( $index >= 0 ) {
        splice @{ $self->{ 'block(s?)' } }, $index + 1, 0, $new_statement;
    }
    else { # We're so excited, this is our first child!!!
        $self->{ 'block(s?)' } = [ $new_statement ];
    }

    # Untested, but should update the lookup hash, in case anyone cares
    my $lookup = $self->{__PARENT__}->{lookup};

    $lookup->{app_statements}{ $keyword } = arg_list->new( \@values );
}

sub add_last_statement_pair {
    my $self          = shift;
    my $params        = shift;

    my $new_statement = block->new_statement_pair( $self, $params );

    my $index         = $self->last_statement_index();

    if ( $index >= 0 ) {
        splice @{ $self->{ 'block(s?)' } }, $index, 0, $new_statement;
    }
    else { # We're so excited, this is our first child!!!
        $self->{ 'block(s?)' } = [ $new_statement ];
    }

    # Untested, but should update the lookup hash, in case anyone cares
    my $lookup = $self->{__PARENT__}->{lookup};

    $lookup->{app_statements}{ $params->{keyword} } = arg_list->new(
                    $params->{ new_value },
                    $params->{ pair_required },
    );
}

sub last_statement_index {
    my $self = shift;

    my $index = -1;
    my $count = 0;
    foreach my $block ( @{ $self->{ 'block(s?)' } } ) {
        if ( defined $block->{app_statement}
                or
             defined $block->{app_config_block}
        ) {
            $index = $count;
        }
        $count++;
    }

    return $index;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my %output;

    foreach my $element ( @{ $child_output } ) {
        if ( $element->{__TYPE__} eq 'join_tables' ) {
            my $output_type                  = $element->{__TYPE__};
            my $name                         = $element->{__DATA__}[0];
            push @{ $output{ $output_type }{ $name } },
                 $element->{__DATA__}[1];

            $name                            = $element->{__DATA__}[2];
            push @{ $output{ $output_type }{ $name } },
                 $element->{__DATA__}[3];
        }
        else {
            my $output_type                  = $element->{__TYPE__};
            my $name                         = $element->{__DATA__}[0];
            $output{ $output_type }{ $name } = $element->{__DATA__}[1];
        }

    }

    return [ %output ];
}

package # block
    block;
use strict; use warnings;

use base 'application_ancestor';

sub new_statement {
    my $class   = shift;
    my $parent  = shift;
    my $keyword = shift;
    my $values  = shift;

    my $self = {
        __RULE__      => 'block',
        __PARENT__    => $parent,
    };

    $self->{app_statement} = app_statement->new( $self, $keyword, $values ),

    return bless $self, $class;
}

sub new_statement_pair {
    my $class  = shift;
    my $parent = shift;
    my $params = shift;

    my $self = {
        __RULE__    => 'block',
        __PARENT__  => $parent,
    };

    $self->{app_statement} = app_statement->new_pair( $self, $params );

    return bless $self, $class;
}

my %block_name_for = (
    table      => 'table_block',
    sequence   => 'seq_block',
    controller => 'controller_block',
    literal    => 'literal_block',
    join_table => 'join_table',
    schema     => 'schema_block',
    config     => 'app_config_block',
);

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self   = {
        __RULE__   => 'block',
        __PARENT__ => $parent,
    };

    bless $self, $class;

    my $constructing_class = $block_name_for{ $data->{type} };

    $self->{ $constructing_class } = $constructing_class->new_block(
        $self, $data
    );

    return $self;
}

sub matches {
    my $self  = shift;
    my $ident = shift;

    my @ident_block_types = qw(
            controller_block
            sql_block
            literal_block
            table_block
            seq_block
            schema_block
            join_table
    );

    my @keys = keys %{ $self };

    TYPE:
    foreach my $block_type_name ( @ident_block_types ) {
        next TYPE unless defined $self->{ $block_type_name };
        return 1 if ( $self->{ $block_type_name }{__IDENT__} eq $ident );
    }
}

sub get_ident {
    my $self = shift;

    foreach my $child_block ( keys %{ $self } ) {
        next unless ref $self->{ $child_block };
        return $self->{ $child_block }->get_ident();
    }
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $block_type ( keys %$self ) {
        next unless (
            $block_type =~ /_block$/
                or
            $block_type =~ /_statement$/
                or
            $block_type eq 'join_table'
        );

        my $child_output = $self->{$block_type}->walk_postorder(
            $action, $data, $self
        );

        push @{ $output }, @{ $child_output } if $child_output;
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return $child_output;
}

package # app_statment
    app_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class   = shift;
    my $parent  = shift;
    my $keyword = shift;
    my $values  = shift;

    my $self    = {
        __PARENT__  => $parent,
        __KEYWORD__ => $keyword,
        __ARGS__    => arg_list->new( $values ),
    };

    return bless $self, $class;
}

sub new_pair {
    my $class   = shift;
    my $parent  = shift;
    my $params  = shift;

    my $self    = {
        __PARENT__  => $parent,
        __KEYWORD__ => $params->{ keyword },
        __ARGS__    => arg_list->new(
                $params->{ new_value },
                $params->{ pair_required },
        ),
    };

    return bless $self, $class;
}

sub get_keyword {
    my $self = shift;

    return $self->{__KEYWORD__};
}

sub set_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data->{keyword} eq $self->{__KEYWORD__} );

    $self->{__ARGS__}->set_args_from( $data->{value}, $data->{pair_required} );

    return [ 1 ];
}

sub set_statement_pairs {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data->{keyword} eq $self->{__KEYWORD__} );

    $self->{__ARGS__}->set_args_from(
            $data->{new_value},
            $data->{pair_required},
    );

    return [ 1 ];
}

sub get_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data eq $self->{__KEYWORD__} );

    return $self->{__ARGS__}->get_unquoted_args;

}

sub output_location {
    my $self = shift;

    return unless $self->{__KEYWORD__} eq 'location';

    my $location = $self->{__ARGS__}[0];

    return [ $location ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [
        {
            '__TYPE__' => 'app_statements',
            '__DATA__' => [
                $self->{__KEYWORD__} => $self->{__ARGS__}
            ]
        }
    ];
}

package # literal_block
     literal_block;
use strict; use warnings;

use base 'application_ancestor';

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self = {
        __PARENT__      => $parent,
        __IDENT__       => Bigtop::Parser->get_ident(),
        __BACKEND__     => $data->{name} || 'None',
        __BODY__        => '',
    };

    return bless $self, $class;
}

sub set_type {
    my $self     = shift;
    my $new_type = shift;

    $self->{__BACKEND__} = $new_type;
}

sub set_value {
    my $self      = shift;
    my $new_value = shift;

    $self->{__BODY__} = $new_value;
}

sub change_type {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident eq $data->{ident} );

    $self->set_type( $data->{new_type} );

    return [ 1 ];
}

sub change_literal {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident eq $data->{ident} );

    $self->set_value( $data->{new_value} );

    return;
}

sub app_block_hashes {
    my $self         = shift;

    return [ {
        ident     => $self->get_ident,
        type      => 'literal',
        keyword   => $self->{__BACKEND__},
        value     => $self->{__BODY__},
    } ];
}

sub get_ident {
    my $self = shift;
    return $self->{__IDENT__};
}

sub get_backend {
    my $self = shift;

    return $self->{__BACKEND__};
}

sub show_idents {
    my $self         = shift;
    my $child_output = shift;

    push @{ $child_output },
            [ 'literal', $self->{ __NAME__ }, $self->{ __IDENT__ } ];

    return $child_output;
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub make_output {
    my $self      = shift;
    my $backend   = shift;
    my $want_hash = shift;

    if ( $backend eq $self->{__BACKEND__} ) {
        my $output = $self->{__BODY__};

        $output    =~ s/\Z/\n/ if ( $output !~ /\s\Z/ );

        return $want_hash ? [ { $backend => $output } ] : [ $output ];
    }
    else {
        return;
    }
}

package # table_block
    table_block;
use strict; use warnings;

use base 'application_ancestor';

use Bigtop::ScriptHelp;

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self = {
        __IDENT__ => Bigtop::Parser->get_ident(),
        __NAME__  => $data->{name},
        __TYPE__  => 'tables',
        __BODY__  => [],
    };

    bless $self, $class;

    if ( defined $data->{ columns } ) {
        $self->_create_these_fields( $data->{ columns } );
    }
    else {
        $self->_create_default_fields();
    }

    if ( defined $data->{sequence} ) {
        my $seq_stmnt = table_element_block->new_statement(
            $self,
            'sequence',
            $data->{sequence},
        );
        push @{ $self->{__BODY__} }, $seq_stmnt;
    }

    $self->{__PARENT__} = $parent;

    return $self;
}

sub _create_default_fields {
    my $self = shift;

    my $id_field = table_element_block->new_field(
        $self, 'id'
    );

    $id_field->add_field_statement(
        {
            ident     => $id_field->get_ident,
            keyword   => 'is',
            new_value => 'int4][primary_key][auto',
        },
    );

    push @{ $self->{__BODY__} }, $id_field;

    my %values = (
        is             => 'varchar',
        html_form_type => 'text'
    );

    foreach my $field_name qw( ident description ) {

        $values{ label } = Bigtop::ScriptHelp->default_label( $field_name );

        my $field = table_element_block->new_field(
            $self, $field_name
        );

        foreach my $statement qw( is label html_form_type ) {
            $field->add_field_statement(
                {
                    ident     => $field->get_ident,
                    keyword   => $statement,
                    new_value => $values{ $statement },
                },
            );
        }
        push @{ $self->{__BODY__} }, $field;
    }

    foreach my $date_field qw( created modified ) {
        my $field = table_element_block->new_field(
                $self, $date_field
        );
        $field->add_field_statement(
            {
                ident     => $field->get_ident,
                keyword   => 'is',
                new_value => 'datetime',
            },
        );
        push @{ $self->{__BODY__} }, $field;
    }
}

sub _create_these_fields {
    my $self   = shift;
    my $fields = shift;

    my %non_entry = (
        id       => 1,
        created  => 1,
        modified => 1,
    );

    foreach my $init_field ( @{ $fields } ) {

        if ( $init_field->{ default } ) {
            push @{ $init_field->{ types } },
                 "DEFAULT '$init_field->{ default }'";
        }

        my $type_string = join '][', @{ $init_field->{ types } };

        my $field = table_element_block->new_field(
            $self, $init_field->{ name }
        );

        $field->add_field_statement(
            {
                ident     => $field->get_ident,
                keyword   => 'is',
                new_value => $type_string,
            },
        );

        unless ( $non_entry{ $init_field->{ name } } ) {

            my $label = Bigtop::ScriptHelp->default_label(
                    $init_field->{ name }
            );

            $field->add_field_statement(
                {
                    ident     => $field->get_ident,
                    keyword   => 'label',
                    new_value => $label,
                },
            );

            $field->add_field_statement(
                {
                    ident     => $field->get_ident,
                    keyword   => 'html_form_type',
                    new_value => 'text',
                },
            );

            if ( defined $init_field->{ optional } ) {
                $field->add_field_statement(
                    {
                        ident     => $field->get_ident,
                        keyword   => 'html_form_optional',
                        new_value => $init_field->{ optional },
                    },
                );
            }
            if ( $init_field->{ default } ) {
                $field->add_field_statement(
                    {
                        ident     => $field->get_ident,
                        keyword   => 'html_form_default_value',
                        new_value => $init_field->{ default },
                    },
                );
            }
        }

        push @{ $self->{__BODY__} }, $field;
    }
}

sub add_subblock {
    my $self   = shift;
    shift;
    my $data = shift;

    return unless ( $data->{parent}{type}    eq 'table'          );
    return unless ( $data->{parent}{ident}   eq $self->get_ident );
    return unless ( $data->{new_child}{type} eq 'field'          );

    my $new_field = table_element_block->new_field(
            $self, $data->{new_child}{name}
    );

    push @{ $self->{__BODY__} }, $new_field;

    return [ $new_field ];
}

sub remove_block {
    my $self         = shift;
    shift;
    my $data         = shift;
    my $doomed_ident = $data->{ ident };

    my $doomed_index = -1;
    my $count        = 0;

    my $children     = $self->{__BODY__};

    CHILD:
    foreach my $child ( @{ $children } ) {
        my $child_ident = $child->get_ident;

        next CHILD unless defined $child_ident;

        if ( $child_ident eq $doomed_ident ) {
            $doomed_index = $count;
        }
    }
    continue {
        $count++;
    }

    return if ( $doomed_index == -1 );

    my $deceased = splice @{ $children }, $doomed_index, 1;

    # do things if the we get this far
    my @retval;

    # remove name from foreign_display as needed
    my $result = $self->walk_postorder(
            'update_foreign_display',
            {
                old_value => $deceased->{__NAME__},
                new_value => '',
                ident     => $self->{__IDENT__},
            }
    );

    push @retval, @{ $result } if ( ref( $result ) eq 'ARRAY' );

    # remove from controller form fields or all_fields_but
    # remove from controller cols (and col_labels)

    my $tree = $data->{ __THE_TREE__ };

    $result = $tree->walk_postorder( 'field_removed', 
        {
            table_name      => $self->get_name(),
            dead_field_name => $deceased->{__NAME__},
        }
    );

    push @retval, @{ $result } if ( ref( $result ) eq 'ARRAY' );

    return \@retval;
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    my $body = {
        statements => {},
        fields     => [],
    };

    foreach my $child_item ( @{ $child_output } ) {
        if ( $child_item->{ type } eq 'statement' ) {
            if ( $child_item->{ keyword } eq 'data' ) {
                push @{ $body->{ statements }{ data } },
                     $child_item->{ value };
            }
            else {
                $body->{ statements }{ $child_item->{ keyword } } =
                        $child_item->{ value };
            }
        }
        else {
            push @{ $body->{ fields } }, $child_item;
        }
    }

    return [ {
        type  => 'table',
        body  => $body,
        name  => $self->get_name,
        ident => $self->get_ident,
    } ];
}

sub change_name_table {
    my $self   = shift;
    shift;
    my $data = shift;

    return unless $self->get_ident  eq $data->{ident};

    my $old_name = $self->get_name();
    $self->set_name( $data->{new_value} );

    return $data->{__THE_TREE__}->walk_postorder( 'table_name_changed',
        {
            old_name => $old_name,
            new_name => $data->{ new_value }
        }
    );
}

sub get_ident {
    my $self = shift;

    return $self->{__IDENT__};
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub all_table_names {
    my $self = shift;

    return [ $self->{__NAME__} ];
}

sub set_name {
    my $self     = shift;
    my $new_name = shift;

    $self->{__NAME__} = $new_name;

    # update lookup hash?
}

sub show_idents {
    my $self = shift;
    my $child_output = shift;

    push @{ $child_output },
            [ $self->{ __TYPE__ }, $self->{ __NAME__ }, $self->{ __IDENT__ } ];

    return $child_output;
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $body_element ( @{ $self->{__BODY__} } ) {
        my $child_output = $body_element->walk_postorder(
            $action, $data, $self
        );

        push @{ $output }, @{ $child_output } if $child_output;
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my %output;

    foreach my $element ( @{ $child_output } ) {
        my $output_type                  = $element->{__TYPE__};

        my $name                         = $element->{__DATA__}[0];

        if ( $output_type eq 'data' ) {
            push @{ $output{ data }{ $name } }, $element->{__DATA__}[1];
        }
        else {
            $output{ $output_type }{ $name } = $element->{__DATA__}[1];
        }
    }

    $output{ __IDENT__ } = $self->{ __IDENT__ };

    my $retval = [ 
        {
            __TYPE__ => $self->{__TYPE__},
            __DATA__ => [ $self->get_name() => \%output ],
        }
    ];

    return [ 
        {
            __TYPE__ => $self->{__TYPE__},
            __DATA__ => [ $self->get_name() => \%output ],
        }
    ];
}

sub change_table_statement {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( $self->{__TYPE__} eq 'tables'       );
    return unless ( $self->get_ident  eq $data->{ident} );

    my $success = $self->walk_postorder( 'change_table_keyword_value', $data );

    unless ( defined $success->[0] ) { # make new statement
        $self->add_table_statement( $data );
    }

    return [ 1 ];
}

sub add_table_statement {
    my $self = shift;
    my $data = shift;

    my $new_statement = table_element_block->new_statement(
        $self,
        $data->{keyword},
        $data->{new_value},
    );

    my $blocks = $self->{ __BODY__ };
    push @{ $blocks }, $new_statement;
}

sub remove_table_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__TYPE__} eq 'tables'       );
    return unless ( $self->get_ident  eq $data->{ident} );

    my $doomed_child = -1;
    my $count        = 0;

    BLOCK:
    foreach my $block ( @{ $self->{__BODY__} } ) {
        next BLOCK unless $block->{__TYPE__} eq $data->{keyword};

        $doomed_child = $count;
        last BLOCK;
    }
    continue {
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        # This probably leaks memory because children have parent pointers.
        # But the parent is me and I'm the app_body, so maybe not.
        splice @{ $self->{__BODY__} },
                $doomed_child,
                1;
    }
    # else, nothing to see here, move along quietly

    return [ 1 ];
}

sub change_data_statement {
    my $self           = shift;
    my $child_output   = shift;
    my $data           = shift;

    return unless ( $self->{__IDENT__} eq $data->{ table } );

    my %field_names    = @{ $self->walk_postorder( 'get_field_names' ) };
    my $name_to_change = $field_names{ $data->{ field } };

    my $target         = $child_output->[ $data->{ st_number } - 1 ];

    if ( defined $target ) {
        my $found      = 0;
        my $remove_it  = -1;
        my $count      = -1;
        ARG:
        foreach my $arg ( @{ $target->{__ARGS__} } ) {
            $count++;

            next unless defined $arg->{ $name_to_change };

            if ( defined $data->{ value } ) {
                $arg->{ $name_to_change } = $data->{ value };
                $found++;
                last ARG;
            }
            else {
                $remove_it = $count;
            }
        }
        if ( $remove_it >= 0 ) {
            splice @{ $target->{__ARGS__} }, $remove_it, 1;

            if ( @{ $target->{__ARGS__} } == 0 ) { # no more keys, kill it
                my $doomed_child = -1;
                my $count        = -1;
                CHILD:
                foreach my $child ( @{ $self->{__BODY__} } ) {
                    $count++;
                    if ( $child eq $target ) {
                        $doomed_child = $count;
                        last CHILD;
                    }
                }
                if ( $doomed_child >= 0 ) {
                    splice @{ $self->{__BODY__} }, $doomed_child, 1;
                }
            }
        }
        elsif ( not $found ) {
            push @{ $target->{__ARGS__} },
                 { $name_to_change => $data->{ value } };
        }
    }
    else {
        $self->add_table_statement(
            {
                ident     => $self->get_ident,
                keyword   => 'data',
                new_value => {
                    keys   => $name_to_change,
                    values => $data->{value},
                }
            },
        );
    }

    return $self->walk_postorder( 'app_block_hashes' );
}

sub table_reset_bool {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->{ __IDENT__} eq $data->{ ident };

    return $self->walk_postorder( 'field_reset_bool', $data );
}

sub get_table_statement {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( $self->{__TYPE__} eq 'tables'       );
    return unless ( $self->get_ident  eq $data->{ident} );

    BLOCK:
    foreach my $block ( @{ $self->{__BODY__} } ) {
        next BLOCK unless $block->{__TYPE__} eq $data->{keyword};

        return [ $block->{__ARGS__}->get_unquoted_args ];
    }

    return;
}

package # seq_block
    seq_block;
use strict; use warnings;

use base 'application_ancestor';

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self = {
        __IDENT__  => Bigtop::Parser->get_ident(),
        __NAME__   => $data->{name},
        __TYPE__   => 'sequences',
        __BODY__   => [],
        __PARENT__ => $parent,
    };

    return bless $self, $class;
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    return [ {
        type  => 'sequence',
        body  => undef,
        name  => $self->get_name,
        ident => $self->get_ident,
    } ];
}

sub get_ident {
    my $self = shift;

    return $self->{__IDENT__};
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub set_name {
    my $self     = shift;
    my $new_name = shift;

    $self->{__NAME__} = $new_name;

    # update lookup hash?
}

sub change_name_sequence {
    my $self   = shift;
    shift;
    my $params = shift;

    return unless $self->get_ident  eq $params->{ident};

    $self->set_name( $params->{new_value} );

    return [ 1 ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

# This might be needed if sequence blocks ever have statements.
#
#    foreach my $seq_statement ( @{ $self->{__BODY__} } ) {
#        my $child_output = $seq_statement->walk_postorder(
#            $action, $data, $self
#        );
#
#        push @{ $output }, @{ $child_output } if $child_output;
#    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [
        {
            __TYPE__ => $self->{__TYPE__},
            __DATA__ => [ $self->{__NAME__} => $self->{__IDENT__} ],
        }
    ];
}

sub show_idents {
    my $self = shift;

    return [ $self->{ __TYPE__ }, $self->{ __NAME__ }, $self->{ __IDENT__ } ];
}

package # schema_block
    schema_block;
use strict; use warnings;

use base 'application_ancestor';

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self = {
        __IDENT__  => Bigtop::Parser->get_ident(),
        __NAME__   => $data->{name},
        __PARENT__ => $parent,
    };

    return bless $self, $class;
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    return [ {
        type  => 'schema',
        body  => undef,
        name  => $self->get_name,
        ident => $self->get_ident,
    } ];
}

sub get_ident {
    my $self = shift;

    return $self->{__IDENT__};
}

sub set_name {
    my $self     = shift;
    my $new_name = shift;

    $self->{__NAME__} = $new_name;
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub change_name_schema {
    my $self   = shift;
    shift;
    my $params = shift;

    return unless $self->get_ident  eq $params->{ident};

    $self->set_name( $params->{new_value} );

    return [ 1 ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self = shift;

    return [
        {
            __TYPE__ => 'schema',
            __DATA__ => [ $self->{__NAME__} => $self->{__IDENT__} ],
        }
    ];
}

sub show_idents {
    my $self = shift;

    return [ 'schema', $self->{__NAME__}, $self->{__IDENT__} ];
}

package # sequence_statement
    sequence_statement;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ 
        {
            '__TYPE__' => 'sequences',
            '__DATA__' => [
                $self->{__NAME__} => $self->{__ARGS__},
            ]
        }
    ];
}

package # table_element_block
    table_element_block;
use strict; use warnings;

use base 'application_ancestor';

sub new_statement {
    my $class   = shift;
    my $parent  = shift;
    my $keyword = shift;
    my $values  = shift;

    my $self    = {
        __PARENT__ => $parent,
        __BODY__   => $keyword,
        __TYPE__   => $keyword,
        __ARGS__   => arg_list->new( $values ),
    };

    return bless $self, $class;
}

sub new_field {
    my $class  = shift;
    my $parent = shift;
    my $name   = shift;

    my $self   = {
        __PARENT__ => $parent,
        __TYPE__   => 'field',
        __IDENT__  => Bigtop::Parser->get_ident(),
        __NAME__   => $name,
        __BODY__   => [],
    };

    return bless $self, $class;
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    my %statements;

    foreach my $child_item ( @{ $child_output } ) {
        $statements{ $child_item->{ keyword } } = $child_item->{ values };
    }

    if ( $self->{__TYPE__} eq 'field' ) {
        return [ {
            type       => 'field',
            name       => $self->get_name,
            ident      => $self->get_ident,
            statements => \%statements,
        } ];
    }
    else {
        return [ {
            ident     => $self->get_ident,
            type      => 'statement',
            keyword   => $self->{__BODY__},
            value     => $self->{__ARGS__},
        } ];
    }
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub all_field_names {
    my $self          = shift;
    shift;
    my $desired_table = shift;

    return unless ( $self->get_table_name eq $desired_table );

    return [ $self->get_name ];
}

sub set_name {
    my $self     = shift;
    my $new_name = shift;

    $self->{__NAME__} = $new_name;
}

sub get_ident {
    my $self = shift;

    return $self->{__IDENT__};
}

sub get_table_name {
    my $self = shift;

    # does this still work for join_tables?
    return $self->{__PARENT__}{__NAME__};
}

sub get_table_ident {
    my $self = shift;

    return $self->{__PARENT__}{__IDENT__};
}

sub show_idents {
    my $self = shift;
    my $child_output = shift;

    return unless $self->{ __TYPE__ } eq 'field';

    push @{ $child_output },
            [ 'field', $self->{ __NAME__ }, $self->{ __IDENT__ } ];

    return $child_output;
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output;

    if ( $self->{__TYPE__} eq 'field' ) {
        foreach my $field_stmnt ( @{ $self->{__BODY__} } ) {
            my $child_output = $field_stmnt->walk_postorder(
                $action, $data, $self
            );
 
            push @{ $output }, @{ $child_output } if $child_output;
        }
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my %output;

    if ( $child_output ) {
        my %sub_output;

        foreach my $element ( @{ $child_output } ) {
            my $output_type                      = $element->{__TYPE__};

            my $name                             = $element->{__DATA__}[0];

            $sub_output{ $output_type }{ $name } = $element->{__DATA__}[1];
        }

        $sub_output{ __IDENT__ } = $self->{ __IDENT__ };

        %output = (
            '__TYPE__' => 'fields',
            '__DATA__' => [
                $self->{__NAME__} => \%sub_output,
            ],
        );
    }
    # for non-field statements
    else {
        %output = (
            '__TYPE__' => $self->{__BODY__},
            '__DATA__' => [
                __ARGS__ => $self->{__ARGS__},
            ],
        );
    }

    return [ \%output ];
}

sub change_table_keyword_value {
    my $self = shift;
    shift;
    my $data = shift;

    return if ( defined $self->get_name ); # only fields have names

    return unless ( $self->{__BODY__} eq $data->{keyword} );

    $self->{__ARGS__}->set_args_from(
            $data->{new_value},
            $data->{pair_required},
    );

    return [ 1 ];
}

sub change_field_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__TYPE__}     eq 'field'        );
    return unless ( $self->get_ident      eq $data->{ident} );

    my $success = $self->walk_postorder( 'change_field_keyword_value', $data );

    unless ( defined $success->[0] ) { # make new statement

        $success = [ $self->add_field_statement( $data ) ];
    }

    # This array needs to be two levels deep.
    return [ $success ];
}

sub get_field_statement {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return unless ( $self->{__TYPE__}     eq 'field'        );
    return unless ( $self->get_ident      eq $data->{ident} );

    return $child_output;
}

sub add_field_statement {
    my $self = shift;
    my $data = shift;

    my $new_statement = field_statement->new_statement(
        {
            parent        => $self,
            keyword       => $data->{keyword},
            new_value     => $data->{new_value},
            pair_required => $data->{pair_required} || 0,
        }
    );

    my $blocks = $self->{ __BODY__ };
    push @{ $blocks }, $new_statement;

    if ( $data->{ keyword } eq 'is' ) {
        my %values = map { $_ => 1 } split /\]\[/, $data->{ new_value };
        return 'date' if ( $values{ date } );
    }
    elsif ( $data->{ keyword } eq 'date_select_text' ) {
        return 'date_select_text';
    }

    return 1;
}

sub remove_field_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__TYPE__}     eq 'field'        );
    return unless ( $self->get_ident      eq $data->{ident} );

    my $statements   = $self->{ __BODY__ };
    my $doomed_index = get_statement_index( $statements, $data->{keyword} );

    if ( $doomed_index >= 0 ) {
        splice @{ $statements }, $doomed_index, 1;
        return [ 1 ];
    }
    else {
        return [ 0 ];
    }
}

sub get_statement_index {
    my $statements   = shift;
    my $target_name  = shift;

    my $target_index = -1;
    my $count        = 0;

    STATEMENT:
    foreach my $statement ( @{ $statements } ) {
        if ( $statement->get_name eq $target_name ) {
            $target_index = $count;
            last STATEMENT;
        }
    }
    continue {
        $count++;
    }

    return $target_index;
}

sub change_name_field {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( defined $self->get_ident ); # only fields can change names

    return unless $self->get_ident eq $data->{ident};

    my @retval;

    my $old_name = $self->get_name(); # who were we fka
    $self->set_name( $data->{ new_value } );

    # update our label, if the old one was the default label
    my $result = $self->walk_postorder( 'update_label',
            { old_name => $old_name, new_name => $data->{ new_value } }
    );

    push @retval, @{ $result } if ( ref( $result ) eq 'ARRAY' );

    $data->{ old_value } = $old_name;
    $result = $self->{ __PARENT__ }->walk_postorder(
            'update_foreign_display', $data
    );

    push @retval, @{ $result } if ( ref( $result ) eq 'ARRAY' );

    my $tree = $data->{ __THE_TREE__ };

    $result = $tree->walk_postorder( 'field_name_changed', 
        {
            table_name     => $self->get_table_name(),
            old_field_name => $old_name,
            new_field_name => $data->{ new_value },
        }
    );

    push @retval, @{ $result } if ( ref( $result ) eq 'ARRAY' );

    return \@retval;
}

sub change_data_statement {
    my $self         = shift;
    shift;
    my $data         = shift;

    return if     ( defined $self->{__IDENT__}  );
    return unless ( $self->{__TYPE__} eq 'data' );

    return [ $self ];
}

sub get_field_names {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( defined $self->{__IDENT__} );

    return [ $self->{__IDENT__} => $self->{__NAME__} ];
}

# if a renamed field is in foreign_display, update it
sub update_foreign_display {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->{ __TYPE__ } eq 'foreign_display';

    my $display     = $self->{ __ARGS__ }->get_first_arg;
    my $old_display = $display;

    if ( $data->{ new_value } ) {
        $display        =~ s/%$data->{ old_value }/%$data->{ new_value }/g;
    }
    else {
        $display        =~ s/%$data->{ old_value }//g;
    }

    if ( $display =~ /^\s*$/ ) {
        $display = '';
        $self->{__PARENT__}->remove_table_statement(
                undef,
                {
                    ident   => $data->{ ident },
                    keyword => 'foreign_display',
                }
        );
    }
    else {
        $self->{ __ARGS__ }->set_args_from( $display );
    }

    if ( $display eq $old_display ) {
        return;
    }
    else {
        return [ $self->get_table_ident() . '::foreign_display' => $display ];
    }
}

sub get_table_name_from_field_ident {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->{ __TYPE__  } eq 'field';
    return unless $self->{ __IDENT__ } eq $data->{ ident };

    return [ $self->get_table_name ];
}

sub field_reset_bool {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return unless $self->{ __TYPE__ } eq 'field';
    return if $self->{ __NAME__ } eq 'id';

    unless ( $child_output->[0] ) {
        $self->add_field_statement(
            {
                keyword       => $data->{keyword},
                new_value     => $data->{new_value},
            }
        );
    }

    return [ $self->{ __IDENT__ } ];
}

package # field_statement
    field_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new_statement {
    my $class   = shift;
    my $params  = shift;

    my $self = {
        __PARENT__  => $params->{ parent },
        __KEYWORD__ => $params->{ keyword },
        __DEF__     => field_statement_def->new(
            $params->{ new_value },
            $params->{ pair_required },
        ),
    };

    $self->{__DEF__}{__PARENT__} = $self;

    return bless $self, $class;
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    return [ {
        keyword => $self->get_name,
        values  => $self->get_values,
    } ];
}

sub get_table_name {
    my $self = shift;

    #       table_elemnt_block table_block
    return $self->{__PARENT__}{__PARENT__}{__NAME__};
}

sub get_field_ident {
    my $self = shift;

    return $self->{__PARENT__}{__IDENT__};
}

sub get_field_name {
    my $self = shift;

    return $self->{__PARENT__}{__NAME__};
}

sub get_name {
    my $self = shift;

    return $self->{__KEYWORD__};
}

sub get_values {
    my $self = shift;

    return $self->{__DEF__}{__ARGS__};
}

sub change_field_keyword_value {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data->{type}         eq 'field'          );
    return unless ( $self->{__KEYWORD__}  eq $data->{keyword} );

    $self->{__DEF__}{__ARGS__}->set_args_from(
            $data->{new_value},
            $data->{pair_required},
    );

    # see if we changed the SQL type to date
    my %values = map { $_ => 1 } split /\]\[/, $data->{ new_value };
    if ( $data->{ keyword } eq 'is' and $values{ date } ) {
        return [ 'date' ];
    }
    elsif ( $data->{ keyword } eq 'date_select_text'
                and
            $data->{ new_value } )
    {
        return [ 'date_select_text' ];
    }

    return [ 1 ];
}

sub get_field_statement {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( $data->{ keyword } eq $self->{ __KEYWORD__ } );

    return [ $self->{ __DEF__ }{ __ARGS__ } ];
}

# If the old label was the default, the label will be changed to default
# for new name.
sub update_label {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return unless $self->{ __KEYWORD__ } eq 'label';

    my $field_ident = $self->get_field_ident();

    my $old_label         = $child_output->[0];
    my $old_default_label = Bigtop::ScriptHelp->default_label(
            $data->{ old_name }
    );

    if ( $old_label eq $old_default_label ) {
        my $new_label = Bigtop::ScriptHelp->default_label(
                $data->{ new_name }
        );
        $self->{__DEF__}{__ARGS__}->set_args_from( $new_label );

        return [ $field_ident . '::label' => $new_label ];
    }

    return;
}

sub table_name_changed {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->{ __KEYWORD__ } eq 'refers_to';

    my $current_foreigner = $self->{ __DEF__ }{ __ARGS__ }->get_first_arg;

    if ( $current_foreigner eq $data->{ old_name } ) {
        $self->{ __DEF__}{ __ARGS__ }->set_args_from( $data->{ new_name } );

        return [ $self->get_field_ident . '::refers_to', $data->{ new_name } ];
    }

    return;
}

sub field_reset_bool {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->{ __KEYWORD__ } eq $data->{ keyword };

    $self->{ __DEF__ }{ __ARGS__ }[0] = $data->{ new_value };

    return [ 1 ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output;
    
    if ( $self->{__DEF__}->can( 'walk_postorder' ) ) {
        $output = $self->{__DEF__}->walk_postorder( $action, $data, $self );
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ 
        {
            '__TYPE__' => $self->{__KEYWORD__},
            '__DATA__' => [ @{ $child_output } ],
        }
    ];
}

package # field_statement_def
    field_statement_def;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class         = shift;
    my $values        = shift;
    my $pair_required = shift;

    my $self   = {
        __ARGS__ => arg_list->new( $values, $pair_required ),
    };

    return bless $self, $class;
}

sub update_label {
    my $self = shift;

    return [ $self->{ __ARGS__ }->get_first_arg ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ 'args' => $self->{__ARGS__} ];
}

package # extra_sql_block
    extra_sql_block;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output;

    # if we add more extra_sql types, we might need this:
    #if ( $self->{__TYPE__} eq 'extra_sql' ) {
    foreach my $stmnt ( @{ $self->{__BODY__} } ) {
        my $child_output = $stmnt->walk_postorder(
            $action, $data, $self
        );
 
        push @{ $output }, @{ $child_output } if $child_output;
    }
    #}

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my %output;

    if ( $child_output ) {
        my %sub_output;

        foreach my $element ( @{ $child_output } ) {
            my $output_type                      = $element->{__TYPE__};
            my $name                             = $element->{__DATA__}[0];
            $sub_output{ $output_type }{ $name } = $element->{__DATA__}[1];
        }

        $sub_output{ __IDENT__ } = $self->{ __IDENT__ };

        %output = (
            '__TYPE__' => 'extra_sqls',
            '__DATA__' => [
                $self->{__NAME__} => \%sub_output,
            ],
        );
    }
    return [ \%output ];
}

package # extra_sql_statement
    extra_sql_statement;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output;
    
    if ( $self->{__DEF__}->can( 'walk_postorder' ) ) {
        $output = $self->{__DEF__}->walk_postorder( $action, $data, $self );
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ 
        {
            '__TYPE__' => $self->{__KEYWORD__},
            '__DATA__' => [ @{ $child_output } ],
        }
    ];
}

package # extra_sql_statement_def
    extra_sql_statement_def;
use strict; use warnings;

use base 'application_ancestor';

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ 'args' => $self->{__ARGS__} ];
}

package # join_table
    join_table;
use strict; use warnings;

use base 'application_ancestor';

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self;

    $self = {
        __IDENT__       => Bigtop::Parser->get_ident(),
        __NAME__        => $data->{name},
        __BODY__        => [],
    };

    $self->{__PARENT__} = $parent;

    return bless $self, $class;
}

sub change_join_table_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident      eq $data->{ident} );

    my $success = $self->walk_postorder(
            'change_join_table_statement_value', $data
    );

    unless ( defined $success->[0] ) { # make new statement

        $self->add_join_table_statement( $data );
    }

    return [ 1 ];
}

sub add_join_table_statement {
    my $self = shift;
    my $data = shift;

    my $new_statement = join_table_statement->new(
        $self, $data->{ keyword }, $data->{ new_value },
    );

    my $blocks = $self->{ __BODY__ };
    push @{ $blocks }, $new_statement;
}

sub remove_join_table_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident   eq $data->{ident} );

    my $doomed_child = -1;
    my $count        = 0;

    my $blocks = $self->{__BODY__};

    BLOCK:
    foreach my $block ( @{ $blocks } ) {
        next BLOCK unless $block->{__KEYWORD__} eq $data->{keyword};

        $doomed_child = $count;
        last BLOCK;
    }
    continue {
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        splice @{ $blocks }, $doomed_child, 1;
    }
    # else, nothing to see here, move along quietly

    return [ 1 ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $field_stmnt ( @{ $self->{__BODY__} } ) {
        my $child_output = $field_stmnt->walk_postorder(
            $action, $data, $self
        );

        push @{ $output }, @{ $child_output } if $child_output;
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my %child_hash;

    while ( my $output_type = shift @{ $child_output } ) {
        my $hash = shift @{ $child_output };

        if ( $output_type ne 'data' ) {
            if ( defined $child_hash{ $output_type } ) {
                die "join_table $self->{__NAME__} has multiple "
                    .   "$output_type statement.\n";
            }
            $child_hash{ $output_type } = $hash;
        }
    }

    if ( not defined $child_hash{ joins } ) {
        die "join_table $self->{__NAME__} has no joins statement.\n";
    }

    my ( $table1, $table2 ) = %{ $child_hash{ joins } };

    my ( $name1,  $name2  );
    if ( defined $child_hash{ names } ) {
        ( $name1, $name2 ) = %{ $child_hash{ names } };
    }
    else {
        ( $name1, $name2 ) = ( "${table1}s", "${table2}s" );
    }

    return [
        {
            '__TYPE__' => 'join_tables',
            '__DATA__' => [
                $table1 => {
                    joins => { $table2 => $self->{__NAME__} },
                    name  => $name2,
                },
                $table2 => {
                    joins => { $table1 => $self->{__NAME__} },
                    name  => $name1,
                },
                __IDENT__ => $self->{ __IDENT__ },
            ],
        }
    ];
}

sub get_ident {
    my $self = shift;
    return $self->{__IDENT__};
}

sub show_idents {
    my $self = shift;
    my $child_output = shift;

    push @{ $child_output },
            [ 'join_table', $self->{ __NAME__ }, $self->{ __IDENT__ } ];

    return $child_output;
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    my $body = {
        statements => {},
    };

    foreach my $child_item ( @{ $child_output } ) {
        $body->{ statements }{ $child_item->{ keyword } } =
            $child_item->{ value };
    }

    return [ {
        ident           => $self->get_ident,
        type            => 'join_table',
        body            => $body,
        name            => $self->{__NAME__},
    } ];
}

package # join_table_statement
    join_table_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class   = shift;
    my $parent  = shift;
    my $keyword = shift;
    my $values  = shift;

    my $self    = {
        __PARENT__  => $parent,
        __KEYWORD__ => $keyword,
        __DEF__     => arg_list->new( $values ),
    };

    return bless $self, $class;
}

sub change_join_table_statement_value {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__KEYWORD__} eq $data->{keyword} );

    $self->{__DEF__}->set_args_from(
            $data->{new_value},
            $data->{pair_required},
    );

    return [ 1 ];
}

sub get_join_table_name {
    my $self = shift;

    return $self->{ __PARENT__ }{ __NAME__ };
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ $self->{__KEYWORD__} => $self->{__DEF__}->get_first_arg() ];
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    return [ { keyword => $self->{__KEYWORD__}, value => $self->{__DEF__} } ];
}

package # controller_block
    controller_block;
use strict; use warnings;

use base 'application_ancestor';

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    my $self = {
        __IDENT__  => Bigtop::Parser->get_ident(),
        __NAME__   => $data->{name},
        __TYPE__   => $data->{subtype},
        __BODY__   => []
    };

    $self->{__PARENT__} = $parent;

    bless $self, $class;

    # if we were given a table name, use it and do other nice things
    if ( $data->{ table } ) {
        $self->add_controller_statement(
            { keyword   => 'controls_table',
              new_value => $data->{ table },
            }
        );
        $self->add_controller_statement(
            { keyword   => 'rel_location',
              new_value => $data->{ rel_loc } || $data->{ table },
            }
        );
        $self->add_controller_statement(
            { keyword   => 'text_description',
              new_value => $data->{ text_description } || $data->{ table },
            }
        );
        $self->add_controller_statement(
            { keyword   => 'page_link_label',
              new_value => $data->{ page_link_label } || $data->{ name },
            }
        );
    }

    # now add some clever defaults if we're a CRUD or AutoCRUD
    if ( defined $data->{ subtype }
            and
         $data->{ subtype } =~ /CRUD/
    ) {
        my $table_name = $data->{ table } || lc $data->{name};

        # make the do_main method
        my $cols     = $data->{ on_main_listing } || 'ident, description';
        $cols        =~ s/, /][/g;

        my $main_arr = $self->add_subblock(
            undef,
            {
                parent => {
                    type => 'controller',
                    ident => $self->get_ident,
                },
                new_child => {
                    type     => 'method',
                    sub_type => 'main_listing',
                    name     => 'do_main',
                },
            }
        );
        my $do_main = $main_arr->[0];
        my %values  = (
            cols           => $cols,
            header_options => 'Add',
            row_options    => 'Edit][Delete',
            title          => $data->{ page_link_label } || $self->{__NAME__},
        );

        foreach my $statement qw( cols header_options row_options title ) {
            $do_main->add_method_statement( {
                keyword   => $statement,
                new_value => $values{ $statement },
            } );
        }

        # make the form method
        my $form_method_name;
        if ( $data->{ subtype } eq 'AutoCRUD' ) {
            $form_method_name = 'form';
        }
        else {
            $form_method_name = 'my_crud_form';
        }
        my $form_arr = $self->add_subblock(
            undef,
            {
                parent => {
                    type => 'controller',
                    ident => $self->get_ident,
                },
                new_child => {
                    type     => 'method',
                    sub_type => $data->{ subtype } . '_form',
                    name     => $form_method_name,
                },
            }
        );
        my $form_method = $form_arr->[0];

        my $all_fields_but = $data->{ all_fields_but }
                          || 'id, created, modified';
        $all_fields_but    =~ s/, /][/g;

        $form_method->add_method_statement( {
            keyword   => 'all_fields_but',
            new_value => $all_fields_but,
        } );

        $form_method->add_method_statement( {
            keyword   => 'extra_keys',
            new_value => {
                keys   => 'legend',
                values => q{$self->path_info =~ /edit/i ? q!Edit! : q!Add!}
            }
        } );
    }
    # base controllers get nav link methods by default
    elsif ( defined $data->{ subtype }
                and
            $data->{ subtype } eq 'base_controller'
    ) {
        # first a do_main with nav links for default main page
        my $main_arr = $self->add_subblock(
            undef,
            {
                parent => {
                    type => 'controller',
                    ident => $self->get_ident,
                },
                new_child => {
                    type     => 'method',
                    sub_type => 'base_links',
                    name     => 'do_main',
                },
            }
        );

        my $do_main = $main_arr->[0];

        # then a site_links method for other controllers and their templates
        $self->add_subblock(
            undef,
            {
                parent => {
                    type => 'controller',
                    ident => $self->get_ident,
                },
                new_child => {
                    type     => 'method',
                    sub_type => 'links',
                    name     => 'site_links',
                },
            }
        );
    }

    return $self;
}

sub add_subblock {
    my $self   = shift;
    shift;
    my $params = shift;

    return unless ( $params->{parent}{type}    eq 'controller'     );
    return unless ( $params->{parent}{ident}   eq $self->get_ident );

    if ( $params->{new_child}{type} eq 'method' ) {
        my $new_method = controller_method->new(
                $self, $params
        );

        push @{ $self->{__BODY__} }, $new_method;

        return [ $new_method ];
    }
    elsif ( $params->{new_child}{type} eq 'config' ) {
        my $new_config = controller_config_block->new( $self, $params );

        push @{ $self->{__BODY__} }, $new_config;

        return [ $new_config ];
    }
}

sub remove_block {
    my $self         = shift;
    shift;
    my $data         = shift;
    my $doomed_ident = $data->{ ident };

    my $doomed_index = -1;
    my $count        = 0;

    my $children     = $self->{__BODY__};

    CHILD:
    foreach my $child ( @{ $children } ) {
        next CHILD unless $child->can( 'get_ident' );

        if ( $child->get_ident eq $doomed_ident ) {
            $doomed_index = $count;
        }
    }
    continue {
        $count++;
    }

    return if ( $doomed_index == -1 );

    splice @{ $children }, $doomed_index, 1;

    return [ 1 ];
}

sub get_ident {
    my $self = shift;
    return $self->{__IDENT__};
}

sub get_name {
    my $self = shift;
    return $self->{__NAME__};
}

sub set_name {
    my $self          = shift;
    $self->{__NAME__} = shift;
}

sub get_controller_type {
    my $self = shift;

    return $self->{__TYPE__} || 'stub';
}

sub set_type {
    my $self          = shift;
    $self->{__TYPE__} = shift;
}

sub is_base_controller {
    my $self = shift;

    return (
        defined $self->{__TYPE__}
            and
        $self->{__TYPE__} eq 'base_controller'
    );
}

sub output_location {
    my $self         = shift;
    my $child_output = shift;

    return unless $self->is_base_controller;

    return $child_output;
}

sub get_controlled_table {
    my $self = shift;
}

sub change_name_controller {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->get_ident  eq $data->{ident};

    $self->set_name( $data->{new_value} );

    return [ 1 ];
}

sub change_type {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident eq $data->{ident} );

    $self->set_type( $data->{new_type} );

    return [ 1 ];
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    my $body = {
        statements => {},
        blocks     => [],
    };

    foreach my $child_item ( @{ $child_output } ) {
        if ( $child_item->{ type } eq 'statement' ) {
            $body->{ statements }{ $child_item->{ keyword } } =
                $child_item->{ value };
        }
        else {
            push @{ $body->{ blocks } }, $child_item;
        }
    }

    my $controller_type = $self->get_controller_type || 'stub';

    return [ {
        ident           => $self->get_ident,
        type            => 'controller',
        body            => $body,
        name            => $self->get_name,
        controller_type => $controller_type,
    } ];
}

sub change_controller_statement {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless ( $self->get_ident   eq $data->{ident} );

    my $success = $self->walk_postorder(
                    'change_controller_keyword_value', $data
    );

    unless ( defined $success->[0] ) { # make new statement
        $self->add_controller_statement( $data );
    }

    return [ 1 ];
}

sub add_controller_statement {
    my $self = shift;
    my $data = shift;

    my $new_statement = controller_statement->new(
        $self, $data->{ keyword }, $data->{ new_value },
    );

    my $blocks = $self->{ __BODY__ };
    push @{ $blocks }, $new_statement;
}

sub remove_controller_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident   eq $data->{ident} );

    my $doomed_child = -1;
    my $count        = 0;

    my $blocks = $self->{__BODY__};

    BLOCK:
    foreach my $block ( @{ $blocks } ) {
        next BLOCK unless defined $block->{__KEYWORD__}; # skip methods
        next BLOCK unless $block->{__KEYWORD__} eq $data->{keyword};

        $doomed_child = $count;
        last BLOCK;
    }
    continue {
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        # This probably leaks memory because children have parent pointers.
        # But the parent is me and I'm the app_body, so maybe not.
        splice @{ $blocks }, $doomed_child, 1;
    }
    # else, nothing to see here, move along quietly

    return [ 1 ];
}

sub get_controller_statement {
    my $self    = shift;
    my $keyword = shift;

    my $blocks  = $self->{__BODY__};

    BLOCK:
    foreach my $block ( @{ $blocks } ) {
        next BLOCK unless defined $block->{ __KEYWORD__ }; # no methods
        next BLOCK unless $block->{ __KEYWORD__ } eq $keyword;

        return $block;
    }

    return;
}

sub field_name_changed {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return unless defined $child_output->[0];

    return $self->walk_postorder( 'update_field_name', $data );
}

sub field_removed {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return unless defined $child_output->[0];

    return $self->walk_postorder( 'remove_field', $data );
}

sub show_idents {
    my $self = shift;
    my $child_output = shift;

    push @{ $child_output },
            [ 'controller', $self->{ __NAME__ }, $self->{ __IDENT__ } ];

    return $child_output;
}

sub get_controller_configs {
    my $self         = shift;
    my $child_output = shift;

    my $name         = $self->get_name();

    my %my_children;
    foreach my $child ( @{ $child_output } ) {
        $my_children{ $child->{ type } } = $child->{ statements };
    }

    return [ { controller => $name, configs => \%my_children } ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $controller_stmnt ( @{ $self->{__BODY__} } ) {
        my $child_output = $controller_stmnt->walk_postorder(
            $action, $data, $self
        );
        push @{ $output }, @{ $child_output } if $child_output;
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my %output       = ( type => $self->get_controller_type );

    foreach my $element ( @{ $child_output } ) {
        my $output_type                  = $element->{__TYPE__};

        my $name                         = $element->{__DATA__}[0];

        $output{ $output_type }{ $name } = $element->{__DATA__}[1];
    }

    return [
        {
            '__TYPE__' => 'controllers',
            '__DATA__' => [
                $self->{__NAME__} => {
                        __IDENT__ => $self->{ __IDENT__ },
                        %output
                }
            ],
        }
    ];
}

sub use_date_plugin {
    my $self = shift;
    shift;
    my $data = shift;

    my $it_is_I = $self->walk_postorder(
            'do_I_control', $data->{ table }
    )->[0];

    my @retval;

    if ( $it_is_I ) {
        # first, update my uses
        my $current_uses = $self->get_controller_statement( 'uses' );

        if ( not defined $current_uses ) {
            $self->add_controller_statement(
                {
                    keyword   => 'uses',
                    new_value => 'Gantry::Plugins::Calendar',
                }
            );
            push @retval, $self->get_ident . '::uses',
                 $self->get_controller_statement( 'uses' )->{ __ARGS__ };
        }
        else { # see if its already there
            my %current_modules = map { $_ => 1 }
                                  @{ $current_uses->{ __ARGS__ } };

            unless ( defined $current_modules{ 'Gantry::Plugins::Calendar' } )
            {
                push @{ $current_uses->{ __ARGS__ } },
                     'Gantry::Plugins::Calendar';
            }
            push @retval,
                 $self->get_ident . '::uses',
                 $current_uses->{ __ARGS__ };
        }

        # then, tell update my form
        my $result = $self->walk_postorder(
                'add_date_popups', $data->{ table }
        );

        push @retval, @{ $result };

        return \@retval;
    }

    return;
}

package # controller_method
    controller_method;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class  = shift;
    my $parent = shift;
    my $params = shift;

    my $type   = $params->{new_child}{sub_type} || 'stub';

    my $self   = {
        __IDENT__  => Bigtop::Parser->get_ident(),
        __NAME__   => $params->{new_child}{name},
        __BODY__   => method_body->new(),
        __TYPE__   => $type,
        __PARENT__ => $parent,
    };

    $self->{__BODY__}{__PARENT__} = $self;

    return bless $self, $class;
}

sub get_ident {
    my $self = shift;

    return $self->{__IDENT__};
}

sub get_name {
    my $self = shift;

    return $self->{__NAME__};
}

sub set_name {
    my $self          = shift;
    $self->{__NAME__} = shift;
}

sub set_type {
    my $self          = shift;
    $self->{__TYPE__} = shift;
}

sub get_controller_ident {
    my $self = shift;

    return $self->{__PARENT__}{__PARENT__}->get_ident();
}

sub get_controller_name {
    my $self = shift;

    return $self->{__PARENT__}{__PARENT__}->get_name();
}

sub change_name_method {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->get_ident eq $data->{ident};

    $self->set_name( $data->{ new_value } );

    return;
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    my %statements;

    foreach my $child_item ( @{ $child_output } ) {
        $statements{ $child_item->{ keyword } } = $child_item->{ values };
    }

    return [ {
        ident       => $self->get_ident,
        type        => 'method',
        name        => $self->get_name,
        method_type => $self->{__TYPE__},
        statements  => \%statements,
    } ];
}

sub change_method_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data->{ident} eq $self->get_ident() );

    my $old_value = $self->walk_postorder( 'get_method_keyword_value', $data );

    my $success   = $self->walk_postorder(
            'change_method_keyword_value', $data
    );

    unless ( defined $success->[0] ) {
        $self->add_method_statement( $data );
    }

    if ( $data->{ keyword } eq 'paged_conf' ) {
        my $current_value = $data->{ app }->get_config_statement(
                'base', $data->{ new_value }
        );

        unless ( defined $current_value->[0] and $current_value->[0] > 0 ) {
            my $config_ident = $data->{ app }->get_config_ident( 'base' );

            $data->{ app }->set_config_statement(
                    $config_ident, $data->{ new_value }, 20
            );
            return [ [ $config_ident . '::' . $data->{ new_value }, 20 ] ];
        }
    }

    return [ 1 ];
}

sub add_method_statement {
    my $self = shift;
    my $data = shift;

    my $new_statement = method_statement->new(
        $self->{__BODY__},
        $data->{keyword},
        $data->{new_value},
        $data->{pair_required},
    );

    my $blocks = $self->{ __BODY__ }{ 'method_statement(s?)' };
    push @{ $blocks }, $new_statement;
}

sub remove_method_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $data->{ident} eq $self->get_ident() );

    my $doomed_child = -1;
    my $count        = 0;

    my $statements = $self->{ __BODY__ }{'method_statement(s?)'};

    STATEMENT:
    foreach my $statement ( @{ $statements } ) {
        next STATEMENT unless $statement->{__KEYWORD__} eq $data->{keyword};

        $doomed_child = $count;
        last STATEMENT;
    }
    continue {
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        # This probably leaks memory because children have parent pointers.
        # But the parent is me and I'm the app_body, so maybe not.
        splice @{ $statements }, $doomed_child, 1;
    }
    # else, nothing to see here, move along quietly

    return [ 1 ];
}

sub get_method_statement {
    my $self    = shift;
    my $keyword = shift;

    my $statements = $self->{ __BODY__ }{'method_statement(s?)'};

    STATEMENT:
    foreach my $statement ( @{ $statements} ) {
        next STATEMENT unless $statement->{__KEYWORD__} eq $keyword;
        return $statement;
    }
    return;
}

sub change_type {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->get_ident eq $data->{ident} );

    $self->set_type( $data->{new_type} );

    return [ 1 ];
}

sub add_date_popups {
    my $self  = shift;
    shift;
    my $table = shift;

    return unless $self->{ __TYPE__ } =~ /form/;

    # First, make sure the form is named for the table (or has a name)
    my $form_statement = $self->get_method_statement( 'form_name' );
    my $form_name      = $table;

    if ( defined $form_statement ) {
        $form_name     = $form_statement->{ __ARGS__ }->get_first_arg();
    }
    else { # create a form_name statement
        $self->add_method_statement(
            {
                keyword   => 'form_name',
                new_value => $table,
            }
        );
    }

    # Second, make sure that name is in javascript code for calendars.
    my $javascript_code = qq{\$self->calendar_month_js( '$table' )},
    my $keys_statement  = $self->get_method_statement( 'extra_keys' );
    my $extra_keys;

    if ( defined $keys_statement ) {
        push @{ $keys_statement->{ __ARGS__ } },
             { javascript => $javascript_code };

        $extra_keys = $keys_statement->{ __ARGS__ };
    }
    else {
        $self->add_method_statement(
            {
                keyword   => 'extra_keys',
                new_value => {
                    'keys'   => 'javascript',
                    'values' => $javascript_code,
                },
            }
        );

        $extra_keys = $self->get_method_statement( 'extra_keys' )->{__ARGS__};
    }

    my $ident = $self->get_ident;
    return [
        $ident . '::form_name'  => $table,
        $ident . '::extra_keys' => $extra_keys,
    ];
}

sub update_field_name {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $count = 0;
    # remember that foreach aliases, this loop alters child output
    foreach my $key_or_val ( @{ $child_output } ) {
        if ( $count % 2 == 0 ) {
            $key_or_val = $self->{__IDENT__} . '::' . $key_or_val;
        }
        $count++;
    }

    return $child_output;
}

sub remove_field {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $count = 0;
    # remember that foreach aliases, this loop alters child output
    foreach my $key_or_val ( @{ $child_output } ) {
        if ( $count % 2 == 0 ) {
            $key_or_val = $self->{__IDENT__} . '::' . $key_or_val;
        }
        $count++;
    }

    return $child_output;
}

sub show_idents {
    my $self = shift;
    my $child_output = shift;

    push @{ $child_output }, [
        'method',
        $self->{ __NAME__ },
        $self->{ __IDENT__ },
        'controller: ' . $self->get_controller_ident,
    ];

    return $child_output;
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = $self->{__BODY__}->walk_postorder( $action, $data, $self );

    if ( $self->can( $action ) ) {
        return $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    my $statements   = {};

    if ( $child_output ) {
        $statements  = { @{ $child_output } }
    }

    return [
        {
            '__TYPE__'        => 'methods',
            '__DATA__'        => [
                $self->{__NAME__} => {
                    type       => $self->{__TYPE__},
                    statements => $statements,
                    __IDENT__  => $self->{__IDENT__},
                },
            ],
        }
    ];
}

package # method_body
    method_body;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class  = shift;

    my $self  = {
        __RULE__               => 'method_body',
        'method_statement(s?)' => [],
    };

    return bless $self, $class;
}

sub get_method_name {
    my $self = shift;

    return $self->{__PARENT__}{__NAME__};
}

sub get_controller_name {
    my $self = shift;

    return $self->{__PARENT__}{__PARENT__}->get_name();
}

sub get_table_name {
    my $self   = shift;
    my $lookup = shift;

    my $controller = $self->get_controller_name();
    return $lookup->{controllers}{$controller}{statements}{controls_table}[0];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $child ( @{ $self->{'method_statement(s?)'} } ) {
        my $child_output = $child->walk_postorder( $action, $data, $self );
        push @{ $output }, @{ $child_output } if $child_output;
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

package # method_statement
    method_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class     = shift;
    my $parent    = shift;
    my $keyword   = shift;
    my $new_value = shift;

    my $self      = {
        __PARENT__  => $parent,
        __KEYWORD__ => $keyword,
        __ARGS__    => arg_list->new( $new_value ),
    };

    return bless $self, $class;
}

sub change_method_keyword_value {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__KEYWORD__}     eq $data->{keyword} );

    $self->{__ARGS__}->set_args_from(
            $data->{new_value},
            $data->{pair_required},
    );

    return [ 1 ];
}

sub get_method_keyword_value {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__KEYWORD__}     eq $data->{keyword} );

    return $self->{__ARGS__};
}

sub app_block_hashes {
    my $self         = shift;

    return [ {
        keyword     => $self->{__KEYWORD__},
        values      => $self->{__ARGS__},
    } ];
}

sub update_field_name {
    my $self = shift;
    shift;
    my $data = shift;

    unless ( $self->{ __KEYWORD__ } eq 'cols'
                or
             $self->{ __KEYWORD__ } eq 'all_fields_but'
                or
             $self->{ __KEYWORD__ } eq 'fields' )
    {
        return;
    }

    my $we_did_something = 0;
    foreach my $arg ( @{ $self->{ __ARGS__ } } ) {
        if ( $arg eq $data->{ old_field_name } ) {
            $arg = $data->{ new_field_name };
            $we_did_something++;
        }
    }

    if ( $we_did_something ) {
        return [ $self->{ __KEYWORD__ }, $self->{ __ARGS__ } ];
    }
    else {
        return;
    }
}

sub remove_field {
    my $self = shift;
    shift;
    my $data = shift;

    unless ( $self->{ __KEYWORD__ } eq 'cols'
                or
             $self->{ __KEYWORD__ } eq 'all_fields_but'
                or
             $self->{ __KEYWORD__ } eq 'fields' )
    {
        return;
    }

    # we need to remove the arg if it matches the name of the deceased field
    my @new_args;

    # first, build a list of remaining args
    my $someone_died = 0;
    ARG:
    foreach my $arg ( @{ $self->{__ARGS__} } ) {
        if ( $arg eq $data->{ dead_field_name } ) { $someone_died++; }
        else                                      { push @new_args, $arg; }
    }

    return unless $someone_died;

    # second, install them in the object
    $self->{__ARGS__}->set_args_from( \@new_args );

    push @new_args, '';

    # third, return them as a full list for the statement
    return [ $self->{ __KEYWORD__ }, \@new_args ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [ $self->{__KEYWORD__} => $self->{__ARGS__} ];
}

package # controller_literal_block
    controller_literal_block;
use strict; use warnings;

use base 'application_ancestor';

sub get_backend {
    my $self = shift;

    return $self->{__BACKEND__};
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub make_output {
    my $self    = shift;
    my $backend = shift;

    if ( $backend eq $self->{__BACKEND__} ) {
        my $output = $self->{__BODY__};

        $output    =~ s/\Z/\n/ if ( $output !~ /\s\Z/ );

        return [ $output ];
    }
    else {
        return;
    }
}

package # controller_statement
    controller_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class   = shift;
    my $parent  = shift;
    my $keyword = shift;
    my $values  = shift;

    my $self    = {
        __PARENT__  => $parent,
        __KEYWORD__ => $keyword,
        __ARGS__    => arg_list->new( $values ),
    };

    return bless $self, $class;
}

sub get_controller_ident {
    my $self = shift;

    return $self->{__PARENT__}{__IDENT__};
}

sub get_controller_name {
    my $self = shift;

    return $self->{__PARENT__}{__NAME__};
}

sub change_controller_keyword_value {
    my $self = shift;
    shift;
    my $data = shift;

    return unless ( $self->{__KEYWORD__} eq $data->{keyword} );

    $self->{__ARGS__}->set_args_from(
            $data->{new_value},
            $data->{pair_required},
    );

    return [ 1 ];
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    return [ {
        type    => 'statement',
        keyword => $self->{__KEYWORD__},
        value   => $self->{__ARGS__},
    } ];
}

sub table_name_changed {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->{ __KEYWORD__ } eq 'controls_table';

    my $controlled_table = $self->{ __ARGS__ }->get_first_arg();

    if ( $controlled_table eq $data->{ old_name } ) {
        $self->{ __ARGS__ }->set_args_from( $data->{ new_name } );

        return [
            $self->get_controller_ident . '::controls_table',
            $data->{ new_name }
        ];
    }

    return;
}

sub field_name_changed {
    my $self         = shift;
    shift;
    my $data         = shift;

    return unless $self->{ __KEYWORD__ } eq 'controls_table';
    return unless $self->{ __ARGS__ }->get_first_arg()
                        eq
                  $data->{ table_name };

    # Leave this return value alone, an ancestor checks it to see if the
    # name change is for this controller or not.
    return [ 1 ];
}

# Yes, I know this is the same as the code above.  They are in different
# walk stacks.

sub field_removed {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return unless $self->{ __KEYWORD__ } eq 'controls_table';
    return unless $self->{ __ARGS__ }->get_first_arg()
                        eq
                  $data->{ table_name };

    # Leave this return value alone, an ancestor checks it to see if the
    # name change is for this controller or not.
    return [ 1 ];
}

sub do_I_control {
    my $self  = shift;
    shift;
    my $table = shift;

    return unless $self->{ __KEYWORD__ } eq 'controls_table';
    my $controlled_table = $self->{ __ARGS__ }->get_first_arg();

    if ( $controlled_table eq $table ) {
        return [ 1 ];
    }
    else {
        return;
    }
}

sub output_location {
    my $self         = shift;
    my $child_output = shift;

    return unless $self->{__KEYWORD__} eq 'location';

    return $self->{__ARGS__};
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [
        {
            '__TYPE__' => 'statements',
            '__DATA__' => [
                $self->{__KEYWORD__} => $self->{__ARGS__}
            ]
        }
    ];
}

package # app_config_block
    app_config_block;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class  = shift;
    my $params = shift;

    return bless {
        __IDENT__  => Bigtop::Parser->get_ident(),
        __PARENT__ => $params->{parent},
        __BODY__   => $params->{statements},
        __TYPE__   => $params->{type},
    }, $class;
}

sub new_block {
    my $class  = shift;
    my $parent = shift;
    my $data   = shift;

    return $class->new(
        {
            parent     => $parent,
            statements => [],
            type       => $data->{ name },
        }
    );
}

sub change_name_config {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->{__IDENT__} eq $data->{ident};

    $self->set_name( $data->{ new_value } );

    return;
}

sub set_name {
    my $self          = shift;
    $self->{__TYPE__} = shift;
}

sub add_config_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $data->{ ident } eq $self->{__IDENT__};

    my $new_statement = app_config_statement->new(
        $data->{ keyword  },
        $data->{ value    },
        $data->{ accessor },
        $self,
    );

    push @{ $self->{ __BODY__ } }, $new_statement;

    return [ 1 ];
}

sub remove_config_statement {
    my $self    = shift;
    shift;
    my $data    = shift;
    my $ident   = $data->{ ident   };
    my $keyword = $data->{ keyword };

    return unless $self->{__IDENT__} eq $ident;

    my $doomed_child = -1;
    my $count        = 0;

    STATEMENT:
    foreach my $child ( @{ $self->{ __BODY__ } } ) {
        my $child_keyword = $child->get_keyword();
        if ( $keyword eq $child_keyword ) {
            $doomed_child = $count;
            last STATEMENT;
        }
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        splice @{ $self->{ __BODY__ } }, $doomed_child, 1;
    }

    return [ 1 ];
}

sub get_app_configs {
    my $self         = shift;
    my $child_output = shift;

    my $type = $self->{__TYPE__} || 'base';

    my %my_children;
    foreach my $child ( @{ $child_output } ) {
        $my_children{ $child->{ var } } = $child->{ val };
    }

    return [ { type => $type, statements => \%my_children } ];
}

sub get_app_config_types {
    my $self = shift;

    my $type = $self->{__TYPE__} || 'base';

    return [ $type ];
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    my @statements;

    foreach my $child_item ( @{ $child_output } ) {
        my $no_accessor = 0;
        my $value       = $child_item->{ value };
        if ( ref( $value ) eq 'HASH' ) {
            ( $value, $no_accessor ) = %{ $value };
        }

        push @statements, {
            keyword     => $child_item->{ keyword },
            value       => $value,
            no_accessor => $no_accessor,
        };
    }

    return [ {
        ident       => $self->{__IDENT__},
        type        => 'config',
        name        => $self->{__TYPE__} || 'base',
        statements  => \@statements,
    } ];
}

sub get_ident {
    my $self = shift;

    return $self->{__IDENT__};
}

sub get_config_idents {
    my $self       = shift;
    shift;
    my $block_name = shift;

    if ( ( not defined $self->{__TYPE__} and $block_name eq 'base' )
                or
           $self->{__TYPE__} eq $block_name
    ) {
        return [ $self->{__IDENT__} ];
    }
    else {
        return;
    }
}

sub show_idents {
    my $self         = shift;
    my $child_output = shift;

    push @{ $child_output },
            [ 'config', $self->{ __NAME__ }, $self->{ __IDENT__ } ];

    return $child_output;
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $child ( @{ $self->{ __BODY__ } } ) {
        my $child_output = $child->walk_postorder( $action, $data, $self );
        push @{ $output }, @{ $child_output } if $child_output;
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return $child_output;
}

package # controller_config_block
    controller_config_block;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class  = shift;
    my $parent = shift;
    my $params = shift;

    my $self   = {
        __PARENT__ => $parent,
        __IDENT__  => Bigtop::Parser->get_ident(),
        __BODY__   => [],
        __TYPE__   => $params->{ new_child }{ name },
    };

    return bless $self, $class;
}

sub change_name_controller_config {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $self->get_ident  eq $data->{ident};

    $self->{__TYPE__} = $data->{new_value};

    return [ 1 ];
}

sub get_controller_name {
    my $self = shift;

    return $self->{__PARENT__}->get_name();
}

sub get_ident {
    my $self = shift;

    return $self->{__IDENT__};
}

sub get_controller_configs {
    my $self         = shift;
    my $child_output = shift;

    my $type = $self->{__TYPE__} || 'base';

    my %my_children;
    foreach my $child ( @{ $child_output } ) {
        $my_children{ $child->{ var } } = $child->{ val };
    }

    return [ { type => $type, statements => \%my_children } ];
}

sub add_config_statement {
    my $self = shift;
    shift;
    my $data = shift;

    return unless $data->{ ident } eq $self->{__IDENT__};

    my $new_statement = controller_config_statement->new(
        $data->{ keyword  },
        $data->{ value    },
        $self,
    );

    push @{ $self->{__BODY__} }, $new_statement;

    return [ 1 ];
}

sub remove_config_statement {
    my $self    = shift;
    shift;
    my $data    = shift;
    my $ident   = $data->{ ident   };
    my $keyword = $data->{ keyword };

    return unless $self->{__IDENT__} eq $ident;

    my $doomed_child = -1;
    my $count        = 0;

    STATEMENT:
    foreach my $child ( @{ $self->{__BODY__} } ) {
        my $child_keyword = $child->get_keyword();
        if ( $keyword eq $child_keyword ) {
            $doomed_child = $count;
            last STATEMENT;
        }
        $count++;
    }

    if ( $doomed_child >= 0 ) {
        splice @{ $self->{__BODY__} }, $doomed_child, 1;
    }

    return [ 1 ];
}

sub app_block_hashes {
    my $self         = shift;
    my $child_output = shift;

    my @statements;

    foreach my $child_item ( @{ $child_output } ) {
        my $no_accessor = 0;
        my $value       = $child_item->{ value };
        if ( ref( $value ) eq 'HASH' ) {
            ( $value, $no_accessor ) = %{ $value };
        }

        push @statements, {
            keyword     => $child_item->{ keyword },
            value       => $value,
            no_accessor => $no_accessor,
        };
    }

    return [ {
        ident       => $self->{__IDENT__},
        type        => 'config',
        name        => $self->{__TYPE__} || 'base',
        statements  => \@statements,
    } ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    my $output = [];

    foreach my $child ( @{ $self->{__BODY__} } ) {
        my $child_output = $child->walk_postorder( $action, $data, $self );
        push @{ $output }, @{ $child_output } if $child_output;
    }

    if ( $self->can( $action ) ) {
        $output = $self->$action( $output, $data, $parent );
    }

    ( ref( $output ) =~ /ARRAY/ ) ? return $output : return;
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return $child_output;
}

package # app_config_statement
    app_config_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class    = shift;
    my $keyword  = shift;
    my $value    = shift;
    my $accessor = shift;
    my $parent   = shift;

    my $self = {
        __PARENT__  => $parent,
        __KEYWORD__ => $keyword,
    };
 
    if ( $accessor ) {
        $self->{__ARGS__} = arg_list->new( [ { $value => 'no_accessor' } ] );
    }
    else {
        $self->{__ARGS__} = arg_list->new( [ $value ] );
    }

    return bless $self, $class;
}

sub get_keyword {
    my $self = shift;

    return $self->{__KEYWORD__};
}

sub get_config_statements {
    my $self = shift;

    return [ $self->{__KEYWORD__} => $self->{__ARGS__} ];
}

sub update_config_statement {
    my $self   = shift;
    shift;
    my $data   = shift;

    return unless ( $data->{ ident } eq $self->{__PARENT__}->get_ident );

    return [] unless ( $data->{ keyword } eq $self->{ __KEYWORD__ } );

    my $arg = $self->{__ARGS__}->get_first_arg();

    if ( ref( $arg ) eq 'HASH' ) {
        my ( $value, $no_access ) = %{ $arg };

        $self->{__ARGS__} = arg_list->new(
            [ { $data->{value} => $no_access } ]
        );
    }
    else {
        $self->{__ARGS__} = arg_list->new(
            [ $data->{value} ]
        );
    }

    return [ 1 ];
}

sub get_config_value {
    my $self    = shift;
    shift;
    my $data    = shift;

    my $config_type_name = $data->{ config_type_name };
    my $keyword          = $data->{ keyword };

#    warn "I want the config value for:\n";
#    use Data::Dumper; warn Dumper( $data );
#    warn 'my config type: ' . $self->get_config_type_name() . "\n";
#    warn "my keyword: $self->{__KEYWORD__}\n";
    
    return [] unless ( $config_type_name eq $self->get_config_type_name() );
    return [] unless ( $keyword eq $self->{ __KEYWORD__ } );

    return $self->{__ARGS__};
}

sub config_statement_status {
    my $self   = shift;
    shift;
    my $data   = shift;

    return unless ( $data->{ ident } eq $self->{__PARENT__}->get_ident );

    return [] unless ( $data->{ keyword } eq $self->{ __KEYWORD__ } );

    my $arg = $self->{__ARGS__}->get_args();

    if ( $data->{ value } ) { # add no_accessor flag
        $self->{__ARGS__} = arg_list->new(
            [ { $arg => 'no_accessor' } ]
        );
    }
    else { # remove flag
        $self->{__ARGS__} = arg_list->new(
            [ $arg ]
        );
    }

    return [];
}

sub get_app_configs {
    my $self = shift;

    my $var  = $self->{__KEYWORD__};
    my $val  = $self->{__ARGS__}->get_first_arg;

    if ( ref( $val ) eq 'HASH' ) {
        ( $val ) = keys %{ $val };
    }

    return [ { var => $var, val => $val } ];
}

sub app_block_hashes {
    my $self         = shift;

    return [ {
        keyword     => $self->{__KEYWORD__},
        value       => $self->{__ARGS__}[0],
    } ];
}

sub get_config_type_name {
    my $self = shift;

    return $self->{__PARENT__}{__TYPE__} || 'base';
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [
        {
            '__TYPE__' => 'configs',
            '__DATA__' => [
                $self->{__KEYWORD__} => $self->{__ARGS__}
            ]
        }
    ];
}

package # controller_config_statement
    controller_config_statement;
use strict; use warnings;

use base 'application_ancestor';

sub new {
    my $class    = shift;
    my $keyword  = shift;
    my $value    = shift;
    my $parent   = shift;

    my $self = {
        __PARENT__  => $parent,
        __KEYWORD__ => $keyword,
    };
 
    $self->{__ARGS__} = arg_list->new( [ $value ] );

    return bless $self, $class;
}

sub get_keyword {
    my $self = shift;

    return $self->{__KEYWORD__};
}

sub get_controller_configs {
    my $self = shift;

    my $var  = $self->{__KEYWORD__};
    my $val  = $self->{__ARGS__}->get_first_arg;

    if ( ref( $val ) eq 'HASH' ) {
        ( $val ) = keys %{ $val };
    }

    return [ { var => $var, val => $val } ];
}

sub app_block_hashes {
    my $self         = shift;

    return [ {
        keyword     => $self->{__KEYWORD__},
        value       => $self->{__ARGS__}[0],
    } ];
}

sub update_config_statement {
    my $self   = shift;
    shift;
    my $data   = shift;

    return unless ( $data->{ ident } eq $self->{__PARENT__}->{__IDENT__} );

    return [] unless ( $data->{ keyword } eq $self->{ __KEYWORD__ } );

    my $arg = $self->{__ARGS__}->get_first_arg();

    $self->{__ARGS__} = arg_list->new(
        [ $data->{value} ]
    );

    return [ 1 ];
}

sub walk_postorder {
    my $self   = shift;
    my $action = shift;
    my $data   = shift;
    my $parent = shift;

    if ( $self->can( $action ) ) {
        return $self->$action( undef, $data, $parent );
    }
    else {
        return;
    }
}

sub build_lookup_hash {
    my $self         = shift;
    my $child_output = shift;
    my $data         = shift;

    return [
        {
            '__TYPE__' => 'configs',
            '__DATA__' => [
                $self->{__KEYWORD__} => $self->{__ARGS__}
            ]
        }
    ];
}

package # arg_list
    arg_list;
use strict; use warnings;

sub new {
    my $class         = shift;
    my $values        = shift;
    my $pair_required = shift;

    return bless build_values( $values, $pair_required ), $class;
}

sub build_values {
    my $values        = shift;
    my $pair_required = shift;

    if ( ref( $values ) eq 'ARRAY' ) {
        return $values;
    }
    elsif ( ref( $values ) eq 'HASH' ) {
        my $value_str = $values->{ values } || '';
        my @keys      = split /\]\[/, $values->{ keys   };
        my @values    = split /\]\[/, $value_str;

        my @retvals;

        for ( my $i = 0; $i < @keys; $i++ ) {
            if ( $pair_required ) {
                my $push_value = defined ( $values[ $i ] )
                               ? $values[ $i ]
                               : '';

                push @retvals, { $keys[ $i ] => $push_value };
            }
            elsif ( defined $pair_required ) {
                if ( not defined $values[ $i ]
                        or
                     $values[ $i ] eq 'undefined'
                        or
                     not $values[ $i ]
                ) {
                    push @retvals, $keys[ $i ];
                }
                else {
                     push @retvals, { $keys[ $i ] => $values[ $i ] };
                }
            }
            else {
                if ( defined $values[ $i ] and $values[ $i ] ne 'undefined' ) {
                     push @retvals, { $keys[ $i ] => $values[ $i ] };
                }
                else {
                    push @retvals, $keys[ $i ];
                }
            }
        }

        return \@retvals;
    }
    else {
        my @values = split /\]\[/, $values;

        return \@values;
    }
}

sub get_first_arg {
    my $self = shift;

    return $self->[0];
}

sub get_args {
    my $self = shift;

    my @args;

    foreach my $arg ( @{ $self } ) {
        if ( ref( $arg ) =~ /HASH/ ) {
            my ( $name, $condition ) = %{ $arg };
            push @args, $name;
        }
        else {
            push @args, $arg;
        }
    }

    return join ', ', @args;
}

sub get_quoted_args {
    my $self = shift;

    my @args;

    foreach my $arg ( @{ $self } ) {
        if ( ref( $arg ) =~ /HASH/ ) {
            my ( $name, $condition ) = %{ $arg };

            unless ( $name =~ /^\w[\w\d_]*$/ ) {
                $name = "`$name`";
            }

            unless ( $condition =~ /^\w[\w\d_]*$/ ) {
                $condition = "`$condition`";
            }

            push @args, "$name => $condition";
        }
        else {
            my $value = $arg;
            if ( $value !~ /^\w[\w\d_:]*$/ ) {
                $value = "`$value`";
            }
            else {
                my @value_pieces = split /::/, $value;
                # if any of the pieces has a colon, quote the value
                VALUE_PIECE:
                foreach my $piece ( @value_pieces ) {
                    if ( $piece =~ /:/ ) {
                        $value = "`$value`";
                        last VALUE_PIECE;
                    }
                }
            }

            push @args, $value;
        }
    }

    return ( wantarray ) ? @args : join ', ', @args;
}

sub get_unquoted_args {
    my $self = shift;

    my @args;

    foreach my $arg ( @{ $self } ) {
        if ( ref( $arg ) =~ /HASH/ ) {
            my ( $name, $condition ) = %{ $arg };

            push @args, "$name => $condition";
        }
        else {
            push @args, $arg;
        }
    }

    return \@args;
}

sub set_args_from {
    my $self          = shift;
    my $new_values    = shift;
    my $pair_required = shift;

    pop  @{ $self } while ( @{ $self } );

    my $paired_values = build_values( $new_values, $pair_required );

    push @{ $self }, @{ $paired_values };
}

sub one_hash {
    my $self = shift;

    my %args;

    foreach my $arg ( @{ $self } ) {
        if ( ref( $arg ) =~ /HASH/ ) {
            my ( $key, $value ) = %{ $arg };
            $args{ $key } = $value;
        }
        else {
            $args{ $arg } = undef;
        }
    }

    return \%args;
}

sub unbless_args {
    my $self = shift;

    my @args;

    foreach my $arg ( @{ $self } ) {
        push @args, $arg;
    }

    return \@args;
}

1;

=head1 NAME

Bigtop::Parser - the Parse::RecDescent grammar driven parser for bigtop files

=head1 SYNOPSIS

Make a file like this:

    config {
        base_dir `/home/username`;
        Type1 Backend {}
        Type2 Backend {}
        Type3 Backend {}
    }
    app App::Name {
        table name { }
        controller SomeController {}
    }

Then run this command:

    bigtop my.bigtop all

=head1 DESCRIPTION

This module is really only designed to be used by the bigtop and tentmaker
scripts.  It provides access to the grammar which understands bigtop files
and turns them into syntax trees.  It provides various utility functions
for bigtop, tentmaker, backends, and similar tools you might write.

If you just want to use bigtop, you should look in C<Bigtop::Docs::TOC>
where all the docs are outlined.

Reading further is an indication that you are interested in working on Bigtop
and not just in using it to serve your needs.

=head1 METHODS

In this section, the methods are grouped, so that similar ones appear together.

=head2 METHODS which drive generation for scripts

=over 4

=item gen_from_file

The bigtop script calls this method.

Returns: the app name and the name of the build directory.

You can call this as a class method passing it the name of the bigtop
file to read and a list of the things to build.

The method is actually quite simple.  It merely reads the file, then
calls gen_from_string.

=item gen_from_string

The bigtop script calls this method when --new is used.

Returns: the app name and the name of the build directory.

This method orchestrates the build.  It is called internally by gen_from_file.
Call it as a class method.  Pass it a hash with these keys:

    bigtop_string => the bigtop source code
    bigtop_file   => the name of the bigtop file, if you know it
    create        => are you in create mode? if so make this true
    build_list    => [ what to build ]
    flags         => command line args given to your script

bigtop_file is used by Bigtop::Init::Std to copy the bigtop file from
its original location into the docs subdirectory of the build directory.
If the file name is not defined, it skips that step.

If you set create to any true value, you will be in create mode and bigtop
will make the build directory as a subdirectory of the current directory.
Otherwise, it will make sure you are in a directory which looks like a build
directory before building.

The list of things to build can include any backend type listed in the
config block and/or the word 'all'.  'all' will be replaced with a list
of all the backend types in the config section (in the order they appear
there), as if they had been passed in.

It is legal to mention the same backend more than once.  For instance, you
could call gen_from_string directly

    Bigtop::Parser->gen_from_string(
        {
            bigtop_string => $bigtop_string,
            bigtop_file   => 'file.bigtop',
            create        => $create,
            build_list    => [ 'Init', 'Control', 'Init' ]
        }
    );

or equivalently, and more typically, you could call gen_from_file:

    Bigtop::Parser->gen_from_file(
        'file.bigtop', $create, 'Init', 'Control', 'Init'
    );

Either of these might be useful, if the first Init sets up directories that
the Control backend needs, but the generated output from Control should
influence the contents of file which Init finally builds.  Check your backends
for details.

The flags are given to Init Std as text, so they may be preserved for
posterity in the Changes file.

gen_from_string internals

gen_from_string works like this.  First, it attempts to parse the config
section of the bigtop string.  If that works, it iterates through each
backend mentioned there building a list of modules to require.  This
includes looking in backend blocks for template statements.  Their values
must be template files relative to the directory from which bigtop
was invoked.

Once the list is built, it calls its own import method to require them.
This allows each backend to register its keywords.  If any keyword
used in the app section is not registered, a fatal parse error results.

Once the backends are all required, gen_from_string parses the whole
bigtop string into an abstract syntax tree (AST).  Then it iterates
through the build list calling gen_Type on each element's backend.
So this:

    config {
        Init Std      {}
        SQL  Postgres { template `postgres.tt`; }
    }
    app ...

    Bigtop::Parser->gen_from_string(
            $bigtop_string, 'file.bigtop', 'Init', 'SQL'
    );

Results first in the loading of Bigtop::Init::Std and Bigtop::SQL::Postgres,
then in calling gen_Init on Init::Std and gen_SQL on SQL::Postgres.  During
the loading, setup_template is called with postgres.tt on SQL::Postgres.

gen_* methods are called as class methods.  They receive the build directory,
the AST, and the name of the bigtop_file (which could be undef).
Backends can do whatever they like from there.  Typically, they put
files onto the disk.  Those files might be web server conf files,
sql to build the database, control modules, templates for viewing, models,
etc.

=back

=head2 METHODS which invoke the grammar

=over 4

=item parse_config_string

Called as a class method (usually by gen_from_string), this method receives
the bigtop input as a string.  It attempts to parse only the config section
which it returns as an AST.  Syntax errors in the config section are
fatal.  Errors in the app section are not noticed.

=item parse_file

Call this as a class method, passing it the file name to read.  It reads
the file into memory, then calls parse_string, returning whatever it
returns.

=item parse_string

Call this as a class method, passing it the bigtop string to parse.
It calls the grammar to turn the input into an AST, which it returns.

=back

=head2 METHODS which control which simple statement keywords are legal

=over 4

=item add_valid_keywords

The grammar of a bigtop file is structured, but the legal keywords in
its simple statements are defined by the backends (excepts that the config
keywords are defined by this module, see Config Keywords below for those).

Acutally, all the keywords that any module will use should be defined
in C<Bigtop::Keywords> so tentmaker can display them.  Then the backend
(or its type) should pull the keyword definitions it wants from
C<Bigtop::Keywords>.

If you are writing a backend, you should use the base module for your
backend type.  This will register the standard keywords for that type.
For example, suppose you are writing Bigtop::Backend::SQL::neWdB.  It
should be enough to say:

    use Bigtop::SQL;

in your module.

If you need to add additional keywords that are specific to your backend,
put them in a begin block like this:

    BEGIN {
        Bigtop::Parser->add_valid_keywords(
            Bigtop::Keywords->get_docs_for(
                $type,
                qw( your keywords here),
            )
        );
    }

Here $type is the name of the surrounding block in which this keyword 
will make a valid statement.  For example, if $type above is 'app' then
this would be legal:

    app App::Name {
        your value;
    }

The type must be one of these levels:

=over 4

=item config

=item app

=item app_literal

=item table

=item join_table

=item field

=item controller

=item controller_literal

=item method

=back

These correspond to the block types in the grammar.  Note, that there
are also sequence blocks, but they are deprecated and never allowed statements.
Further, the various literals are blocks in the grammar (they have block
idents and can have defined keywords), but they don't have brace delimiters.
Instead, they have a single backquoted string.

=item is_valid_keyword

Call this as a class method, passing it a type of keyword and a word that
might be a valid keyword of that type.

Returns true if the keyword is valid, false otherwise.

=item get_valid_keywords

Call this as a class method passing it the type of keywords you want.

Returns a list of all registered keywords, of the requested type, in
string sorted order.

The two preceding methogs are really for internal use in the grammar.

=back

=head2 METHODS which work on the AST

There are quite a few other methods not documented here (shame on me).
Most of those support tentmaker manipulations of the tree, but there
are also some convenience accessors.

=over 4

=item walk_postorder

Walks the AST for you, calling you back when it's time to build something.

The most common skeleton for gen_Backend is:

    use Bigtop;
    use Bigtop::Backend;

    sub gen_Backend {
        my $class     = shift;
        my $build_dir = shift;
        my $tree      = shift;

        # walk the tree
        my $something     = $tree->walk_postoder( 'output_something' );
        my $something_str = join '', @{ $something };

        # write the file
        Bigtop::write_file( $build_dir, $something_string );
    }

This walks the tree from the root.  The walking is postorder meaning that
all children are visited before the current node.  Each walk_postorder
returns an array reference (which is why we have to join the result
in the above skeleton).  After the children have been visited, the
callback (C<output_something> in the example) is called with their output
array reference.  You can also pass an additional scalar (which is usually
a hash reference) to walk_postorder.  It will be passed along to all
the child walk_postorders and to the callbacks.

With this module walking the tree, all you must do is provide the appropriate
callbacks.  Put one at each level of the tree that interests you.

For example, if you are generating SQL, you need to put callbacks in
at least the following packages:

    table_block
    table_element_block
    field_statement

This does require some knowledge of the tree.  Please consult bigtop.grammar,
in the lib/Bigtop subdirectory of Bigtop's build directory,
for the possible packages (or grep for package on this file).
There are also several chapters of the Gantry book devoted to explaining
how to use the AST to build backends.

The callbacks are called as methods on the current tree node.  They receive
the output array reference from their children and the data scalar that
was passed to walk_postorder (if one was passed in the top level call).
So, a typical callback method might look like this:

    sub output_something {
        my $self         = shift;
        my $child_output = shift;
        my $data         = shift;
        ...
        return [ $output ];
    }

Remember that they must return an array reference.  If you need something
fancy, you might do this:

    return [ [ type1_output => $toutput, type2_output => $other_out ] ];

Then the parent package's callback will receive that and must tease
apart the the two types.  Note that I have nested arrays here.  This prevents
two children from overwriting each other's output if you are ever tempted
to try saving the return list directly to a hash (think recursion).

(walk_postorder also passes the current node to each child after the
data scalar.  This is the child's parent, which is really only useful
during parent building inside the grammar.  The parent comes
after the data scalar in both walk_postorder and in the callback.
Most backends will just peek in $self->{__PARENT__} which is gauranteed
to have the parent once the grammar finishes with the AST.)

=item set_parent

This method is the callback used by the grammar to make sure that all nodes
know who their daddy is.  You shouldn't call it, but looking at it shows
what the simplest callback might look like.  Note that there is only one
of these and it lives in the application_ancestor package, which is not
one of the packages defined in the grammar.  But, this module makes
sure that all the grammar defined packages inherit from it.

=item build_lookup_hash

This method builds the lookup hash you can use to find data about other
parts of the tree, without walking to it.

The AST actually has three keys: configuration, application, and lookup.
The first two are built in the normal way from the input file.  They
are genuine ASTs in their own right.  The lookup key is not.  It does
not preserve order.  But it does make it easier to retrieve things.

For example, suppose that you are in the method_body package attempting
to verify that requested fields for this method are defined in the
table for this controller.  You could walk the tree, but the lookup hash
makes it easier:

    unless (
        defined $tree->{lookup}{tables}{$table_name}{fields}{$field_name}
    ) {
        die "No such column $field_name\n";
    }

The easiest way to know what is available is to dump the lookup hash.
But the pattern is basically this.  At the top level there are fixed keywords
for the app level block types: tables, sequences, controllers.  The next
level is the name of a block.  Under that, there is a fixed keyword for
each subblock type, etc.

=back

=head2 METHODS for use in walk_postorder callbacks

=over 4

=item dumpme

Use this method instead of directly calling Data::Dumper::Dump.

While you could dump $self, that's rather messy.  The problem is the parent
nodes.  Their presence means a simple dump will always show the whole app
AST.  This method carefully removes the parent, dumps the node, and restores
the parent, reducing clutter and leaving everything in tact.  The closer
to a leaf you get, the better it works.

=item get_appname

Call this on the full AST.  It returns the name of the application.

=item get_config

Call this on the full AST.  It returns the config subtree.

=item get_controller_name

Call this, from the method_body package, on the AST node ($self in the
callback).  Returns the name of the controller for this method.  This
is useful for error reporting.

=item get_method_name

Call this, from the method_body package, on the AST node ($self in the
callback).  Returns the name of this method.  Useful for error reporting.

=item get_name

While this should work everywhere, it doesn't.  Some packages have it.
If yours does, call it.  Otherwise peek in $self->{__NAME__}.  But,
remember that not everything has a name.

=item get_table_name

Call this, from the method_body package, on the AST node ($self in the
callback).  Returns the name of the table this controller controls.
Useful for error reporting.

=back

=head2 METHODS used internally

=over 4

=item import

You probably don't need to call this.  But, if you do, pass it a list
of backends to import like this:

    use Bigtop::Parser qw( Type=Backend=template.tt );

This will load Bigtop::Type::Backend and tell it to use template.tt.
You can accomplish the same thing by directly calling import as a class
method:

    Bigtop::Parser->import( 'Type=Backend=template.tt' );

=item fatal_error_two_lines

This method is used by the grammar to report fatal parse error in the input.
It actually gives 50 characters of trailing context, not two lines, but
the name stuck.

=item fatal_keyword_error

This method is used by the grammer to report on unregistered (often misspelled)
keywords.  It identifies the offending keyword and the line where it appeared
in the input, gives the remainder of the line on which it was seen (which
is sometimes only whitespace), and lists the legal choices (often wrapping
them in an ugly fashion).

=back

=head1 Config KEYWORDS

For simplicity, all config keywords are requested from C<Bigtop::Keywords>
in this module.  This is not necessarily ideal and is subject to change.

=over 4

=item base_dir

Used only if you supply the --create flag to bigtop (or set create to true
when calling gen_from_file or gen_from_string as class methods of this
module).

When in create mode, the build directory will be made as a subdirectory
of the base_dir.  For instance, I could use my home directory:

    base_dir `/home/username`;

Note that you need the backquotes to hide the slashes.  Also note, that
you should use a path which looks good on your development system.  In
particular, this would work on the appropriate platform:

    base_dir `C:\path\to\build`;

The default base_dir is the current directory from which bigtop is run.

=item app_dir

Used only if you supply the --create flag to bigtop (or set create to true
when calling gen_from_file or gen_from_string as class methods of this
module).

When in create mode, the actual generated files will be placed into
base_dir/app_dir (where the slash is correctly replaced with your OS
path separator).  If you are in create mode, but don't supply an app_dir,
a default is formed from the app name in the manner h2xs would use.
Consider:

    config {
        base_dir `/home/username`;
    }
    app App::Name {
    }

In this case the app_dir is App-Name.  So the build directory is

    /home/username/App-Name

By specifying your own app_dir statement, you have complete control
of where the app is initially built.  For example:

    config {
        base_dir `/home/username`;
        app_dir  `myappdir`;
    }
    app App::Name { }

Will build in /home/username/myappdir.

When not using create mode, all files will be built under the current
directory.  If that directory doesn't look like an app build directory,
a fatal error will result.  Either move to the proper directory, or
use create mode to avoid the error.

=item engine

This is passed directly to the C<use Framework;> statement of the top level
controller.

Thus,

    engine MP13;

becomes something like this:

    use Framework qw/ engine=MP13 /;

in the base level controller.  Both Catalyst and Gantry expect this
syntax.

The available engines depend on what the framework supports.  The one
in the example is mod_perl 1.3 in the syntax of Catalyst and Gantry.

=item template_engine

Similar to engine, this specifies the template engine.  Choices almost always
include TT, but might also include Mason or other templaters depending on
what your framework supports..

=back

=head1 Other KEYWORDS

=over 4

=item literal

This keyword applies to many backends at the app level and at some other
levels.  This keyword is special, because it expects a type keyword
immediately before its values.  For example:

    literal SQL `CREATE...`;

It always instructs someone (the backend of type SQL in the example) to
directly insert the backquoted string into its output, without so much as
adjusting whitespace.

Backend types that should obey this statement are:

    SQL      - for backends of type SQL
    Location - for backends constructing apache confs or the like

The literal Location statement may also be used at the controller level.

=item no_gen

Applies to backend blocks in the config block, app blocks, controller
blocks, and method blocks.

gen_from_string enforces the app level no_gen.  If it has a true value
only a warning is printed, nothing is generated.  None of the backends
are called.

gen_from_string also enforces no_gen on entire backends, if their config
block has a true no_gen value.

The Control backend of your choice is responsible for enforcing no_gen
at the controller and method levels.

=item not_for

Applies to tables and fields (although the latter only worked for Models
at the time of this writing).

Each backend is responsible for enforcing not_for.  It should mean
that the field or table is ignored by the named backend type.  Thus

    table skip_model {
        not_for Model;
    }

should generate as normal in SQL backends, but should be completely
ignored for Models.  The same should hold for fields marked not_for.
But my SQL backends didn't do that when I wrote this, only the Models
worked.

=back

=head1 METHODS

=over 4

=item get_keyword_docs

Called by TentMaker, so it can display the backend comments to the user
through their browser.

Returns: a hash reference of keyword docs understood by tentmaker's
templates.

=item gen_mode

Used internally.

Get accessor for whether we are really generating, or just serving tentmaker.
If we are not generating, there is no need to set up the templates for
all the backends.

=item set_gen_mode

Used internally.

Set accessor for whether we are really generating.

=item get_ident

Returns: the next available ident (as ident_n).

=item get_parser

Used internally.

Accessor to ensure that only one parser is ever instantiated.

=item load_backends

Used internally.

Responsible for loading all needed backends.

=item preprocess

Used internally.

Strips comment lines.

Returns: a hash keyed by line number, storing the comment on that line
before it was stripped..

=back

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005-7 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
