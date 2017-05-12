package Bigtop::TentMaker;
use strict; use warnings;

use base 'Gantry';

use Bigtop::Parser;
use Bigtop::Deparser;
use Bigtop::ScriptHelp;

use File::Find;
use File::Spec;

# Parsing takes time, I'm caching these.  I blow out the cached values
# when $file changes.
my $file;
my $input;
my $tree;
my $deparsed;
my $dirty;
my %backends;
my %engines;
my %template_engines;
my $statements;
my $testing = 0;

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    return if $AUTOLOAD =~ /DESTROY$/;

    warn "$self was asked to $AUTOLOAD\n";
}

# preambles

sub take_performance_hit {
    my $class        = shift;
    my $style        = shift;
    $file            = shift;   # this one is global, sorry Damian
    my $art          = shift;
    my $new_app_name = shift;

    build_backend_list( @_ );

    $class->read_file( $new_app_name );

    # build and deparse the tree
    Bigtop::Parser->set_gen_mode( 0 );
    $tree      = Bigtop::Parser->parse_string( $class->input );

    # now that we have the initial tree, add the art
    Bigtop::ScriptHelp->augment_tree( $style, $tree, $art );

    $class->deparsed( Bigtop::Deparser->deparse( $tree ) );

    $class->update_backends( $tree );

    $statements = Bigtop::Parser->get_keyword_docs();

    # No changes yet, but we called deparsed.
    $dirty = 0;
}

sub build_backend_list {
    my @incs           = @_;

    if ( @incs < 1 ) {
        require Bigtop;

        my $bigtop_path = $INC{ 'Bigtop.pm' };

        my ( undef, $dir, undef ) = File::Spec->splitpath( $bigtop_path );

        @incs = ( $dir );
    }

    %backends          = (); # in testing we call this repeatedly
    %engines           = ();
    %template_engines  = ();

    my %seen;  # don't try to load all possible modules, just the first ones
    my @modules;

    my $filter = sub {
        my $module = $File::Find::name;

        if ( $module =~ /Gantry.Engine.*.pm/ ) {
            $module =~ s{.*Engine\W}{};
            $module =~ s{.pm$}{};
            $engines{ $module }++;

            return;
        }

        if ( $module =~ /Gantry.Template.*.pm/ ) {
            $module =~ s{.*Template\W}{};
            $module =~ s{.pm$}{};
            $template_engines{ $module }++;

            return;
        }

        return unless $module =~ /Bigtop.*Backend.*\.pm$/;

        my $module_prefix = File::Spec->catfile( 'Bigtop', 'Backend' );

        $module =~ s{.*Bigtop.Backend}{$module_prefix}; # could use look ahead

        return if $seen{ $module }++;

        push @modules, $module;
    };

    #my @real_inc;
    #foreach my $entry ( @INC ) {
    #    push @real_inc, $entry if ( -d $entry );
    #}

    find( { wanted => $filter, chdir => 0 }, @incs );

    foreach my $module ( sort @modules ) {

        require "$module";

        # Load in its what_do_you_make info
        my ( undef, $dirs, $pm_name ) = File::Spec->splitpath( $module );

        my @dirs = grep /\w/, File::Spec->splitdir( $dirs );

        $pm_name =~ s{.pm}{};

        my $package = join '::', @dirs, $pm_name;

        my ( undef, undef, $type, $name ) = split /::/, $package;

        if ( defined $name ) {

            if ( $package->can( 'what_do_you_make' ) ) {
                my $package_output = $package->what_do_you_make();
                $backends{ $type }{ $name }{ output } = $package_output;
            }

            if ( $package->can( 'backend_block_keywords' ) ) {
                my $block_keywords = $package->backend_block_keywords();
                $backends{ $type }{ $name }{ keywords } = $block_keywords;
            }

            $backends{ $type }{ $name }{ in_use     } = 0;
            $backends{ $type }{ $name }{ statements } = {};
        }
    }

    my @engines          = sort keys %engines;
    my @template_engines = sort keys %template_engines;
}

sub init {
    my $self = shift;
    my $r    = shift;

    $self->SUPER::init( $r );

    $self->set_file( $self->fish_config( 'file' ) );
}

# for testing only, usually objects are constructed in the Gantry handler
sub new {
    my $class = shift;

    return bless {}, $class;
}

sub set_testing {
    shift;             # don't need invocant
    $testing  = shift;
}

# for doc building scripts:
sub get_backends {
    return \%backends;
}

# for testing
sub show_idents {
    $tree->walk_postorder( 'show_idents' );
}

# initial end user page handler

sub do_main {
    my $self        = shift;
    my $tab         = shift || 'tab-bigtop-config';
    my $tab_scroll  = shift || 0;
    my $body_scroll = shift || 0;

    if ( not defined $tree ) {
        $self->read_file();

        # deparse the tree
        Bigtop::Parser->set_gen_mode( 0 );
        $tree      = Bigtop::Parser->parse_string( $self->input );
        $self->deparsed( Bigtop::Deparser->deparse( $tree ) );

        $self->update_backends( $tree );
    }

    my @types   = keys %{ $statements };

    $self->stash->view->template( 'tenter.tt' );
    $self->stash->view->title( 'TentMaker Home' );
    $self->stash->view->data(
        {
            input                 => $self->deparsed,
            top_level_configs     => $tree->get_top_level_configs,
            engine                => $tree->get_engine,
            template_engine       => $tree->get_template_engine,
            app                   => $tree->get_app,
            app_blocks            => $tree->get_app_blocks,
            backends              => \%backends,
            statements            => $statements,
            app_config_statements => compile_app_configs(),
            file_name             => $file,
            tab                   => $tab,
            tab_scroll            => $tab_scroll,
            body_scroll           => $body_scroll,
        }
    );
    # warn $self->stash->view->data()->{ input } . "\n";
}

sub compile_app_configs {
    my %app_config_statements = @{ $tree->get_app()->get_config() };
    my @app_config_statements;

    foreach my $config_statement ( sort keys %app_config_statements ) {
        my $arg = $app_config_statements{ $config_statement }->get_first_arg;

        my $no_accessor;
        my $value;

        if ( ref( $arg ) eq 'HASH' ) {
            ( $value, $no_accessor ) = %{ $arg };
            $no_accessor = ( $no_accessor eq 'no_accessor' ) ? 1 : 0;
        }
        else {
            ( $value, $no_accessor ) = ( $arg, 0 );
        }

        my $statement_hash = {
            keyword     => $config_statement,
            value       => $value,
            no_accessor => $no_accessor,
        };

        push @app_config_statements, $statement_hash;
    }

    return \@app_config_statements;
}

sub do_save {
    my $self          = shift;

    # Some versions of HTTP::Server::Simple prematurely convert %2F to /,
    # making these directory separators look like URL path elements.
    # Here, I join them back together.
    my @unescaped_path_els;
    foreach my $path_el ( @_ ) {
        push @unescaped_path_els, unescape( $path_el );
    }

    return $self->stash->controller->data(
            "Error: No file name given."
    ) unless ( @unescaped_path_els > 0 );

    my $new_file_name = File::Spec->catfile( @unescaped_path_els );

    if ( open my $BIGTOP_UPDATE, '>', $new_file_name ) {

        # XXX Assume it will work if we opened it (not always good, I know).
        print $BIGTOP_UPDATE $self->deparsed;
        close $BIGTOP_UPDATE;

        $dirty = 0;

        $self->template_disable( 1 );
        return $self->stash->controller->data( "Saved $new_file_name" );
    }
    else {
        warn "Couldn't open file $new_file_name: $!\n";

        $self->template_disable( 1 );
        return $self->stash->controller->data(
                "Couldn't write $new_file_name: $!"
        );
    }
}

sub do_server_stop {
    my $pid = $$;

    my $parent_of = fork();

    if ( $parent_of ) {
        return 1;
    }
    else {
        kill 'TERM', $pid;
        exit;
    }
}

# for use by all do_update_* methods
sub complete_update {
    my $self = shift;

    $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
    $self->update_backends( $tree );

    $self->template_disable( 1 );
    return $self->stash->controller->data( $self->deparsed );
}

sub unescape {
    my $input = shift;

    return unless defined $input;

    $input    =~ s/\+/ /g;
    $input    =~ s/%([0-9a-fA-F]{2})/chr( hex( $1 ) )/ge;

    return $input;
}

sub _old_unescape {
    my $input = shift;

    return unless defined $input;

    $input    =~ s/\+/ /g;
    $input    =~ s/%([0-9a-fA-F]{2})/chr( hex( $1 ) )/ge;

    return $input;
}

# AJAX handlers MISC.

sub do_update_std {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( @_ );

    my $method    = "set_$parameter";

    eval {
        $tree->$method( $new_value );
    };
    if ( $@ ) {
        warn "error: $@\n";
    }

    $self->complete_update();
}

sub do_update_top_config_text {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( @_ );

    eval {
        if ( $new_value eq 'undefined' ) {
            $tree->clear_top_level_config( $parameter );
        }
        else {
            $tree->set_top_level_config( $parameter, $new_value );
        }
    };
    if ( $@ ) {
        warn "error: $@\n";
        return;
    }

    $self->complete_update();
}

sub do_update_backend {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( @_ );

    if ( $parameter =~ /(.*)::(.*)/ ) {
        my ( $type, $backend ) = ( $1, $2 );

        if ( $new_value eq 'false' ) {
            drop_backend( $tree, $type, $backend );
        }
        else {
            add_backend(  $tree, $type, $backend );
        }
    }
    else {
        warn "error: mal-formed update_backend request\n";
        return;
    }

    $self->complete_update();
}

# AJAX hanlers for Bigtop config block

sub do_update_conf_text {
    my $self      = shift;
    my $parameter = shift;

    #pop @_ if ( $_[-1] eq 'undefined' );

    my $new_value = unescape( @_ );

    if ( $parameter =~ /(.*)::(.*)::(.*)/ ) {
        my ( $type, $backend, $keyword ) = ( $1, $2, $3 );

        my $value = ( $new_value ) ? $new_value : 'undef';

        change_conf( $tree, $type, $backend, $keyword, $value );
    }
    else {
        warn "error: mal-formed update_conf_bool request\n";
        return;
    }

    $self->complete_update();
}

sub do_update_conf_bool {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    if ( $parameter =~ /(.*)::(.*)::(.*)/ ) {
        my ( $type, $backend, $keyword ) = ( $1, $2, $3 );

        my $value = ( $new_value eq 'false' ) ? 0 : 1;

        change_conf( $tree, $type, $backend, $keyword, $value );
    }
    else {
        warn "error: mal-formed update_conf_bool request\n";
        return;
    }

    $self->complete_update();
}

sub do_update_conf_bool_controlled {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );
    my $false     = shift;
    my $true      = shift;

    if ( $parameter =~ /(.*)::(.*)::(.*)/ ) {
        my ( $type, $backend, $keyword ) = ( $1, $2, $3 );

        my $value = ( $new_value eq 'false' ) ? $false : $true;

        change_conf( $tree, $type, $backend, $keyword, $value );
    }
    else {
        warn "error: mal-formed update_conf_bool_backward request\n";
        return;
    }

    $self->complete_update();
}

# AJAX handlers for Bigtop app block statements

sub do_update_app_statement_text {
    my $self      = shift;
    my $keyword   = shift;
    my $new_value = unescape( @_ );

    $new_value    = 'undefined' unless defined $new_value;

    $new_value    =~ s/\s+\Z//m; # strip trailing whitespace from last line

    if ( $new_value ne 'undefined' and $new_value ) {
        eval {
            $tree->get_app->set_app_statement( $keyword, $new_value );
        };
        if ( $@ ) {
            warn "error: $@\n";
            return;
        }
    }
    else {
        eval {
            $tree->get_app->remove_app_statement( $keyword );
        };
        if ( $@ ) {
            warn "error: $@\n";
            return;
        }
    }

    $self->complete_update();
}

sub do_update_app_statement_bool {
    my $self      = shift;
    my $keyword   = shift;
    my $new_value = unescape( shift );

    my $actual_value = ( $new_value eq 'false' ) ? 0 : 1;

    eval {
        $tree->get_app->set_app_statement( $keyword, $actual_value );
    };
    if ( $@ ) {
        warn "error: $@\n";
    }

    $self->complete_update();
}

sub do_update_app_statement_pair {
    my $self      = shift;
    my $keyword   = shift;
    my $params    = $self->params();

    if ( defined $params->{keys} and $params->{keys} ) {
        eval {
            $tree->get_app->set_app_statement_pairs(
                {
                    keyword   => $keyword,
                    new_value => $params,
                }
            );
        };
        if ( $@ ) {
            warn "error: $@\n";
        }
    }
    else {
        eval {
            $tree->get_app->remove_app_statement( $keyword );
        };
        if ( $@ ) {
            warn "error: $@\n";
        }
    }

    return $self->complete_update();
}

# AJAX handlers for managing app level blocks (including literals)

sub do_create_app_block {
    my $self           = shift;
    my $new_block_name = shift;
    my $block_type     = shift || 'stub';

    my @new_blocks;

    if ( $new_block_name =~ /(.*?)::(.*)/ ) {
        my ( $type, $name ) = ( $1, $2 );

        # Make the requested block.
        my $new_block = $tree->create_block(
                $type, $name, { subtype => $block_type }
        );
        push @new_blocks, $new_block;

        # Make extra blocks the user probably wants.
        if ( $type eq 'table' ) {
            # add other fields?

            $tree->change_statement(
                {
                    type      => 'table',
                    ident     => $new_block->get_ident(),
                    keyword   => 'foreign_display',
                    new_value => '%ident',
                }
            );

            # add a controller for it
            my $descr         = $name;
            $descr            =~ s/_/ /g; # underscores to spaces

            my $model_label   = Bigtop::ScriptHelp->default_label( $name );

            my $control_block = $tree->create_block(
                    'controller',
                    Bigtop::ScriptHelp->default_controller( $name ),
                    { subtype          => 'AutoCRUD',
                      table            => $name,
                      text_description => $descr,
                      page_link_label  => $model_label,
                    }
            );
            push @new_blocks, $control_block;
        }
        elsif ( $type eq 'sequence' ) {
            my $table_name  = $name;
            $table_name     =~ s/_seq//;

            my $table_block = $tree->create_block(
                    'table', $table_name, { sequence => $name }
            );
            push @new_blocks, $table_block;

            $tree->change_statement(
                {
                    type      => 'table',
                    ident     => $table_block->get_ident(),
                    keyword   => 'foreign_display',
                    new_value => '%ident',
                }
            );

            my $control_block = $tree->create_block(
                    'controller',
                    ucfirst $table_name,
                    { subtype => 'AutoCRUD',
                      table   => $table_name,
                    }
            );
            push @new_blocks, $control_block;
        }
    }
    else {
        warn "error: mal-formed create_app_block request\n";
        return;
    }

    # now fill in the new app_body element
    my $new_divs     = '';

    $self->stash->view->template( 'new_app_body_div.tt' );
    delete $self->{__TEMPLATE_WRAPPER__}; # just in case

    foreach my $new_block ( @new_blocks ) {
        my $block_hashes = $new_block->walk_postorder( 'app_block_hashes' );

        $self->stash->view->data(
            {
                block      => $block_hashes->[0],
                statements => $statements,
            }
        );

        eval {
            $new_divs .= $self->do_process( ) || '';
        };
        if ( $@ ) {
            warn "error: $@\n";
        }
    }

    $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
    $self->update_backends( $tree );

    $self->template_disable( 1 );

    if ( $testing ) {
        return $self->deparsed;
    }
    else {
        return $self->stash->controller->data( $new_divs . $self->deparsed );
    }
}

sub do_delete_block {
    my $self         = shift;
    my $doomed_ident = shift;

    my $instructions;

    eval {
        $instructions = $tree->delete_block( $doomed_ident );
    };
    if ( $@ ) {
        warn "Error: $@\n";
    }

    my ( $jsons, $keywords_used ) = _make_json_center( $instructions );

    my $json = "[\n" . join( ",\n", @{ $jsons } ) . "\n]\n";

    $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
    $self->update_backends( $tree );

    $self->template_disable( 1 );
    return $self->stash->controller->data( $json . $self->deparsed );
}

sub do_move_block_after {
    my $self  = shift;
    my $mover = shift;
    my $pivot = shift;

    $tree->move_block( { mover => $mover, pivot => $pivot, after => 1 } );

    $self->complete_update();
}

# log_warn is for use during testing with Test::Warn::warns_ok which eats
# all output on STDERR.
#sub log_warn {
#    open my $LOG, '>>', 'warn.log' or die "Couldn't write warn.log: $!\n";
#
#    print $LOG @_;
#
#    close $LOG;
#}

sub do_create_subblock {
    my $self           = shift;
    my $new_block_name = shift;
    my $block_type     = shift || 'stub';

    my @new_blocks;

    my ( $parent_type, $parent_ident, $type, $name );
    if ( $new_block_name =~ /(.*)::(.*)::(.*)::(.*)/ ) {
        ( $parent_type, $parent_ident, $type, $name ) = ( $1, $2, $3, $4 );

        eval {
            my @names = split /\s+/, unescape( $name );

            foreach my $name ( @names ) {
                my $new_block = $tree->create_subblock(
                    {
                        parent    => {
                            type => $parent_type, ident => $parent_ident
                        },
                        new_child => {
                            type     => $type,
                            name     => $name,
                            sub_type => $block_type,
                        },
                    }
                );
 
                if ( $type eq 'field' ) {
                    my $ident = $new_block->get_ident;
                    $new_block->add_field_statement(
                        {
                            ident     => $ident,
                            keyword   => 'is',
                            new_value => 'varchar',
                        }
                    );
                    $new_block->add_field_statement(
                        {
                            ident     => $ident,
                            keyword   => 'label',
                            new_value =>
                                    Bigtop::ScriptHelp->default_label( $name ),
                        }
                    );
                    $new_block->add_field_statement(
                        {
                            ident     => $ident,
                            keyword   => 'html_form_type',
                            new_value => 'text',
                        }
                    );
                }
                push @new_blocks, $new_block;
            }
        };
        if ( $@ ) {
            warn "Error creating subblock: $@\n";
            return;
        }
    }
    else {
        warn "error: mal-formed create_field_block request\n";
        return;
    }

    delete $self->{__TEMPLATE_WRAPPER__}; # just in case

    my $template     = ( $type eq 'field' )  ? 'new_field_div.tt'
                     : ( $type eq 'method' ) ? 'new_method_div.tt'
                                             : 'new_controller_config_div.tt';
    my @new_divs;
    my $new_block_hashes;
    my $table_block_hash;

    if ( defined $new_blocks[0] and defined $new_blocks[0]{__PARENT__} ) {
        my $parent_hashes = $new_blocks[0]{__PARENT__}->walk_postorder(
                'app_block_hashes'
        );
        $new_block_hashes = $parent_hashes->[0]{ body }{ fields };
        $table_block_hash = $parent_hashes->[0];
    }

    foreach my $new_block ( @new_blocks ) {
        my $field_hashes = $new_block->walk_postorder( 'app_block_hashes' );

        $self->stash->view->template( $template );
        $self->stash->view->data(
            {
                item       => $field_hashes->[0],
                block      => { ident => $parent_ident },
                statements => $statements,
            }
        );

        eval {
            my $tmp_div = $self->do_process( );

            $tmp_div =~ s/^\s+//;
            $tmp_div =~ s/\s+\Z//m;

            push @new_divs, $tmp_div;
        };
        if ( $@ ) {
            warn "error: $@\n";
            return;
        }
    }

    $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
    $self->update_backends( $tree );

    my $new_divs = join '<!-- BEGIN DIV -->', @new_divs;

    # make quick table and data statement table if needed
    my $data_statement_table = '';
    my $quick_table          = '';
    if ( $type eq 'field' ) {
        # quick edit table
        $self->stash->view->template( 'new_quick_edit.ttc' );
        $self->stash->view->data(
            {
                table_ident => $parent_ident,
                fields      => $new_block_hashes,
                statements  => $statements,
            }
        );

        eval {
            $quick_table = $self->do_process();

            $quick_table =~ s/^\s+//;
            $quick_table =~ s/\s+\Z//m;
        };
        if ( $@ ) {
            warn "error: $@\n";
            return;
        }

        # data statement table
        $self->stash->view->template( 'new_data_div.ttc' );
        $self->stash->view->data(
            {
                block       => $table_block_hash,
            }
        );

        eval {
            $data_statement_table = $self->do_process();

            $data_statement_table =~ s/^\s+//;
            $data_statement_table =~ s/\s+\Z//m;
        };
        if ( $@ ) {
            warn "error: $@\n";
            return;
        }

    }

    $self->template_disable( 1 );

    return $self->stash->controller->data(
        $data_statement_table
        . '<!-- END DATA TABLE -->'
        . $quick_table
        . '<!-- END QUICK TABLE -->'
        . $new_divs 
        . $self->deparsed 
    );
}

sub do_update_statement {
    my $self      = shift;
    my $type      = shift;
    my $ancestors = shift;
    my $keyword   = shift;
    my $new_value = unescape( @_ );

    my $already_completed;

    eval {
        if ( not defined $new_value
                    or
             $new_value eq 'undef'
                    or
             $new_value eq 'undefined'
        ) {
            $tree->remove_statement(
                {
                    type    => $type,
                    ident   => $ancestors,
                    keyword => $keyword,
                }
            );
        }
        else {
            my $success = $tree->change_statement(
                {
                    type      => $type,
                    ident     => $ancestors,
                    keyword   => $keyword,
                    new_value => $new_value,
                }
            );

            if ( $type eq 'field'
                    and
                 ref $success eq 'ARRAY'
                    and
                 $success->[0] =~ /^date/
               )
            {
                # tell the tree so it can update these:
                #   controller uses calendar plugin
                #   form has a name (the table's name)
                #   form has extra_keys key javascript
                #   field's html_form_type is text
                #   and either date_select_text or is

                my $result = $tree->field_became_date(
                    {
                        ident   => $ancestors,
                        trigger => $success->[0],
                    }
                );

                # make jason here
                my ( $jsons, $keywords_used ) = _make_json_center( $result );
                my $json = "[\n" . join( ",\n", @{ $jsons } ) . "\n]\n";

                $already_completed = 1;

                $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
                $self->update_backends( $tree );

                $self->template_disable( 1 );
                $self->stash->controller->data( $json . $self->deparsed );
            }

            if ( $type eq 'method'
                    and
                 $keyword eq 'paged_conf'
                    and
                 ref $success eq 'ARRAY'
            ) {
                my ( $json_center ) = _make_json_center(
                    [
                        "app_conf_value::$success->[0]",
                        $success->[1]
                    ]
                );
                my $json = "[\n" . join( ",\n", @{ $json_center } ) . "\n]\n";

                $already_completed = 1;

                $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
                $self->update_backends( $tree );

                $self->template_disable( 1 );
                $self->stash->controller->data( $json . $self->deparsed );
            }
        }
    };
    if ( $@ ) {
        warn "Error changing statement: $@\n";
    }

    if ( $already_completed ) {
        return $self->stash->controller->data();
    }
    else {
        return $self->complete_update();
    }
}

sub do_update_block_statement_text {
    my $self      = shift;
    my $type      = shift;
    my $parameter = shift;
    my $new_value = unescape( @_ );

    if ( $parameter =~ /(.*)::(.*)/ ) {
        my ( $ident, $keyword ) = ( $1, $2 );

        return $self->do_update_statement(
            $type, $ident, $keyword, $new_value
        );
    }
    else {
        warn "error: mal-formed update_block_statement_text request\n";
        return;
    }
}

sub do_update_subblock_statement_text {
    my $self      = shift;
    my $type      = shift;
    my $parameter = shift;
    my $new_value = unescape( @_ );

    if ( $parameter =~ /(.*)::(.*)/ ) {
        my ( $parent, $keyword ) = ( $1, $2 );

        return $self->do_update_statement(
            $type, $parent, $keyword, $new_value
        );
    }
    else {
        warn "error: mal-formed update_subblock_statement_text request\n";
        return;
    }
}

    # This one takes its args from the query string.
sub do_update_subblock_statement_pair {
    my $self      = shift;
    my $type      = shift;
    my $parameter = shift;
    my %params    = $self->get_param_hash();

    if ( $parameter =~ /(.*)::(.*)/ ) {
        my ( $ident, $statement ) = ( $1, $2 );

        eval {
            if ( $params{ keys } ) {
                $tree->change_statement(
                    {
                        type      => $type,
                        ident     => $ident,
                        keyword   => $statement,
                        new_value => \%params,
                    }
                );
            }
            else {
                $tree->remove_statement(
                    {
                        type    => $type,
                        ident   => $ident,
                        keyword => $statement,
                    }
                );
            }
        };
        if ( $@ ) {
            warn "Error changing paired statement: $@\n";
        }
    }
    else {
        warn "error: mal-formed do_update_*_statement_pair request\n";
        return;
    }

    $self->complete_update();
}

# AJAX handlers for table blocks (inside the app block)

sub do_update_table_statement_text {
    my $self = shift;

    $self->do_update_block_statement_text( 'table', @_ );
}

sub do_update_table_statement_pair {
    my $self = shift;
    return $self->do_update_subblock_statement_pair( 'table', @_ )
}

sub do_update_data_statement {
    my $self         = shift;
    my $statement_id = shift;
    my $new_value    = unescape( @_ );

    my $new_block_hashes;

    if ( $statement_id =~ /.*::(.*)::(.*)::(.*)/ ) {
        my (  $table_ident, $field_ident, $data_statement_number ) =
            ( $1,           $2,           $3 );

        eval {
            $new_block_hashes = $tree->data_statement_change(
                {
                    table     => $table_ident,
                    field     => $field_ident,
                    st_number => $data_statement_number,
                    value     => $new_value,
                }
            );
        };
        if ( $@ ) {
            warn "Error changing data statement: $@\n";
        }
    }
    else {
        warn "error: mal-formed do_update_data_statement request\n";
        return;
    }

    $self->stash->view->template( 'new_data_div.ttc' );
    delete $self->{__TEMPLATE_WRAPPER__}; # just in case

    $self->stash->view->data(
        { block      => $new_block_hashes->[0], }
    );

    my $new_div;
    eval {
        $new_div = $self->do_process( ) || '';
    };
    if ( $@ ) {
        warn $@;
    }

    $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
    $self->update_backends( $tree );

    $self->template_disable( 1 );

    return $self->stash->controller->data( $new_div . $self->deparsed );
}

sub do_update_name {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    my ( $type, $ident );
    my $instructions;

    if ( ( $type, $ident ) = split /::/, $parameter ) {

        eval {
            if ( $new_value eq 'undef' or $new_value eq 'undefined' ) {
                warn 'Error: To delete an item use its Delete button, '
                        .   "don't blank the name.\n";
            }
            else {
                $instructions = $tree->change_name(
                    {
                        ident        => $ident,
                        type         => $type,
                        new_value    => $new_value,
                    }
                );
            }
        };
        if ( $@ ) {
            warn "Error changing statement: $@\n";
        }
    }
    else {
        warn "error: mal-formed update_table_statement_text request\n";
        return;
    }

    my ( $jsons, $keywords_used ) = _make_json_center( $instructions );

    if ( $type eq 'field' ) {
        push @{ $jsons },
             qq/  { "keyword" : "field_edit_option\::$ident", /
                .   qq/"text" : "$new_value" }/;

        push @{ $jsons },
             qq/  { "keyword" : "field_name\::$ident", /
                .   qq/"value" : "$new_value" }/;

        if ( $keywords_used->{ $ident . '::label' } ) { # quick edit too
            push @{ $jsons },
                 qq/  { "keyword" : "quick_label_$ident", /
                    .   q/"value" : /
                    .   qq/"$keywords_used->{ $ident . '::label' }" }/;
        }
    }

    my $json = "[\n" . join( ",\n", @{ $jsons } ) . "\n]\n";

    $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
    $self->update_backends( $tree );

    $self->template_disable( 1 );
    return $self->stash->controller->data( $json . $self->deparsed );
}

sub _make_json_center {
    my $instructions = shift;
    my @jsons;
    my %keywords_used;

    while ( @{ $instructions } ) {
        my $keyword = shift @{ $instructions };
        my $values  = shift @{ $instructions };

        $keywords_used{ $keyword } = $values;

        if ( ref( $values ) eq 'arg_list'
                    or
             ref( $values ) eq 'ARRAY'
        ) {
            my @result_values;
            my $result_type;
            foreach my $val ( @{ $values } ) {
                if ( ref( $val ) eq 'HASH' ) {
                    my @hashes;
                    foreach my $key ( keys %{ $val } ) {
                        push @hashes,
                             qq/      { "keyword" : "$key",\n        /
                             .  qq/"value" : "$val->{ $key }" }/;
                    }
                    push @result_values, join( ",\n", @hashes );
                    $result_type = 'hashes';
                }
                else {
                    $result_type = 'values';
                    push @result_values, qq{      "$val"};
                }
            }
            my $result_values =
                    qq"[\n" . join( ",\n", @result_values ). qq"\n    ]";
            push @jsons,
                qq/  { "keyword" : "$keyword", /
                .   qq/"$result_type" : $result_values\n  }/;
        }
        elsif ( $keyword =~ s/^app_conf_value::// ) {
            push @jsons,
                qq/  { "keyword" : "$keyword", "config_value" : "$values" }/;
        }
        else {
            push @jsons,
                qq/  { "keyword" : "$keyword", "value" : "$values" }/;
        }
    }

    return \@jsons, \%keywords_used;
}

sub do_update_field_statement_bool {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    my ( $real_value ) = ( $new_value eq 'true' ) ? 1 : 0;

    return $self->do_update_subblock_statement_text(
        'field', $parameter, $real_value
    );
}

sub do_update_field_statement_text {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( @_ );

    return $self->do_update_subblock_statement_text(
        'field', $parameter, $new_value
    );
}

    # This one takes its args from the query string.
sub do_update_field_statement_pair {
    my $self = shift;
    return $self->do_update_subblock_statement_pair( 'field', @_ )
}

sub do_table_reset_bool {
    my $self        = shift;
    my $table_ident = shift;
    my $keyword     = shift;
    my $raw_value   = shift;

    my $new_value   = ( $raw_value eq 'true' ) ? 1 : 0;

    my $field_idents = join ',', @{ $tree->table_reset_bool(
        {
            ident     => $table_ident,
            keyword   => $keyword,
            new_value => $new_value,
        }
    ) };

    $self->deparsed( Bigtop::Deparser->deparse( $tree ) );
    $self->update_backends( $tree );

    $self->template_disable( 1 );

    return $self->stash->controller->data(
        "$new_value;$table_ident;$field_idents"
        . $self->deparsed
    );
}

# AJAX handlers for join_table blocks (inside the app block)

sub do_update_join_table_statement_pair {
    my $self = shift;
    return $self->do_update_subblock_statement_pair( 'join_table', @_ );
}

# AJAX handlers for controller blocks (inside the app block)

sub do_update_controller_statement_text {
    my $self = shift;

    $self->do_update_block_statement_text( 'controller', @_ );
}

sub do_update_controller_statement_bool {
    my $self      = shift;
    my $parameter = shift;
    my $value     = shift;
    my $extra     = shift;

    $value = ( $value eq 'true' ) ? 1 : 0;

    return $self->do_update_block_statement_text(
        'controller',
        $parameter,
        $value,
        $extra,
    );
}

sub do_update_method_statement_text {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( @_ );

    return $self->do_update_subblock_statement_text(
        'method',
        $parameter,
        $new_value,
    );
}

sub do_update_method_statement_bool {
    my $self      = shift;
    my $parameter = shift;
    my $new_value = unescape( shift );

    $new_value = ( $new_value eq 'true' ) ? 1 : 0;

    return $self->do_update_subblock_statement_text(
        'method',
        $parameter,
        $new_value,
    );
}

sub do_update_controller_statement_pair {
    my $self = shift;
    return $self->do_update_subblock_statement_pair( 'controller', @_ );
}

    # This one takes its args from the query string.
sub do_update_method_statement_pair {
    my $self = shift;
    return $self->do_update_subblock_statement_pair( 'method', @_ )
}

sub do_type_change {
    my $self       = shift;
    my $ident      = shift;
    my $new_type   = shift;

    eval {
        $tree->type_change(
            {
                ident    => $ident,
                new_type => $new_type,
            }
        );
    };
    if ( $@ ) {
        warn "Error in type_change: $@\n";
    }

    $self->complete_update();
}

sub do_update_literal {
    my $self      = shift;
    my $ident     = shift;
    pop @_ while ( $_[-1] eq 'undefined' );
    my $new_value = unescape( @_ );

    eval {
        $tree->walk_postorder(
            'change_literal', { ident => $ident, new_value => $new_value }
        );
    };
    if ( $@ ) {
        warn "Error in literal change:$@\n";
    }

    $self->complete_update();
}

# AJAX handlers for the config block inside the app block

sub do_update_app_conf_statement {
    my $self    = shift;
    my $id      = shift;
    my $checked = pop; # it's always last, but value can be in several slots
    my $value   = unescape( @_ );
    my $accessor;

    my ( $ident, $keyword ) = split /::/, $id;

    if ( $value eq 'undefined' or $value eq 'undef' ) {
        $value = '';
    }

    # if box is checked, don't make an accessor
    if ( defined $checked ) {
        $accessor = ( $checked eq 'undefined' ) ? undef :
                    ( $checked eq 'false'     ) ? 0     : 1;
    }

    $tree->get_app->set_config_statement(
        $ident,
        $keyword,
        $value,
        $accessor,
    );

    $self->complete_update();
}

sub do_update_app_conf_accessor {
    my $self    = shift;
    my $id      = shift;
    my $value   = unescape( shift );

    my ( $ident, $keyword ) = split /::/, $id;

    my $actual_value = ( $value eq 'false' ) ? 0 : 1;

    eval {
        $tree->get_app->set_config_statement_status(
            $ident,
            $keyword,
            $actual_value,
        );
    };
    warn $@ if $@;

    $self->complete_update();
}

sub do_delete_app_config {
    my $self    = shift;
    my $ident   = shift;
    my $keyword = shift;

    $tree->get_app->delete_config_statement( $ident, $keyword );

    $self->complete_update();
}

# AJAX handler helpers

sub change_conf {
    my $tree      = shift;
    my $type      = shift;
    my $backend   = shift;
    my $keyword   = shift;
    my $value     = shift;
    my $config    = $tree->get_config();

    STATEMENT:
    for( my $i = 0; $i <= $#{ $config->{__STATEMENTS__} }; $i++ ) {
        next STATEMENT unless (
                ref( $config->{__STATEMENTS__}[$i][1] ) eq 'HASH'
        );  # find backends, skip simple statements

        if ( $config->{__STATEMENTS__}[$i][0] eq $type
                    and
            $config->{__STATEMENTS__}[$i][1]{__NAME__} eq $backend
        ) {
            if ( $value eq 'undef' or $value eq 'undefined' ) {
                delete $config->{__STATEMENTS__}[$i][1]{ $keyword };
            }
            else {
                $config->{__STATEMENTS__}[$i][1]{ $keyword } = $value;
            }
            last STATEMENT;
        }
    }
}

sub drop_backend {
    my $tree      = shift;
    my $type      = shift;
    my $backend   = shift;
    my $config    = $tree->get_config();

    # remove the item from the __STATEMENTS__ list
    my $doomed_element = -1;

    STATEMENT:
    for( my $i = 0; $i <= $#{ $config->{__STATEMENTS__} }; $i++ ) {

        next STATEMENT unless (
                ref( $config->{__STATEMENTS__}[$i][1] ) eq 'HASH'
        );  # find backends, skip simple statements

        if ( $config->{__STATEMENTS__}[$i][0] eq $type
                    and
            $config->{__STATEMENTS__}[$i][1]{__NAME__} eq $backend
        ) {
                $doomed_element = $i;
                last STATEMENT;
        }
    }
    if ( $doomed_element >= 0 ) {
        splice @{ $config->{__STATEMENTS__} }, $doomed_element, 1;
    }
}

sub add_backend {
    my $tree      = shift;
    my $type      = shift;
    my $backend   = shift;
    my $config    = $tree->get_config();

    if ( $type eq 'Init' ) { # put it at the top
        unshift @{ $config->{__STATEMENTS__} },
                [ 'Init', { __NAME__ => $backend } ];
    }
    else {
        push @{ $config->{__STATEMENTS__} },
             [ $type, { __NAME__ => $backend } ];
    }

    $config->{ $type } = { __NAME__ => $backend };
}

sub update_backends {
    my $self   = shift;
    my $tree   = shift;
    my $config = $tree->get_config();

    # remove old values
    foreach my $type ( keys %backends ) {
        foreach my $backend ( keys %{ $backends{ $type } } ) {
            $backends{ $type }{ $backend }{ in_use     } = 0;
            $backends{ $type }{ $backend }{ statements } = {};
        }
    }

    # set current values
    CONFIG_ITEM:
    foreach my $block ( @{ $config->{__STATEMENTS__} } ) {

        my ( $type, $backend ) = @{ $block };

        next CONFIG_ITEM unless ( ref( $backend ) eq 'HASH' ); # blocks only

        my $name       = $backend->{__NAME__};
        my $statements = _get_backend_block_statements( $backend );

        $backends{ $type }{ $name }{ in_use     } = 1;
        $backends{ $type }{ $name }{ statements } = $statements;
    }
}

sub _get_backend_block_statements {
    my $backend = shift;

    my %retval;

    STATEMENT:
    foreach my $statement ( keys %{ $backend } ) {
        next STATEMENT if $statement eq '__NAME__';

        $retval{ $statement } = [ $backend->{ $statement } ];
    }

    return \%retval;
}

# Accessors and global helpers

sub read_file {
    my $self         = shift;
    my $new_app_name = shift || 'Sample';

    my $BIGTOP_FILE;
    my $file_name = $self->get_file;

    my $retval;

    if ( $file_name ) {
        unless ( open $BIGTOP_FILE, '<', $file_name ) {
            die "Couldn't read '$file_name': $!\n  perhaps you needed -n?\n";

            return '';
        }

        $retval = join '', <$BIGTOP_FILE>;

        close $BIGTOP_FILE;
    }
    else {
        $retval = Bigtop::ScriptHelp->get_minimal_default( $new_app_name );
    }

    $self->input( $retval );

    return $retval;
}

sub set_file {
    my $self     = shift;
    my $new_file = shift;

    if ( not defined $file or defined $new_file and $new_file ne $file ) {
        $file = $new_file;
        undef $input;
        undef $tree;
    }
}

sub get_file {
    my $self = shift;

    return $file;
}

sub get_tree {
    return $tree;
}

sub input {
    my $self      = shift;
    my $new_input = shift;

    if ( defined $new_input ) {
        $input = $new_input;
    }

    return $input
}

sub deparsed {
    my $self     = shift;
    my $deparsed = shift;

    if ( defined $deparsed ) {
        $input = $deparsed;
        $dirty = 1;
    }

    return $input
}

sub dirty {
    return $dirty;
}

1;

=head1 NAME

Bigtop::TentMaker - A Gantry App to Help You Code Bigtop Files

=head1 SYNOPSIS

Start the tentmaker:

    tentmaker [ --port=8192 ] [ file ]

Point your browser to the address it prints.  Consult the POD for the
tentmaker script for other command line options.

=head1 DESCRIPTION

Bigtop is a language for describing web applications.  The Bigtop language
is fairly complete, in that it lets you describe complex apps,
but that means it is not so small.  This module (and the tentmaker
script which drives it) helps you get the syntax right using your
browser.

Unless you need to work on tentmaker internals, you probably want to read
the POD for the tentmaker script instead of the rest of this documentation.
You might also want to look at C<Bigtop::Docs::TentTut> and/or
C<Bigtop::Docs::TentRef>.

=head1 HANDLERS

There are three types of methods in this module: handlers called by browser
action, methods called by the driving script during launch, and methods
which help the others.  This section discusses the handlers.  See below
for details on the other types.

=head2 do_main

This is the main handler users hit to initially load the page.  It sends
them the tenter.tt template populated with data from the file given on
the command line.  If no file is given, it gives them a small default
bigtop as a starting point.

Expects: nothing

=head2 do_save

Writes current abstract syntax tree back to the disk.

Params:

    full_path

Returns:

stash controller data saying either "Saved..." or "Couldn't write...'

The remaining handlers are all AJAX handlers.  They are triggered by GUI
events and return the plain text representation of the updated
abstract syntax tree being edited.

Each routine is given a parameter (think keyword) and a new value.
Some of them also receive additional data, see below.  Errors are
trapped and reported as warnings on the server side.

=head2 do_server_stop

Kills the running tentmaker.

Params: None

Returns: undef

Note that the script usually dies before it can return a good AJAX response
to the browser, which results in one Javascript error in the browser.

=head2 do_update_std

This method only serves to update the app name.  It does that by calling
set_appname on the AST.

=head2 do_update_top_config_text

This method is a generic accessor for top level config block statements.

Parameters:

    the top level config statement name
    the new value to give it

If the new value is 'undefined' (the string), the statement will be cleared.

=head2 do_update_backend

This method handles backend selection/deselection.

Params:

    backend_type::backend
    new_value

The backend_type::backend must be a module in the Bigtop::Backend::
namespace.

The new value is a string (repeat: it is a string).  If the string eq 'false',
the backend is dropped from the config block of the file.  Otherwise,
it is added to the list.

Note well: When a config is dropped, all of the statements in its config block
are LOST.  This creates a disappointing end user reality.  If you uncheck
a backend box by mistake, after you recheck it, you must go focus and
defocus on all text backend statements and check and uncheck all checkboxes.
This is bad.

=head2 do_update_conf_bool

Allows toggling for boolean backend block keywords.

Parameters:

    type::backend::keyword
    new_value

As in do_update_backend, the new value is a string 'false' means the
user unchecked the box, anything else means she checked it.

It uses change_conf to do the actual work.

=head2 do_update_conf_bool_controlled

Like do_update_conf_bool, but allows control over what true and false mean.

Parameters:

    type::backend::keyword
    new_value
    false_value
    true_value

If the new value eq 'false', the false value is assigned, otherwise
the true value is used.  This facilitates statements like the Init::Std
'Changes no_gen', where the value of the statement is not zero or one.
In that case, the value should be undef or the string no_gen.

If one of the values is the string 'undef' or 'undefined' the statement
will be deleted from the backend.

It uses change_conf to do the actual work.

=head2 do_update_conf_text

Updates backend block statements which have string values.

Parameters:

    type::backend::keyword
    new_value

This is like do_update_conf_bool, except that the new value is used
as the statement value.  If the value is false, the statement is
removed from the backend's config block.

It uses change_conf to do the actual work.

=head2 do_update_app_statement_text

Creates/updates the value of app level statements, when the value is text.

Parameters:

    statement_keyword
    new_value

It uses set_app_statement on the application subtree in Bigtop::Parser.

=head2 do_update_app_statement_bool

Like do_update_app_statement_text, but for when the value is boolean.

Parameters:

    statement_keyword
    new_value

Use the word 'false' to delete the statement.

It uses set_app_statement on the application subtree in Bigtop::Parser.

=head2 do_update_app_statement_pair

Somewhat like do_update_app_statement_text, but for when the value takes
one or more pairs.

Parameters:

    keyword

Query string params:

    keys=key1][key2][key3&values=value1][value2][value3

Note that the key/value pairs are passed in the query string.

If there are no keys, the statement is removed.

It uses set_app_statement_pairs on the application subtree in Bigtop::Parser.

=head2 do_delete_app_config

Removes a statement from the app level config block.

Params:

    keyword

=head2 do_update_app_conf_statement

Creates/updates an app level config statement.

Params:

    keyword
    value
    accessor

keyword is the name of the config statement (which is entirely up to the
user, except that it must be a valid ident).

value is the completely arbitrary value of the statement (except that it
can't have embedded backticks).

accessor is only used if the statement is new.  In that case, this is
the value for the accessor check box.  If it is set, an accessor will
be made for the statement, otherwise we assume the framework is handling
it.

=head2 do_update_app_conf_accessor

For exisiting app level config statements, changes the accessor flag.

Params:

    keyword
    value

keyword is the name of that config statement.

value is either the string 'false' or anything else.  If the value eq 'false',
the accessor flag is removed.  Otherwise, it is set.

=head2 do_update_name

Changes the name of a named block.

Params:

    type::ident
    new_value

Each nameable block in the Bigtop AST has a unique ident.  Calling this with
the type of the block, that ident, and a new value changes its name.

=head2 do_create_app_block

Makes a new app level block.

Params:

    type::name
    subtype

The type can be sequence, table, join_table, or controller.  The name
must be a valid ident.  If they block's type understands a subtype,
include it as a second, separate, parameter.  Only controllers
have types and they are: AutoCRUD, CRUD, or stub.

It uses create_block on the AST.

=head2 do_create_subblock

Makes a new block inside a table or controller.

Params:

    parent_type::parent_ident::type::name
    subtype

The parent type can be table or controller.  The type can be field (for
tables) or method (for controllers).  The name must be a valid ident.
Methods must have subtypes.  Choose from: AutoCRUD_form, CRUD_form,
or main_listing.

It uses create_subblock on the AST.

=head2 do_delete_block

Removes a block from the AST.

Params:

    ident

The front end is responsible for any user confirmation popups.

It uses delete_block on the AST.

=head2 do_type_change

Changes the is type for blocks which acept those.

Params:

    ident
    new_type

new_type must be a string naming the new type.

Applies to controllers and methods.

It uses type_change on the AST.

=head2 do_update_block_statement_text

Creates/updates a statement in a block.

Params:

    block_type
    ident::keyword
    new_value

block_type is table, join_table, or controller.

If new_value is false, the statement will be removed.

It uses do_update_statement (see below).

=head2 do_update_controller_statement_bool

Directly calls do_update_block_statement_text, specifying type controller.

If value eq 'true', the statement is made true, otherwise it will be
removed.

=head2 do_update_controller_statement_text

Directly calls do_update_block_statement_text, specifying type controller.

=head2 do_update_controller_statement_pair

Directly calls do_update_subblock_statement_pair, specifying type controller.

=head2 do_update_statement

Updates statements at many levels of the tree, including table, join_table,
controller, field, and method blocks.

Params:

    block_type
    block_ident
    keyword
    new_value

It uses either change_statement or remove_statement.

I don't think this is called by the templates or their javascript.

=head2 do_update_table_statement_text

Directly calls do_update_block_statement_text specifying type table.

=head2 do_update_table_statement_pair

Directly calls do_update_subblock_statement_pair specifying type table
and passing on all parameters.

=head2 do_update_data_statement

Tells the tree to update or add a data statement to an existing table.
Only one argument of the data statement is ever updated.  This corresponds
to the single box the user updated in the front end.

Params:
    statement_id
    new_value

The statement id must be of the form:

    data_value::ident_9::ident_4::2

where data_value is literal (and is discarded), ident_9 is the table's
ident, ident_4 is the ident of the field whose value should become new_value,
and 2 is the number of the data statement.  The data statement number
starts at 1 and is the order of appearance of the statement to change.

If the new_value is false, the item will be removed from the data statement.
Yes, this is a problem is you want a zero.

=head2 do_table_reset_bool

Tells the tree to set one keyword to true or false for all of its fields.

Params:
    table_ident
    keyword
    raw_value

The raw_value is a string, either 'true' or 'false.'

=head2 do_update_field_statement_bool

Creates/updates boolean statements in field blocks.

Params:

    keyword
    new_value

If new_value eq 'true' the statement will be made true, otherwise it
will be removed.

It uses do_update_subblock_statement_text.

=head2 do_update_field_statement_pair

Immediately calls do_update_subblock_statement_pair, specifying type field.

=head2 do_update_field_statement_text

Immediately calls do_update_subblock_statement_text, specifying type field.

=head2 do_update_join_table_statement_pair

Immediately calls do_update_subblock_statement_pair, specifying type
join_table.  (Astute readers will note that join_table is a block
not a subblock, the the necessary code is the same for both.  Some
refactoring is probably in order.)

=head2 do_update_literal

Updates the text of a literal.

Params:

    ident
    new_value

new_value can have any charactes except backquotes.

You must create and delete blocks with direct calls to do_create_app_block
and do_delete_block.

It directly calls walk_postorder with 'change_literal' as the action.

=head2 do_update_method_statement_bool

Params:

    keyword
    new_value

If new_value eq 'true' boolean is made true, otherwise the statement
will be removed.

It calls do_update_subblock_statement_text, specifying type method.

=head2 do_update_method_statement_pair

Directly calls do_update_subblock_statement_pair, specifying type method.

=head2 do_update_method_statement_text

Directly calls do_update_subblock_statement_text, specifying type method.

=head2 do_update_subblock_statement_pair

Supports all pair updates in subblocks.

Params:

    type
    ident::keyword

The values are received from the query string:

    keys=key1][key2&values=val1][val2

It uses change_statement on the AST.

=head2 do_update_subblock_statement_text

Supports all single value updates on subblock statements (and some block
statements too).

Params:

    block_type
    block_ident::keyword
    new_value

It uses do_update_statement.

=head2 do_move_block_after

Not yet called by the front end.

Exchanges the position of two app level blocks.

Params:

    ident_to_move
    ident_to_put_it_after

It uses move_block on the AST.

=head1 LAUNCH METHODS

=head2 take_performance_hit

This method allows the server to take the hit of compiling Bigtop::Parser
and initially parsing the input file with it, before declaring that the
server is up and available.  I no longer think this is a good idea,
but for now it is reality.  In any case, since I learned to compile
the grammar into a module, the times involved are no longer significant.

It builds a list of all the backends available on the system (by walking
@INC looking for things in the Bigtop::Backend:: namespace).  It also
reads the file given to it and parses that into a bigtop AST.  Then
it deparses that to produce the initial raw input presented in the browser.
Think of this as canonicallizing the input file for presentation.  Finally,
it builds the statements hash, filling it with docs from all the
keywords that all of the backends register.

=head2 build_backend_list

The backends hash is used internally to know which backends are available,
whether they are in use, and what statements they support.  Documentation
scripts are welcome to call this method to kick start a doc pull from
the backends.  They should then call:

=head2 get_backends

Accessor which returns the internal hash of all backends and their backend
block keywords.

=head2 read_file

Reads the input file.  If the user didn't supply a file, asks
Bigtop::ScriptHelp to generate a starting point using the requested (or
default) style.

=head1 HELPER METHODS

=head2 new

Used by tests to gain a pseudo-instance through which to call helper methods.
For instance, some tests call methods on this instance to turn templating
on an off.  See t/tentmaker/*.t for examples.

=head2 set_testing

Pass this a true value to turn off html dumps from app block creation for
testing.

=head2 show_idents

Used during test development to get a dump of all the idents in the current
tree.  You get Data::Dumper output of an array of the idents.  Each element
is an array listing the type, name, and ident for one tree node.  All nodes
with idents appear in the output, but the order is a bit odd (it is depth
first traversal order).  This saves counting created items on your fingers.

=head2 init

This is a gantry init method.  It fishes the file name from the site object.

=head2 compile_app_configs

Builds an array whose elements are hashes describing each config statement
in the app level config block.

=head2 complete_update

Used by almost all AJAX handlers to deparse the updated tree and return it
to the client.

=head2 unescape

Typical routine to turn %.. into a proper character.  Takes a list which
it will join with slashes to undo HTTP::Server::Simple's overly aggressive
unescaping.

=head2 change_conf

Used by all the do_update_conf_* methods to actually change the config
portion of the AST.

=head2 drop_backend

Used by do_update_backend to remove a backend from the AST.

=head2 add_backend

Used by do_update_backend to add a backend from the AST.

=head2 update_backends

Keeps the backends hash up to date.

=head2 file

Accessor to get/set the name of the input file.  Setting it blows the
cache of other accessible values.

=head2 get_file

Returns the name of the input file given on the command line.

=head2 set_file

Stores the input file name during startup.  Calling this blows the cashed
deparsed bigtop source code and abstarct syntax tree.  Any future request
for the tree or input text will trigger reading of the file.

=head2 get_tree

Returns the Bigtop abstract syntax tree.

=head2 input

Accessor to get/set the input file text in memory.

=head2 deparsed

Accessor to get/set the deparsed (canonicalized) text of the file.

=head2 dirty

Returns 1 if there have been changes since the last save, 0 otherwise.

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-7, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

